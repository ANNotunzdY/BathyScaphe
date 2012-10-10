//
//  SQLiteDB.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/12/12.
//  Copyright 2005 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "sqlite3.h"

@protocol SQLiteRow <NSObject>
- (NSUInteger) columnCount;
- (NSArray *) columnNames;
- (id) valueForColumn : (NSString *) column;
@end

@protocol SQLiteCursor <NSObject>
- (NSUInteger) columnCount;
- (NSArray *) columnNames;

- (NSUInteger) rowCount;
- (id) valueForColumn : (NSString *) column atRow : (NSUInteger) row;
- (NSArray *) valuesForColumn : (NSString *) column;
- (id <SQLiteRow>) rowAtIndex : (NSUInteger) row;
- (NSArray *) arrayForTableView;
@end

@protocol SQLiteMutableCursor <SQLiteCursor>
- (BOOL) appendRow : (id <SQLiteRow>) row;
- (BOOL) appendCursor : (id <SQLiteCursor>) cursor;
@end

@class SQLiteReservedQuery;

@interface SQLiteDB : NSObject
{
	NSString *mPath;
	sqlite3 *mDatabase;
	
	BOOL _isOpen;
	BOOL _transaction;
	
	NSMutableDictionary *reservedQueries;
}

#ifdef USE_NSZONE_MALLOC
+ (NSZone *)allocateZone;
#endif

- (id) initWithDatabasePath : (NSString *) path;

+ (NSString *) prepareStringForQuery : (NSString *) inString;

- (void) setDatabaseFile : (NSString *) path;
- (NSString *) databasePath;

- (sqlite3 *) rowDatabase;

- (BOOL) open;
- (NSInteger) close;
- (BOOL) isDatabaseOpen;

- (NSString *) lastError;
- (NSInteger) lastErrorID;

- (id <SQLiteMutableCursor>) cursorForSQL : (NSString *) sqlString;
- (id <SQLiteMutableCursor>) performQuery : (NSString *) sqlString; // alias cursorForSQL. for compatible QuickLite.

- (SQLiteReservedQuery *) reservedQuery : (NSString *) sqlString;

@end

@interface SQLiteDB (DatabaseAccessor)

- (NSArray *) tables;

- (BOOL) beginTransaction;
- (BOOL) commitTransaction;
- (BOOL) rollbackTransaction;

- (BOOL) save; // do nothing. for compatible QuickLite.

- (BOOL) createTable : (NSString *) table withColumns : (NSArray *) columns andDatatypes : (NSArray *) datatypes;
- (BOOL) createTable : (NSString *) table
			 columns : (NSArray *) columns
		   datatypes : (NSArray *) datatypes
	   defaultValues : (NSArray *)defaultValues
	 checkConstrains : (NSArray *)checkConstrains;
- (BOOL) createTemporaryTable : (NSString *) table withColumns : (NSArray *) columns andDatatypes : (NSArray *) datatypes;
- (BOOL) createTemporaryTable : (NSString *) table
					  columns : (NSArray *) columns
					datatypes : (NSArray *) datatypes
				defaultValues : (NSArray *)defaultValues
			  checkConstrains : (NSArray *)checkConstrains;


- (BOOL) createIndexForColumn : (NSString *) column inTable : (NSString *) table isUnique : (BOOL) isUnique;


- (BOOL) deleteIndexForColumn:(NSString *)column inTable:(NSString *)table;

@end

@interface SQLiteDB (ResercedQuerySupport)
- (SQLiteReservedQuery *)reservedQueryWithKey:(NSString *)key;
- (void)setReservedQuery:(SQLiteReservedQuery *)query forKey:(NSString *)key;
@end

@interface SQLiteReservedQuery : NSObject
{
	sqlite3_stmt *m_stmt;
}
+ (id) sqliteReservedQueryWithQuery : (NSString *) sqlString usingSQLiteDB : (SQLiteDB *) db;
- (id) initWithQuery : (NSString *) sqlString usingSQLiteDB : (SQLiteDB *) db;

- (id <SQLiteMutableCursor>) cursorForBindValues : (NSArray *) values;

#define F_NSString "s"
#define F_Int	"i"
#define F_Double	"d"
#define F_Null	"n"
#define F_NSNumberOfInt	"j"
#define F_NSNumberOfDouble	"e"

- (id <SQLiteMutableCursor>)cursorWithFormat:(const char *)format, ...;
@end


extern NSString *QLString; // alias TEXT. for compatible QuickLite.
extern NSString *QLNumber; // alias NUMERIC. for compatible QuickLite.
extern NSString *QLDateTime; // alias TEXT. for compatible QuickLite. NOTE : 

extern NSString *INTERGER_PRIMARY_KEY;
extern NSString *TEXT_NOTNULL;
extern NSString *TEXT_UNIQUE;
extern NSString *TEXT_NOTNULL_UNIQUE;
extern NSString *INTEGER_NOTNULL;
extern NSString *INTERGER_UNIQUE;
extern NSString *INTERGER_NOTNULL_UNIQUE;
extern NSString *NUMERIC_NOTNULL;
extern NSString *NUMERIC_UNIQUE;
extern NSString *NUMERIC_NOTNULL_UNIQUE;
extern NSString *NONE_NOTNULL;
extern NSString *NONE_UNIQUE;
extern NSString *NONE_NOTNULL_UNIQUE;
