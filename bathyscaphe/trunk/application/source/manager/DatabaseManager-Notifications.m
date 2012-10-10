//
//  DatabaseManager-Notifications.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 07/06/26.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "DatabaseManager.h"

#import "ThreadTextDownloader.h"
#import "CMRDocumentFileManager.h"
#import "CMRTrashbox.h"
#import "CMRReplyMessenger.h"
#import "AppDefaults.h"

NSString *const DatabaseDidFinishUpdateDownloadedOrDeletedThreadInfoNotification = @"DatabaseDidFinishUpdateDownloadedOrDeletedThreadInfoNotification";

NSString *const DatabaseWillUpdateThreadItemNotification = @"DatabaseWillUpdateThreadItemNotification";
NSString *const DatabaseWillDeleteThreadItemsNotification = @"DatabaseWillDeleteThreadItemsNotification";

NSString *const DatabaseDidUpdateThreadLabelNotification = @"DatabaseDidUpdateThreadLabelNotification";

NSString *const DatabaseWantsThreadItemsUpdateNotification = @"DatabaseWantsThreadItemsUpdateNotification";
NSString *const UserInfoBoardNameKey = @"BoardName";
NSString *const UserInfoThreadIDKey = @"Identifier";
NSString *const UserInfoThreadCountKey = @"Count";
NSString *const UserInfoThreadModDateKey = @"ModDate";
NSString *const UserInfoThreadPathsArrayKey = @"Files";
NSString *const UserInfoUpdateTypeKey = @"UpdateType";
NSString *const UserInfoIsDBInsertedKey = @"IsInsert";
NSString *const UserInfoThreadStatusKey = @"ThreadStatus";


@implementation DatabaseManager(Notifications)
-(void)registNotifications
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	[nc addObserver:self
		   selector:@selector(finishWriteMesssage:)
			   name:CMRReplyMessengerDidFinishPostingNotification
			 object:nil];
}

#pragma mark ## Notification (Moved From BSDBThreadList) ##
- (void)makeThreadsListsUpdateCursor
{
	NSNotification *notification = [NSNotification notificationWithName:DatabaseDidFinishUpdateDownloadedOrDeletedThreadInfoNotification object:self];
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
}

- (BOOL)searchBoardID:(NSInteger *)outBoardID threadID:(NSString **)outThreadID fromFilePath:(NSString *)inFilePath
{
	CMRDocumentFileManager *dfm = [CMRDocumentFileManager defaultManager];
	
	if (outThreadID) {
		*outThreadID = [dfm datIdentifierWithLogPath:inFilePath];
	}
	
	if (outBoardID) {
		NSArray *boardIDs;
        NSString *boardName;
		id boardID;
		
		boardName = [dfm boardNameWithLogPath:inFilePath];
		if (!boardName) {
            return NO;
		}
		boardIDs = [self boardIDsForName:boardName];
		if (!boardIDs || [boardIDs count] == 0) {
            return NO;
		}
		boardID = [boardIDs objectAtIndex:0];
		
        *outBoardID = [boardID integerValue];
	}
	
	return YES;
}

- (void)updateStatus:(ThreadStatus)status modifiedDate:(NSDate *)date forThreadSignature:(CMRThreadSignature *)signature
{
    NSString *identifier = [signature identifier];
    NSString *boardName = [signature boardName];
    
    NSArray *boardIDs = [self boardIDsForName:boardName];
    if (!boardIDs || [boardIDs count] == 0) {
        return;
    }
    NSUInteger boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];
    if (![self setThreadStatus:status modifiedDate:date atBoardID:boardID threadIdentifier:identifier]) {
        return;
    }

    NSNotification *notification = [NSNotification notificationWithName:DatabaseWillUpdateThreadItemNotification object:self];
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
    if ([CMRPref sortsImmediately]) {
        [self makeThreadsListsUpdateCursor];
    } else {
        NSDictionary *userInfo;
        if (date) {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  identifier, UserInfoThreadIDKey,
                                  [NSNumber numberWithUnsignedInteger:status], UserInfoThreadStatusKey,
                                  date, UserInfoThreadModDateKey,
                                  boardName, UserInfoBoardNameKey,
                                  NULL];
        } else {
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        identifier, UserInfoThreadIDKey,
                        [NSNumber numberWithUnsignedInteger:status], UserInfoThreadStatusKey,
                        boardName, UserInfoBoardNameKey,
                        NULL];
        }
        
        NSNotification *notification = [NSNotification notificationWithName:DatabaseWantsThreadItemsUpdateNotification object:self userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
    }
}

