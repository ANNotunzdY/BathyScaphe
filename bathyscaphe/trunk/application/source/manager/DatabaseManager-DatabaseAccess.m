//
//  DatabaseManager-DatabaseAccess.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005-2008 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "DatabaseManager.h"

#import "SQLiteDB.h"
#import "CMRThreadAttributes.h"
#import "CMRDocumentFileManager.h"

static NSMutableDictionary *boardIDNameCache = nil;
static NSLock *boardIDNumberCacheLock = nil;
NSString *const DatabaseManagerInvalidFilePathsArrayKey = @"FilePathsArray";

@implementation DatabaseManager (DatabaseAccess)
- (NSUInteger)boardIDForURLStringExceptingHistory:(NSString *)urlString
{
	NSMutableString *query;
	NSString *prepareURL;
	SQLiteDB *db;
	id <SQLiteCursor> cursor;
	id value;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NSNotFound;
	}
	
	prepareURL = [SQLiteDB prepareStringForQuery:urlString];
	query = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", BoardIDColumn, BoardInfoTableName];
	[query appendFormat:@"\n\tWHERE %@ = '%@'", BoardURLColumn, prepareURL];
	cursor = [db performQuery:query];
	
	if (!cursor || [cursor rowCount] == 0) {
		return NSNotFound;
	}

	value = [cursor valueForColumn:BoardIDColumn atRow:0];
	if (!value) {
		return NSNotFound;
	}
	if (![value respondsToSelector:@selector(integerValue)]) {
		NSLog (@"%@ is broken.", BoardInfoTableName);
		return NSNotFound;
	}

	return (NSUInteger)[value integerValue];
}

// return NSNotFound, if not registered.
- (NSUInteger)boardIDForURLString:(NSString *)urlString
{
	NSMutableString *query;
	NSString *prepareURL;
	SQLiteDB *db;
	id <SQLiteCursor> cursor;
	id value;
	BOOL found = NO;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NSNotFound;
	}
	
	prepareURL = [SQLiteDB prepareStringForQuery:urlString];
	query = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", BoardIDColumn, BoardInfoTableName];
	[query appendFormat:@"\n\tWHERE %@ = '%@'", BoardURLColumn, prepareURL];
	cursor = [db performQuery:query];
	
	if (cursor && [cursor rowCount]) {
		found = YES;
	}

	if (!found) {
		query = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", BoardIDColumn, BoardInfoHistoryTableName];
		[query appendFormat:@"\n\tWHERE %@ = '%@'", BoardURLColumn, prepareURL];
		cursor = [db performQuery:query];
		if (cursor && [cursor rowCount]) {
			found = YES;
		}
	}

    if (!found) {
        NSURL *tmp = [NSURL URLWithString:urlString];
        if ([[tmp host] hasSuffix:@".2ch.net"]) {
            query = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", BoardIDColumn, BoardInfoTableName];
            [query appendFormat:@"\n\tWHERE %@ LIKE '%%%@/'", BoardURLColumn, [tmp path]];
            cursor = [db performQuery:query];
            if (cursor && [cursor rowCount]) {
                found = YES;
            }
        }
	}

	if (!found) {
		return NSNotFound;
	}

	value = [cursor valueForColumn:BoardIDColumn atRow:0];
	if (!value) {
		return NSNotFound;
	}
	if (![value respondsToSelector:@selector(integerValue)]) {
		NSLog (@"%@ or %@ is broken.", BoardInfoTableName, BoardInfoHistoryTableName );
		return NSNotFound;
	}
	
	return (NSUInteger)[value integerValue];
}

- (NSString *)urlStringForBoardID:(NSUInteger)boardID
{
	NSMutableString *query;
	NSURL *url;
	SQLiteDB *db;
	id<SQLiteCursor> cursor;
	id value;

	if (boardID == 0) {
        return nil;
    }

	db = [self databaseForCurrentThread];
	if (!db) {
		return nil;
	}

//	query = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@", BoardURLColumn, BoardInfoTableName];
//	[query appendFormat:@"\n\tWHERE %@ = %lu", BoardIDColumn, (unsigned long)boardID];
    query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %lu", BoardURLColumn, BoardInfoTableName, BoardIDColumn, (unsigned long)boardID];
	cursor = [db performQuery:query];

	if (!cursor || ![cursor rowCount]) {
		return nil;
	}

	value = [cursor valueForColumn:BoardURLColumn atRow:0];
	if (!value) {
		return nil;
	}

	url = [NSURL URLWithString:value];
	if (!url) {
		NSLog(@"[%@ -%@]: %@ is broken.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), BoardInfoTableName);
		return nil;
	}

	return value;
}
// return nil, if not registered.
- (NSArray *) boardIDsForName : (NSString *) name
{	
	NSMutableString *query;
	NSString *prepareName;
	SQLiteDB *db;
	id <SQLiteCursor> cursor;
	id value;
	BOOL found = NO;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return nil;
	}
	
	if(!boardIDNameCache) {
		boardIDNameCache = [[NSMutableDictionary alloc] init];
		boardIDNumberCacheLock = [[NSLock alloc] init];
		if(!boardIDNumberCacheLock) {
			[boardIDNameCache release];
			boardIDNameCache = nil;
		}
	}
	
	if(boardIDNameCache) {
		id idArray;
		
		idArray = [boardIDNameCache objectForKey:name];
		if(idArray) {
			return idArray;
		}
	}
	
	prepareName = [SQLiteDB prepareStringForQuery : name];
	query = [NSMutableString stringWithFormat: @"SELECT %@ FROM %@", BoardIDColumn, BoardInfoTableName];
	[query appendFormat: @"\n\tWHERE %@ LIKE '%@'", BoardNameColumn, prepareName];
	cursor = [db performQuery : query];
	
	if (cursor && [cursor rowCount]) {
		found = YES;
	}
	
	if (!found) {
		query = [NSMutableString stringWithFormat: @"SELECT %@ FROM %@", BoardIDColumn, BoardInfoHistoryTableName];
		[query appendFormat: @"\n\tWHERE %@ LIKE '%@'", BoardNameColumn, prepareName];
		cursor = [db performQuery : query];
		if (cursor && [cursor rowCount]) {
			found = YES;
		}
	}
	
	if (!found) {
		return nil;
	}
	
	value = [cursor valuesForColumn : BoardIDColumn];
	if([value count] != 0 ) {
		[boardIDNumberCacheLock lock];
		[boardIDNameCache setObject:value forKey:name];
		[boardIDNumberCacheLock unlock];
	}
	return [value count] > 0 ? value : nil;
}
- (NSString *) nameForBoardID : (NSUInteger) boardID
{
	NSMutableString *query;
	SQLiteDB *db;
	id <SQLiteCursor> cursor;
	id value;
	
	if (boardID == 0) return nil;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return nil;
	}
	
	query = [NSMutableString stringWithFormat: @"SELECT %@ FROM %@", BoardNameColumn, BoardInfoTableName];
	[query appendFormat: @"\n\tWHERE %@ = %lu", BoardIDColumn, (unsigned long)boardID];
	cursor = [db performQuery : query];
	
	if (!cursor || ![cursor rowCount]) {
		return nil;
	}
	
	value = [cursor valueForColumn : BoardNameColumn atRow : 0];
	
	return value;
}

