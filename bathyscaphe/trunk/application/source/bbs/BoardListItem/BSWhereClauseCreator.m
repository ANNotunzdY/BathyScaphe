//
//  BSWhereClauseVisitor.m
//
//  Created by Hori,Masaki on 10/05/09.
// Copyright 2006-2010 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "BSWhereClauseCreator.h"


@interface NSObject(BSVisitor)
+ (id)visit:(id)acceptor;
@end
@interface NSPredicate(BSAcceptor)
- (id)accept:(id)visitor;
@end

@implementation NSObject(SQLSupport)
- (NSString *)sqlStatementPart
{
	return [self description];
}
@end
@implementation NSDate(SQLSupport)
- (NSString *)sqlStatementPart
{
	return [NSString stringWithFormat:@"%.0f", [self timeIntervalSince1970]];
}
@end

static NSString *whereClauseFromArray(NSArray *values, NSString *join)
{
	id array = [NSMutableArray array];
	for(id v in values) {
		[array addObject:[v sqlStatementPart]];
	}
	NSString *string = [array componentsJoinedByString:join];
	return [string sqlStatementPart];
}
static id parseExpression(id expression)
{
	id expressionValue = nil;
	
	switch([expression expressionType]) {
		case NSConstantValueExpressionType:
			expressionValue = [expression constantValue];
			NSString *notContainREGPrefix = @"(?:(?!.*";
			NSString *notContainREGSuffix = @").)*";
			if([expressionValue isKindOfClass:[NSString class]] &&
			   [expressionValue hasPrefix:notContainREGPrefix] &&
			   [expressionValue hasSuffix:notContainREGSuffix]) {
				NSScanner *scanner = [NSScanner scannerWithString:expressionValue];
				[scanner setScanLocation:[notContainREGPrefix length]];
				NSString *strings = nil;
				if([scanner scanUpToString:notContainREGSuffix intoString:&strings]) {
					expressionValue = strings;
				}
			}
			break;
		case NSKeyPathExpressionType:
			expressionValue = [expression keyPath];
			break;
		case NSFunctionExpressionType:
		{
			id obj = [[expression operand] constantValue];
			SEL selector = NSSelectorFromString([expression function]);
			NSArray *args = [expression arguments];
			id value = nil;
			{
				NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
				NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
				NSInteger i = 2;
				for(id arg in args) {
					id aValue = [arg constantValue];
					if(aValue && aValue != [NSNull null])
						[inv setArgument:&aValue atIndex:i];
					i++;
				}
				[inv setSelector:selector];
				[inv invokeWithTarget:obj];
				[inv getReturnValue:&value];
			}
			if(value) {
				if([value isKindOfClass:[NSArray class]]) {
					expressionValue = whereClauseFromArray(value, @" AND ");
				} else {
					expressionValue = value;
				}
			}
			break;
		}
		case NSAggregateExpressionType:
		{
			NSMutableArray *array = [NSMutableArray array];			
			for(id elem in [expression collection]) {
				[array addObject:[elem constantValue]];
			}
			expressionValue = whereClauseFromArray(array, @" AND ");
			break;
		}
		case NSEvaluatedObjectExpressionType:
		case NSVariableExpressionType:
			//
			break;
	}
	
	return expressionValue;
}
static id parseComparision(id predicate)
{
	NSInteger type = [predicate predicateOperatorType];
	NSString *op = nil;
	
	switch(type) {
		case NSLessThanPredicateOperatorType:
			op = @"%@ < %@";
			break;
		case NSLessThanOrEqualToPredicateOperatorType:
			op = @"%@ <= %@";
			break;
		case NSGreaterThanPredicateOperatorType:
			op = @"%@ > %@";
			break;
		case NSGreaterThanOrEqualToPredicateOperatorType:
			op = @"%@ >= %@";
			break;
		case NSEqualToPredicateOperatorType:
			op = @"%@ == '%@'";
			break;
		case NSNotEqualToPredicateOperatorType:
			op = @"%@ != '%@'";
			break;
		case NSLikePredicateOperatorType:
			op = @"%@ LIKE '%%@%%'";
			break;
		case NSBeginsWithPredicateOperatorType:
			op = @"%@ LIKE '%@%%'";
			break;
		case NSEndsWithPredicateOperatorType:
			op = @"%@ LIKE '%%%@'";
			break;
		case NSContainsPredicateOperatorType:
			op = @"%@ LIKE '%%%@%%'";
			break;
		case NSBetweenPredicateOperatorType:
			op = @"%@ BETWEEN %@";
			break;
		case NSMatchesPredicateOperatorType:
			op = @"NOT %@ LIKE '%%%@%%'";
			break;
		case NSCustomSelectorPredicateOperatorType:
		case NSInPredicateOperatorType:
		default:
			UTILUnknownCSwitchCaseNSInteger(type);
			return nil;
			break;
	}
	
//	NSString *left = [parseExpression([predicate leftExpression]) sqlStatementPart];
//	if([left isEqualToString:@"LastWrittenDate"]) {
//		NSString *right = [parseExpression([predicate rightExpression]) sqlStatementPart];
//		NSDate *date = [NSDate dateWithTimeIntervalSince1970:[right floatValue]];
//		NSLog(@"############## DEBUG WRITE ################");
//		NSLog(op, left, date);
//		NSLog(@"##############  END DEBUG  ################");
//	}
	
	NSString *where = [NSString stringWithFormat:op,
					   [parseExpression([predicate leftExpression]) sqlStatementPart],
					   [parseExpression([predicate rightExpression]) sqlStatementPart]];
	return where;
}


@implementation NSPredicate(BSAcceptor)
- (id)accept:(id)visitor
{
	return [visitor visit:self];
}
@end


@implementation BSWhereClauseCreator
+ (NSString *)whereClauseFromPredicate:(NSPredicate *)predicate
{
	NSString *result = [predicate accept:self];
	return result;
}
+ (id)visit:(id)acceptor
{
	NSString *className = NSStringFromClass([acceptor class]);
	NSString *selName = [NSString stringWithFormat:@"visit%@:", className];
	SEL selector = NSSelectorFromString(selName);
	return [self performSelector:selector withObject:acceptor];
}

+ (id)visitNSCompoundPredicate:(NSCompoundPredicate *)predicate
{
	NSString *join = nil;
	switch([predicate compoundPredicateType]) {
		case NSAndPredicateType:
			join = @" AND ";
			break;
		case NSOrPredicateType:
			join = @" OR ";
			break;
		default:
			UTILUnknownSwitchCase([predicate compoundPredicateType]);
			break;
	}
	if(!join) return nil;
	
	id subs = [NSMutableArray array];
	NSArray *sub = [predicate subpredicates];
	for(id p in sub) {
		[subs addObject:[NSString stringWithFormat:@"(%@)", [p accept:self]]];
	}
	
	return [subs componentsJoinedByString:join];
}
+ (id)visitNSComparisonPredicate:(NSComparisonPredicate *)predicate
{
	return parseComparision(predicate);
}
@end

