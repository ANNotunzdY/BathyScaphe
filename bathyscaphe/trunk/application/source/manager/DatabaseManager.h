//
//  DatabaseManager.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

#import <SQLiteDB.h>

@class ThreadTextDownloader;
@class CMRThreadAttributes;
@class CMRThreadSignature;

@interface DatabaseManager : NSObject
+ (id)defaultManager;

+ (void)setupDatabase;

- (NSString *)databasePath;

- (SQLiteDB *)databaseForCurrentThread;

@end


@interface DatabaseManager(DatabaseAccess)
// return NSNotFound, if not registered.
- (NSUInteger)boardIDForURLString:(NSString *)urlString;
- (NSUInteger)boardIDForURLStringExceptingHistory:(NSString *)urlString; // Do not search BoardInfoHistoryTable.

// return nil, if not registered.
- (NSString *)urlStringForBoardID:(NSUInteger)boardID;
// return nil, if not registered.
- (NSArray *)boardIDsForName:(NSString *)name;
// return nil, if not registered.
- (NSString *)nameForBoardID:(NSUInteger)boardID;

// raise DatabaseManagerCantFountKeyExseption.
- (id)valueForKey:(NSString *)key boardID:(NSUInteger)boardID threadID:(NSString *)threadID;
// - (void)setValue:(id)value forKey:(NSString *)key boardID:(NSUInteger)boardID threadID:(NSString *)threadID;

- (BOOL)registerBoardName:(NSString *)name URLString:(NSString *)urlString;
// Currently not available.
// - (BOOL)registerBoardNamesAndURLs:(NSArray *)array;

- (BOOL)moveBoardID:(NSUInteger)boardID toURLString:(NSString *)urlString;
- (BOOL)renameBoardID:(NSUInteger)boardID toName:(NSString *)name;

// Currently not available.
// - (BOOL)registerThreadName:(NSString *)name threadIdentifier:(NSString *)identifier intoBoardID:(NSUInteger)boardID;
// - (BOOL)registerThreadNamesAndThreadIdentifiers:(NSArray *)array intoBoardID:(NSUInteger)boardID;

// Added by tsawada2.
- (BOOL)isThreadIdentifierRegistered:(NSString *)identifier onBoardID:(NSUInteger)boardID;
- (BOOL)isThreadIdentifierRegistered:(NSString *)identifier onBoardID:(NSUInteger)boardID numberOfAll:(NSUInteger *)number;

- (BOOL)isFavoriteThreadIdentifier:(NSString *)identifier onBoardID:(NSUInteger)boardID;
- (BOOL)appendFavoriteThreadIdentifier:(NSString *)identifier onBoardID:(NSUInteger)boardID;
- (BOOL)removeFavoriteThreadIdentifier:(NSString *)identifier onBoardID:(NSUInteger)boardID;

- (BOOL)registerThreadFromFilePath:(NSString *)filepath;
- (BOOL)registerThreadFromFilePath:(NSString *)filepath needsDisplay:(BOOL)flag; // Available in Tenori Tiger.
- (BOOL)rebuildFromLogFolder:(NSString *)path boardID:(NSNumber *)boardID error:(NSError **)errorPtr;

- (NSString *)threadTitleFromBoardName:(NSString *)boadName threadIdentifier:(NSString *)identifier;

- (void)setLastWriteDate:(NSDate *)writeDate atBoardID:(NSUInteger)boardID threadIdentifier:(NSString *)threadID;
// Available in BathyScaphe 2.0.
- (BOOL)setThreadStatus:(ThreadStatus)status modifiedDate:(NSDate *)date atBoardID:(NSUInteger)boardID threadIdentifier:(NSString *)identifier;
- (void)setLabel:(NSUInteger)code
	   boardName:(NSString *)boardName
threadIdentifier:(NSString *)identifier;
// Available in Tenori Tiger.
- (BOOL)insertThreadOfIdentifier:(NSString *)identifier
						   title:(NSString *)title
						   count:(NSUInteger)count
						    date:(NSDate *)date
					   isDatOchi:(BOOL)flag
						 atBoard:(NSUInteger)boardID;

// Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
- (BOOL)insertThreadOfAttributes:(CMRThreadAttributes *)attr shouldUpdateCursor:(BOOL)flag;
// Available in BathyScaphe 1.7 "Prima Aspalas" and later. For debugging use.
- (BOOL)removeThreadOfIdentifier:(NSString *)identifier atBoard:(NSUInteger)boardID;

