//
//  BSDBThreadsListDBUpdateTask2.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/06.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSDBThreadsListDBUpdateTask2.h"

#import <CocoaOniguruma/OnigRegexp.h>

#import "DatabaseManager.h"
#import "CMRHostHandler.h"
#import "CMXTextParser.h"
#import "CMRDocumentFileManager.h"

//NSString *const BSDBThreadsListDBUpdateTask2DidFinishNotification = @"BSDBThreadsListDBUpdateTask2DidFinishNotification";


static inline id nilIfObjectIsNSNull(id obj)
{
	return (obj == [NSNull null]) ? nil : obj;
}

@implementation BSDBThreadsListDBUpdateTask2

static NSString *sSelectThreadTableQuery = nil;
static NSString *sInsertQuery = nil;
static NSString *sUpdateQuery = nil;
static NSString *sInsertNumberQuery = nil;
static OnigRegexp *gRegexp = nil;

- (id)initWithBBSName:(NSString *)name data:(NSData *)data livedoor:(BOOL)isLivedoorFlag rebuilding:(BOOL)isRebuildingFlag
{
	if (self = [super init]) {
        bbsName = [name retain];

		subjectData = [data retain];
		isRebuilding = isRebuildingFlag;
        isLivedoor = isLivedoorFlag;
	}

	return self;
}

+ (id)taskWithBBSName:(NSString *)name data:(NSData *)data livedoor:(BOOL)isLivedoorFlag rebuilding:(BOOL)isRebuildingFlag
{
    return [[[self alloc] initWithBBSName:name data:data livedoor:isLivedoorFlag rebuilding:isRebuildingFlag] autorelease];
}

- (BOOL)isRebuilding
{
	return isRebuilding;
}

- (BOOL)isLivedoor
{
    return isLivedoor;
}

- (NSError *)lastErrorWhileRebuilding
{
    return lastError;
}

- (void)dealloc
{
	[subjectData release];
	[boardID release];
	[bbsName release];
    [lastError release];

	[super dealloc];
}

- (void)setBBSName:(NSString *)name
{
	NSArray *boradIDs = [[DatabaseManager defaultManager] boardIDsForName:name];
	if (!boradIDs || [boradIDs count] == 0) {
        return;
	}
	boardID = [[boradIDs objectAtIndex:0] retain];
	bbsName = [name retain];
}

static inline SQLiteReservedQuery *reservedSelectThreadTable(SQLiteDB* db)
{
	return [SQLiteReservedQuery sqliteReservedQueryWithQuery:sSelectThreadTableQuery usingSQLiteDB:db];
}

static inline SQLiteReservedQuery *reservedInsert(SQLiteDB* db)
{
	return [SQLiteReservedQuery sqliteReservedQueryWithQuery:sInsertQuery usingSQLiteDB:db];
}

static inline SQLiteReservedQuery *reservedUpdate(SQLiteDB* db)
{
	return [SQLiteReservedQuery sqliteReservedQueryWithQuery:sUpdateQuery usingSQLiteDB:db];
}

static inline SQLiteReservedQuery *reservedInsertNumber(SQLiteDB* db)
{
	return [SQLiteReservedQuery sqliteReservedQueryWithQuery:sInsertNumberQuery usingSQLiteDB:db];
}

+ (BOOL)makeQuerys
{
	// データ確認用
	if (!sSelectThreadTableQuery) {
		sSelectThreadTableQuery = [NSString stringWithFormat: @"SELECT %@, %@, %@ FROM %@ WHERE %@ = ? AND %@ = ?",
								   ThreadStatusColumn, NumberOfAllColumn, NumberOfReadColumn,
								   ThreadInfoTableName,
								   BoardIDColumn, ThreadIDColumn];
		[sSelectThreadTableQuery retain];
	}
	
	// スレッド登録用
	if (!sInsertQuery) {
		sInsertQuery = [NSString stringWithFormat: @"INSERT INTO %@ ( %@, %@, %@, %@, %@ ) VALUES ( ?, ?, ?, ?, %ld )",
						ThreadInfoTableName,
						BoardIDColumn, ThreadIDColumn, ThreadNameColumn, NumberOfAllColumn, ThreadStatusColumn,
						(long)ThreadNewCreatedStatus];
		[sInsertQuery retain];
	}
	
	// スレッドデータ更新用
	if (!sUpdateQuery) {
		sUpdateQuery = [NSString stringWithFormat: @"UPDATE %@ SET %@ = ?, %@ = ? WHERE %@ = ? AND %@ = ?",
						ThreadInfoTableName,
						NumberOfAllColumn, ThreadStatusColumn,
						BoardIDColumn, ThreadIDColumn];
		[sUpdateQuery retain];
	}
	
	// スレッド番号登録用
	if (!sInsertNumberQuery) {
		sInsertNumberQuery = [NSString stringWithFormat: @"INSERT INTO %@ ( %@, %@, %@ ) VALUES ( ?, ?, ? )",
							  TempThreadNumberTableName,
							  BoardIDColumn, ThreadIDColumn, TempThreadThreadNumberColumn];
		[sInsertNumberQuery retain];
	}
	
	return YES;
}

