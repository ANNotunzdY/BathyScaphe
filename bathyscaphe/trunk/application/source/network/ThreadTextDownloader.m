//
//  ThreadTextDownloader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "ThreadTextDownloader_p.h"
#import "CMRDATDownloader.h"
#import "CMRThreadHTMLDownloader.h"
#import "DatabaseManager.h"
#import "missing.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"


NSString *const ThreadTextDownloaderDidFinishLoadingNotification = @"ThreadTextDownloaderDidFinishLoadingNotification";
NSString *const ThreadTextDownloaderInvalidPerticalContentsNotification = @"ThreadTextDownloaderInvalidPerticalContentsNotification";
NSString *const CMRDownloaderUserInfoAdditionalInfoKey = @"AddtionalInfo";


@implementation ThreadTextDownloader
+ (Class *)classClusters
{
	static Class classes[3] = {Nil, };
	
	if (Nil == classes[0]) {
		classes[0] = [(id)[CMRDATDownloader class] retain];
		classes[1] = [(id)[CMRThreadHTMLDownloader class] retain];
		classes[2] = Nil;
	}
	
	return classes;
}

+ (id)downloaderWithIdentifier:(CMRThreadSignature *)signature
				   threadTitle:(NSString *)aTitle
					 nextIndex:(NSUInteger) aNextIndex
{
	return [[[self alloc] initWithIdentifier:signature threadTitle:aTitle nextIndex:aNextIndex] autorelease];
}

- (id)initClusterWithIdentifier:(CMRThreadSignature *)signature
					threadTitle:(NSString *)aTitle
					  nextIndex:(NSUInteger)aNextIndex
{
	if (self = [super init]) {
		[self setNextIndex:aNextIndex];
		[self setIdentifier:signature];
		m_threadTitle = [aTitle retain];
	}
	return self;
}
// do not release!
+ (id)allocWithZone:(NSZone *)zone
{
	if ([self isEqual:[ThreadTextDownloader class]]) {
		static id instance_;
		
		if (!instance_) {
			instance_ = [super allocWithZone:zone];
		}
		return instance_;
	}
	return [super allocWithZone:zone];
}

- (id)initWithIdentifier:(CMRThreadSignature *)signature
			 threadTitle:(NSString *)aTitle
			   nextIndex:(NSUInteger)aNextIndex
{
	Class			*p;
	id				instance_;
	NSURL			*boardURL_;
	
	instance_ = nil;
	boardURL_ = [[BoardManager defaultManager] URLForBoardName:[signature boardName]];
	UTILRequireCondition(boardURL_, return_instance);
	
	for (p = [[self class] classClusters]; *p != Nil; p++) {
		if ([*p canInitWithURL:boardURL_]) {
			instance_ = [[*p alloc] initClusterWithIdentifier:signature threadTitle:aTitle nextIndex:aNextIndex];
			break;
		}
	}
	
return_instance:
	return instance_;
}

- (void)dealloc
{	
	NSAssert2(
		NO == [(id)[self class] isEqual:(id)[ThreadTextDownloader class]],
		@"%@<%p> was place holder instance, do not release!!",
		NSStringFromClass([ThreadTextDownloader class]),
		self);

	[m_lastDateStore release];
	[m_localThreadsDict release];
	[m_threadTitle release];
	[super dealloc];
}

- (NSUInteger)nextIndex
{
	return m_nextIndex;
}

- (void)setNextIndex:(NSUInteger)aNextIndex
{
	m_nextIndex = aNextIndex;
}

- (NSDate *)lastDate
{
	return m_lastDateStore;
}

- (void)setLastDate:(NSDate *)date
{
	[date retain];
	[m_lastDateStore release];
	m_lastDateStore = date;
}

+ (BOOL)canInitWithURL:(NSURL *)url
{
	UTILAbstractMethodInvoked;
	return NO;
}

- (CFStringEncoding)CFEncodingForLoadedData
{
	CMRHostHandler	*handler_;
	
	handler_ = [CMRHostHandler hostHandlerForURL:[self boardURL]];
	return handler_ ? [handler_ threadEncoding] : kCFStringEncodingDOSJapanese; // とりあえず
}

- (NSStringEncoding)encodingForLoadedData
{
	CFStringEncoding	enc;
	
	enc = [self CFEncodingForLoadedData];
	return CF2NSEncoding(enc);
}