// raise DatabaseManagerCantFountKeyExseption.
- (id)valueForKey:(NSString *)key boardID:(NSUInteger)boardID threadID:(NSString *)threadID
{
	NSString *query;
	SQLiteDB *db;
	id <SQLiteCursor> cursor;
	id value;
	
	if (boardID == 0) return nil;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %lu AND %@ = %@",
		BoardThreadInfoViewName,
		BoardIDColumn, (unsigned long)boardID,
		ThreadIDColumn, threadID];
	cursor = [db performQuery : query];
	if (!cursor || ![cursor rowCount]) {
		return nil;
	}
	
	value = [cursor valueForColumn : key atRow : 0];
	
	return value;
}
	
//- (void)setValue:(id)value forKey:(NSString *)key boardID:(NSUInteger)boardID threadID:(NSString *)threadID;


- (BOOL) registerBoardName : (NSString *) name URLString : (NSString *) urlString
{
	BOOL result = NO;
	
	NSMutableString *query;
	NSString *prepareName;
	NSString *prepareURL;
	SQLiteDB *db;
	
	// checking URL.
	{
		if(!urlString) {
			NSLog(@"urlString is nil.");
			return NO;
		}
		id url = [NSURL URLWithString : urlString];
		if (!url) {
			NSLog(@"urlString (%@) is NOT url.", urlString);
			return NO;
		}
	}
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	prepareName = [SQLiteDB prepareStringForQuery : name];
	prepareURL = [SQLiteDB prepareStringForQuery : urlString];
	query = [NSMutableString stringWithFormat: @"INSERT INTO %@", BoardInfoTableName];
	[query appendFormat: @" ( %@, %@, %@ ) ", BoardIDColumn, BoardNameColumn, BoardURLColumn];
	[query appendFormat: @"VALUES ( (SELECT max(%@) FROM %@) + 1, '%@', '%@' ) ",
		BoardIDColumn, BoardInfoTableName, prepareName, prepareURL];
	[db performQuery : query];
	
	result = ([db lastErrorID] == 0);
	if(!result) {
		NSLog(@"Fail registerBoard.\nReson: %@", [db lastError]);
	}
	return result;
}

/*- (BOOL)deleteBoardOfBoardID:(NSUInteger)boardID
{
	SQLiteDB	*db;
	NSString	*query;

	[self recache];
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}

	query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %u", BoardInfoTableName, BoardIDColumn, boardID];
	[db performQuery:query];

	BOOL result = ([db lastErrorID] == 0);
	if(!result) {
		NSLog(@"Fail deleteBoard.\nReson: %@", [db lastError]);
	}
	return result;
}
}*/

/*
 - (BOOL) registerBoardNamesAndURLs : (NSArray *) array;
 */

- (BOOL) moveBoardID : (NSUInteger) boardID
		 toURLString : (NSString *) urlString
{
	NSMutableString *query;
	SQLiteDB *db;
	NSString *currentURLString;
	NSString *prepareURLString;
	
	BOOL inTransactionBlock = NO;
	
	if (!urlString || ![urlString length]) {
		NSLog(@"urlString MUST NOT be nil or NOT zero length.");
		return NO;
	}
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	currentURLString = [self urlStringForBoardID : boardID];
	if ([currentURLString isEqualTo : urlString]) return YES;
	
	if(![db beginTransaction]) {
		if([db lastErrorID] == 0) {
			inTransactionBlock = YES;
		} else {
			return NO;
		}
	}
	
	prepareURLString = [SQLiteDB prepareStringForQuery : currentURLString];
	query = [NSMutableString string];
	[query appendFormat: @"INSERT INTO %@", BoardInfoHistoryTableName];
	[query appendFormat: @"\t (%@, %@) ", BoardIDColumn, BoardURLColumn];
	[query appendFormat: @"\tVALUES (%lu, '%@') ", (unsigned long)boardID, prepareURLString];
	
	[db performQuery : query];
	if ([db lastErrorID] != 0 && [db lastErrorID] != SQLITE_CONSTRAINT) {
		NSLog(@"Fail insert into %@", BoardInfoHistoryTableName);
		[db rollbackTransaction];
		
		return NO;
	}
	
	prepareURLString = [SQLiteDB prepareStringForQuery : urlString];
	query = [NSMutableString string];
	[query appendFormat: @"UPDATE %@", BoardInfoTableName];
	[query appendFormat: @"\tSET %@ = '%@'", BoardURLColumn, prepareURLString];
	[query appendFormat: @"\tWHERE %@ = %lu", BoardIDColumn, (unsigned long)boardID];
	
	[db performQuery : query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail update %@", BoardInfoTableName);
		[db rollbackTransaction];
		
		return NO;
	}
	
	if(!inTransactionBlock) {
		[db commitTransaction];
	}
	
	return YES;
}

