//
//  BSSExpParser.m
//  BSSpotlighter
//
//  Created by Hori,Masaki on 06/05/16.
//  Copyright 2006-2008 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSSExpParser.h"

static BSSExpParser *sharedInstance = nil;

@implementation BSSExpParser

+ (id)sharedInstance
{
	@synchronized(self) {
		if(!sharedInstance) {
			sharedInstance = [[self alloc] init];
		}
	}
	
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self) {
		if(!sharedInstance) {
			return [super allocWithZone:zone];
		}
	}
	
	return sharedInstance;
}
- (id)copyWithZone:(NSZone *)zone
{
	return self;
}
- (id)retain{ return self; }
- (oneway void)release {}
- (NSUInteger)retainCount { return NSUIntegerMax; }
- (id)autorelease { return self; }
- (id)init
{
	if(sharedInstance) {
		[super init];
		[self release];
		return sharedInstance;
	}
	
	if(self = [super init]) {
		sharedInstance = self;
	}
	
	return self;
}

- (NSCharacterSet *)openParenthesisSet
{
	static id result = nil;

	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '(', (unichar)0xFF08];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}

	return result;
}
- (NSCharacterSet *)closeParenthesisSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", ')', (unichar)0xFF09];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
- (NSCharacterSet *)orSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '|', (unichar)0xFF5C];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
- (NSCharacterSet *)andSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '&', (unichar)0xFF06];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
- (NSCharacterSet *)notSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '!', (unichar)0xFF01];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}

+ (NSPredicate *)predicateForString:(NSString *)string forKey:(NSString *)key
{
	return [self predicateForTokens:[BSSTokenizer tokenizerWithString:string] forKey:key];
}
+ (NSPredicate *)predicateForTokens:(BSSTokenizer *)token forKey:(NSString *)key
{
	return [[self sharedInstance] predicateForTokens:token forKey:key];
}

- (NSPredicate *)predicateForTokens:(BSSTokenizer *)token forKey:(NSString *)key
{
	NSString *predicateString = [self predicateStringForTokens:token forKey:key];
	if(!predicateString || [predicateString length] == 0) return nil;
	
	return [NSPredicate predicateWithFormat:predicateString];
}

- (NSString *)predicateStringForTokens:(BSSTokenizer *)token forKey:(NSString *)key
{
	NSMutableString *result = [NSMutableString string];
	
	NSCharacterSet *openParenthesisSet = [self openParenthesisSet];
	NSCharacterSet *closeParenthesisSet = [self closeParenthesisSet];
	NSCharacterSet *orSet = [self orSet];
	NSCharacterSet *andSet = [self andSet];
	NSCharacterSet *notSet = [self notSet];
	
	BOOL isFirst = YES;
	NSString *andOrStr = @"";
	NSString *notStr = @"";
	
	NSString *str;
	
	while((str = [token nextToken])) {
		if([openParenthesisSet characterIsMember:[str characterAtIndex:0]]) {
			NSString *subPredicate;
			NSString *s;
			BOOL foundClose = NO;
			NSUInteger start, end;
			
			[token saveTokenIndex];
			start = [token currentIndex];
			while((s = [token nextToken])) {
				if([closeParenthesisSet characterIsMember:[s characterAtIndex:0]]) {
					NSRange range;
					foundClose = YES;
					end = [token currentIndex];
					range = NSMakeRange(start, end - start - 1);
					BSSTokenizer *sub = [token tokenizerWithRange:range];
					subPredicate = [self predicateStringForTokens:sub forKey:key];
					
					break;
				}
			}
			if(foundClose) {
				[result appendFormat:@"%@%@(%@)", andOrStr, notStr, subPredicate];
//				[token rewind];
				isFirst = NO;
			} else {
				[token restoreTokenIndex];
				continue;
			}
			
		} else if([orSet characterIsMember:[str characterAtIndex:0]]) {
			andOrStr = isFirst ? @"" : @" || ";
			continue;
		} else if([andSet characterIsMember:[str characterAtIndex:0]]) {
			//
			continue;
		} else if([notSet characterIsMember:[str characterAtIndex:0]]) {
			notStr = @" NOT ";
			continue;
		} else {
			[result appendFormat:@"%@%@(%@ CONTAINS[cd] '%@')", andOrStr, notStr, key, str];
			isFirst = NO;
		}
		
		andOrStr = isFirst ? @"" : @" && ";
		notStr = @"";
	}
	
	return result;
}