+ (BOOL)makeRegex
{
    if (!gRegexp) {
        gRegexp = [OnigRegexp compile:[NSString stringWithFormat:@"(\\d+)[^,<>]*(?:<>|,)(.*)\\s*(?:\\(|<>|%C)(\\d+)", (unichar)0xFF08]];
        [gRegexp retain];
    }
    return YES;
}

- (BOOL)updateDB:(SQLiteDB *)db ID:(NSString *)datString title:(NSString *)title count:(NSInteger)countInt index:(NSInteger)index
{
	NSArray *bindValues;
	id<SQLiteCursor> cursor;

	// 対象スレッドを以前読み込んだか調べる
	// [cursor rowCount] が0なら初めて読み込んだ。
	bindValues = [NSArray arrayWithObjects:
        boardID, datString, nil];

	cursor = [reservedSelectThreadTable(db) cursorForBindValues:bindValues];
	if (!cursor) {
        return NO;
    }

	if ([cursor rowCount] == 0) {
		// 初めての読み込み。データベースに登録。
		SQLiteReservedQuery *rFirstQuery = reservedInsert(db);
        const char *format = F_NSNumberOfInt F_NSString F_NSString F_Int;
        [rFirstQuery cursorWithFormat:format, boardID, datString, title, countInt, nil];
		if ([db lastErrorID] != SQLITE_OK) {
			NSLog(@"Fail INSERT. ErrorID -> %ld. Reason: %@", (long)[db lastErrorID], [db lastError]);
		}
		
	} else {
		// ２度目以降の読み込み。レス数かステータスが変更されていればデータベースを更新。
		id<SQLiteRow> row = [cursor rowAtIndex:0];

		NSUInteger currentNumber;
		NSUInteger currentStatus, newStatus;
		NSUInteger readNumber;
		
		currentNumber = [nilIfObjectIsNSNull([row valueForColumn:NumberOfAllColumn]) integerValue];
		currentStatus = [nilIfObjectIsNSNull([row valueForColumn:ThreadStatusColumn]) integerValue];
		readNumber = [nilIfObjectIsNSNull([row valueForColumn:NumberOfReadColumn]) integerValue];

		if (readNumber == 0) {
			newStatus = ThreadNoCacheStatus;
		} else if (countInt <= readNumber) {
			newStatus = ThreadLogCachedStatus;
		} else {
			newStatus = ThreadUpdatedStatus;;
		}
		
		if (currentNumber != countInt || currentStatus != newStatus) {
			SQLiteReservedQuery *rUpdateQuery = reservedUpdate(db);
            const char *format2 = F_Int F_Int F_NSNumberOfInt F_NSString;
            [rUpdateQuery cursorWithFormat:format2, countInt, newStatus, boardID, datString, nil];
			if ([db lastErrorID] != SQLITE_OK) {
				NSLog(@"Fail UPDATE. ErrorID -> %ld. Reason: %@", (long)[db lastErrorID], [db lastError]);
			}
		}
	}
	
	// スレッド番号のための一時テーブルに番号を登録。
    SQLiteReservedQuery *rTempInsertQuery = reservedInsertNumber(db);
    const char *format3 = F_NSNumberOfInt F_NSString F_Int;
    [rTempInsertQuery cursorWithFormat:format3, boardID, datString, index, nil];
	if ([db lastErrorID] != SQLITE_OK) {
		NSLog(@"Fail INSERT. ErrorID -> %ld. Reason: %@", (long)[db lastErrorID], [db lastError]);
	}
	
	return YES;
}

- (void)deleteUnusedInfomations:(SQLiteDB *)db
{
	BOOL isDelete = SGTemplateBool(@"System - Delete Unused Thread Informations");
	if (!isDelete) {
        return;
	}

	if (db && [db beginTransaction]) {
		// 不要なデータを削除
		UTILDebugWrite(@"START DELETING");
		NSString *query = [NSString stringWithFormat:
						   @"DELETE FROM %@ "
						   @"WHERE "
						   @"%@ = %@ AND "
						   @"%@ IS NULL AND "
						   @"%@ NOT IN "
						   @"(SELECT %@ FROM %@ WHERE %@ = %@)"
						   ,
						   ThreadInfoTableName, 
						   BoardIDColumn, boardID, 
						   NumberOfReadColumn, 
						   ThreadIDColumn, 
						   ThreadIDColumn, TempThreadNumberTableName, BoardIDColumn, boardID];
		[db performQuery:query];
		if ([db lastErrorID] != 0) {
			NSLog(@"Fail DELETE. ErrorID -> %ld. Reason: %@", (long)[db lastErrorID], [db lastError] );
		}
		UTILDebugWrite1(@"	%d row(s) deleted.", sqlite3_changes([db rowDatabase]));
		[db commitTransaction];
		UTILDebugWrite(@"END DELETEING");
	}
}

