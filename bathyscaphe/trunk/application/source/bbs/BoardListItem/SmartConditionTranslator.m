//
//  SmartConditionTranslator.m
//
//  Created by Hori,Masaki on 10/04/18.
// Copyright 2006-2010 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "SmartConditionTranslator.h"
#import "SmartCondition.h"
#import "XspfMRule.h"
#import "XspfMRule_private.h"


@interface NSObject(BSVisitor)
- (id)visit:(id)acceptor;
@end
@interface SmartCondition(BSAcceptor)
- (id)accept:(id)visitor;
@end
@interface SmartConditionComposit(BSAcceptor)
- (id)accept:(id)visitor;
@end

@implementation SmartCondition(BSAcceptor)
- (id)accept:(id)visitor
{
	return [visitor visit:self];
}
@end
@implementation SmartConditionComposit(BSAcceptor)
- (id)accept:(id)visitor
{
	return [visitor visit:self];
}
@end

@implementation SmartConditionTranslator

+ (id)predicateFromSmartCondition:(SmartCondition *)condition
{
	return [condition accept:self];
}
+ (id)visit:(id)acceptor
{
	NSString *className = NSStringFromClass([acceptor class]);
	NSString *selName = [NSString stringWithFormat:@"visit%@:", className];
	SEL selector = NSSelectorFromString(selName);
	return [self performSelector:selector withObject:acceptor];
}
static NSString *formatComparision(SmartCondition *condition)
{
	NSInteger type = [condition operator];
	NSString *op = nil;
	
	switch(type) {
		case SCSmallerOperator:
		case SCDaysSmallerOperator:
		case SCDateSmallerOperator:
			op = @"%K < %@";
			break;
		case SCLargerOperator:
		case SCDaysLargerOperator:
		case SCDateLargerOperator:
			op = @"%K > %@";
			break;
		case SCExactOperator:
		case SCEqualOperator:
		case SCDateEqualOperator:
		case SCDaysEqualOperator:
			op = @"%K = %@";
			break;
		case SCNotExactOperator:
		case SCNotEqualOperator:
		case SCDaysNotEqualOperator:
		case SCDateNotEqualOperator:
			op = @"%K != %@";
			break;
		case SCContaionsOperator:
			op = @"%K CONTAINS[cd] %@";
			break;
		case SCNotContainsOperator:
			op = @"%K MATCHES[cd] %@";
			break;
		case SCBeginsWithOperator:
			op = @"%K BEGINSWITH %@";
			break;
		case SCEndsWithOperator:
			op = @"%K ENDSWITH %@";
			break;
		default:
			//
			break;
	}
	
	return op;
}
inline static NSString *SCTrightValue(SmartCondition *condition)
{
	if([condition operator] == SCNotContainsOperator) {
		return [NSString stringWithFormat:@"(?:(?!.*%@).)*", [condition value]];
	}
	return [condition value];
}
+ (id)visitSmartCondition01:(SmartCondition *)condition
{
	return [NSPredicate predicateWithFormat:formatComparision(condition), [condition key], SCTrightValue(condition)];
}
+ (id)visitStringCondition:(StringCondition *)condition
{
	id result = [self visitSmartCondition01:condition];
	return result;
}
+ (id)visitNumberCondition:(NumberCondition *)condition
{
	if([condition operator] != SCRangeOperator) {
		return [self visitSmartCondition01:condition];
	}
	
	NSArray *args = [NSArray arrayWithObjects:
					 [NSExpression expressionForConstantValue:[condition value]],
					 [NSExpression expressionForConstantValue:[condition value2]],
					 nil];
	NSExpression *argsEx = [NSExpression expressionForAggregate:args];
	return [NSPredicate predicateWithFormat:@"%K BETWEEN %@", [condition key], argsEx];
}
+ (id)visitDaysCondition:(DaysCondition *)condition
{
	SCOperator op = [condition operator];
	
	NSString *selName = nil;
	switch(op) {
		case SCDaysTodayOperator:
			selName = @"rangeOfToday";
			break;
		case SCDaysYesterdayOperator:
			selName = @"rangeOfYesterday";
			break;
		case SCDaysThisWeekOperator:
			selName = @"rangeOfThisWeek";
			break;
		case SCDaysLastWeekOperator:
			selName = @"rangeOfLastWeek";
			break;
		default:
			//
			break;
	}
	if(!selName) return nil;
	
	NSExpression *lhs = [NSExpression expressionForKeyPath:[condition key]];
	NSExpression *target = [NSExpression expressionForConstantValue:[XspfMRule functionHost]];
	NSExpression *rhs = [NSExpression expressionForFunction:target selectorName:selName arguments:nil];
	
	id result = [NSComparisonPredicate predicateWithLeftExpression:lhs 
												   rightExpression:rhs 
														  modifier:NSDirectPredicateModifier 
															  type:NSBetweenPredicateOperatorType
														   options:0];
	return result;
}