- (BOOL)createRebuildTempTableForBoardID:(id)boardID;
- (BOOL)deleteAllRecordsOfBoard:(NSUInteger)boardID; // Available in Tenori Tiger.
// キャッシュを放棄
- (BOOL)recache;
@end


@interface DatabaseManager(CreateTable)
- (BOOL)createFavoritesTable;
- (BOOL)createBoardInfoTable;
- (BOOL)createThreadInfoTable;
- (BOOL)createBoardInfoHistoryTable;
// - (BOOL)createResponseTable;

- (BOOL)createTempThreadNumberTable;
- (BOOL)createVersionTable;

// - (BOOL)createFavThraedInfoView;

- (BOOL)createBoardThreadInfoView;
@end


@interface DatabaseManager(Notifications)
- (void)makeThreadsListsUpdateCursor;
- (void)updateStatus:(ThreadStatus)status modifiedDate:(NSDate *)date forThreadSignature:(CMRThreadSignature *)signature;
- (void)threadTextDownloader:(ThreadTextDownloader *)downloader didUpdateWithContents:(NSDictionary *)userInfo;
- (void)cleanUpItemsWhichHasBeenRemoved:(NSArray *)files;
- (void)doVacuum;
@end

// スレッド一覧テーブルカラムのIDからデータベース上のテーブル名を取得。
NSString *tableNameForKey(NSString *key);
extern NSString *escapeQuotes(NSString *str);


extern NSString *BoardInfoTableName;
extern		NSString *BoardIDColumn;
extern		NSString *BoardURLColumn;
extern		NSString *BoardNameColumn;
extern NSString *ThreadInfoTableName;
// extern		NSString *BoardIDColumn; same as BoardIDColumn in BoardInfoTableName.
extern		NSString *ThreadIDColumn;
extern		NSString *ThreadNameColumn;
extern		NSString *NumberOfAllColumn;
extern		NSString *NumberOfReadColumn;
extern		NSString *ModifiedDateColumn;
extern		NSString *ThreadStatusColumn;
extern		NSString *ThreadAboneTypeColumn;
extern		NSString *ThreadLabelColumn;
extern		NSString *LastWrittenDateColumn;
extern		NSString *IsDatOchiColumn;
// extern		NSString *IsFavoriteColumn;	// this column is no longer used.
extern NSString *FavoritesTableName;
// extern		NSString *BoardIDColumn;
// extern		NSString *ThreadIDColumn;
extern NSString *BoardInfoHistoryTableName;
// extern		NSString *BoardIDColumn;
// extern		NSString *BoardNameColumn;
// extern		NSString *BoardURLColumn;

extern	NSString *VersionTableName;
extern		NSString *VersionColumn;

extern NSString *TempThreadNumberTableName;
// extern		NSString *BoardIDColumn;
// extern		NSString *ThreadIDColumn;
extern		NSString *TempThreadThreadNumberColumn;

// extern NSString *FavThreadInfoViewName;
extern NSString *BoardThreadInfoViewName;
extern		NSString *NumberOfDifferenceColumn;
extern		NSString *IsCachedColumn;
extern		NSString *IsUpdatedColumn;
extern		NSString *IsNewColumn;
extern		NSString *IsHeadModifiedColumn;

extern NSString *FavoritesViewName;

// Added by tsawada2 (2008-02-19)
extern NSString *const DatabaseDidFinishUpdateDownloadedOrDeletedThreadInfoNotification;

extern NSString *const DatabaseWillUpdateThreadItemNotification;
extern NSString *const DatabaseWillDeleteThreadItemsNotification;

extern NSString *const DatabaseDidUpdateThreadLabelNotification; // Available in BathyScaphe 2.0 "Final Moratorium" and later.

extern NSString *const DatabaseWantsThreadItemsUpdateNotification; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.
extern     NSString *const UserInfoBoardNameKey;
extern     NSString *const UserInfoThreadIDKey;
extern     NSString *const UserInfoThreadCountKey;
extern     NSString *const UserInfoThreadModDateKey;
extern     NSString *const UserInfoThreadPathsArrayKey;
extern     NSString *const UserInfoUpdateTypeKey;
extern     NSString *const UserInfoIsDBInsertedKey;
extern     NSString *const UserInfoThreadStatusKey;

// Added by tsawada2 (2011-01-24)
enum {
    DatabaseManagerRebuildLogFileContentsError = 2501,
    DatabaseManagerRebuildLogFileDBError = 2502,
};

extern NSString *const DatabaseManagerInvalidFilePathsArrayKey;
