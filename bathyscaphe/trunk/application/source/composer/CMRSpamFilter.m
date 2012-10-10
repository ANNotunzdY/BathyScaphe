//
//  CMRSpamFilter.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/10.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRSpamFilter.h"
#import "BSNGExpression.h"
#import "AppDefaults.h"
#import "CMRThreadSignature.h"

static NSString *const kBSSpamSamplesFile = @"SpamSamples.plist";

@implementation CMRSpamFilter(FileReadWrite)
- (NSMutableArray *)restoreFromPlistToCorpus:(id)rep
{
	UTILAssertKindOfClass(rep, NSArray);
	NSMutableArray	*theArray = [NSMutableArray array];
	NSEnumerator	*iter = [rep objectEnumerator];
	NSDictionary	*item;

	while (item = [iter nextObject]) {
		[theArray addObject:[BSNGExpression objectWithPropertyListRepresentation:item]];
	}
	return theArray;
}

- (NSMutableArray *)restoreFromPlistToSamples:(id)rep
{
    UTILAssertKindOfClass(rep, NSArray);
    NSArray *plistArray = (NSArray *)rep;
    NSMutableArray *mutableArray = [NSMutableArray array];
    for (id item in plistArray) {
        [mutableArray addObject:[BSMessageSample objectWithPropertyListRepresentation:item]];
    }
    return mutableArray;
}

- (id)readFromContentsOfPropertyListFile:(NSString *)plistPath
{
	NSData *data;
	id		rep;
	NSString *err = [NSString string];
	NSString *errInfo;
	BOOL	isDir;

	UTILAssertNotNil(plistPath);
	errInfo = [plistPath lastPathComponent];

	if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath isDirectory:&isDir] && !isDir) {
		data = [NSData dataWithContentsOfFile:plistPath];

		if (!data) {
			NSLog(@"Failed to read %@ as NSData.", errInfo);
			return nil;
		}

		rep = [NSPropertyListSerialization propertyListFromData:data
                                               mutabilityOption:NSPropertyListImmutable
                                                         format:NULL
                                               errorDescription:&err];

		if (!rep) {
			NSLog(@"Failed to read %@ with NSPropertyListSerialization. reason:%@", errInfo, err);
		}

		return rep;
	} else {
//		NSLog(@"Failed to read %@. %@ does not exist, or is a folder.", errInfo, errInfo);
		return nil;
	}
}

- (NSArray *)propertyListRepresentation:(NSArray *)base
{
    NSUInteger count = [base count];
    if (count < 1) {
        return [NSArray empty];
    }
    NSMutableArray *plistArray = [NSMutableArray arrayWithCapacity:count];
    id rep;
    for (id<CMRPropertyListCoding> object in base) {
        rep = [object propertyListRepresentation];
        if (rep) {
            [plistArray addObject:rep];
        }
    }
    return plistArray;
}

- (BOOL)saveRepresentation:(id)rep toFile:(NSString *)filepath
{
    if ([rep isKindOfClass:[NSDictionary class]] || [rep isKindOfClass:[NSArray class]]) {
        if ([rep count] == 0) {
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([fm fileExistsAtPath:filepath]) {
                return [fm removeItemAtPath:filepath error:NULL];
            } else {
                return YES;
            }
        }
    }
	NSString *errorStr = [NSString string];
	NSData *binaryData_ = [NSPropertyListSerialization dataFromPropertyList:rep
																	 format:NSPropertyListBinaryFormat_v1_0
														   errorDescription:&errorStr];

	if (!binaryData_) {
		NSLog(@"Failed to serialize with NSPropertyListSerialization. reason:%@", errorStr);
		return [rep writeToFile:filepath atomically:YES];
	}

	return [binaryData_ writeToFile:filepath atomically:YES];
}
@end


@implementation CMRSpamFilter
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance);

@synthesize spamSamples = m_spamSamples;

+ (NSString *)expressionsFilepath
{
	return [[CMRFileManager defaultManager] supportFilepathWithName:BSNGExpressionsFile resolvingFileRef:NULL];
}

+ (NSString *)samplesFilepath
{
    return [[CMRFileManager defaultManager] supportFilepathWithName:kBSSpamSamplesFile resolvingFileRef:NULL];
}

- (id)init
{
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:NSApp];

        NSArray *arrayRep2 = [self readFromContentsOfPropertyListFile:[[self class] samplesFilepath]];
        if (!arrayRep2) {
            arrayRep2 = [NSArray array];
        }
        m_spamSamples = [[self restoreFromPlistToSamples:arrayRep2] retain];

        NSArray *arrayRep = [self readFromContentsOfPropertyListFile:[[self class] expressionsFilepath]];
        if (!arrayRep) {
            arrayRep = [NSArray array];
        }
        [self setNgExpressions:[self restoreFromPlistToCorpus:arrayRep]];
	}
	return self;
}

- (void)dealloc
{
	[m_timer invalidate];
	[m_timer release];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [m_spamSamples release];
    m_spamSamples = nil;
	[self setNgExpressions:nil];

	[super dealloc];
}

- (void)resetSpamFilter
{
    [self.spamSamples removeAllObjects];
    [self saveNgExpressionsAndSamplesToFiles];
}

