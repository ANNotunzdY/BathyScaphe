//
//  DatabaseUpdater.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 07/02/03.
//  Copyright 2007 BathyScaphe Project. All rights reserved.
//

#import "DatabaseUpdater.h"

@interface DatabaseUpdater(ForSubclasses)
- (BOOL)useProgressPanel;

- (void)setInformationText:(NSString *)information;
@end

/*
 *	Version 0: 初期データベース
 *	Version 1: Version Table を導入
 *	Version 2: BoardInfoHistory 上のインデックスを修正
 *	Version 3: Version Table を廃止。 ThreadInfo Table に IsDatOchi カラムを追加
 *	Version 4: Favorites Table を廃止。 ThreadInfo Table に IsFavorite カラムを追加
 *	Version 5: BoardThreadInfoView を変更。 isCached, isUpdated, isNew, isHeadModified カラムを追加
 *	Version 6: This is mine!
 *	Version 7: ThreadInfo Table の ThreadLabelColumn と ThreadAboneTypeColumn に NOT NULL 制約を追加 
 */

@interface DatabaseUpdaterOneToTow : DatabaseUpdater
@end
@interface DatabaseUpdaterToThree : DatabaseUpdater
@end
@interface DatabaseUpdaterToFour : DatabaseUpdater
@end
@interface DatabaseUpdaterToFive : DatabaseUpdater
@end
@interface DatabaseUpdaterToSeven : DatabaseUpdater
@end


@implementation DatabaseUpdater

- (id)init
{
	[super init];
	
	if([self useProgressPanel]) {
		[NSBundle loadNibNamed:@"DatabaseUpdatePanel" owner:self];
		
		[self setInformationText:@""];
		
		NSRect mainScreenFrame = [[NSScreen mainScreen] visibleFrame];
		NSPoint center = NSMakePoint(NSMidX(mainScreenFrame), NSMidY(mainScreenFrame));
		
		NSRect windowFrame = [window frame];
		NSPoint origin = NSMakePoint(center.x - windowFrame.size.width / 2, center.y - windowFrame.size.height / 2 + 100);
		[window setFrameOrigin:origin];
		
		[window makeKeyAndOrderFront:nil];
		[progress setUsesThreadedAnimation:YES];
		[progress startAnimation:nil];
	}
	
	return self;
}
- (void)dealloc
{
	[progress stopAnimation:nil];
	[window close];
	
	[super dealloc];
}

- (BOOL)backupDatabase
{
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	NSString *databasePath = [db databasePath];
	if(!databasePath) {
		NSLog(@"Could not open database");
		return NO;
	}
	
	NSString *backupPath = databasePath;
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL exist = YES;
	do {
		backupPath = [backupPath stringByAppendingString:@"~"];
		exist = [fm fileExistsAtPath:backupPath];
	} while(exist);
	
//	if(![fm copyPath:databasePath toPath:backupPath handler:nil]) {
    if (![fm copyItemAtPath:databasePath toPath:backupPath error:NULL]) {
		NSLog(@"Could not backup database");
		return NO;
	}
	
	return YES;
}

+ (BOOL)updateFrom:(NSInteger)fromVersion to:(NSInteger)toVersion
{
	BOOL result = YES;
	
	if(fromVersion < 0) return YES;
	
	if(fromVersion < 2 && toVersion >= 2) {
		result = [[[[DatabaseUpdaterOneToTow alloc] init] autorelease] updateDB];
	}
	if(!result) return result;
	
	if(fromVersion < 3 && toVersion >= 3) {
		result = [[[[DatabaseUpdaterToThree alloc] init] autorelease] updateDB];
	}
	if(!result) return result;
	
	if(fromVersion < 4 && toVersion >= 4) {
		result = [[[[DatabaseUpdaterToFour alloc] init] autorelease] updateDB];
	}
	if(!result) return result;
	
	if(fromVersion < 5 && toVersion >= 5) {
		result = [[[[DatabaseUpdaterToFive alloc] init] autorelease] updateDB];
	}
	if(!result) return result;
	
	if(fromVersion < 7 && toVersion >= 7) {
		result = [[[[DatabaseUpdaterToSeven alloc] init] autorelease] updateDB];
	}
	if(!result) return result;
	
	return result;
}