- (BOOL) renameBoardID : (NSUInteger) boardID
				toName : (NSString *) name
{
	NSMutableString *query;
	SQLiteDB *db;
	NSString *currentName;
	NSString *prepareName;
	
	BOOL inTransactionBlock = NO;
	
	if (!name || ![name length]) {
		NSLog(@"name MUST NOT be nil or NOT zero length.");
		return NO;
	}
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	currentName = [self nameForBoardID : boardID];
	if ([currentName isEqualTo : name]) return YES;
	
	[self recache];
	
	if(![db beginTransaction]) {
		if([db lastErrorID] == 0) {
			inTransactionBlock = YES;
		} else {
			return NO;
		}
	}
	
	prepareName = [SQLiteDB prepareStringForQuery : currentName];
	query = [NSMutableString string];
	[query appendFormat: @"INSERT INTO %@", BoardInfoHistoryTableName];
	[query appendFormat: @"\t (%@, %@) ", BoardIDColumn, BoardNameColumn];
	[query appendFormat: @"\tVALUES (%lu, '%@') ", (unsigned long)boardID, prepareName];
	
	[db performQuery : query];
	if ([db lastErrorID] != 0 && [db lastErrorID] != SQLITE_CONSTRAINT) {
		NSLog(@"Fail insert into %@", BoardInfoHistoryTableName);
		[db rollbackTransaction];
		
		return NO;
	}
	
	prepareName = [SQLiteDB prepareStringForQuery : name];
	query = [NSMutableString string];
	[query appendFormat: @"UPDATE %@", BoardInfoTableName];
	[query appendFormat: @"\tSET %@ = '%@'", BoardNameColumn, prepareName];
	[query appendFormat: @"\tWHERE %@ = %lu", BoardIDColumn, (unsigned long)boardID];
	
	[db performQuery : query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail insert into %@", BoardInfoHistoryTableName);
		[db rollbackTransaction];
		
		return NO;
	}
	
	if(!inTransactionBlock) {
		[db commitTransaction];
	}
	return YES;
}

/*
 - (BOOL) registerThreadName : (NSString *) name 
 threadIdentifier : (NSString *) identifier
 intoBoardID : (NSUInteger) boardID;
 - (BOOL) registerThreadNamesAndThreadIdentifiers : (NSArray *) array
 intoBoardID : (NSUInteger) boardID;
 */
- (BOOL)isThreadIdentifierRegistered:(NSString *)identifier onBoardID:(NSUInteger)boardID
{
	return [self isThreadIdentifierRegistered:identifier onBoardID:boardID numberOfAll:NULL];
}

- (BOOL)isThreadIdentifierRegistered:(NSString *)identifier onBoardID:(NSUInteger)boardID numberOfAll:(NSUInteger *)number
{
	SQLiteDB *db = [self databaseForCurrentThread];
	
	if (!db) {
		return NO;
	}

	NSString *query;
	id<SQLiteCursor> cursor;	
	query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %lu AND %@ = %@",
				NumberOfAllColumn, ThreadInfoTableName, BoardIDColumn, (unsigned long)boardID, ThreadIDColumn, identifier];
	cursor = [db performQuery:query];

	if (cursor && ([cursor rowCount] > 0)) {
		if (number != NULL) {
			id value = [cursor valueForColumn:NumberOfAllColumn atRow:0];
			if ([value isKindOfClass:[NSString class]]) {
				*number = [value integerValue];
			}
		}
		return YES;
	}

	return NO;
}

- (BOOL) isFavoriteThreadIdentifier : (NSString *) identifier
						  onBoardID : (NSUInteger) boardID
{
	NSMutableString *query;
	SQLiteDB *db;
	id<SQLiteCursor> cursor;
	id value;
	BOOL isFavorite = NO;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	query = [NSMutableString stringWithFormat: @"SELECT count(*) FROM %@ WHERE %@ = %lu AND %@ = %@",
			 FavoritesTableName, BoardIDColumn, (unsigned long)boardID, ThreadIDColumn, identifier];
	cursor = [db performQuery : query];
	if (cursor && [cursor rowCount]) {
		value = [cursor valueForColumn : @"count(*)" atRow : 0];
		if ([value integerValue]) {
			isFavorite = YES;
		}
	}
	
	return isFavorite;
}
- (BOOL) appendFavoriteThreadIdentifier : (NSString *) identifier
							  onBoardID : (NSUInteger) boardID
{
	NSMutableString *query;
	SQLiteDB *db;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	if([db beginTransaction]) {
		query = [NSMutableString stringWithFormat: @"INSERT INTO %@", FavoritesTableName];
		[query appendFormat: @" ( %@, %@ ) ", BoardIDColumn, ThreadIDColumn];
		[query appendFormat: @" VALUES ( %lu, %@ ) ", (unsigned long)boardID, identifier];
		[db performQuery : query];
		if([db lastErrorID] != 0) goto abort;
		
		[db commitTransaction];
	} else {
		return NO;
	}
	
	return YES;
	
abort:
	NSLog(@"FAIL append Favorote. Reason : %@", [db lastError]);
	[db rollbackTransaction];
	return NO;
}
- (BOOL) removeFavoriteThreadIdentifier : (NSString *) identifier
							  onBoardID : (NSUInteger) boardID
{
	NSMutableString *query;
	SQLiteDB *db;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	if([db beginTransaction]) {
		query = [NSMutableString stringWithFormat: @"DELETE FROM %@", FavoritesTableName];
		[query appendFormat: @" WHERE %@ = %lu", BoardIDColumn, (unsigned long)boardID];
		[query appendFormat: @" AND %@ = %@", ThreadIDColumn, identifier];
		[db performQuery : query];
		if([db lastErrorID] != 0) goto abort;
		
		[db commitTransaction];
	} else {
		return NO;
	}
	
	return YES;
	
abort:
	NSLog(@"FAIL delete Favorote. Reason : %@", [db lastError]);
	[db rollbackTransaction];
	return NO;
}