- (NSString *)contentsWithData:(NSData *)theData
{
	CFStringEncoding	enc;
	NSString			*src = nil;

	if (!theData || [theData length] == 0) return nil;
	
	enc = [self CFEncodingForLoadedData];
	src = [CMXTextParser stringWithData:theData CFEncoding:enc];
	
    // 下の処理は +[CMXTextParser stringWithData:CFEncoding:] にも含まれておりここに書く意味が無い
/*	if (!src) {
		NSLog(@"\n"
			@"*** WARNING ***\n\t"
			@"Can't convert the bytes\n\t"
			@"into Unicode characters(NSString). so retry TEC... "
			@"CFEncoding:%@", 
			(NSString*)CFStringConvertEncodingToIANACharSetName(enc));

		src = [[NSString alloc] initWithDataUsingTEC:theData encoding:CF2TextEncoding(enc)];
		[src autorelease];
	}*/
	return src;
}

- (CMRThreadSignature *)threadSignature
{
	return [self identifier];
}

- (NSString *)threadTitle
{
	return m_threadTitle;
}

- (void)setThreadTitle:(NSString *)title
{
    [title retain];
    [m_threadTitle release];
    m_threadTitle = title;
}

- (NSURL *)threadURL
{
	UTILAbstractMethodInvoked;
	return nil;
}

- (NSDictionary *)localThreadsDict
{
	if (!m_localThreadsDict) {
		m_localThreadsDict = [[NSDictionary alloc] initWithContentsOfFile:[self filePathToWrite]];
	}
	return m_localThreadsDict;
}

- (BOOL)useMaru
{
    return NO;
}
#pragma mark Partial contents
- (BOOL)partialContentsRequested
{
	return ([[self localThreadsDict] objectForKey:ThreadPlistLengthKey] != nil);
}

// To cancel any background loading, cause partial contents was invalid.
- (void)cancelDownloadWithInvalidPartial
{
	NSArray			*recoveryOptions;
	NSDictionary	*dict;
	NSError			*error;

	recoveryOptions = [NSArray arrayWithObjects:[self localizedString:@"PartialContentsRetry"], [self localizedString:@"ErrorRecoveryCancel"], nil];
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
				recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 検討済
				[NSString stringWithFormat:[self localizedString:@"PartialContentsDescription"], [self threadTitle]], NSLocalizedDescriptionKey,
				[self localizedString:@"PartialContentsSuggestion"], NSLocalizedRecoverySuggestionErrorKey,
                [self localizedString:@"PartialContentsHelpAnchor"], NSHelpAnchorErrorKey,
				NULL];

	error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSThreadTextDownloaderInvalidPartialContentsError userInfo:dict];
	UTILNotifyInfo3(ThreadTextDownloaderInvalidPerticalContentsNotification, error, @"Error");
}

#pragma mark CMRDownloader
- (NSString *)filePathToWrite
{
	UTILAssertNotNil([self threadSignature]);
	return [[self threadSignature] threadDocumentPath];
}

- (NSURL *)resourceURL
{
	return [self threadURL];
}

- (NSURL *)boardURL
{
	UTILAssertNotNil([self threadSignature]);
	return [[BoardManager defaultManager] URLForBoardName:[[self threadSignature] boardName]];
}

- (NSURL *)resourceURLForWebBrowser
{
	return [self threadURL];
}

- (NSString *)connectionFailedErrorMessageText
{
    if (![self threadTitle]) {
        return [super connectionFailedErrorMessageText];
    }
    return [NSString stringWithFormat:[self localizedString:@"ConnectionFailedDescription"], [self threadTitle]];
}
@end


@implementation ThreadTextDownloader(ThreadDataArchiver)
- (void)postDATFinishedNotificationWithContents:(NSString *)datContents
								 additionalInfo:(NSDictionary *)additionalInfo
{
	NSDictionary		*userInfo_;
	
	userInfo_ = [NSDictionary dictionaryWithObjectsAndKeys:
					datContents,		CMRDownloaderUserInfoContentsKey,
					additionalInfo,		CMRDownloaderUserInfoAdditionalInfoKey,
					nil];

	UTILNotifyInfo(ThreadTextDownloaderDidFinishLoadingNotification, userInfo_);
}

- (void)updateDatabaseWithContents:(NSDictionary *)logContents
{
	NSMutableDictionary	*userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
	
	NSArray *messages;
	NSUInteger count;
	NSDate *modDate;
	messages = [logContents objectForKey:ThreadPlistContentsKey];
	count = messages ? [messages count] : 0;
	[userInfo setObject:[NSNumber numberWithUnsignedInteger:count] forKey:@"ttd_count"];

	modDate = [logContents objectForKey:CMRThreadModifiedDateKey];
	if (modDate) [userInfo setObject:modDate forKey:@"ttd_date"];
	
	[[DatabaseManager defaultManager] threadTextDownloader:self didUpdateWithContents:userInfo];
}