- (BOOL)updateVersion:(NSInteger)newVersion usingDB:(SQLiteDB *)db
{
	if (!db) return NO;
	
	[db performQuery : [NSString stringWithFormat: @"PRAGMA user_version = %ld;",
		(long)newVersion]];
	if([db lastErrorID] != noErr) return NO;
	
	return YES;
}

- (void)setInformationText:(NSString *)anInformation
{
	information.stringValue = anInformation;
	[information display];
}
+ (NSString *)localizableStringsTableName
{
	return @"DatabaseUpdater";
}
	
@end


/*	
 *	Version 0 -> 2
 *	Version 1 -> 2
 *	
 *	BoardInfoHistoryTableName 上の BoardIDColumn のインデックスが UNIQUE インデックスになっていたのを
 *	通常のインデックスに変更
 */
@implementation DatabaseUpdaterOneToTow
- (BOOL) updateDB
{
	BOOL isOK = NO;
	
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	if (!db) return NO;
	
	if ([db beginTransaction]) {
		isOK = [db deleteIndexForColumn : BoardIDColumn inTable : BoardInfoHistoryTableName];
		if (!isOK) goto abort;
		
		isOK = [db createIndexForColumn : BoardIDColumn
								inTable : BoardInfoHistoryTableName
							   isUnique : NO];
		if (!isOK) goto abort;
		
		if(![self updateVersion : 2 usingDB : db]) goto abort;
		
		[db commitTransaction];
		[db save];
	}
	
	return isOK;
	
abort:
	NSLog(@"Fail Database operation. Reason: \n%@", [db lastError]);
	[db rollbackTransaction];
	return NO;
}
@end

/*
 *	Version 2 -> 3
 *	
 *	ThreadInfo Table に IsDatOchiColumn カラムを追加
 */
@implementation DatabaseUpdaterToThree
- (BOOL) updateDB
{
	BOOL isOK = NO;
	
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	if (!db) return NO;
	
	if ([db beginTransaction]) {
		id query = [NSString stringWithFormat: @"ALTER TABLE %@ ADD COLUMN %@ %@ DEFAULT 0 CHECK(%@ IN (0,1))",
			ThreadInfoTableName, IsDatOchiColumn, INTEGER_NOTNULL, IsDatOchiColumn];
		[db cursorForSQL : query];
		if ([db lastErrorID] != 0) goto abort;
		
		if(![self updateVersion : 3 usingDB : db]) goto abort;
		
		[db commitTransaction];
		[db save];
	}
	
	return isOK;
	
abort:
		NSLog(@"Fail Database operation. Reason: \n%@", [db lastError]);
	[db rollbackTransaction];
	return NO;
}
@end

/*
 *	Version 3 -> 4
 *	
 *	ThreadInfo Table に IsFavoriteColumn カラムを追加
 */
@implementation DatabaseUpdaterToFour

- (BOOL) updateDB
{
	return YES;
}
@end

/*
 *	Version 4 -> 5
 *	
 *	BoardThreadInfoView を変更。 isCached, isUpdated, isNew, isHeadModified カラムを追加
 */
