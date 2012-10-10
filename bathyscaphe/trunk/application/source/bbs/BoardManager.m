//
//  BoardManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/08.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BoardManager_p.h"
#import "CMRDocumentFileManager.h"
#import "BSBoardInfoInspector.h"
#import "DatabaseManager.h"
#import <CocoMonar/CMRSingletonObject.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import "BoardWarrior.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"


@implementation BoardManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (id)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillTerminate:)
													 name:NSApplicationWillTerminateNotification
												   object:NSApp];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[m_localRulesPanelControllers release];
    [_defaultList release];
    [_userList release];
	[_noNameDict release];
    [m_corpusCache release];
    [m_invalidBoardURLs release];
    [super dealloc];
}

- (NSString *)userBoardListPath
{
	return [[CMRFileManager defaultManager] supportFileUnderDataRootDirectoryPathWithName:CMRUserBoardFile];
}

- (NSString *)defaultBoardListPath
{
	return [[CMRFileManager defaultManager] supportFileUnderDataRootDirectoryPathWithName:CMRDefaultBoardFile];
}

+ (NSString *)spareDefaultBoardListPath
{
	return [[NSBundle mainBundle] pathForResource:@"board_default" ofType:@"plist"];
}

+ (NSString *)NNDFilepath
{
	return [[CMRFileManager defaultManager] supportFilepathWithName:BSBoardPropertiesFile resolvingFileRef:NULL];
}

- (void)reloadBoardFilesIfNeeded
{
    if (!m_syncInProgress) {
        [[self defaultList] reloadBoardFile:[self defaultBoardListPath]];
        [[self userList] reloadBoardFile:[self userBoardListPath]];
    }
}

- (SmartBoardList *)makeBoardList:(Class)aClass withContentsOfFile:(NSString *)aFile
{
    if (!m_syncInProgress && [CMRPref shouldAutoSyncBoardListImmediately]) {
        BoardWarrior *warrior = [BoardWarrior warrior];
        if ([warrior syncBoardLists]) {
            m_syncInProgress = YES;
            NSRunLoop *loop = [NSRunLoop currentRunLoop];
            while ([warrior isInProgress]) {
                id pool = [[NSAutoreleasePool alloc] init];
                @try {
                    [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
                }
                @catch(id ex) {
                    // do nothing.
                    @throw;
                }
                @finally {
                    [pool release];
                }
            }
            m_syncInProgress = NO;
        }
        
    }

    SmartBoardList *list;
    
    list = [[aClass alloc] initWithContentsOfFile:aFile];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(boardListDidChange:)
												 name:CMRBBSListDidChangeNotification
											   object:list];

    return list;
}

// このへん、暫定
- (SmartBoardList *)defaultList:(BOOL)flag
{
    if (flag && !_defaultList) {
		NSFileManager	*dfm;
		NSString		*dListPath;
		dfm = [NSFileManager defaultManager];
		dListPath = [self defaultBoardListPath];
		
		if (![dfm fileExistsAtPath:dListPath]) {
            [dfm copyItemAtPath:[[self class] spareDefaultBoardListPath] toPath:dListPath error:NULL];
		}
        _defaultList = [self makeBoardList:[SmartBoardList class] withContentsOfFile:dListPath];
    }
    return _defaultList;
}

- (SmartBoardList *)defaultList
{
	return [self defaultList:YES];
}

- (SmartBoardList *)defaultListWithoutNeedingInitialize
{
	return [self defaultList:NO];
}

- (SmartBoardList *)userList
{
    if (!_userList) {
        _userList = [self makeBoardList:[SmartBoardList class] withContentsOfFile:[self userBoardListPath]];
    }
    return _userList;
}

#pragma mark Filtering List
- (BOOL)copyMatchedItem:(NSString *)keyword items:(NSArray *)items toList:(SmartBoardList *)filteredList
{
    NSInteger i;
    BOOL found = NO;

    for (i = 0; i < [items count]; i++) {
        BoardListItem	*root = [items objectAtIndex:i];
        NSRange			range;
		
        range = [[root representName] rangeOfString:keyword options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
			[filteredList addItem:root afterObject:nil];
            found |= YES;
        } else {
            found |= NO;
        }

        if ([root numberOfItem] != 0 && ![self copyMatchedItem:keyword items:[root items] toList:filteredList]) {
			continue;
        }
    }
    return found;
}

- (SmartBoardList *)filteredListWithString:(NSString *)keyword
{
	SmartBoardList *result_ = [[SmartBoardList alloc] init];

    [self copyMatchedItem:keyword items:[[self defaultList] boardItems] toList:result_];

	return [result_ autorelease];
}

