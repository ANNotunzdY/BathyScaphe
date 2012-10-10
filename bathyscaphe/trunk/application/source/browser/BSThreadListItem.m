//
//  BSThreadListItem.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 07/03/18.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadListItem.h"

#import "CMRThreadSignature.h"
#import "DatabaseManager.h"
#import "CMRDocumentFileManager.h"
#import <SGAppKit/NSImage-SGExtensions.h>
#import "CMRThreadAttributes.h"

static inline BOOL searchBoardIDAndThreadIDFromFilePath( NSUInteger *outBoardID, NSString **outThreadID, NSString *inFilePath );
static inline NSImage *_statusImageWithStatusBSDB(ThreadStatus s);
static inline NSArray *dateTypeKeys();
static inline NSArray *numberTypeKeys();
//static inline NSArray *threadListIdentifiers();
static inline BSThreadListItem *itemFromRow(id <SQLiteRow> row);

static NSString *const BSThreadListItemErrorDomain = @"BSThreadListItemErrorDomain";
#define BSThreadListItemClassMismatchError	1
#define BSThreadListItemStatusMismatchError	2


@implementation BSThreadListItem

- (id)init
{
	if (self = [super init]) {
        data = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithIdentifier:(NSString *)identifier boardID:(NSUInteger)boardID boardName:(NSString *)boardName
{
	if (self = [super init]) {
		if (boardID == 0) {
			[self release];
			return nil;
		}

		data = [[NSMutableDictionary alloc] init];
		[data setValue:identifier forKey:[ThreadIDColumn lowercaseString]];
		[data setValue:[NSNumber numberWithUnsignedInteger:boardID] forKey:[BoardIDColumn lowercaseString]];
		if (boardName) {
            [data setValue:boardName forKey:[BoardNameColumn lowercaseString]];
        }
	}

	return self;
}

+ (id)threadItemWithIdentifier:(NSString *)identifier boardID:(NSUInteger)boardID
{
	return [[[[self class] alloc] initWithIdentifier:identifier boardID:boardID] autorelease];
}

- (id)initWithIdentifier:(NSString *)identifier boardID:(NSUInteger)boardID
{
	return [self initWithIdentifier:identifier boardID:boardID boardName:nil];
}

+ (id)threadItemWithIdentifier:(NSString *)identifier boardName:(NSString *)boardName
{
	return [[[[self class] alloc] initWithIdentifier:identifier boardName:boardName] autorelease];
}

- (id)initWithIdentifier:(NSString *)identifier boardName:(NSString *)boardName
{
	NSArray *boardIDs = [[DatabaseManager defaultManager] boardIDsForName:boardName];
	NSUInteger boardID;

	boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];

	return [self initWithIdentifier:identifier boardID:boardID boardName:boardName];
}

+ (id)threadItemWithFilePath:(NSString *)path
{
	return [[[[self class] alloc] initWithFilePath:path] autorelease];
}

- (id)initWithFilePath:(NSString *)path
{
	NSUInteger boardID = 0;
	NSString *identifier = nil;
	
	if (!searchBoardIDAndThreadIDFromFilePath(&boardID, &identifier, path)) {
		[[super init] release];
		return nil;
	}

	return [self initWithIdentifier:identifier boardID:boardID];
}

- (void)dealloc
{
	[data release];
	[super dealloc];
}

+ (NSArray *)threadItemArrayFromCursor:(id <SQLiteCursor>)cursor
{
	NSMutableArray *result;
	NSUInteger i;
    NSUInteger count;

	count = [cursor rowCount];
	result = [NSMutableArray arrayWithCapacity:count];
	
	for (i = 0; i < count; i++) {
		id item = itemFromRow([cursor rowAtIndex:i]);
		if (!item) {
			NSLog(@"BSThreadListItem (item is nil.)");
			continue;
		}
		[result addObject:item];
	}

	return result;
}

- (NSString *)description
{
    NSMutableString *foo = [NSMutableString string];
    for (NSString *key in data) {
        [foo appendString:key];
        [foo appendString:@":"];
        [foo appendString:NSStringFromClass([[data objectForKey:key] class])];
        [foo appendString:@", "];
    }
	return [NSString stringWithFormat:@"%@ <%@(%ld), %@(%ld)>\n%@",
		NSStringFromClass([self class]), [self boardName], (long)[self boardID], [self threadName], (long)[self identifier], foo];
}

#pragma mark## Accessor ##
- (NSString *)identifier
{
	return [self cachedValueForKey:ThreadIDColumn];
}

- (NSString *)boardName
{
	return [self valueForKey:BoardNameColumn];
}

- (NSUInteger)boardID
{
	return [[self cachedValueForKey:BoardIDColumn] unsignedIntegerValue];
}

- (NSString *)threadName
{
	return [self valueForKey:ThreadNameColumn];
}

- (NSString *)threadFilePath
{
	return [[CMRDocumentFileManager defaultManager] threadPathWithBoardName:[self boardName]
															  datIdentifier:[self identifier]];
}

- (ThreadStatus)status
{
	return [[self valueForKey:ThreadStatusColumn] unsignedIntegerValue];
}

- (NSNumber *)responseNumber
{
	return [self valueForKey:NumberOfAllColumn];
}

- (NSNumber *)readNumber
{
	return [self valueForKey:NumberOfReadColumn];
}

- (NSNumber *)delta
{
	id res = [self responseNumber];
	id read = [self readNumber];
	
	if(!res || !read) return nil;
	if(res == [NSNull null] || read == [NSNull null]) return nil;
	
	NSUInteger delta = [res integerValue] - [read integerValue];
	return [NSNumber numberWithInteger:delta];
}

- (NSDate *)creationDate
{
	return [NSDate dateWithTimeIntervalSince1970:[[self identifier] doubleValue]];
}

- (NSDate *)modifiedDate
{
	return [self valueForKey:ModifiedDateColumn];
}

- (NSDate *)lastWrittenDate
{
	return [self valueForKey:LastWrittenDateColumn];
}

- (BOOL)isDatOchi
{
	return [[self valueForKey:IsDatOchiColumn] integerValue];
}

- (NSUInteger)label
{
	return [[self valueForKey:ThreadLabelColumn] unsignedIntegerValue];
}

- (NSNumber *)labelObject
{
    return [self valueForKey:ThreadLabelColumn];
}

- (NSNumber *)threadNumber
{
	return [self valueForKey:TempThreadThreadNumberColumn];
}

// ($res *60 * 60 * 24) / (time() - $key)
- (NSNumber *)ikioi
{
	id result;
	
	result = [self cachedValueForKey:BSThreadEnergyKey];
	if(result) return result;
	
	NSInteger res = [[self responseNumber] integerValue];
	CGFloat createDateTime = [[self creationDate] timeIntervalSince1970];
	
	CGFloat currentDateTime = [[NSDate dateWithTimeIntervalSinceNow:0.0] timeIntervalSince1970];
	
	CGFloat deltaTime = currentDateTime - createDateTime;
	if(deltaTime == 0) return nil;
	
	CGFloat ikioi = (res * 60 * 60 * 24) / deltaTime;

	result = [NSNumber numberWithDouble:ikioi];
	[self setCachedValue:result forKey:BSThreadEnergyKey];
	
	return result;
}

- (NSImage *)statusImage
{
	return _statusImageWithStatusBSDB([self status]);
}

- (NSDictionary *)attribute
{
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:7];
	
	[result setValue:[self threadName] forKey:CMRThreadTitleKey];
	[result setValue:[[self responseNumber] stringValue] forKey:CMRThreadNumberOfMessagesKey];
	[result setValue:[self identifier] forKey:ThreadPlistIdentifierKey];
	[result setValue:[self boardName] forKey:ThreadPlistBoardNameKey];
    [result setValue:[NSNumber numberWithUnsignedInteger:[self status]] forKey:CMRThreadStatusKey];
	[result setValue:[self modifiedDate] forKey:CMRThreadModifiedDateKey];
	[result setValue:[self threadFilePath] forKey:CMRThreadLogFilepathKey];
	
	return result;
}