static BOOL numberAndUnitFromValue(NSNumber **number, NSInteger *unit, NSNumber *value)
{
	NSInteger diff = [value integerValue];
	if(diff % (60 * 60 * 24 * 30) == 0) {
		*unit = XspfMMonthsUnitType;
		*number = [NSNumber numberWithInteger:-diff / (60 * 60 * 24 * 30)];
	} else if(diff % (60 * 60 * 24 * 7) == 0) {
		*unit = XpsfMWeeksUnitType;
		*number = [NSNumber numberWithInteger:-diff / (60 * 60 * 24 * 7)];
	} else if(diff % (60 * 60 * 24) == 0) {
		*unit = XspfMDaysUnitType;
		*number = [NSNumber numberWithInteger:-diff / (60 * 60 * 24)];
	} else if(diff % (60 * 60) == 0) {
		*unit = XspfMHoursUnitType;
		*number = [NSNumber numberWithInteger:-diff / (60 * 60)];
	} else {
		NSLog(@"Could not convert time unit.");
		return NO;
	}
	
	return YES;
}
+ (id)visitRelativeDateLiveCondition:(RelativeDateLiveCondition *)condition
{
	NSNumber *number;
	NSInteger unit;
	NSString *selName = nil;
	NSInteger type = -1;
	if(!numberAndUnitFromValue(&number, &unit, [condition value])) {
		return nil;
	}
	NSArray *args;
	NSInteger operator = [condition operator];
	if(operator != SCDaysRangeOperator) {
		args = [NSArray arrayWithObjects:[NSExpression expressionForConstantValue:number],
				[NSExpression expressionForConstantValue:[NSNumber numberWithInteger:unit]],
				nil];
		if(operator == SCDaysEqualOperator) {
			selName = @"dateRangeByNumber:unit:";
			type = NSEqualToPredicateOperatorType;
		} else {
			selName = @"dateByNumber:unit:";
			switch(operator) {
				case SCDaysNotEqualOperator:
					type = NSNotEqualToPredicateOperatorType;
					break;
				case SCDaysLargerOperator:
					type = NSGreaterThanOrEqualToPredicateOperatorType;
					break;
				case SCDaysSmallerOperator:
					type = NSLessThanPredicateOperatorType;
					break;
			}
		}
	} else {
		id number01 = [NSExpression expressionForConstantValue:number];
		NSInteger unit02;
		
		if(!numberAndUnitFromValue(&number, &unit02, [condition value2])) {
			return nil;
		}
		if(unit != unit02) {
			NSLog(@"Could not convert time unit.");
			return nil;
		}
		args = [NSArray arrayWithObjects:number01,
				[NSExpression expressionForConstantValue:number],
				[NSExpression expressionForConstantValue:[NSNumber numberWithInteger:unit]],
				nil];
		selName = @"rangeDateByNumber:toNumber:unit:";
		type = NSBetweenPredicateOperatorType;
	}
	NSExpression *lhs = [NSExpression expressionForKeyPath:[condition key]];
	NSExpression *target = [NSExpression expressionForConstantValue:[XspfMRule functionHost]];
	NSExpression *rhs = [NSExpression expressionForFunction:target
									selectorName:selName
									   arguments:args];
	
	id result = [NSComparisonPredicate predicateWithLeftExpression:lhs 
												   rightExpression:rhs 
														  modifier:NSDirectPredicateModifier 
															  type:type
														   options:0];
	return result;
	
}
+ (id)visitAbsoluteDateLiveCondition:(AbsoluteDateLiveCondition *)condition
{
	NSDate *value01 = [NSDate dateWithTimeIntervalSince1970:[[condition value] doubleValue]];
	
	if([condition operator] != SCDateRangeOperator) {
		return [NSPredicate predicateWithFormat:formatComparision(condition), [condition key], value01];
	}
	
	NSDate *value02 = [NSDate dateWithTimeIntervalSince1970:[[condition value2] doubleValue]];
	NSArray *array = [NSArray arrayWithObjects:
					  [NSExpression expressionForConstantValue:value01],
					  [NSExpression expressionForConstantValue:value02], nil];
	NSExpression *aggre = [NSExpression expressionForAggregate:array];
	return [NSPredicate predicateWithFormat:@"%K BETWEEN %@", [condition key], aggre];
}
//+ (id)visitIncludeDatOtiCondition:(IncludeDatOtiCondition *)condition;
//+ (id)visitExcludeAdThreadCondition:(ExcludeAdThreadCondition *)condition;
+ (id)visitSmartConditionComposit:(SmartConditionComposit *)condition
{
	NSMutableArray *sub = [NSMutableArray array];
	for(id obj in [condition conditions]) {
		id predicate = [obj accept:self];
		if(!predicate) {
			NSLog(@"Fail parse");
		} else {
			[sub addObject:predicate];
		}
	}
	
	SCCOperator op = [condition operator];
	if(op == SCCUnionOperator) {
		return [NSCompoundPredicate andPredicateWithSubpredicates:sub];
	}
	if(op == SCCIntersectionOperator) {
		return [NSCompoundPredicate orPredicateWithSubpredicates:sub];
	}
	
	NSLog(@"Fail parse so unnkown SmartConditionComposit operator.");
	return nil;
}
@end
