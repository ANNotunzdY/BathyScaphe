//
//  BSThreadListUpdateTask.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/03/29.
//  Copyright 2006-2008,2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadListUpdateTask.h"
#import "BSDBThreadList.h"
#import "BoardListItem.h"
#import "BoardBoardListItem.h"
#import "DatabaseManager.h"
#import "AppDefaults.h"

NSString *BSThreadListUpdateTaskDidFinishNotification = @"BSThreadListUpdateTaskDidFinishNotification";

@interface BSThreadListUpdateTask()
// re-declare override Writability
@property (readwrite, copy) NSString *message;
@end

@implementation BSThreadListUpdateTask
// message property implementation in BSThreadListTask
@dynamic message;

+ (id)taskWithBSDBThreadList:(BSDBThreadList *)threadList
{
	return [[[[self class] alloc] initWithBSDBThreadList:threadList] autorelease];
}

- (id)initWithBSDBThreadList:(BSDBThreadList *)threadList
{
	if(self = [super init]) {
		target = threadList;
		userCanceled = NO;
		
		bbsName = [[[target boardListItem] representName] copy];
		self.message = [NSString stringWithFormat:
						NSLocalizedStringFromTable(@"Updating Thread(%@)", @"ThreadsList", @""),
						bbsName];
	}
	
	return self;
}

- (void)dealloc
{
	[cursor release];
	[bbsName release];
	
	[super dealloc];
}

- (NSString *)title
{
	return bbsName;
}

- (IBAction)cancel:(id)sender
{
	userCanceled = YES;
	target = nil;
	
	[super cancel:sender];
}

#pragma mark -
- (NSString *)sqlForList
{
	NSMutableString *sql;
	BoardListItem *boardItem = [target boardListItem];
	
	if ([BoardListItem isBoardItem:boardItem] && [CMRPref threadsListViewMode] == BSThreadsListShowsStoredLogFiles) {
		sql = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %lu AND %@ > 0",
				BoardThreadInfoViewName, BoardIDColumn, (unsigned long)[(BoardBoardListItem *)boardItem boardID], NumberOfReadColumn];
	} else {
		NSString *targetTable = [boardItem query];
		sql = [NSMutableString stringWithFormat: @"SELECT * FROM (%@) ",targetTable];
	}
	return sql;
}

- (id)cursor
{
	return cursor;
}

- (void)setCursor:(id)new
{
	id temp = cursor;
	cursor = [new retain];
	[temp release];
}

- (void)excute
{
	id <SQLiteMutableCursor> result = nil;
		
	SQLiteDB *db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	NSString *sql;
	
	UTILAssertNotNil(db);
	
	sql = [self sqlForList];
	if(userCanceled) goto final;
	result = [db cursorForSQL : sql];
	if ([db lastErrorID] != 0) {
		NSLog(@"sql error on BSThreadListUpdateTask.m (-doExecuteWithLayout.) \n\tReason : %@", [db lastError]);
		result = nil;
	}

final:
	[self setCursor:result];
	[self postTaskDidFinishNotification];
}
@end


@implementation BSThreadListUpdateTask(Notification)
- (void)postTaskDidFinishNotification
{
	NSNotificationCenter	*nc_;
		
	nc_ = [NSNotificationCenter defaultCenter];
	[nc_ postNotificationName:BSThreadListUpdateTaskDidFinishNotification object:self];
}
@end


@implementation NSString(BSThreadListUpdateTaskAddition)
- (NSComparisonResult)numericCompare:(NSString *)string
{
	return [self compare:string options:NSNumericSearch];
}
@end


@implementation NSNumber(BSThreadListUpdateTaskAddition)
- (NSComparisonResult)numericCompare:(id)obj
{
	return [self compare:obj];
}
@end


@implementation NSDate(BSThreadListUpdateTaskAddition)
- (NSComparisonResult)numericCompare:(id)obj
{
	return [self compare:obj];
}
@end
