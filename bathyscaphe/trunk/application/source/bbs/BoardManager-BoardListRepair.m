//
//  BoardManager-BoardListRepair.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/03/30.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BoardManager_p.h"
#import "DatabaseManager.h"

@implementation BoardManager(BoardListRepairing)
- (BOOL)shouldRepairInvalidBoardData
{
    NSString *path = [self userBoardListPath];
    BOOL isDir = NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
        return YES;
    }
    return NO;
}

// BoardURLColumn が削除対象 URL に一致するレコードを指定のテーブルから探して
// そのカーソルを返す。失敗時は nil が返る。
- (id<SQLiteCursor>)cursorOfTargetURL:(NSString *)urlString table:(NSString *)tableName
{
    SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
    if (!db) {
        return nil;
    }

    NSString *prepareURL = [SQLiteDB prepareStringForQuery:urlString];
    NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = '%@'", tableName, BoardURLColumn, prepareURL];
    return [db performQuery:query];
}

// 掲示板リストから掲示板を探して、あれば削除して YES を返す。
// なかったら、NO を返す。
- (BOOL)removeTargetItemFromList:(SmartBoardList *)list urls:(NSArray *)array
{
    for (NSString *url in array) {
        id<SQLiteCursor> cursor = [self cursorOfTargetURL:url table:BoardInfoTableName];
        if (!cursor) {
            continue;
        }
        if ([cursor rowCount] == 0) {
            continue;
        }

        id values = [cursor valuesForColumn:BoardNameColumn];
        if (!values) {
            continue;
        }
        for (NSString *name in values) {
            NSLog(@"** Remove invalid board data ** Trying to remove board item %@ (%@) (if exists.)", name, url);
            id item = [list itemForName:name ofType:BoardListBoardItem];
            if (!item) {
                continue;
            }
            [list removeItem:item];
        }
    }
    return YES;
}

// データベースから BoardURLColumn 列の内容が削除対象 URL に一致するレコードを探し出して、あれば削除する。
// 正常時は YES を返す。
// エラー時は NO を返す。
- (BOOL)removeTargetURLFromDB:(NSArray *)array
{
    NSMutableString *query;
    NSString *prepareURL;
    SQLiteDB *db;
    BOOL result = YES;

    db = [[DatabaseManager defaultManager] databaseForCurrentThread];
    if (!db) {
        return NO;
    }
    for (NSString *url in array) {
        prepareURL = [SQLiteDB prepareStringForQuery:url];
        
        query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@'", BoardInfoTableName, BoardURLColumn, prepareURL];
        [db performQuery:query];
        
        result = ([db lastErrorID] == SQLITE_OK);
        if (!result) {
            NSLog(@"** Remove invalid board data ** Fail DELETE. Reason: %@", [db lastError]);
        }
        query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = '%@'", BoardInfoHistoryTableName, BoardURLColumn, prepareURL];
        [db performQuery:query];
        
        result = ([db lastErrorID] == SQLITE_OK);
        if (!result) {
            NSLog(@"** Remove invalid board data ** Fail DELETE. Reason: %@", [db lastError]);
        }
    }
	return result;
}    

- (void)repairInvalidBoardData
{
    // 削除対象の取得…
    NSLog(@"** Remove invalid board data ** Started.");
    NSArray *urlsArray = [self invalidBoardURLsToBeRemoved];
    if (!urlsArray || ([urlsArray count] == 0)) {
        NSLog(@"** Remove invalid board data ** No invalid board data to remove, so cancel repairing.");
        return;
    }

    NSLog(@"** Remove invalid board data ** Entries count = %lu", (unsigned long)[urlsArray count]);
    // ユーザ定義リスト…
    // デフォルトリスト…
    NSLog(@"** Remove invalid board data ** Remove board item from user list.");
    [self removeTargetItemFromList:[self userList] urls:urlsArray];
    NSLog(@"** Remove invalid board data ** Remove board item from default list.");
    [self removeTargetItemFromList:[self defaultList] urls:urlsArray];

    // DB…
    NSLog(@"** Remove invalid board data ** Delete records from database.");
    [self removeTargetURLFromDB:urlsArray];
    NSLog(@"** Remove invalid board data ** Finished.");
}

- (NSArray *)invalidBoardURLsToBeRemoved
{
    if (!m_invalidBoardURLs) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"BoardURLsToBeRemoved" ofType:@"plist"];
        m_invalidBoardURLs = [[NSArray alloc] initWithContentsOfFile:filePath];
    }
    return m_invalidBoardURLs;
}
@end
