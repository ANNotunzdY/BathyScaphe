//
//  BSSmartBoardUpdateTask.m
//  BathyScaphe
//
//  Created by 堀 昌樹 on 12/07/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BSSmartBoardUpdateTask.h"

#import <CocoaOniguruma/OnigRegexp.h>

#import "AppDefaults.h"
#import "CMRFavoritesManager.h"
#import "BoardManager.h"
#import "CMRHostHandler.h"
#import "CMXTextParser.h"
#import "BSDownloadTask.h"
#import "DatabaseManager.h"

@interface BSSmartBoardUpdateTask ()
@property (assign) BSDBThreadList *targetList;
@property (retain) BoardListItem *item;
@end

@implementation BSSmartBoardUpdateTask
@synthesize targetList = _targetList;
@synthesize item = _item;

+ (NSString *)localizableStringsTableName
{
    return @"ThreadsList";
}

+ (id)taskWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)forceDL rebuild:(BOOL)flag
{
	return [[[[self class] alloc] initWithThreadList:list forceDownload:forceDL rebuild:flag] autorelease];
}
- (id)initWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)inForceDL rebuild:(BOOL)flag
{
	self = [super init];
	if(self) {
		forceDL = inForceDL;
		_boards = [[NSMutableSet alloc] init];
		_updateData = [[NSMutableDictionary alloc] init];
		self.targetList = list;
		self.item = [list boardListItem];
		if(!([self.item type] & (BoardListFavoritesItem | BoardListSmartBoardItem))) {
			[self autorelease];
			return nil;
		}
				
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(downloadFail:)
													 name:BSDownloadTaskFailDownloadNotification
												   object:nil];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_boards release];
	[_updateData release];
	[_item release];
	[_targetThreads release];
	
	[super dealloc];
}
- (NSString *)title
{
	return [NSString stringWithFormat:[self localizedString:@"Checking SmartBoard(%@)."], [[self.targetList boardListItem] name]];
}

+ (OnigRegexp *)regex
{
	static OnigRegexp *sRegexp = nil;
    if (!sRegexp) {
        sRegexp = [OnigRegexp compile:[NSString stringWithFormat:@"(\\d+)[^,<>]*(?:<>|,).*\\s*(?:\\(|<>|%C)(\\d+)",(unichar)0xFF08]];
        [sRegexp retain];
    }
    return sRegexp;
}
- (OnigRegexp *)regex
{
	return [[self class] regex];
}

- (void)downloadFail:(NSNotification *)notification
{
	NSError *error = [[notification userInfo] objectForKey:BSDownloadTaskErrorObjectKey];
	
	// networkErrorsの解放はシングルスレッドで実行されるので確保されているかどうかのチェック時に@synchronized(self)する必要はない
	if(!networkErrors) {
		@synchronized(self) {
			if(!networkErrors) {
				networkErrors = [[NSMutableArray alloc] init];
			}
		}
		
	}
	@synchronized(networkErrors) {
		[networkErrors addObject:error];
	}
}

- (void)playFinishSoundIsUpdate:(BOOL)isUpDate
{
	NSSound *finishedSound_ = nil;
	NSString *soundName_ = [CMRPref HEADCheckNewArrivedSound];
	
	if (isUpDate && ![soundName_ isEqualToString:@""]) {
		finishedSound_ = [NSSound soundNamed:soundName_];
	} else {
		soundName_ = [CMRPref HEADCheckNoUpdateSound];
		if (![soundName_ isEqualToString:@""]) {
			finishedSound_ = [NSSound soundNamed:soundName_];
        }
	}
	[finishedSound_ play];
}



- (void)collectTargetBoards
{
	_targetThreads = [[self.item cursorForThreadList] retain];
	for(NSUInteger row = 0, rowCount = [_targetThreads rowCount]; row < rowCount; row++) {
		if(self.isInterrupted) return;
		
		id boardName = [_targetThreads valueForColumn:BoardNameColumn atRow:row];
		if(boardName && ![boardName isKindOfClass:[NSNull class]]) {
			[_boards addObject:boardName];
		}
	}
}


