//
//  NSCharacterSet-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSCharacterSet-SGExtensions.h"


@implementation NSCharacterSet(SGExtentions)
+ (NSCharacterSet *)alphanumericPunctuationCharacterSet
{
	NSRange		lcEnglishRange;
	
	lcEnglishRange.location = (NSUInteger)' ';
	lcEnglishRange.length = ((NSUInteger)'~') - lcEnglishRange.location;
	
	return [NSCharacterSet characterSetWithRange:lcEnglishRange];
}

// as RFC 2396.
+ (NSCharacterSet *)URLCharacterSet
{
	static NSCharacterSet *charSet = nil;
	if (!charSet) {
		charSet = [[NSCharacterSet characterSetWithCharactersInString:
//					@"!$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~"] retain];
					@"!$&'()*+,-./0123456789:;=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~#%"] retain];
	}
	return charSet;
}

+ (NSCharacterSet *)extraspaceAndNewlineCharacterSet
{
	static NSCharacterSet *st_finalCharSet = nil;
	
	if (!st_finalCharSet) {
		NSMutableCharacterSet *workingSet;
		
		workingSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[workingSet addCharactersInRange:NSMakeRange(0x3000, 1)];
		st_finalCharSet = [workingSet copy];
		[workingSet release];
	}
	return st_finalCharSet;
}
@end