- (id)threadListValueForKey:(NSString *)key
{
	if([key isEqualToString:CMRThreadTitleKey]) {
		return [self threadName];
	} else if([key isEqualToString:CMRThreadLastLoadedNumberKey]) {
		return [self readNumber];
	} else if([key isEqualToString:CMRThreadNumberOfMessagesKey]) {
		return [self responseNumber];
	} else if([key isEqualToString:CMRThreadNumberOfUpdatedKey]) {
		return [self delta];
	} else if([key isEqualToString:CMRThreadSubjectIndexKey]) {
		return [self threadNumber];
	} else if([key isEqualToString:CMRThreadStatusKey]) {
		return [self statusImage];
	} else if([key isEqualToString:CMRThreadModifiedDateKey]) {
		return [self modifiedDate];
	} else if([key isEqualToString:ThreadPlistIdentifierKey]) {
		return [self creationDate];
	} else if([key isEqualToString:ThreadPlistBoardNameKey]) {
		return [self boardName];
	} else if([key isEqualToString:BSThreadEnergyKey]
		|| [key isEqualToString:[BSThreadEnergyKey lowercaseString]] ) {
		return [self ikioi];
	} else if ([key isEqualToString:BSThreadLabelKey]) {
		return [self labelObject];
	}
	
	return nil;
}