- (BOOL)rebuildFromLogFiles:(NSError **)errorPtr
{
	NSString *folderPath = [[CMRDocumentFileManager defaultManager] directoryWithBoardName:bbsName];
	
	return [[DatabaseManager defaultManager] rebuildFromLogFolder:folderPath boardID:boardID error:errorPtr];
}

- (void)run
{
	NSString *str;
	NSArray *lines;
	NSUInteger count, i;
	NSString *line;
	NSString *datString;
	id title;
	NSString *numString;

	UTILDebugWrite(@"Start BSDBThreadsListDBUpdateTask2.");

	CFStringEncoding enc;
	DatabaseManager *dbm = [DatabaseManager defaultManager];
	NSArray *array = [dbm boardIDsForName:bbsName];
	NSString *urlStr;
	NSURL *url;
	CMRHostHandler *handler;

	if (!array || [array count] == 0) {
		NSLog(@"Can NOT found bbs named %@.",bbsName);
		return;
	}
    boardID = [[array objectAtIndex:0] retain];

	urlStr = [dbm urlStringForBoardID:[boardID integerValue]];
	url = [NSURL URLWithString:urlStr];
	if (!url) {
		NSLog(@"Can NOT create url from bbs named %@.",bbsName);
		return;
	}
	handler = [CMRHostHandler hostHandlerForURL:url];
	if (!handler) {
		NSLog(@"Can NOT create host handler from url %@.",url);
		return;
	}
	enc = [handler subjectEncoding];
	str = [CMXTextParser stringWithData:subjectData CFEncoding:enc];//[NSString stringWithDataUsingTEC:subjectData encoding:enc];
	// 行分割
	lines = [str componentsSeparatedByNewline];	

    if (![[self class] makeRegex]) {
        UTILDebugWrite(@"Can not create regular expression(BSDBThreadsListDBUpdateTask2.)");
        return;
    }
    OnigResult *match;
	
	SQLiteDB *db = [dbm databaseForCurrentThread];
	
	if (db && [db beginTransaction]) {
		if (![BSDBThreadsListDBUpdateTask2 makeQuerys]) {
			UTILDebugWrite(@"Can not create query string(BSDBThreadsListDBUpdateTask2.)");
			goto abort;
		}

		if (isInterrupted) {
            goto abort;
		}
		// スレッド番号用テーブルをクリア
		UTILDebugWrite(@"START CLEAR TEMP DATA");
		id query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %@",
			TempThreadNumberTableName,
			BoardIDColumn, boardID];
		[db performQuery:query];
		UTILDebugWrite1(@"	%d row(s) deleted.", sqlite3_changes([db rowDatabase]));
		UTILDebugWrite(@"END CLEAR TEMP DATA");
		
		UTILDebugWrite(@"START REGISTER THREADS");
        count = [lines count];
        NSMutableSet *dats = isLivedoor ? [[NSMutableSet alloc] initWithCapacity:count] : nil;
        for (i = 0; i < count; i++) {
			if (isInterrupted) {
                [dats release];
                goto abort;
			}
			line = [lines objectAtIndex:i];
            match = [gRegexp search:line];

			datString = [match stringAt:1];
			title = [match stringAt:2];
			numString = [match stringAt:3];
			
			if (!numString) {
                continue;
			}
            if (isLivedoor) {
                if ([dats member:datString]) {
                    continue;
                } else {
                    [dats addObject:datString];
                }
            }
			title = [[title mutableCopy] autorelease];
			[CMXTextParser replaceEntityReferenceWithString:title];
			
			// DB に投入
			if(![self updateDB:db ID:datString title:title count:[numString integerValue] index:(i+1)]) {
				UTILDebugWrite(@"Abort in updateDB.");
                [dats release];
				goto abort;
			}
		}
        [dats release];
		[db commitTransaction];
		UTILDebugWrite(@"END REGISTER THREADS");
	}

	if (isRebuilding) {
        NSError *error = nil;
		[self rebuildFromLogFiles:&error];
        if (error) {
            lastError = [error retain];
        }
	} else {
		[self deleteUnusedInfomations:db];
	}
	
//	[self postNotificationWithName:BSDBThreadsListDBUpdateTask2DidFinishNotification];
	
	return;
	
abort:
	NSLog(@"Fail Database operation. Reason: \n%@\nin %@(%@)",
		  [db lastError], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	[db rollbackTransaction];
	
//	if (!isInterrupted) {
//		[self postNotificationWithName:BSDBThreadsListDBUpdateTask2DidFinishNotification];
//	}
}

- (void)cancel:(id)sender
{
//	[self postNotificationWithName:BSDBThreadsListDBUpdateTask2DidFinishNotification];
	isInterrupted = YES;
}
@end

/*
@implementation BSDBThreadsListDBUpdateTask2(TaskNotification)
- (void)postNotificationWithName:(NSString *)name
{
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self];	
	UTILDebugWrite(@"End BSDBThreadsListDBUpdateTask2.");
}
@end
*/