- (BOOL)registerThreadFromFilePath:(NSString *)filepath
{
	return [self registerThreadFromFilePath:filepath needsDisplay:YES];
}

- (BOOL)registerThreadFromFilePath:(NSString *)filepath needsDisplay:(BOOL)flag
{
	NSDictionary *hoge = [NSDictionary dictionaryWithContentsOfFile:filepath];
	NSString *datNum, *title, *boardName;
	NSUInteger count;
	NSDate *date;
	CMRThreadUserStatus	*s;
	id rep;
	NSUInteger boardID;
	BOOL	isDatOchi;
	NSUInteger label = 0;
	
	datNum = [hoge objectForKey:ThreadPlistIdentifierKey];
	if (!datNum) return NO;
	title = [hoge objectForKey:CMRThreadTitleKey];
	if (!title) return NO;
	boardName = [hoge objectForKey:ThreadPlistBoardNameKey];
	if (!boardName) return NO;
	count = [[hoge objectForKey: ThreadPlistContentsKey] count];
	
	rep = [hoge objectForKey:CMRThreadUserStatusKey];
	s = [CMRThreadUserStatus objectWithPropertyListRepresentation:rep];
	isDatOchi = (s ? [s isDatOchiThread] : NO);
	label = (s ? [s label] : 0);
	
	date = [hoge objectForKey:CMRThreadModifiedDateKey];
	
	NSArray *boardIDs = [self boardIDsForName:boardName];
	if (!boardIDs || [boardIDs count] == 0) {
		CMRDocumentFileManager *dfm = [CMRDocumentFileManager defaultManager];
		NSString *otherBoardName = [dfm boardNameWithLogPath:filepath];
		if(![otherBoardName isEqualToString:boardName]) {
			boardIDs = [self boardIDsForName:otherBoardName];
			if(!boardIDs || [boardIDs count] == 0) {
				NSLog(@"board %@ is not registered.(%@)", otherBoardName, filepath);
				return NO;
			}
		} else {
			NSLog(@"board %@ is not registered.(%@)", boardName, filepath);
			return NO;
		}
	}
	boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];
	
	BOOL isSuccess = [self insertThreadOfIdentifier:datNum title:title count:count date:date isDatOchi:isDatOchi atBoard:boardID];
	[self setLabel:label boardName:boardName threadIdentifier:datNum];
	if (isSuccess && flag) {
		[self makeThreadsListsUpdateCursor];
		return YES;
	}
	return isSuccess;
}

- (NSString *) threadTitleFromBoardName:(NSString *)boadName threadIdentifier:(NSString *)identifier
{
	NSString *boardID;
	NSArray *boardIDs;
	NSString *query;
	SQLiteDB *db;
	id<SQLiteCursor> cursor;
	
	NSString *title = nil;
	
	UTILAssertKindOfClass(boadName, NSString);
	UTILAssertKindOfClass(identifier, NSString);
	if([boadName length] == 0) return nil;
	if([identifier length] == 0) return nil;
	
	boardIDs = [self boardIDsForName:boadName];
	if(!boardIDs || [boardIDs count] == 0) return nil;
	
	boardID = [boardIDs objectAtIndex:0];
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return nil;
	}
	
	query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %@ AND %@ = %@",
		ThreadNameColumn,
		ThreadInfoTableName,
		BoardIDColumn, boardID,
		ThreadIDColumn, identifier,
		nil];
	cursor = [db performQuery: query];
	if (cursor && [cursor rowCount]) {
		title = [cursor valueForColumn : ThreadNameColumn atRow : 0];
	}
	
	return title;
}

- (void)setLastWriteDate:(NSDate *)writeDate atBoardID:(NSUInteger)boardID threadIdentifier:(NSString *)identifier
{
	NSString *query;
	SQLiteDB *db;
	UTILAssertKindOfClass(identifier, NSString);
		
	if([identifier length] == 0) return;
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return;
	}
	
	query = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %.0lf WHERE %@ = %lu AND %@ = %@",
		ThreadInfoTableName,
		LastWrittenDateColumn, [writeDate timeIntervalSince1970],
		BoardIDColumn, (unsigned long)boardID,
		ThreadIDColumn, identifier,
		nil];
	[db performQuery: query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail update LastWrittenDate.");
	}
}


- (BOOL)setThreadStatus:(ThreadStatus)status modifiedDate:(NSDate *)date atBoardID:(NSUInteger)boardID threadIdentifier:(NSString *)identifier
{
	NSString *query;
	SQLiteDB *db;

	if ([identifier length] == 0) {
        return NO;
	}

	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}

    if (date) {
        NSTimeInterval intSince1970;
        intSince1970 = [date timeIntervalSince1970];

        query = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %ld, %@ = %.0lf WHERE %@ = %lu AND %@ = %@",
                 ThreadInfoTableName,
                 ThreadStatusColumn, (long)status,
                 ModifiedDateColumn, intSince1970,
                 BoardIDColumn, (unsigned long)boardID,
                 ThreadIDColumn, identifier,
                 nil];
    } else {
        query = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %ld WHERE %@ = %lu AND %@ = %@",
                 ThreadInfoTableName,
                 ThreadStatusColumn, (long)status,
                 BoardIDColumn, (unsigned long)boardID,
                 ThreadIDColumn, identifier,
                 nil];
    }
	[db performQuery:query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail update ThreadStatus.");
        return NO;
	}
    return YES;
}