- (NSArray *)directAcceptKeys
{
	static NSArray *cachedArray = nil;
	if (!cachedArray) {
        cachedArray = [[NSArray alloc] initWithObjects:
			 BoardIDColumn,
			 BoardNameColumn,
			 ThreadNameColumn,
			 NumberOfAllColumn,
			 NumberOfReadColumn,
			 ModifiedDateColumn,
			 ThreadStatusColumn,
			 ThreadAboneTypeColumn,
			 ThreadLabelColumn,
			 LastWrittenDateColumn,
			 TempThreadThreadNumberColumn,
			 IsDatOchiColumn,
			 IsNewColumn,
			 nil];
    }
	
	return cachedArray;
}

- (id)valueForUndefinedKey:(NSString *)key
{
	// 例外が発生するとやっかいなのでオーバーライド
	return nil;
}
- (id)valueForKey:(NSString *)key
{
	id result = [self cachedValueForKey:key];
    if (result) {
        return (result == [NSNull null]) ? nil : result;
    }

	result = [self threadListValueForKey:key];
	if(result) {
        return (result == [NSNull null]) ? nil : result;
	}
	
	result = [[DatabaseManager defaultManager] valueForKey:key
                                                   boardID:[self boardID]
                                                  threadID:[self identifier]];
	
	if (!result) {
		NSLog(@"Can not find %@ for boardName(%@) threadID(%@)",
			  key, [self cachedValueForKey:BoardNameColumn], [self identifier]);
		result = [self valueForUndefinedKey:key];
	} else if (result == [NSNull null]) {
		[self setCachedValue:result forKey:key];
		return nil;
	}
	
	if ([dateTypeKeys() containsObject:key] && ![result isKindOfClass:[NSDate class]]) {
		result = [NSDate dateWithTimeIntervalSince1970:[result doubleValue]];
	} else if ([numberTypeKeys() containsObject:key] && ![result isKindOfClass:[NSNumber class]]) {
		result = [NSNumber numberWithDouble:[result doubleValue]];
	}

	if (result) {
		[self setCachedValue:result forKey:key];
	}

	return result;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	BOOL accepted = NO;
	if([[self directAcceptKeys] containsObject:key]) {
		accepted = YES;
	}
	
	if(accepted) {
		if([dateTypeKeys() containsObject:key] && ![value isKindOfClass:[NSDate class]]) {
			if([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
				value = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
			}
		}
		[self setCachedValue:value forKey:key];
	} else {
		[super setValue:value forKey:key];
	}
}

- (id) cachedValueForKey:(NSString *)key
{
	return [data valueForKey:[key lowercaseString]];
}

- (void) setCachedValue:(id)value forKey:(NSString *)key
{
	if([ThreadIDColumn isEqualToString:key]) return;
	if([ThreadPlistIdentifierKey isEqualToString:key]) return;
	
	NSString *cacheKey = tableNameForKey(key);
	if(cacheKey && ![CMRThreadStatusKey isEqualToString:key]) key = cacheKey;
	
	if([dateTypeKeys() containsObject:key] && ![value isKindOfClass:[NSDate class]]) {
		if([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]]) {
			value = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
		}
	}
	
	[data setValue:value forKey:[key lowercaseString]];
}