#pragma mark Accessors
- (NSMutableArray *)ngExpressions
{
	if (!m_spamCorpus) {
		m_spamCorpus = [[NSMutableArray alloc] init];
	}
	return m_spamCorpus;
}

- (void)setNgExpressions:(NSMutableArray *)aSpamCorpus
{
	[aSpamCorpus retain];
	[m_spamCorpus release];
	m_spamCorpus = aSpamCorpus;
}

- (BOOL)needsSaveToFiles
{
	return m_needsSaveToFiles;
}

- (void)setNeedsSaveToFiles:(BOOL)flag
{
	if (!m_timer) {
		m_timer = [[NSTimer scheduledTimerWithTimeInterval:1200 // 20 minutes
													target:self
												  selector:@selector(saveToFilesIfNeeded:)
												  userInfo:nil
												   repeats:YES] retain];
	}

	@synchronized(self) {
		m_needsSaveToFiles = flag;
	}
}

#pragma mark Writing to file
- (void)removeTooOldIDSamples
{
    NSMutableArray *samples = self.spamSamples;
    NSUInteger count = [samples count];
    if (count < 1) {
        return;
    }
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    NSDate *now = [NSDate date];
    NSUInteger i;
    BSMessageSample *sample;
    for (i = 0; i < count; i++) {
        sample = [samples objectAtIndex:i];
        if (sample.sampleType != BSMessageSampleIDType) {
            continue;
        }
        if ([now timeIntervalSinceDate:sample.sampledDate] > 259200) { // 72 hours
            [indexes addIndex:i];
        }
    }
    if ([indexes count] > 0) {
        [samples removeObjectsAtIndexes:indexes];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	UTILAssertNotificationName(
		notification,
		NSApplicationWillTerminateNotification);
	UTILAssertNotificationObject(
		notification,
		NSApp);

	[self saveNgExpressionsAndSamplesToFiles];
}

- (void)saveNgExpressionsAndSamplesToFiles
{
    [self removeTooOldIDSamples];
    [self saveRepresentation:[self propertyListRepresentation:self.spamSamples] toFile:[[self class] samplesFilepath]];
	[self saveRepresentation:[self propertyListRepresentation:[self ngExpressions]] toFile:[[self class] expressionsFilepath]];
}

- (void)saveToFilesIfNeeded:(NSTimer *)timer
{
	if ([self needsSaveToFiles]) {
		[self saveNgExpressionsAndSamplesToFiles];
		[self setNeedsSaveToFiles:NO];
	}
}

#pragma mark NG Expression
- (void)addNGExpression:(BSNGExpression *)expression
{
	[CMRPref willChangeValueForKey:@"spamMessageCorpus"];
	[self willChangeValueForKey:@"ngExpressions"];
	[[self ngExpressions] addObject:expression];
	[self didChangeValueForKey:@"ngExpressions"];
	[CMRPref didChangeValueForKey:@"spamMessageCorpus"];
	[self setNeedsSaveToFiles:YES];
}


#pragma mark Spam Samples
- (void)addMessageSample:(BSMessageSample *)sample
{
    NSString *boardName = [sample.sampledThreadIdentifier boardName];
    BSMessageSample *existingSample = [self sampleOfType:sample.sampleType object:sample.sampleObject withBoard:boardName];
    if (existingSample) {
        [existingSample incrementMatchedCount];
    } else {
        [self.spamSamples addObject:sample];
    }
}

- (void)removeMessageSample:(BSMessageSample *)sample
{
    [self.spamSamples removeObject:sample];
}

- (BSMessageSample *)sampleOfType:(BSMessageSampleType)type object:(NSString *)sampleObject withBoard:(NSString *)boardName
{
    NSArray *samples = self.spamSamples;
    for (BSMessageSample *sample in samples) {
        if (sample.sampleType != type) {
            continue;
        }
        if (![[sample.sampledThreadIdentifier boardName] isEqualToString:boardName]) {
            continue;
        }
        if ([sample.sampleObject isEqualToString:sampleObject]) {
            return sample;
        }
    }
    return nil;
}

- (void)getSpamSampleObjectsForBoard:(NSString *)boardName
                            idString:(NSArray **)idsPtr
                                name:(NSArray **)namesPtr
                                mail:(NSArray **)mailsPtr
{
    NSMutableArray *ids = [NSMutableArray array];
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *mails = [NSMutableArray array];

    NSArray *samples = self.spamSamples;

    for (BSMessageSample *sample in samples) {
        if (![[sample.sampledThreadIdentifier boardName] isEqualToString:boardName]) {
            continue;
        }
        switch (sample.sampleType) {
            case BSMessageSampleIDType:
                [ids addObject:sample.sampleObject];
                break;
            case BSMessageSampleNameType:
                [names addObject:sample.sampleObject];
                break;
            case BSMessageSampleMailType:
                [mails addObject:sample.sampleObject];
                break;
            default:
                break;
        }
    }

    if (idsPtr != NULL) {
        *idsPtr = ids;
    }
    if (namesPtr != NULL) {
        *namesPtr = names;
    }
    if (mailsPtr != NULL) {
        *mailsPtr = mails;
    }
}
@end
