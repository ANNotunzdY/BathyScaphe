//
//  BSBoardListItemHEADCheckTask.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/13.
//  Copyright 2006-2010,2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSBoardListItemHEADCheckTask.h"

#import "DatabaseManager.h"
#import "BoardManager.h"
#import "CMRHostHandler.h"
#import "BSDownloadTask.h"
#import "AppDefaults.h"
#import "CMRFavoritesManager.h"
#import "BSHTMLHEADChecker.h"

static NSString *const BSFavHEADerLMKey	= @"Last-Modified";

static NSURL *datURLForBoardIDStringAndThreadID(NSString *boardIDString, NSString *threadID);
static BOOL shouldCheckItemHeader(id dict);

@interface BSBoardListItemHEADCheckTask ()
@property (copy) NSString *amountString;
@property (copy) NSString *descString;

- (NSArray *)threadInfomations;
- (BSDownloadTask *)sendHEADMethod:(NSURL *)url;
- (void)resetNewStatus;
- (void)updateDB:(id)threads;
@end

@implementation BSBoardListItemHEADCheckTask
@synthesize amountString;
@synthesize descString;

+ (id)taskWithThreadList:(BSDBThreadList *)list
{
	return [[[self alloc] initWithThreadList:list] autorelease];
}

- (id)initWithThreadList:(BSDBThreadList *)list
{
	if (self = [super init]) {
		targetList = list;
		item = [[list boardListItem] retain];
	}
	
	return self;
}

- (void)dealloc
{
	[item release];
	[amountString release];
	[descString release];
	
	[super dealloc];
}

#pragma mark -
+ (NSSet *)keyPathsForValuesAffectingMessage
{
	return [NSSet setWithObjects:@"amountString", @"descString", nil];
}
- (NSString *)title
{
	NSString *format = NSLocalizedStringFromTable(@"Checking SmartBoard(%@).", @"ThreadsList", @"");
	return [NSString stringWithFormat:format, [item name]];
}