#pragma mark## Functions ##
static inline NSArray *dateTypeKeys()
{
	static NSArray *result = nil;
	
	if(!result) {
		@synchronized([BSThreadListItem class]) {
			if(!result) {
				result = [NSArray arrayWithObjects:
					ModifiedDateColumn,
					LastWrittenDateColumn,
					
					[ModifiedDateColumn lowercaseString],
					[LastWrittenDateColumn lowercaseString],
					nil];
				[result retain];
			}
		}
	}
	
	return result;
}
static inline NSArray *numberTypeKeys()
{
	static NSArray *result = nil;
	
	if(!result) {
		@synchronized([BSThreadListItem class]) {
			if(!result) {
				result = [NSArray arrayWithObjects:
					NumberOfAllColumn,
					NumberOfReadColumn,
					NumberOfDifferenceColumn,
					TempThreadThreadNumberColumn,
					IsNewColumn,
//					BSThreadEnergyKey,
					ThreadLabelColumn,
					
					[NumberOfAllColumn lowercaseString],
					[NumberOfReadColumn lowercaseString],
					[NumberOfDifferenceColumn lowercaseString],
					[TempThreadThreadNumberColumn lowercaseString],
					[IsNewColumn lowercaseString],
//					[BSThreadEnergyKey lowercaseString],
					[ThreadLabelColumn lowercaseString],
					
					nil];
				[result retain];
			}
		}
	}
	
	return result;
}
/*static inline NSArray *threadListIdentifiers()
{
	static NSArray *result = nil;
	
	if(!result) {
		@synchronized([BSThreadListItem class]) {
			if(!result) {
				result = [NSArray arrayWithObjects:
					CMRThreadTitleKey,
					CMRThreadLastLoadedNumberKey,
					CMRThreadNumberOfMessagesKey,
					CMRThreadNumberOfUpdatedKey,
					CMRThreadSubjectIndexKey,
					CMRThreadStatusKey,
					CMRThreadModifiedDateKey,
					ThreadPlistIdentifierKey,
					ThreadPlistBoardNameKey,
					IsNewColumn,
					BSThreadEnergyKey,
					nil];
				[result retain];
			}
		}
	}
	
	return result;
}*/

static inline BOOL searchBoardIDAndThreadIDFromFilePath(NSUInteger *outBoardID, NSString **outThreadID, NSString *inFilePath)
{
	CMRDocumentFileManager *dfm = [CMRDocumentFileManager defaultManager];
	NSUInteger boardID;
	NSString *threadID;
	
	threadID = [dfm datIdentifierWithLogPath : inFilePath];
	
	{
		NSString *boardName;
		NSArray *boardIDs;
		id boardIDstring;
		
		boardName = [dfm boardNameWithLogPath : inFilePath];
		if (!boardName) return NO;
		
		boardIDs = [[DatabaseManager defaultManager] boardIDsForName : boardName];
		if (!boardIDs || [boardIDs count] == 0) return NO;
		
		boardIDstring = [boardIDs objectAtIndex : 0];
		
		boardID = [boardIDstring unsignedIntegerValue];
	}
	
	id threadName = [[DatabaseManager defaultManager] valueForKey:ThreadNameColumn
														  boardID:boardID
														 threadID:threadID];
	if(!threadName) {
		[[DatabaseManager defaultManager] registerThreadFromFilePath:inFilePath];
	}
	
	if(outThreadID) {
		*outThreadID = threadID;
	}
	if(outBoardID) {
		*outBoardID = boardID;
	}
	
	return YES;
}

// Status image
#define kStatusUpdatedImageName		@"Status_updated"
#define kStatusCachedImageName		@"Status_logcached"
#define kStatusNewImageName			@"Status_newThread"
#define kStatusHEADModImageName		@"Status_HeadModified"
static inline NSImage *_statusImageWithStatusBSDB(ThreadStatus s)
{
	switch (s){
		case ThreadLogCachedStatus :
			return [NSImage imageAppNamed : kStatusCachedImageName];
		case ThreadUpdatedStatus :
			return [NSImage imageAppNamed : kStatusUpdatedImageName];
		case ThreadNewCreatedStatus :
			return [NSImage imageAppNamed : kStatusNewImageName];
		case ThreadHeadModifiedStatus :
			return [NSImage imageAppNamed : kStatusHEADModImageName];
		case ThreadNoCacheStatus :
			return nil;
		default :
			return nil;
	}
	return nil;
}