#pragma mark Board Name <--> URL
- (NSURL *)URLForBoardName:(NSString *)boardName
{
	NSURL	*url_ = nil;
	NSString *urlString;
	DatabaseManager *dbm = [DatabaseManager defaultManager];
	NSArray *ids;
	
	ids = [dbm boardIDsForName:boardName];
	/* TODO 複数の場合の処理 */
	urlString = [dbm urlStringForBoardID:[[ids objectAtIndex:0] unsignedIntegerValue]];
	if (urlString) {
		url_ = [NSURL URLWithString:urlString];
	}
	
	return url_;
}

- (NSURL *)URLForBoardID:(NSUInteger)boardID
{
    NSString *urlString = [[DatabaseManager defaultManager] urlStringForBoardID:boardID];
    if (urlString) {
        return [NSURL URLWithString:urlString];
    }
    return nil;
}


- (NSString *)boardNameForURL:(NSURL *)theURL
{
	NSString	*name_;
	DatabaseManager *dbm = [DatabaseManager defaultManager];
	NSUInteger boardID;
	
	boardID = [dbm boardIDForURLString:[theURL absoluteString]];
	name_ = [dbm nameForBoardID:boardID];
	
	return name_;
}

- (void)updateURL:(NSURL *)anURL forBoardName:(NSString *)aName
{
	id item = [self itemForName:aName];
	NSString	*newURLString = [anURL absoluteString];
	[self editBoardItem:item newURLString:newURLString];
}

#pragma mark detect moved BBS
- (BOOL)movedBoardWasFound:(NSString *)boardName newLocation:(NSURL *)anNewURL oldLocation:(NSURL *)anOldURL
{
	NSAlert *alert_ = [[[NSAlert alloc] init] autorelease];
	[alert_ setAlertStyle:NSInformationalAlertStyle];
	[alert_ setMessageText:NSLocalizedString(@"MovedBBSFoundTitle", nil)];
// #warning 64BIT: Check formatting arguments
// 2011-08-27 tsawada2 検討済
	[alert_ setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"MovedBBSFoundFormat", nil),
															  boardName, [anOldURL absoluteString], [anNewURL absoluteString]]];
	[alert_ addButtonWithTitle:NSLocalizedString(@"MovedOK", nil)];
	[alert_ addButtonWithTitle:NSLocalizedString(@"MovedCancel", nil)];
	[alert_ setHelpAnchor:NSLocalizedString(@"MovedBBSHelpAnchor", nil)];
    [alert_ setDelegate:[NSApp delegate]];
	[alert_ setShowsHelp:YES];

	if ([alert_ runModal] != NSAlertFirstButtonReturn) {
        return NO;
    }
    [self updateURL:anNewURL forBoardName:boardName];

    return YES;
}

- (BOOL)detectMovedBoardWithResponseHTML:(NSString *)htmlContents boardName:(NSString *)boardName
{
    NSURL    *oldURL = [self URLForBoardName:boardName];
    NSURL    *newURL = nil;

    UTIL_DEBUG_WRITE2(@"Name:%@ Old:%@", boardName, [oldURL stringValue]);
    UTIL_DEBUG_WRITE1(@"HTML response was:\n"
    @"----------------------------------------\n"
    @"%@", htmlContents);
    if (!oldURL) {
        return NO;
    }

    OnigRegexp *re = [OnigRegexp compile:@"<a href=\"(.*)\".*>(.*)</a>"];
    OnigResult *match = [re search:htmlContents];
    if (!match) {
        return NO;
    } else {
        newURL = [NSURL URLWithString:[match stringAt:1]];
    }
    
    if (newURL) {
    	NSString *newHost = [newURL host];
    	if ([newHost isEqualToString:[oldURL host]] || [newHost hasSuffix:@"u.la"]) {
            return NO;
        }
        return [self movedBoardWasFound:boardName newLocation:newURL oldLocation:oldURL];
    }
    return NO;
}

static inline NSError *genericDetectMovedBoardError(NSString *boardName, NSURL *boardURL)
{
    NSString *messageText = NSLocalizedStringFromTable(@"Not Found", @"ThreadsList", nil);
    NSString *informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Not Found %@", @"ThreadsList", nil), (boardURL ? [boardURL absoluteString] : boardName)];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:messageText, NSLocalizedDescriptionKey, informativeText, NSLocalizedRecoverySuggestionErrorKey, NULL];
    return [NSError errorWithDomain:BSBathyScapheErrorDomain code:BoardManagerMovedBoardDetectGeneralError userInfo:userInfo];
}