@implementation DatabaseUpdaterToFive
- (BOOL) updateDB
{
	BOOL isOK = NO;
	
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	if (!db) return NO;
	
	if ([db beginTransaction]) {
		id query = [NSString stringWithFormat: @"DROP VIEW %@;", BoardThreadInfoViewName];
		[db cursorForSQL : query];
		if ([db lastErrorID] != 0) goto abort;
		
		query = [NSMutableString stringWithFormat: @"CREATE VIEW %@ AS\n", BoardThreadInfoViewName];
		[query appendFormat: @"\tSELECT *, (%@ - %@) AS %@\n",
		 NumberOfAllColumn, NumberOfReadColumn, NumberOfDifferenceColumn];
		[query appendFormat: @", NOT(%@ - %ld) AS %@\n",
		 ThreadStatusColumn, (long)ThreadLogCachedStatus, IsCachedColumn];
		[query appendFormat: @", NOT(%@ - %ld) AS %@\n",
		 ThreadStatusColumn, (long)ThreadUpdatedStatus, IsUpdatedColumn];
		[query appendFormat: @", NOT(%@ - %ld) AS %@\n",
		 ThreadStatusColumn, (long)ThreadNewCreatedStatus, IsNewColumn];
		[query appendFormat: @", NOT(%@ - %ld) AS %@\n",
		 ThreadStatusColumn, (long)ThreadHeadModifiedStatus, IsHeadModifiedColumn];
		[query appendFormat: @"FROM %@ INNER JOIN %@ USING(%@) ",
		 ThreadInfoTableName, BoardInfoTableName, BoardIDColumn];
		
		[db cursorForSQL : query];
		if ([db lastErrorID] != 0) goto abort;
		
		
		if(![self updateVersion : 5 usingDB : db]) goto abort;
		
		[db commitTransaction];
		[db save];
	}
	
	return isOK;
	
abort:
	NSLog(@"Fail Database operation. Reason: \n%@", [db lastError]);
	[db rollbackTransaction];
	return NO;
}
@end


/*
 *	Version 5 -> 7
 *	
 *	BoardThreadInfoView を変更。 isCached, isUpdated, isNew, isHeadModified カラムを追加
 */