- (void)setMessageSync:(NSString *)msg
{
	void (^operation)() = ^{
		self.message = msg;
	};
	if([NSThread isMainThread]) {
		operation();
	} else {
		dispatch_sync(dispatch_get_main_queue(), operation);
	}
}
static BOOL isBoardLivedoor(NSURL *boardURL)
{
	const char *host = NULL;
	CMRGetHostCStringFromBoardURL(boardURL, &host);
	return host ? is_jbbs_livedoor(host) : NO;
}
- (void)collectUpdateInformation
{
	NSString *dlFormat = [self localizedString:@"Downloding and Analyzing subject.txt of %@"];
	
	dispatch_queue_t downloadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	NSArray *boardNames = [_boards allObjects];
	dispatch_apply([boardNames count], downloadQueue, ^(size_t index) {
		if(self.isInterrupted) return;
		
		NSString *boardName = [boardNames objectAtIndex:index];
		
		[self setMessageSync:[NSString stringWithFormat:dlFormat, boardName]];
		
		NSURL *boardURL = [[BoardManager defaultManager] URLForBoardName:boardName];
		if (!boardURL) {
			NSLog(@"Can NOT create url from bbs named %@.",boardName);
			return;
		}
		NSURL *subjectURL = [NSURL URLWithString:CMRAppSubjectTextFileName relativeToURL:boardURL];
		if(!subjectURL) {
			NSLog(@"Can not create subject url of %@", boardName);
			return;
		}
		NSArray *subjectLines = nil;
		BSDownloadTask *dlTask = [[[BSDownloadTask alloc] initWithURL:subjectURL] autorelease];
		[dlTask synchronousDownLoad];
		NSData *subjectData = [dlTask receivedData];
		if(!subjectData || [subjectData length] == 0) {
			return;
		}
		
		CMRHostHandler *handler = [CMRHostHandler hostHandlerForURL:boardURL];
		if (!handler) {
			NSLog(@"Can NOT create host handler from url %@.",boardURL);
			return;
		}
		CFStringEncoding enc = [handler subjectEncoding];
		NSString *subjectString = [CMXTextParser stringWithData:subjectData CFEncoding:enc];
		subjectLines = [subjectString componentsSeparatedByNewline];
		
		BOOL isLivedoor = isBoardLivedoor(boardURL);
		NSMutableArray *dats = [NSMutableArray array];
		
		if(self.isInterrupted) return;
		
		NSMutableDictionary *infos = [NSMutableDictionary dictionary];
		OnigRegexp *regex = [self regex];
		for(NSString *line in subjectLines) {
			if(self.isInterrupted) return;
			
			NSString *datString = nil;
			NSString *numString = nil;
			@synchronized(regex) {
				OnigResult *match = [regex search:line];
				datString = [[[match stringAt:1] copy] autorelease];
				numString = [[[match stringAt:2] copy] autorelease];
			}
			if(!numString) continue;
			
			if(isLivedoor) {
				if([dats containsObject:datString]) continue;
				[dats addObject:datString];
			}
			
			[infos setObject:numString forKey:datString];
		}
		@synchronized(_updateData) {
			[_updateData setObject:infos forKey:boardName];
		}
	});
	
	// 本来、ここでの排他処理は必要ないが一応安全のために
	@synchronized(networkErrors) {
		if(networkErrors) {
			if([networkErrors count] > 0) {
				[NSApp presentError:[networkErrors lastObject]];
			}
			@synchronized(self) {
				[networkErrors release];
				networkErrors = nil;
			}
		}
	}
}

static inline BOOL isNSNullOrNil(id obj)
{
	if(!obj) return YES;
	if([obj isKindOfClass:[NSNull class]]) return YES;
	return NO;
}
static inline id nilIfObjectIsNSNull(id obj)
{
	return (obj == [NSNull null]) ? nil : obj;
}
static inline BOOL isUpdatedThread(NSInteger readCount, NSString *numString, NSInteger currentCount)
{
	return (readCount != 0 && !isNSNullOrNil(numString) && currentCount < [numString integerValue]);
}
- (void)updateDB
{
    BOOL isUpdate = NO;
	
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	NSString *queryString = [NSString stringWithFormat:@"UPDATE OR IGNORE %@ SET %@ = ?, %@ = ? WHERE %@ = ? AND %@ = ?",
							 ThreadInfoTableName,
							 NumberOfAllColumn,
							 ThreadStatusColumn,// ThreadUpdatedStatus,
							 BoardIDColumn, ThreadIDColumn];
	SQLiteReservedQuery *query = [db reservedQuery:queryString];
	
	[db beginTransaction];
	for(NSUInteger index = 0, rowCount = [_targetThreads rowCount]; index < rowCount; index++) {
		if(self.isInterrupted) {
			[db rollbackTransaction];
			return;
		}
		id<SQLiteRow> row = [_targetThreads rowAtIndex:index];
		
		NSInteger status = [nilIfObjectIsNSNull([row valueForColumn:ThreadStatusColumn]) integerValue];
		BOOL isNew = (status & ThreadNewCreatedStatus) == ThreadNewCreatedStatus;
		NSInteger readCount = [nilIfObjectIsNSNull([row valueForColumn:NumberOfReadColumn]) integerValue];
		if(!isNew && readCount == 0) continue;
		NSString *boardName = [row valueForColumn:BoardNameColumn];
		if(isNSNullOrNil(boardName)) continue;
		NSString *datString = [row valueForColumn:ThreadIDColumn];
		if(isNSNullOrNil(datString)) continue;
		NSString *boardID = [row valueForColumn:BoardIDColumn];
		if(isNSNullOrNil(boardID)) continue;
		NSInteger currentCount = [nilIfObjectIsNSNull([row valueForColumn:NumberOfAllColumn]) integerValue];
		NSString *numString = nil;
		
		NSDictionary *infoForBoard = [_updateData objectForKey:boardName];
		numString = [infoForBoard objectForKey:datString];
		if(isUpdatedThread(readCount, numString, currentCount)) {
			[query cursorWithFormat:"siss", numString, ThreadUpdatedStatus, boardID, datString];
			isUpdate = YES;
		} else if(isNew) {
			[query cursorWithFormat:"iiss", currentCount, ThreadNoCacheStatus, boardID, datString];
//			isUpdate = YES;
		}
		
	}
	[db commitTransaction];
	
	[self playFinishSoundIsUpdate:isUpdate];
}

- (void)excute
{
	if(!forceDL) {
		if(self.isInterrupted) return;
		[self.targetList updateCursor];
		return;
	}
	// 更新チェックの回数上限に達している場合ここでブロックする
/*	NSError *error = nil;
	if (![[CMRFavoritesManager defaultManager] canHEADCheck:&error]) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
		return;
	}*/
	
	// Boardを収集
	self.message = [self localizedString:@"Collecting Board informations"];
	[self collectTargetBoards];
	if(self.isInterrupted) return;
	
	// 各Boardのsubject.txtを取得
	self.message = [self localizedString:@"Begin download subject.txt"];
    [self collectUpdateInformation];
	if(self.isInterrupted) return;
	
	// 各subject.txtからDBをupdate
	self.message = [self localizedString:@"Updating database"];
	[self updateDB];
	
//	[[CMRFavoritesManager defaultManager] decrementHEADCheckCount];
	
	if(self.isInterrupted) return;
	[self.targetList updateCursor];
}

@end