static inline NSError *urlConnectionDetectMovedBoardError(NSError *underlyingError, NSURL *url)
{
    NSString *messageText = NSLocalizedStringFromTable(@"Not Found", @"ThreadsList", nil);
    NSString *informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Not Found %@ %@", @"ThreadsList", nil), [url absoluteString], [[underlyingError userInfo] objectForKey:NSLocalizedDescriptionKey]];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:messageText, NSLocalizedDescriptionKey, informativeText, NSLocalizedRecoverySuggestionErrorKey, underlyingError, NSUnderlyingErrorKey, NULL];
    return [NSError errorWithDomain:BSBathyScapheErrorDomain code:BoardManagerMovedBoardDetectConnectionDidFailError userInfo:userInfo];
}    

static inline NSError *bbonSuspectedDetectMovedBoardError()
{
    NSArray *recoveryOptions;
    NSDictionary *dict;
    
    recoveryOptions = [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"ErrorRecoveryCancel", @"Downloader", nil), NSLocalizedStringFromTable(@"BBONInfo", @"Downloader", nil), nil];
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
            recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
            NSLocalizedStringFromTable(@"BBONDescription", @"Downloader", nil), NSLocalizedDescriptionKey,
            NSLocalizedStringFromTable(@"BBONSuggestion", @"Downloader", nil), NSLocalizedRecoverySuggestionErrorKey,
            NULL];
    return [NSError errorWithDomain:BSBathyScapheErrorDomain code:BoardManagerMovedBoardDetectBBONSuspectionError userInfo:dict];
}

- (BOOL)tryToDetectMovedBoard:(NSString *)boardName error:(NSError **)errorPtr
{
    NSURL *URL = [self URLForBoardName:boardName];
	NSURLRequest *req_;
	BOOL canHandle_;
    NSURLResponse *response;
    NSData *data;
    NSString *contents;

    // We can do nothing.
    if (!URL) {
        if (errorPtr != NULL) {
            *errorPtr = genericDetectMovedBoardError(boardName, nil);
        }
        return NO;
    }
	
    UTIL_DEBUG_WRITE2(@"BathyScaphe try to detect moved BBS:%@ URL:%@", boardName, [URL absoluteString]);
    
	req_ = [NSURLRequest requestWithURL:URL];
	canHandle_ = [NSURLConnection canHandleRequest:req_];
	if (!canHandle_) {
        if (errorPtr != NULL) {
            *errorPtr = genericDetectMovedBoardError(boardName, URL);
        }
        return NO;
    }

    NSError *networkError;
	data = [NSURLConnection sendSynchronousRequest:req_ returningResponse:&response error:&networkError];
    if (!data) {
        if (errorPtr != NULL) {
            *errorPtr = urlConnectionDetectMovedBoardError(networkError, URL);
        }
		return NO;
	}
    
    id bbonURLs = SGTemplateResource(@"System - BBON Page URLs");
    UTILAssertKindOfClass(bbonURLs, NSArray);
    // response の URL がバーボンかボボン規制のページだった場合
    if ([bbonURLs containsObject:[response URL]]) {
        if (errorPtr != NULL) {
            *errorPtr = bbonSuspectedDetectMovedBoardError();
        }
        return NO;
    }
    
    contents = [NSString stringWithData:data encoding:NSShiftJISStringEncoding];

    if ([self detectMovedBoardWithResponseHTML:contents boardName:boardName]) {
        return YES;
    } else {
        if (errorPtr != NULL) {
            *errorPtr = genericDetectMovedBoardError(boardName, URL);
        }
        return NO;
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    NSWindow *window = [notification object];
    id windowController = [window windowController];
    
    [[self localRulesPanelControllers] removeObjectIdenticalTo:windowController];
    [windowController autorelease];
}
@end


@implementation BoardManager(Notification)
- (void)boardListDidChange:(NSNotification *)notification
{
	UTILAssertNotificationName(notification, CMRBBSListDidChangeNotification);
	UTILAssertKindOfClass([notification object], SmartBoardList);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:([notification object] == [self defaultList])
			 			? CMRBBSManagerDefaultListDidChangeNotification
						: CMRBBSManagerUserListDidChangeNotification
														object:self];
    
    [self saveListsIfNeeded];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	UTILAssertNotificationName(notification, NSApplicationWillTerminateNotification);
	UTILAssertNotificationObject(notification, NSApp);

    [self saveSpamCorpusIfNeeded:nil];
	[self saveListsIfNeeded];
	[self saveNoNameDict];
}

- (BOOL)saveListsIfNeeded
{	
	if ([[self userList] isEdited]) {
		[[self userList] writeToFile:[self userBoardListPath] atomically:YES];
		[[self userList] setIsEdited:NO];
	}
	if ([[self defaultListWithoutNeedingInitialize] isEdited]) {
		[[self defaultList] writeToFile:[self defaultBoardListPath] atomically:YES];
		[[self defaultList] setIsEdited:NO];
	}
	return YES;
}
@end