- (void)threadTextDownloader:(ThreadTextDownloader *)downloader didUpdateWithContents:(NSDictionary *)userInfo
{
	CMRThreadSignature	*signature;
	
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
	UTILAssertNotNil(userInfo);
	UTILAssertKindOfClass(userInfo, NSDictionary);

	signature = [downloader threadSignature];
	UTILAssertNotNil(signature);

	do {
		SQLiteDB *db;
		NSMutableString *sql;
		NSArray *boardIDs;
		
		NSDate *modDate = [userInfo objectForKey:@"ttd_date"];
        NSNumber *numCount = [userInfo objectForKey:@"ttd_count"];
		if (!modDate) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
                NSLog(@"** USER DEBUG ** Why? modDate is nil.");
            }
		} else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
                NSLog(@"** USER DEBUG ** OK. modDate is %@.", modDate);
            }
		}
		NSUInteger count = [numCount unsignedIntegerValue];
		
		NSInteger boardID = 0;
		NSString *threadID;
        NSString *boardName;
        NSTimeInterval intSince1970;
		
		db = [self databaseForCurrentThread];
		if (!db) break;

		threadID = [signature identifier];
        boardName = [signature boardName];
		
		boardIDs = [self boardIDsForName:boardName];
		if (!boardIDs || [boardIDs count] == 0) break;
		
		boardID = [[boardIDs objectAtIndex:0] integerValue];
        intSince1970 = [modDate timeIntervalSince1970];


		sql = [NSMutableString stringWithFormat:@"UPDATE %@ ", ThreadInfoTableName];
		[sql appendFormat:@"SET %@ = %lu, %@ = %lu, %@ = %lu, %@ = %.0lf ",
			NumberOfAllColumn, (unsigned long)count,
			NumberOfReadColumn, (unsigned long)count,
			ThreadStatusColumn, (unsigned long)ThreadLogCachedStatus,
			ModifiedDateColumn, intSince1970];
		[sql appendFormat:@"WHERE %@ = %lu AND %@ = %@",
			BoardIDColumn, (unsigned long)boardID, ThreadIDColumn, threadID];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** SQL: %@", sql);
        }
		[db cursorForSQL:sql];
		
		if ([db lastErrorID] != 0) {
			NSLog(@"Fail to update. Reason: %@", [db lastError] );
            if ([db lastErrorID] == SQLITE_BUSY) {
                // 少し待ってもう一度やり直してみる（ここで DB が update できないままなのは影響が大きいので）
                NSLog(@"Retry later...");
                [self performSelector:@selector(retryUpdate:) withObject:sql afterDelay:0.5];
            }
            break;
		}

        NSInteger updated = sqlite3_changes([db rowDatabase]);
        BOOL isInsert = (updated < 1);

        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** %ld row(s) updated.", (long)updated);
        }

        if (isInsert) {
            sql = [NSString stringWithFormat:@"INSERT INTO %@ ( %@, %@, %@, %@, %@, %@, %@, %@ ) VALUES ( %lu, %@, '%@', %lu, %lu, %.0lf, %lu, %lu)",
			   ThreadInfoTableName,
			   BoardIDColumn, ThreadIDColumn, ThreadNameColumn, NumberOfAllColumn, NumberOfReadColumn, ModifiedDateColumn, ThreadStatusColumn,
               IsDatOchiColumn,
			   (unsigned long)boardID, threadID, escapeQuotes([downloader threadTitle]), (unsigned long)count, (unsigned long)count, intSince1970, (unsigned long)ThreadLogCachedStatus,
               ([downloader useMaru] ? 1UL : 0UL)];
            [db cursorForSQL:sql];
		
            if ([db lastErrorID] != 0) {
                NSLog(@"Fail Insert. ErrorID -> %ld. Reason: %@", (long)[db lastErrorID], [db lastError]);
                break;
            }
        }

        NSNotification *notification = [NSNotification notificationWithName:DatabaseWillUpdateThreadItemNotification object:self];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
        if ([CMRPref sortsImmediately]) {
            [self makeThreadsListsUpdateCursor];
        } else {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                            threadID, UserInfoThreadIDKey,
                            numCount, UserInfoThreadCountKey,
                            modDate, UserInfoThreadModDateKey,
                            boardName, UserInfoBoardNameKey,
                            [NSNumber numberWithBool:isInsert], UserInfoIsDBInsertedKey,
                            NULL];

            NSNotification *notification = [NSNotification notificationWithName:DatabaseWantsThreadItemsUpdateNotification object:self userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
        }
	} while (NO);
}