@end

@implementation BSSTokenizer

+ (id)tokenizerWithString:(NSString *)string
{
	return [[[[self class] alloc] initWithString:string] autorelease];
}

- (id)initWithString:(NSString *)string
{
	if(self = [super init]) {
		mTokens = [[[self class] tokensFromString:string] retain];
		mCurrentIndex = mSavedIndex = 0;
	}
	
	return self;
}

- (id)initWithTokens:(NSArray *)array
{
	if(self = [super init]) {
		mTokens = [NSArray arrayWithArray:array];
		mCurrentIndex = mSavedIndex = 0;
	}
	
	return self;
}

- (NSString *)currentToken
{
	if(mCurrentIndex == NSUIntegerMax) return nil;
	if([mTokens count] <= mCurrentIndex) return nil;
	return [mTokens objectAtIndex:mCurrentIndex];
}
// return nil, if not have next token.
- (NSString *)nextToken
{
	id res = [self currentToken];
	
	mCurrentIndex++;
	
	return res;
}
- (BOOL)hasNextToken
{
	return [self count] <= mCurrentIndex + 1 ? NO : YES;
}

- (NSUInteger)count
{
	return [mTokens count];
}
- (NSUInteger)currentIndex
{
	return mCurrentIndex;
}

- (BSSTokenizer *)tokenizerWithRange:(NSRange)range
{
	NSArray *tokens = [mTokens subarrayWithRange:range];
	
	return [[[[self class] allocWithZone:[self zone]] initWithTokens:tokens] autorelease];
}

- (void)saveTokenIndex
{
	mSavedIndex = mCurrentIndex;
}
- (void)restoreTokenIndex
{
	mCurrentIndex = mSavedIndex;
}
- (void)rewind
{
	mCurrentIndex--;
}

+ (NSCharacterSet *)tokenCharacterSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *path;
				NSString *chars;
				
				path = [[NSBundle bundleForClass:[self class]] pathForResource:@"tokenCharacter"
																		ofType:@"txt"];
				chars = [NSString stringWithContentsOfFile:path
												  encoding:NSUTF8StringEncoding
													 error:NULL];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
	
}
+ (NSCharacterSet *)escapeSet
{
	static id result = nil;
	
	if(!result) {
		@synchronized(self) {
			if(!result) {
				NSString *chars = [NSString stringWithFormat:@"%c%C", '\\', (unichar)0xFF3C];
				
				result = [[NSMutableCharacterSet alloc] init];
				[result addCharactersInString:chars];
			}
		}
	}
	
	return result;
}
+ (NSArray *)tokensFromString:(NSString *)string
{
	NSMutableArray *result = [NSMutableArray array];
	
	NSCharacterSet *tokenCharacterSet = [self tokenCharacterSet];
	NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSCharacterSet *escapeCharacterSet = [self escapeSet];
	BOOL wasEscaped = NO;
	NSUInteger idx, mark, length;
	unichar uchar;
	
	length = [string length];
	for(idx = mark = 0; idx < length; idx++) {
		NSString *substr;
		
		uchar = [string characterAtIndex:idx];
		if([escapeCharacterSet characterIsMember:uchar]) {
			wasEscaped = YES;
			if(idx < length - 1) {
				idx++;
				uchar = [string characterAtIndex:idx];
			}
		}
		if(!wasEscaped && [tokenCharacterSet characterIsMember:uchar]) {
			if(mark != idx) {
				substr = [string substringWithRange:NSMakeRange(mark, idx - mark)];
				[result addObject:substr];
				mark = idx;
			}
			substr = [string substringWithRange:NSMakeRange(mark, idx - mark + 1)];
			[result addObject:substr];
			mark = idx + 1;
			continue;
		}
		if(!wasEscaped && [whitespaceCharacterSet characterIsMember:uchar]) {
			if(mark != idx) {
				substr = [string substringWithRange:NSMakeRange(mark, idx - mark)];
				[result addObject:substr];
			}
			mark = idx + 1;
			continue;
		}
		if(idx == length - 1) {
			substr = [string substringWithRange:NSMakeRange(mark, idx - mark + 1)];
			[result addObject:substr];
			//mark = idx + 1;
			//continue;
		}
		wasEscaped = NO;
	}
	
	return [NSArray arrayWithArray:result];
}

@end