@implementation DatabaseUpdaterToSeven
- (BOOL)useProgressPanel
{
	return YES;
}
- (BOOL) updateDB
{
	BOOL isOK = NO;
	
	[self backupDatabase];
	[self setInformationText:[self localizedString:@"prepare database"]];
		
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	if (!db) return NO;
	
	if ([db beginTransaction]) {
		NSString *tempTable = @"temporaryTable";
		
		// create table copy on memory
		id query = [NSString stringWithFormat: @"CREATE TEMP TABLE %@ AS SELECT * FROM %@",
					tempTable, ThreadInfoTableName];
		[db cursorForSQL: query];
		if ([db lastErrorID] != 0) goto abort;
		
		// drop original
		[db cursorForSQL:@"DROP TABLE ThreadInfo"];
		if ([db lastErrorID] != 0) goto abort;
		
		query = [NSString stringWithFormat:
				 @"CREATE TABLE %@"
				 "(%@ INTEGER NOT NULL ,"
				 "%@ INTEGER NOT NULL , "
				 "%@ TEXT NOT NULL , "
				 "%@ NUMERIC, "
				 "%@ NUMERIC , "
				 "%@ NUMERIC , "
				 "%@ NUMERIC , "
				 "%@ NUMERIC , "
				 "%@ INTEGER NOT NULL DEFAULT 0 CHECK(%@ >= 0), "
				 "%@ INTEGER NOT NULL DEFAULT 0 CHECK(%@ >= 0), "
				 "%@ INTEGER NOT NULL DEFAULT 0 CHECK(%@ IN (0,1)))"
				 ,
				 ThreadInfoTableName,
				 BoardIDColumn,
				 ThreadIDColumn,
				 ThreadNameColumn,
				 NumberOfAllColumn,
				 NumberOfReadColumn,
				 ModifiedDateColumn,
				 LastWrittenDateColumn,
				 ThreadStatusColumn,
				 ThreadAboneTypeColumn, ThreadAboneTypeColumn,
				 ThreadLabelColumn, ThreadLabelColumn,
				 IsDatOchiColumn, IsDatOchiColumn];
		[db cursorForSQL: query];
		if ([db lastErrorID] != 0) goto abort;
		
		// create indexes
		query = [NSString stringWithFormat:
				 @"CREATE INDEX ThreadInfo_boardID_IDX ON %@ (%@)",
				 ThreadInfoTableName, BoardIDColumn];
		[db cursorForSQL: query];
		if ([db lastErrorID] != 0) goto abort;
		
		query = [NSString stringWithFormat:
				 @"CREATE UNIQUE INDEX ThreadInfo_boardID_threadID_IDX ON %@ (%@,%@)",
				 ThreadInfoTableName, BoardIDColumn, ThreadIDColumn];
		[db cursorForSQL: query];
		if ([db lastErrorID] != 0) goto abort;
		
		query = [NSString stringWithFormat:
				 @"CREATE INDEX ThreadInfo_threadID_IDX ON %@ (%@)",
				 ThreadInfoTableName, ThreadIDColumn];
		[db cursorForSQL: query];
		if ([db lastErrorID] != 0) goto abort;
		
		
		// register original data
		[self setInformationText:[self localizedString:@"register to new database"]];
		id <SQLiteMutableCursor> result;
		
		query = [NSString stringWithFormat:@"SELECT count(*) AS c FROM %@", tempTable];
		result = [db cursorForSQL:query];
		if ([db lastErrorID] != 0) goto abort;
		[progress setMaxValue:[[result valueForColumn:@"c" atRow:0] integerValue]];
		progress.doubleValue = 0;
		[progress setIndeterminate:NO];
		
		query = [NSString stringWithFormat:
				 @"SELECT * FROM %@", tempTable];
		result = [db cursorForSQL: query];
		if ([db lastErrorID] != 0) goto abort;
		
		query = [[[NSString alloc] initWithFormat:
				 @"INSERT INTO %@"
				 "(%@, %@, %@, "
				 "%@, %@, "
				 "%@, %@, "
				 "%@, %@,  "
				 "%@, %@) "
				 "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
				 ,
				 ThreadInfoTableName,
				 BoardIDColumn, ThreadIDColumn, ThreadNameColumn,
				 NumberOfAllColumn, NumberOfReadColumn,
				 ModifiedDateColumn, LastWrittenDateColumn,
				 ThreadStatusColumn, ThreadAboneTypeColumn,
				 ThreadLabelColumn, IsDatOchiColumn] autorelease];
		SQLiteReservedQuery *rQuery = [db reservedQuery:query];
		
		id aNull = [NSNull null];
		NSUInteger i, count;
		for(i = 0, count = [result rowCount]; i < count; i++) {
			id <SQLiteRow> row = [result rowAtIndex:i];
			
			[rQuery cursorWithFormat:"jjsjjjjjjjj",
			 [row valueForColumn:BoardIDColumn],
			 [row valueForColumn:ThreadIDColumn],
			 [row valueForColumn:ThreadNameColumn],
			 [row valueForColumn:NumberOfAllColumn],
			 [row valueForColumn:NumberOfReadColumn],
			 [row valueForColumn:ModifiedDateColumn],
			 [row valueForColumn:LastWrittenDateColumn],
			 [row valueForColumn:ThreadStatusColumn],
			 [row valueForColumn:ThreadAboneTypeColumn] == aNull ? [NSNumber numberWithInt:0] : [row valueForColumn:ThreadAboneTypeColumn],
			 [row valueForColumn:ThreadLabelColumn] == aNull ? [NSNumber numberWithInt:0] : [row valueForColumn:ThreadLabelColumn],
			 [row valueForColumn:IsDatOchiColumn]
			 ];
			
			[NSApp nextEventMatchingMask:NSAnyEventMask
							   untilDate:[NSDate dateWithTimeIntervalSinceNow:0.000001]
								  inMode:NSDefaultRunLoopMode
								 dequeue:NO];
			progress.doubleValue += 1;
		}
		
		// drop temporary table
		query = [NSString stringWithFormat: @"DROP TABLE %@", tempTable];
		[db cursorForSQL: query];
		if ([db lastErrorID] != 0) goto abort;
		
		if(![self updateVersion: 7 usingDB: db]) goto abort;
		
		[db commitTransaction];
		[db save];
	}
	
	// vacuum
	[self setInformationText:[self localizedString:@"finalize database"]];
	[progress setIndeterminate:YES];
	[progress startAnimation:nil];
	[db cursorForSQL:@"VACUUM"];
	if ([db lastErrorID] != 0) goto abort;
		
	return isOK;
	
abort:
	NSLog(@"Fail Database operation. Reason: \n%@", [db lastError]);
	[db rollbackTransaction];
	
	return NO;
}
@end