// TODO 暫定
- (void)retryUpdate:(NSString *)sql
{
    SQLiteDB *db = [self databaseForCurrentThread];
    if (db) {
        [db cursorForSQL:sql];
		if ([db lastErrorID] != 0) {
			NSLog(@"Fail to retry update. Reason: %@", [db lastError]);
            return;
        }
        NSNotification *notification = [NSNotification notificationWithName:DatabaseWillUpdateThreadItemNotification object:self];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];

		[self makeThreadsListsUpdateCursor];
    }
}

- (void)cleanUpItemsWhichHasBeenRemoved:(NSArray *)files
{
	SQLiteDB *db = [self databaseForCurrentThread];
	NSString *query;
		
	if ([db beginTransaction]) {
		for (NSString *path in files) {
			NSInteger boardID = 0;
			NSString *threadID;
			
			if ([self searchBoardID:&boardID threadID:&threadID fromFilePath:path]) {
				query = [NSString stringWithFormat:
						 @"UPDATE %@\n"
						 @"SET %@ = NULL,\n"
						 @"%@ = NULL,\n"
						 @"%@ = %ld,\n"
						 @"%@ = 0,\n"
						 @"%@ = 0,\n"
						 @"%@ = 0\n"
						 @"WHERE %@ = %ld\n"
						 @"AND %@ = %@",
						 ThreadInfoTableName,
						 NumberOfReadColumn,
						 ModifiedDateColumn,
						 ThreadStatusColumn, (long)ThreadNoCacheStatus,
						 ThreadAboneTypeColumn,
						 ThreadLabelColumn,
						 IsDatOchiColumn,
						 BoardIDColumn, (long)boardID,
						 ThreadIDColumn, threadID];
				
				[db performQuery:query];
				if([db lastErrorID] != 0) goto abort;
				
				query = [NSMutableString stringWithFormat:
						 @"DELETE FROM %@"
						 @" WHERE %@ = %lu"
						 @" AND %@ = %@",
						 FavoritesTableName,
						 BoardIDColumn, (unsigned long)boardID,
						 ThreadIDColumn, threadID];
				[db performQuery : query];
				if([db lastErrorID] != 0) goto abort;
			}
			
		}
		[db commitTransaction];
	}

        NSNotification *notification = [NSNotification notificationWithName:DatabaseWillDeleteThreadItemsNotification object:self];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
    if ([CMRPref sortsImmediately]) {

        [self makeThreadsListsUpdateCursor];
	} else {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
            files, UserInfoThreadPathsArrayKey,
            NULL];

        NSNotification *notification = [NSNotification notificationWithName:DatabaseWantsThreadItemsUpdateNotification object:self userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:NO];
    }

	return;
	
abort:
	NSLog(@"FAIL delete threadInfo. Reason : %@", [db lastError]);
	[db rollbackTransaction];
}

- (void)finishWriteMesssage:(NSNotification *)aNotification
{
	id obj = [aNotification object];
	UTILAssertKindOfClass(obj, [CMRReplyMessenger class]);
	
	id boardName = [obj boardName];
	id threadID = [obj datIdentifier];
	id writeDate = [obj modifiedDate];
	
	id boardIDs = [self boardIDsForName:boardName];
	// TODO 二つ以上あった場合
	NSInteger boardID = [[boardIDs objectAtIndex:0] integerValue];
	
	[self setLastWriteDate:writeDate atBoardID:boardID threadIdentifier:threadID];
}

- (void)doVacuum
{
	UTILDebugWrite(@"START VACUUM");
	[[self databaseForCurrentThread] performQuery:@"VACUUM"];
	UTILDebugWrite(@"END VACUUM");
}
@end