- (BOOL)synchronizeLocalDataWithContents:(NSString *)datContents
							  dataLength:(NSUInteger)dataLength
{
    NSDictionary *thread;
	NSMutableDictionary *info_;
    BOOL          result = NO;    
    
    // can't process by downloader while viewer execute.
    if ([[CMRNetGrobalLock sharedInstance] has:[self identifier]]) {
        NSLog(@"[WARN] Thread %@ was already inProgress. "
              @"ThreadTextDownloader does nothing. at %@",
              [self identifier],
              UTIL_HANDLE_FAILURE_IN_METHOD);

        return YES;
    }

    thread = [self dictionaryByAppendingContents:datContents dataLength:dataLength];

	info_ = [NSMutableDictionary dictionary];
	[info_ setNoneNil:[thread objectForKey:ThreadPlistLengthKey] forKey:ThreadPlistLengthKey];
	[info_ setNoneNil:[thread objectForKey:CMRThreadModifiedDateKey] forKey:CMRThreadModifiedDateKey];

    // It guarantees that file must exists.
	if ([CMRPref saveThreadDocAsBinaryPlist]) {
		NSData *data_;
		NSString *errStr = [NSString string];
		data_ = [NSPropertyListSerialization dataFromPropertyList:thread format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errStr];

		if (!data_) {
			NSLog(@"NSPropertyListSerialization failed to convert to NSData. Reason:%@", errStr);
			result = NO;
		} else {
			result = [data_ writeToFile:[self filePathToWrite] atomically:YES];
		}
	} else {
		result = [thread writeToFile:[self filePathToWrite] atomically:YES];
	}

    [self updateDatabaseWithContents:thread];
    [self postDATFinishedNotificationWithContents:datContents additionalInfo:info_];

    return result;
}

- (NSDictionary *)dictionaryByAppendingContents:(NSString *)datContents dataLength:(NSUInteger)aLength
{
	NSDictionary			*localThread_;
	NSMutableDictionary		*newThread_;
	NSMutableArray			*messages_;
	
	id<CMRMessageComposer>	composer_;
	CMR2chDATReader			*reader_;
	
	NSUInteger			dataLength_;
	
	dataLength_ = aLength;
	localThread_ = [self localThreadsDict];
	if (!datContents || [datContents length] == 0) return localThread_;
	
	newThread_  = [NSMutableDictionary dictionary];
	messages_ = [NSMutableArray array];

	composer_ = [CMRThreadPlistComposer composerWithThreadsArray:messages_];

	reader_ = [CMR2chDATReader readerWithContents:datContents];

	if (![self partialContentsRequested]) {
		[newThread_ setNoneNil:[reader_ threadTitle] forKey:CMRThreadTitleKey];
        if (![self threadTitle]) {
            [self setThreadTitle:[reader_ threadTitle]];
        }
		[newThread_ setNoneNil:[reader_ firstMessageDate] forKey:CMRThreadCreatedDateKey];
	} else {		
		[newThread_ addEntriesFromDictionary:localThread_];
		[messages_ addObjectsFromArray:[newThread_ objectForKey:ThreadPlistContentsKey]];
		// 
		// We've been got extra 1 byte (for Abone-checking), so we need to adjust.
		//
		dataLength_ += [newThread_ unsignedIntegerForKey:ThreadPlistLengthKey];
		if (dataLength_ > 0) dataLength_--; // important
	}

	[newThread_ setUnsignedInteger:dataLength_ forKey:ThreadPlistLengthKey];
	
	[reader_ setNextMessageIndex:[messages_ count]];
	[reader_ composeWithComposer:composer_];

	messages_ = [composer_ getMessages];
	
	if (![self lastDate]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** At this point, lastDate is nil. This means there is no 'Last-Modified' in the Response header.");
        }
		UTIL_DEBUG_WRITE(@"lastDate is nil, so we use CMR2chDATReader's parsing result.");
		[self setLastDate:[reader_ lastMessageDate]];
	}

	[newThread_ setNoneNil:[self lastDate] forKey:CMRThreadModifiedDateKey];
	[newThread_ setNoneNil:messages_ forKey:ThreadPlistContentsKey];
	[newThread_ setNoneNil:[[self threadSignature] boardName] forKey:ThreadPlistBoardNameKey];
	[newThread_ setNoneNil:[[self threadSignature] identifier] forKey:ThreadPlistIdentifierKey];
	return newThread_;
}
@end


@implementation ThreadTextDownloader(Description)
- (NSString *)resourceName
{
	return [self threadTitle];
}
@end