#pragma mark NSPasteboardWriting
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    if ([self status] & ThreadLogCachedStatus) {
        return [NSArray arrayWithObjects:BSPasteboardTypeThreadSignature, (NSString *)kUTTypeURL, NSPasteboardTypeString, (NSString *)kUTTypeFileURL, nil];
    }
    return [NSArray arrayWithObjects:BSPasteboardTypeThreadSignature, (NSString *)kUTTypeURL, NSPasteboardTypeString, nil];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    if ([type isEqualToString:BSPasteboardTypeThreadSignature]) {
        return [[CMRThreadSignature threadSignatureWithIdentifier:[self identifier] boardName:[self boardName]] pasteboardPropertyListForType:type];
    } else if ([type isEqualToString:NSPasteboardTypeString]) {
        return [NSString stringWithFormat:@"%@\n%@", [self threadName], [CMRThreadAttributes threadURLWithBoardID:[self boardID] datIdentifier:[self identifier]]];
    } else if ([type isEqualToString:(NSString *)kUTTypeFileURL]) {
        return [[NSURL fileURLWithPath:[self threadFilePath]] pasteboardPropertyListForType:(NSString *)kUTTypeFileURL];
    } else if ([type isEqualToString:(NSString *)kUTTypeURL]) {
        return [[CMRThreadAttributes threadURLWithBoardID:[self boardID] datIdentifier:[self identifier]] pasteboardPropertyListForType:(NSString *)kUTTypeURL];
    }
    return nil;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    return 0;
}
@end

static inline NSArray *mustContainsKeys()
{
	static NSArray *array = nil;
	
	if(!array) {
		array = [NSArray arrayWithObjects:
			BoardIDColumn, BoardNameColumn,
			ThreadIDColumn, ThreadNameColumn, NumberOfAllColumn,
			NumberOfReadColumn, ModifiedDateColumn, ThreadStatusColumn,
					ThreadLabelColumn,
			IsDatOchiColumn,
			IsNewColumn,
			nil];
		[array retain];
	}
	
	return array;
}
static inline BSThreadListItem *itemFromRow(id <SQLiteRow> row)
{
	id item = [BSThreadListItem threadItemWithIdentifier:[row valueForColumn:ThreadIDColumn]
												 boardID:[[row valueForColumn:BoardIDColumn] unsignedIntegerValue]];
	
	if(!item) return nil;
	
	for(id key in mustContainsKeys()) {
		if([key isEqualTo:BoardIDColumn] || [key isEqualTo:ThreadIDColumn]) {
			continue;
		}
		[item setValue:[row valueForColumn:key] forKey:key];
	}
	
	if([row valueForColumn:TempThreadThreadNumberColumn]) {
		[item setValue:[row valueForColumn:TempThreadThreadNumberColumn]
				  forKey:TempThreadThreadNumberColumn];
	}
	
	return item;
}

#pragma mark -
NSUInteger indexOfIdentifier(NSArray *array, NSString *search)
{
	NSUInteger i;
    NSUInteger count;
	id object;
	id identifier;
	
	count = [array count];
	if (count == 0) {
        return NSNotFound;
	}
	for (i = 0; i < count; i++ ) {
		object = [array objectAtIndex:i];
		identifier = [object identifier];
		if ([search isEqualTo:identifier]) {
			return i;
		}
	}

	return NSNotFound;
}

BSThreadListItem *itemOfTitle(NSArray *array, NSString *searchTitle)
{
	NSString *title;
	NSString *adjustedSearchTitle = [searchTitle stringByAppendingString:@" "];

	for(id object in array) {
//		if ([object isKindOfClass:[BSThreadListItem class]]) NSLog(@"Class OK");
		title = [object threadName];
//		NSLog(@"title check: %@", title);
		if ([adjustedSearchTitle isEqualToString:title]) {
			return object;
		}
	}

	return nil;
}