- (void) setIsDatOchi:(BOOL)flag
			boardName:(NSString *)boardName
	 threadIdentifier:(NSString *)identifier
{
	NSString *boardID;
	NSArray *boardIDs;
	NSString *query;
	SQLiteDB *db;
		
	UTILAssertKindOfClass(boardName, NSString);
	UTILAssertKindOfClass(identifier, NSString);
	if([boardName length] == 0) return;
	if([identifier length] == 0) return;
	
	boardIDs = [self boardIDsForName:boardName];
	if(!boardIDs || [boardIDs count] == 0) return;
	
	boardID = [boardIDs objectAtIndex:0];
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return;
	}
	
	query = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %ld WHERE %@ = %@ AND %@ = %@",
		ThreadInfoTableName,
		IsDatOchiColumn, flag ? 1L : 0L,
		BoardIDColumn, boardID,
		ThreadIDColumn, identifier,
		nil];
	[db performQuery: query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail update IsDatOchi.");
	}
}
- (BOOL)isDatOchiBoardName:(NSString *)boardName threadIdentifier:(NSString *)identifier
{
	NSString *boardID;
	NSArray *boardIDs;
	NSString *query;
	SQLiteDB *db;
	id<SQLiteCursor> cursor;
	
	BOOL result = NO;
	
	UTILAssertKindOfClass(boardName, NSString);
	UTILAssertKindOfClass(identifier, NSString);
	if([boardName length] == 0) return NO;
	if([identifier length] == 0) return NO;
	
	boardIDs = [self boardIDsForName:boardName];
	if(!boardIDs || [boardIDs count] == 0) return NO;
	
	boardID = [boardIDs objectAtIndex:0];
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %@ AND %@ = %@",
		IsDatOchiColumn,
		ThreadInfoTableName,
		BoardIDColumn, boardID,
		ThreadIDColumn, identifier,
		nil];
	cursor = [db performQuery: query];
	if (cursor && [cursor rowCount]) {
		result = [[cursor valueForColumn : IsDatOchiColumn atRow : 0] integerValue];
	}
	
	return result;
}

- (void)setLabel:(NSUInteger)code
	   boardName:(NSString *)boardName
threadIdentifier:(NSString *)identifier
{
	NSString *boardID;
	NSArray *boardIDs;
	NSString *query;
	SQLiteDB *db;
	
	if ([boardName length] == 0) return;
	if ([identifier length] == 0) return;
	
	boardIDs = [self boardIDsForName:boardName];
	if (!boardIDs || [boardIDs count] == 0) return;
	
	boardID = [boardIDs objectAtIndex:0];
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return;
	}

	query = [NSString stringWithFormat:@"UPDATE %@ SET %@ = %lu WHERE %@ = %@ AND %@ = %@",
			 ThreadInfoTableName,
			 ThreadLabelColumn, (unsigned long)code,
			 BoardIDColumn, boardID,
			 ThreadIDColumn, identifier,
			 nil];
	[db performQuery:query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail update threadLabel.");
	} else {
        NSNotification *notification = [NSNotification notificationWithName:DatabaseDidUpdateThreadLabelNotification object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                   postingStyle:NSPostWhenIdle
                                                   coalesceMask:(NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender)
                                                       forModes:nil];
    }
}

- (NSUInteger)labelBoardName:(NSString *)boardName threadIdentifier:(NSString *)identifier
{
	NSString *boardID;
	NSArray *boardIDs;
	NSString *query;
	SQLiteDB *db;
	id<SQLiteCursor> cursor;
	
	NSUInteger result = 0;
	
	if([boardName length] == 0) return NO;
	if([identifier length] == 0) return NO;
	
	boardIDs = [self boardIDsForName:boardName];
	if(!boardIDs || [boardIDs count] == 0) return NO;
	
	boardID = [boardIDs objectAtIndex:0];
	
	db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	query = [NSString stringWithFormat:@"SELECT %@ FROM %@ WHERE %@ = %@ AND %@ = %@",
			 ThreadLabelColumn,
			 ThreadInfoTableName,
			 BoardIDColumn, boardID,
			 ThreadIDColumn, identifier,
			 nil];
	cursor = [db performQuery: query];
	if (cursor && [cursor rowCount]) {
		result = [[cursor valueForColumn : IsDatOchiColumn atRow : 0] unsignedIntegerValue];
	}
	
	return result;
}
#pragma mark Testing...

static NSString *const DMDA_TEMP_THREAD_INFO_TABLE = @"DMDA_TEMP_THREAD_INFO_TABLE";
static inline NSString *numberOfAllQuery()
{
	static NSString *query = nil;
	if(!query) {
		query = [[NSString alloc] initWithFormat:
		@"SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ?",
		NumberOfAllColumn, ThreadInfoTableName/*DMDA_TEMP_THREAD_INFO_TABLE*/, BoardIDColumn, ThreadIDColumn];
	}
	return query;
}
static inline NSUInteger numberOfAllOfBoardIDAndThreadIDInDatabase(NSNumber *boardID, NSString *threadID, SQLiteDB *db)
{
	NSUInteger result = 0;
	
	SQLiteReservedQuery *rQuery = [db reservedQuery:numberOfAllQuery()];
	const char *format = F_NSNumberOfInt F_NSString;
	id<SQLiteCursor> cursor = [rQuery cursorWithFormat:format, boardID, threadID, nil];
	if (cursor && [cursor rowCount]) {
		result = [[cursor valueForColumn:NumberOfAllColumn atRow:0] unsignedIntegerValue];
	}
	
	return result;
}
static inline NSString *lastWrittenDateQuery()
{
	static NSString *query2 = nil;
	if(!query2) {
		query2 = [[NSString alloc] initWithFormat:
				 @"SELECT %@ FROM %@ WHERE %@ = ? AND %@ = ?",
				 LastWrittenDateColumn, DMDA_TEMP_THREAD_INFO_TABLE, BoardIDColumn, ThreadIDColumn];
	}
	return query2;
}
static inline id lastWrittenDateOfBoardIDAndThreadIDInDatabase(NSNumber *boardID, NSString *threadID, SQLiteDB *db)
{
	id result = nil;
	
	SQLiteReservedQuery *rQuery = [db reservedQuery:lastWrittenDateQuery()];
	const char *format = F_NSNumberOfInt F_NSString;
	id<SQLiteCursor> cursor = [rQuery cursorWithFormat:format, boardID, threadID, nil];
	
	if(SQLITE_OK != [db lastErrorID]) {
		NSLog(@"Fail lastWrittenDateOfBoardIDAndThreadIDInDatabase Reason -> %@", [db lastError]);
	}
	if (cursor && [cursor rowCount]) {
		result = [cursor valueForColumn:LastWrittenDateColumn atRow:0];
	}
	
	return result;
}
static NSString *rebuildQuery()
{
	static NSString *query = nil;
	if(!query) {
		query = [[NSString alloc] initWithFormat:
				 @"REPLACE INTO %@ (%@, %@, %@, %@, %@, %@, %@, %@, %@)"
				 @"VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
				 ThreadInfoTableName,
				 BoardIDColumn, ThreadIDColumn,
				 ThreadNameColumn, NumberOfAllColumn, NumberOfReadColumn, ModifiedDateColumn, LastWrittenDateColumn, IsDatOchiColumn, ThreadLabelColumn];
	}
	return query;
}