- (NSString *)message
{
	NSString *descStr = self.descString;
	NSString *amountStr = self.amountString;
	
	if (descStr && amountStr) {
		return [NSString stringWithFormat:@"%@ (%@)", descStr, amountStr];
	} else if (descStr) {
		return descStr;
	}
	return NSLocalizedStringFromTable(@"ProgressBoardListItemHEADCheck.", @"ThreadsList", @"");
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

- (void)excute
{
	[self resetNewStatus];
	
	NSArray *threads = [self threadInfomations];
	NSMutableArray *updatedThreads = [NSMutableArray array];
	
//	[self checkHOGE];
	
	NSInteger numberOfAllTarget = [threads count];
	NSInteger numberOfFinishCheck = 0;
	NSInteger numberOfSkip = 0;
	NSInteger numberOfChecked = 0; // HEAD を送信した回数
	NSString *amoutFormat = NSLocalizedStringFromTable(@"%ld/%ld (%ld skiped)", @"ThreadsList", @"");

	self.amountString = [NSString stringWithFormat:amoutFormat,
						 (long)numberOfFinishCheck, (long)numberOfAllTarget, (long)numberOfSkip];
	self.descString = NSLocalizedStringFromTable(@"Checking thread", @"ThreadsList", @"");
	
    for (id thread in threads) {
		if(self.isInterrupted) return;
		
		id pool = [[NSAutoreleasePool alloc] init];
		
		id dl;
		id response;
		id newMod;
		
		self.amountString = [NSString stringWithFormat:amoutFormat, 
							 ++numberOfFinishCheck, numberOfAllTarget, numberOfSkip];
		
		if (!shouldCheckItemHeader(thread)) {
			[pool release];
			numberOfSkip++;
			continue;
		}
		
		NSString *threadID = [thread valueForColumn:ThreadIDColumn];
		NSString *modDate = [thread valueForColumn:ModifiedDateColumn];
        NSString *boardID = [thread valueForColumn:BoardIDColumn];
		
		NSURL *datURL = datURLForBoardIDStringAndThreadID(boardID, threadID);
        if (!datURL) {
            NSRunLoop *loop = [NSRunLoop currentRunLoop];
            NSUInteger boardIDUI = [boardID unsignedIntegerValue];
            NSUInteger numberOfAll = [[thread valueForColumn:NumberOfAllColumn] unsignedIntegerValue];
            BSHTMLHEADChecker *checker = [[BSHTMLHEADChecker alloc] initWithBoardID:boardIDUI threadID:threadID count:numberOfAll];
            [checker startChecking];
            while ([checker isChecking]) {
                id pool2 = [[NSAutoreleasePool alloc] init];
				[loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
				[pool2 release];
				if (self.isInterrupted) {
                    [checker autorelease];
                    return;
                }
            }
            if (!(checker.lastError) && checker.isUpdated) {
                [updatedThreads addObject:thread];
            }
            [checker release];
        }
		dl = [self sendHEADMethod:datURL];
		response = [dl response];
		
		if ([response statusCode] == 200) {
			newMod = [[response allHeaderFields] objectForKey:BSFavHEADerLMKey];
			NSDate *dateLastMod = [[BSHTTPDateFormatter sharedHTTPDateFormatter] dateFromString:newMod];
			NSDate *prevMod = [NSDate dateWithTimeIntervalSince1970:[modDate integerValue]];
			if ([dateLastMod compare:prevMod] == NSOrderedDescending) {
				[updatedThreads addObject:thread];
			}
		}
		[pool release];
	}
	
	if(self.isInterrupted) return;
	[self updateDB:updatedThreads];
	
	numberOfChecked = numberOfAllTarget - numberOfSkip;
	[self playFinishSoundIsUpdate:([updatedThreads count] > 0)];
	
	if (numberOfChecked > 0) {
		[[CMRFavoritesManager defaultManager] decrementHEADCheckCount];
	}
	
	if(self.isInterrupted) return;
	[targetList updateCursor];
}

- (NSArray *)threadInfomations
{
	NSArray *result = nil;
	SQLiteDB *db;
	NSString *table = [item query];
	if (!table) return nil;
	
	self.descString = NSLocalizedStringFromTable(@"Collecting infomation of thread", @"ThreadsList", @"");
	
	db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	
	if (db && [db beginTransaction]) {
		NSString *query = [NSString stringWithFormat:
						   @"SELECT %@, %@, %@, %@, %@, %@, %@ FROM (%@)",
						   BoardIDColumn, BoardNameColumn, ThreadIDColumn,
						   NumberOfAllColumn, ThreadStatusColumn, ModifiedDateColumn,
						   IsDatOchiColumn, 
						   table];
		
		id cursor = [db cursorForSQL:query];
		if (!cursor) goto abort;
		
		result = [cursor arrayForTableView];
		
		[db commitTransaction];
	}
	
	return result;
	
abort:
	[db rollbackTransaction];
	return nil;
}


/*  同一の板に存在するスレッドが 50 以上あれば、 subject.txt での更新作業に切り替えるべきかな？？？ */
/* ってことでとりあえず作ってみた。 */
const NSInteger minimumThreadCount = 50;
- (NSDictionary *)checkHOGE
{
	NSString *countColumn = @"count";
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	SQLiteDB *db;
	NSString *table = [item query];
	if (!table) return nil;
	
	db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	
	if (db && [db beginTransaction]) {
		NSString *query = [NSString stringWithFormat:
			@"SELECT DISTINCT %@ FROM (%@)",
			BoardIDColumn,
			table];
		
		id cursor = [db cursorForSQL:query];
		if (!cursor) goto abort;
		
		query = [NSString stringWithFormat:
			@"SELECT count(%@) AS %@ FROM (%@) WHERE %@ = ?",
			BoardIDColumn, countColumn,
			table,
			BoardIDColumn];
		id r = [SQLiteReservedQuery sqliteReservedQueryWithQuery:query usingSQLiteDB:db];
		if (!r) goto abort;
		
		NSInteger c, i;
		id b;
		for (i = 0, c = [cursor rowCount]; i < c; i++) {
			id pool = [[NSAutoreleasePool alloc] init];
			
			id p;
			b = [cursor valueForColumn:BoardIDColumn atRow:i];
			if (!b) {
				[pool release];
				goto abort;
			}
			
			p = [r cursorForBindValues:[NSArray arrayWithObject:b]];
			if (!p) {
				[pool release];
				goto abort;
			}
			
			id v = [p valueForColumn:countColumn atRow:0];
			if (!v) goto abort;
			
			if (minimumThreadCount < [v integerValue]) {
				[result setObject:v forKey:b];
			}
			
			[pool release];
		}
		
		[db commitTransaction];
	}
	
	return result;
	
abort:
    [db rollbackTransaction];
	return nil;
}

static BOOL shouldCheckItemHeader(id dict)
{
	id obj;
	NSInteger s;
	id nsnull = [NSNull null];
	
	obj = [dict valueForColumn:IsDatOchiColumn];
	if (!obj || [obj boolValue]) return NO;
	
	obj = [dict valueForColumn:NumberOfAllColumn];
	if (!obj || [obj integerValue] > 1000) return NO;
	
	obj = [dict valueForColumn:ThreadStatusColumn];
	if (!obj) return NO;
	
	s = [obj integerValue];
	if ( !(s | ThreadLogCachedStatus)) return NO;
	
	obj = [dict valueForColumn:BoardNameColumn];
	if (!obj || obj == nsnull) return NO;
	
	obj = [dict valueForColumn:ThreadIDColumn];
	if (!obj || obj == nsnull) return NO;
	
	obj = [dict valueForColumn:ModifiedDateColumn];
	if (!obj || obj == nsnull) return NO;
	
	return YES;
}

static NSURL *datURLForBoardIDStringAndThreadID(NSString *boardIDString, NSString *threadID)
{
	NSURL *boardURL;
	CMRHostHandler *handler;
	
    boardURL = [NSURL URLWithString:[[DatabaseManager defaultManager] urlStringForBoardID:[boardIDString unsignedIntegerValue]]];
	handler = [CMRHostHandler hostHandlerForURL:boardURL];
	
	return [handler datURLWithBoard:boardURL datName:[threadID stringByAppendingPathExtension:@"dat"]];
}

- (BSDownloadTask *)sendHEADMethod:(NSURL *)url
{
	BSDownloadTask *dlTask = [[BSDownloadTask alloc] initWithURL:url method:@"HEAD"];
	[dlTask synchronousDownLoad];
	
	return [dlTask autorelease];
}

- (void)resetNewStatus
{
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	
	self.descString = NSLocalizedStringFromTable(@"Reseting new threads status.", @"ThreadsList", @"");
	
	if (db && [db beginTransaction]) {
		id cursor = nil;
		NSString *query = [NSString stringWithFormat:
			@"SELECT %@, %@ FROM (%@) WHERE %@ = %ld",
			BoardIDColumn, ThreadIDColumn,
			[item query], ThreadStatusColumn, (long)ThreadNewCreatedStatus];
		cursor = [db performQuery:query];
		if ([cursor rowCount] == 0) {
			[db commitTransaction];
			return;
		}

		query = [NSString stringWithFormat:
			@"UPDATE %@ "
			@"SET %@ = %ld "
			@"WHERE %@ = ? AND %@ = ?",
			ThreadInfoTableName,
			ThreadStatusColumn, (long)ThreadNoCacheStatus,
			BoardIDColumn, ThreadIDColumn];
		id statment = [db reservedQuery:query];

		NSUInteger i;
        NSUInteger count;
		for (i = 0, count = [cursor rowCount]; i < count; i++) {
			[statment cursorForBindValues:
				[NSArray arrayWithObjects:
					[cursor valueForColumn:BoardIDColumn atRow:i],
					[cursor valueForColumn:ThreadIDColumn atRow:i],
					nil]];
		}

		[db commitTransaction];
	}
}

- (void)updateDB:(id)threads
{
	if (!threads || [threads count] == 0) {
        return;
	}
	NSInteger numberOfAllTarget = [threads count];
	NSInteger numberOfFinishCheck = 0;
	self.amountString = [NSString stringWithFormat:@"%ld/%ld", (long)numberOfFinishCheck, (long)numberOfAllTarget];
	self.descString = NSLocalizedStringFromTable(@"Updating database", @"ThreadsList", @"");
	
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	NSString *query = [NSString stringWithFormat:
					   @"UPDATE %@ "
					   @"SET %@ = %ld "
					   @"WHERE %@ = ? AND %@ = ?",
					   ThreadInfoTableName,
					   ThreadStatusColumn, (long)ThreadHeadModifiedStatus,
					   BoardIDColumn, ThreadIDColumn];
	if (db && [db beginTransaction]) {
		SQLiteReservedQuery *rQuery = [db reservedQuery:query];

        for (id thread in threads) {
			if(self.isInterrupted) goto abort;
			self.amountString = [NSString stringWithFormat:@"%ld/%ld", (long)++numberOfFinishCheck, (long)numberOfAllTarget];
			
			const char *format = F_NSNumberOfInt F_NSString;
			[rQuery cursorWithFormat:format, [thread valueForColumn:BoardIDColumn], [thread valueForColumn:ThreadIDColumn]];
		}

		[db commitTransaction];
	}
	
abort:
	[db rollbackTransaction];
}
@end


@implementation BSBoardListItemHEADCheckTask(Notification)
- (void)dlDidFinishDownloadNotification:(id)notification
{
	id obj = [[notification userInfo] objectForKey:BSDownloadTaskServerResponseKey];
	
	if ([obj isKindOfClass:[NSHTTPURLResponse class]]) {
        //
	}
}

- (void)dlDidAbortDownlocadNotification:(id)notification
{
	//
}

- (void)dlCancelDownloadNotification:(id)notification
{
	//
}
@end
