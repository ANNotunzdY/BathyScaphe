//
//  SmartBoardListItem.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//

#import "SmartBoardListItem.h"

#import "DatabaseManager.h"
#import "SmartCondition.h"
#import "SmartConditionTranslator.h"
#import "BSWhereClauseCreator.h"


#import <SGAppKit/NSImage-SGExtensions.h>

@interface SmartBoardListItem(Private)
- (void)setCondition:(id)condition;
- (void)updateQuery;
@end

@implementation SmartBoardListItem
- (id) initWithName : (NSString *) inName condition : (id) condition
{
	if (self = [super init]) {
		if(!inName || !condition) {
			[self release];
			return nil;
		}
		[self setName : inName];
		[self setCondition:condition];
		[self updateQuery];
	}
	
	return self;
}

- (BOOL)isEqual:(id) other
{
	if(self == other) return YES;
	
	if([self class] != [other class]) return NO;
	if(![[self name] isEqualTo:[other name]]) return NO;
	if(![[self query] isEqualTo:[other query]]) return NO;
	
	return YES;
}
- (NSImage *) icon
{
	return [NSImage imageAppNamed:[self iconBaseName]];
}

- (NSString *)iconBaseName
{
    return @"SmartBoardItem";
}

- (NSString *)query
{
	[self updateQuery];
	
	return [super query];
}
- (void)updateQuery
{
	NSString *query;
	
	query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@",
		BoardThreadInfoViewName, [BSWhereClauseCreator whereClauseFromPredicate:mConditions]];
	
	[self setQuery:query];
}

- (id) condition
{
	return mConditions;
}
- (void) setCondition:(id)condition
{
	if(![condition isKindOfClass:[NSPredicate class]]) {
		condition = [SmartConditionTranslator predicateFromSmartCondition:condition];
	}
	id tmp = mConditions;
	mConditions = [condition retain];
	[tmp release];
	
	[self updateQuery];
	
	[self postUpdateThreadsNotification];
}

#pragma mark## CMRPropertyListCoding protocol ##
static NSString *SmartConditionNameKey = @"Name";
static NSString *SmartConditionConditionKey = @"SmartConditionConditionKey";
static NSString *SmartConditionPredicateKey = @"Predicate";

- (id) propertyListRepresentation
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[self name], SmartConditionNameKey,
		[NSKeyedArchiver archivedDataWithRootObject:mConditions], SmartConditionPredicateKey,
		nil];
}
- (id) initWithPropertyListRepresentation : (id) rep
{
	id v;
	id name, cond = nil;
	
	name = [rep objectForKey:SmartConditionNameKey];
	
	v = [rep objectForKey:SmartConditionPredicateKey];
	if(v) {
		cond = [NSKeyedUnarchiver unarchiveObjectWithData:v];
	} else {
		v = [rep objectForKey:SmartConditionConditionKey];
		cond = [NSKeyedUnarchiver unarchiveObjectWithData:v];
	}	
	return [self initWithName:name condition:cond];
}

- (id)plist
{
	return [self propertyListRepresentation];
}
- (id) description
{
	return [[self plist] description];
}

- (BOOL) isHistoryEqual : (id) anObject
{
	if (![super isHistoryEqual : anObject]) return NO;

	if ([[anObject query] isEqualToString: [self query]]) return YES;
	
	return NO;
}
@end