static NSError *fileContentsErrorObject(NSArray *filepaths)
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:filepaths, DatabaseManagerInvalidFilePathsArrayKey,
                          NSLocalizedStringFromTable(@"RebuildingErrorAlert", @"DatabaseManager", nil), NSLocalizedDescriptionKey,
                          NSLocalizedStringFromTable(@"RebuildingErrorMessage", @"DatabaseManager", nil), NSLocalizedRecoverySuggestionErrorKey,
                          [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"RebuildingErrorOK", @"DatabaseManager", nil),
                           NSLocalizedStringFromTable(@"RebuildingErrorShowFiles", @"DatabaseManager", nil), nil], NSLocalizedRecoveryOptionsErrorKey,
                          NULL];
    return [NSError errorWithDomain:BSBathyScapheErrorDomain code:DatabaseManagerRebuildLogFileContentsError userInfo:dict];
}

static NSError *dbErrorObject(NSInteger errorID, NSString *errorMessage)
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:errorID], @"lastErrorID", errorMessage, @"lastError", NULL];
    return [NSError errorWithDomain:BSBathyScapheErrorDomain code:DatabaseManagerRebuildLogFileDBError userInfo:dict];
}

- (BOOL)rebuildFromFilePath:(NSString *)filepath withBoardID:(NSNumber *)boardID isDBError:(BOOL *)dbErrFlagPtr
{
	SQLiteDB *db = [self databaseForCurrentThread];
	
	NSDictionary *fileContents = [NSDictionary dictionaryWithContentsOfFile:filepath];
	NSString *datNum, *title;
	NSUInteger count, numberOfAll;
	NSDate *date;
	id lastWrittenDate = nil;
	CMRThreadUserStatus	*s;
	id rep;
	BOOL isDatOchi;
    NSUInteger labelCode;

	datNum = [fileContents objectForKey:ThreadPlistIdentifierKey];
	if (!datNum) {
        if (dbErrFlagPtr != NULL) {
            *dbErrFlagPtr = NO;
        }
        return NO;
    }

	title = [fileContents objectForKey:CMRThreadTitleKey];
	if (!title) {
        if (dbErrFlagPtr != NULL) {
            *dbErrFlagPtr = NO;
        }
        return NO;
    }

	count = [[fileContents objectForKey:ThreadPlistContentsKey] count];
	
	rep = [fileContents objectForKey:CMRThreadUserStatusKey];
	s = [CMRThreadUserStatus objectWithPropertyListRepresentation:rep];
	isDatOchi = (s ? [s isDatOchiThread] : NO);
    labelCode = (s ? [s label] : 0);

	date = [fileContents objectForKey:CMRThreadModifiedDateKey];
	double interval = 0;
	if (date && [date isKindOfClass:[NSDate class]]) {
		interval = [date timeIntervalSince1970];
	}
	
	lastWrittenDate = lastWrittenDateOfBoardIDAndThreadIDInDatabase(boardID ,datNum, db);	
	
	numberOfAll = numberOfAllOfBoardIDAndThreadIDInDatabase(boardID ,datNum, db);
	numberOfAll = MAX(numberOfAll, count);
	
	SQLiteReservedQuery *rQuery = [db reservedQuery:rebuildQuery()];
	const char *format = F_NSNumberOfInt F_NSString F_NSString F_Int F_Int F_Double F_NSNumberOfDouble F_Int F_Int;
	[rQuery cursorWithFormat:format, boardID, datNum, title, numberOfAll, count, interval, lastWrittenDate, (NSInteger)isDatOchi, labelCode];
	if ([db lastErrorID] != 0) {
        if (dbErrFlagPtr != NULL) {
            *dbErrFlagPtr = YES;
        }
		return NO;
	}
	
	return YES;
}

- (BOOL)rebuildStatusInBoardID:(NSNumber *)boardID
{
	SQLiteDB *db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	NSString *query;
	
	// set ThreadLogCachedStatus if NumberOfReadColumn is not 0
	query = [NSString stringWithFormat:
			 @"UPDATE %@ SET %@ = %lu "
			 @"WHERE %@ = %@ AND %@ <> 0",
			 ThreadInfoTableName, ThreadStatusColumn, (unsigned long)ThreadLogCachedStatus,
			 BoardIDColumn, boardID, NumberOfReadColumn];
	[db performQuery:query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail to update. Reason: %@", [db lastError]);
		return NO;
	}
	
	// set ThreadUpdatedStatus if NumberOfAllColumn > NumberOfReadColumn
	query = [NSString stringWithFormat:
			 @"UPDATE %@ SET %@ = %lu "
			 @"WHERE %@ = %@ AND %@ > %@",
			 ThreadInfoTableName, ThreadStatusColumn, (unsigned long)ThreadUpdatedStatus,
			 BoardIDColumn, boardID, NumberOfAllColumn, NumberOfReadColumn];
	[db performQuery:query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail to update. Reason: %@", [db lastError]);
		return NO;
	}
	
	return YES;
}

- (BOOL)createRebuildTempTableForBoardID:(id)boardID
{
    // TEMP TABLE だと -rebuildFromLogFolder:boardID: 以外の場所からこのメソッドを呼んでテーブルを作った場合に
    // -rebuildFromFilePath:withBoardID: でアクセスできない。
    // どうせあとで DROP TABLE しているから普通の TABLE にしてやり過ごしてみる。
	NSString *query = [NSString stringWithFormat:
//					   @"CREATE TEMP TABLE %@ AS SELECT %@, %@, %@, %@ FROM %@ WHERE %@ = %@",
					   @"CREATE TABLE %@ AS SELECT %@, %@, %@ FROM %@ WHERE %@ = %@",
					   DMDA_TEMP_THREAD_INFO_TABLE,
					   /*NumberOfAllColumn,*/ LastWrittenDateColumn, BoardIDColumn, ThreadIDColumn,
					   ThreadInfoTableName,
					   BoardIDColumn, boardID];
	SQLiteDB *db = [self databaseForCurrentThread];
	[db performQuery:query];
	if([db lastErrorID] != SQLITE_OK) {
		NSLog(@"Fail create temp table(%@) Reason: %@", DMDA_TEMP_THREAD_INFO_TABLE, [db lastError]);
	}
	return [db lastErrorID] == SQLITE_OK;
}
- (BOOL)dropRebuildTempTable
{
	NSString *query = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", DMDA_TEMP_THREAD_INFO_TABLE];
	SQLiteDB *db = [self databaseForCurrentThread];
	[db performQuery:query];
	if([db lastErrorID] != SQLITE_OK) {
		NSLog(@"Fail drop temp table(%@) Reason: %@", DMDA_TEMP_THREAD_INFO_TABLE, [db lastError]);
	}
	return [db lastErrorID] == SQLITE_OK;
}

- (BOOL)rebuildFromLogFolder:(NSString *)folderPath boardID:(NSNumber *)boardID error:(NSError **)errorPtr
{
	SQLiteDB *db = [self databaseForCurrentThread];
	
	NSString *filePath;
	NSAutoreleasePool *pool = nil;
    BOOL success;
    NSMutableArray *invalidFiles = [NSMutableArray array];

	NSDate *date1 = [NSDate dateWithTimeIntervalSinceNow:0.0];
	
	if(db && [db beginTransaction]) {
        // deleteAllRecordsOfBoard: をここで呼び出してしまうと、この前で実行された
        // -[BSDBThreadsListDBUpdateTask2 run] で DB に投入した、最新のスレッド一覧データが
        // 一緒に吹っ飛んでしまう。これでは再構築終了後にログの存在するスレッドのデータしか残らない。
        // 以前のように -[BSDBThreadList rebuildThreadsList] に場所を戻してみる。
//		[self createRebuildTempTableForBoardID:boardID];
//		[self deleteAllRecordsOfBoard:[boardID unsignedIntegerValue]];
		
		for (NSString *fileName in [[NSFileManager defaultManager] enumeratorAtPath:folderPath]) {
			pool = [[NSAutoreleasePool alloc] init];
			if ([[fileName pathExtension] isEqualToString:@"thread"]) {
                BOOL isDBErr;
				filePath = [folderPath stringByAppendingPathComponent:fileName];
                success = [self rebuildFromFilePath:filePath withBoardID:boardID isDBError:&isDBErr];
				if (!success) {
                    if (isDBErr) {
                        goto abort;
                    } else {
                        [invalidFiles addObject:filePath];
                    }
				}
			}
			[pool release];
			pool = nil;
		}
		[self dropRebuildTempTable];
		[self rebuildStatusInBoardID:boardID];
		
		[db commitTransaction];
	}

    if ((errorPtr != NULL) && ([invalidFiles count] > 0)) {
        *errorPtr = fileContentsErrorObject(invalidFiles);
    }
	NSDate *date2 = [NSDate dateWithTimeIntervalSinceNow:0.0];
	NSLog(@"Work time is %.3f", [date2 timeIntervalSinceDate:date1]);
	
	return YES;
	
    abort:{
        NSLog(@"Fail insertOrUpdateFromLogFiles. ErrorID -> %ld. Reason: %@", (long)[db lastErrorID], [db lastError] );
        if (errorPtr != NULL) {
            *errorPtr = dbErrorObject([db lastErrorID], [db lastError]);
        }
        [db rollbackTransaction];
        [pool release];
        
        return NO;
    }
}


NSString *escapeQuotes(NSString *str)
{
	NSRange range = [str rangeOfString:@"'" options:NSLiteralSearch];
	if (range.location == NSNotFound) {
		return str;
	} else {
		NSMutableString *newStr = [str mutableCopy];
		[newStr replaceOccurrencesOfString:@"'" withString:@"''" options:NSLiteralSearch range:NSMakeRange(0, [newStr length])];
		return [newStr autorelease];
	}
}

- (BOOL)isRegisteredWithFavoritesTable:(NSString *)identifier atBoard:(NSUInteger)boardID
{
	SQLiteDB *db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %lu AND %@ = %@",
					   FavoritesTableName, BoardIDColumn, (unsigned long)boardID, ThreadIDColumn, identifier];
	id<SQLiteCursor> cursor;
	cursor = [db cursorForSQL:query];
	if (cursor && [cursor rowCount]) {
		return YES;
	}
	return NO;
}

- (BOOL)removeThreadOfIdentifier:(NSString *)identifier atBoard:(NSUInteger)boardID
{
	SQLiteDB *db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}

	if (![self isThreadIdentifierRegistered:identifier onBoardID:boardID numberOfAll:NULL]) {
        return NO;
    }
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = %lu AND %@ = %@",
        ThreadInfoTableName, BoardIDColumn, (unsigned long)boardID, ThreadIDColumn, identifier];
    [db cursorForSQL:sql];
    
    if ([db lastErrorID] != 0) {
        NSLog(@"Fail to remove. Reason: %@", [db lastError]);
        return NO;
    }
    NSNotification *notification = [NSNotification notificationWithName:DatabaseDidFinishUpdateDownloadedOrDeletedThreadInfoNotification object:self];
    [self performSelectorOnMainThread:@selector(makeThreadsListUpdateCursorWhenIdle:) withObject:notification waitUntilDone:NO];
    return YES;
}

- (BOOL)insertThreadOfIdentifier:(NSString *)identifier
						   title:(NSString *)title
						   count:(NSUInteger)count
						    date:(NSDate *)date
					   isDatOchi:(BOOL)flag
						 atBoard:(NSUInteger)boardID
{
	SQLiteDB *db = [self databaseForCurrentThread];
	if (!db) {
		return NO;
	}
	
	double interval = 0;
	if (date && [date isKindOfClass:[NSDate class]]) {
		interval = [date timeIntervalSince1970];
	}
	
	NSUInteger number = 0;
	ThreadStatus status = ThreadLogCachedStatus;
	NSMutableString *sql;
	
	if ([self isThreadIdentifierRegistered:identifier onBoardID:boardID numberOfAll:&number]) {
		if (number < count) {
			number = count;
		} else if (number > count) {
			status = ThreadUpdatedStatus;
		}
		
		sql = [NSMutableString stringWithFormat:@"UPDATE %@ ", ThreadInfoTableName];
		[sql appendFormat:@"SET %@ = %lu, %@ = %lu, %@ = %lu, %@ = %.0lf, %@ = %lu ",
		 NumberOfAllColumn, (unsigned long)number,
		 NumberOfReadColumn, (unsigned long)count,
		 ThreadStatusColumn, (unsigned long)status,
		 ModifiedDateColumn, interval,
		 IsDatOchiColumn, (flag ? 1UL : 0UL)];
		[sql appendFormat:@"WHERE %@ = %lu AND %@ = %@",
		 BoardIDColumn, (unsigned long)boardID, ThreadIDColumn, identifier];

		[db cursorForSQL:sql];

		if ([db lastErrorID] != 0) {
			NSLog(@"Fail to update. Reason: %@", [db lastError]);
			return NO;
		}

	} else {
		sql = [NSString stringWithFormat:@"INSERT INTO %@ ( %@, %@, %@, %@, %@, %@, %@, %@ ) VALUES ( %lu, %@, '%@', %lu, %lu, %.0lf, %lu, %lu)",
			   ThreadInfoTableName,
			   BoardIDColumn, ThreadIDColumn, ThreadNameColumn, NumberOfAllColumn, NumberOfReadColumn, ModifiedDateColumn, ThreadStatusColumn,
			   IsDatOchiColumn,
			   (unsigned long)boardID, identifier, escapeQuotes(title), (unsigned long)count, (unsigned long)count, interval, (unsigned long)status,
			   (flag ? 1UL : 0UL)];
		[db cursorForSQL:sql];
		
		if ([db lastErrorID] != 0) {
			NSLog(@"Fail Insert. ErrorID -> %ld. Reason: %@", (long)[db lastErrorID], [db lastError]);
			return NO;
		}
		
	}
	
	return YES;
}

- (void)makeThreadsListUpdateCursorWhenIdle:(NSNotification *)notification
{
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle];
}

- (BOOL)insertThreadOfAttributes:(CMRThreadAttributes *)attr shouldUpdateCursor:(BOOL)flag
{
    BOOL result;
    NSUInteger boardID;
    NSArray *boardIDs = [self boardIDsForName:[attr boardName]];
    if (!boardIDs || [boardIDs count] == 0) {
        return NO;
    }
	boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];

    result = [self insertThreadOfIdentifier:[[attr threadSignature] identifier]
                                      title:[attr threadTitle]
                                      count:[attr numberOfLoadedMessages]
                                       date:[attr modifiedDate]
                                  isDatOchi:YES
                                    atBoard:boardID];
    if (result && flag) {
        NSNotification *notification = [NSNotification notificationWithName:DatabaseDidFinishUpdateDownloadedOrDeletedThreadInfoNotification object:self];
        [self performSelectorOnMainThread:@selector(makeThreadsListUpdateCursorWhenIdle:) withObject:notification waitUntilDone:NO];
    }
    return result;
}

- (BOOL)recache
{
	[boardIDNumberCacheLock lock];
	[boardIDNameCache release];
	boardIDNameCache = [[NSMutableDictionary alloc] init];
	[boardIDNumberCacheLock unlock];
	
	return YES;
}

- (BOOL)deleteAllRecordsOfBoard:(NSUInteger)boardID
{
	SQLiteDB *db = [self databaseForCurrentThread];
	NSString *query = [NSString stringWithFormat:
		@"DELETE FROM %@ WHERE %@ = %lu", ThreadInfoTableName, BoardIDColumn, (unsigned long)boardID];
	if (!db) return NO;
	[db cursorForSQL:query];
	if ([db lastErrorID] != 0) {
		NSLog(@"Fail deleteAllRecordsOfBoard:%lu. Reason: %@ (ErrorID -> %ld)", (unsigned long)boardID, [db lastError], (long)[db lastErrorID]);
		return NO;
	}
	return YES;
}
@end
