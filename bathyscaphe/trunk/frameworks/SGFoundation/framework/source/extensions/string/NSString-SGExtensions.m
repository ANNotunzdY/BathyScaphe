//
//  NSString-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/23.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/NSString-SGExtensions.h>
#import <SGFoundation/String+Utils.h>
#import <SGFoundation/NSMutableString-SGExtensions.h>
#import <SGFoundation/NSCharacterSet-SGExtensions.h>
#import "UTILKit.h"


@implementation NSString(SGExtensions)
+ (id)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding
{
	return [[[self alloc] initWithData:data encoding:encoding] autorelease];
}

+ (id)stringWithCharacter:(unichar)aCharacter
{
	return [[[self alloc] initWithCharacter:aCharacter] autorelease];
}

- (id)initWithCharacter:(unichar)aCharacter
{
	return [self initWithCharacters:&aCharacter length:1];
}

- (NSString *)stringByDeletingURLScheme:(NSString *)aScheme
{
	NSScanner *scanner_;
	NSString  *context_;
	
	if ([self isEmpty] || !aScheme || [aScheme isEmpty]) {
		return self;
	}
	scanner_ = [NSScanner scannerWithString:self];
	[scanner_ setCaseSensitive:NO];
	if (![scanner_ scanString:aScheme intoString:NULL]) {
		return nil;
	}
	//@":"とそれにつづく空白をスキップし、アドレスを読み込む
	if(![scanner_ scanString:@":" intoString:NULL]) {
		return nil;
	}
	[scanner_ scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
	context_ = [[scanner_ string] substringFromIndex:[scanner_ scanLocation]];
	
	return [context_ stringByStripedAtEnd];
}

- (BOOL)containsString:(NSString *)aString
{
	return ([self rangeOfString:aString].length != 0);
}

- (NSRange)rangeOfCharacterSequenceFromSet:(NSCharacterSet *)aSet options:(NSUInteger)mask range:(NSRange)aRange
{
	NSRange		result_;
	NSUInteger	maxRange_;
	BOOL		backward_;
	
	result_ = [self rangeOfCharacterFromSet:aSet options:mask range:aRange];
	if (NSNotFound == result_.location || 0 == result_.length) {
		return result_;
	}
	maxRange_ = NSMaxRange(aRange);
	backward_ = (mask & NSBackwardsSearch);
	
	while (1) {
		NSUInteger	index_;

		index_ = backward_ ? result_.location : NSMaxRange(result_);
		if (backward_) {
			if (0 == index_ || aRange.location == index_) {
				break;
            }
			index_--;
		} else {
			if (index_ >= maxRange_) {
				break;
            }
		}
		if (![aSet characterIsMember:[self characterAtIndex:index_]]) {
			break;
		}
		if (backward_) {
			result_.location--;
		}
		result_.length++;
	}
	return result_;
}

- (NSArray *)componentsSeparatedByCharacterSequenceFromSet:(NSCharacterSet *)aCharacterSet
{
	NSMutableArray		*components_;
	NSRange				result_;
	NSRange				searchRange_;
	NSUInteger			srcLength_;
	
	components_ = [NSMutableArray array];
	if (!aCharacterSet) {
		[components_ addObject:self];
		return components_;
	}
	srcLength_ = [self length];
	searchRange_ = [self range];
	while ((result_ = [self rangeOfCharacterSequenceFromSet:aCharacterSet options:0 range:searchRange_]).length != 0) {
		NSRange subrange_ = searchRange_;
		subrange_.length = result_.location - subrange_.location;
		[components_ addObject:[self substringWithRange:subrange_]];
		searchRange_.location = NSMaxRange(result_);
		searchRange_.length = (srcLength_ - searchRange_.location);
	}
	
	if (srcLength_ == searchRange_.length) {
		[components_ addObject:self];
	} else if (0 == searchRange_.length) {
		[components_ addObject:@""];
	} else {
		[components_ addObject:[self substringWithRange:searchRange_]];
	}
	return components_;
}

- (NSArray *)componentsSeparatedByNewline
{
	NSMutableArray *lines;				// 行毎に詰めていく配列
	NSRange         lineRng;			// 行の範囲
	NSUInteger    startIndex;			// 最初の文字のインデックス
	NSUInteger    lineEndIndex;		// 次の行（段落）の最初の文字のインデックス
	NSUInteger    contentsEndIndex;	// 最初の改行文字のインデックス
	NSUInteger    len;				// 文字列の長さ

	lines = [NSMutableArray array];
	len = [self length];
	lineRng = NSMakeRange(0, 0);
	// 行毎に範囲を求め、切り出した文字列を
	// 配列に詰めていく。
	do {
		[self getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex forRange:lineRng];

		lineRng.location = startIndex;
		lineRng.length = (contentsEndIndex - startIndex);
		
		// 文字列を行単位で切り出し、配列の末尾へ
		[lines addObject:[self substringWithRange:lineRng]];

		// 調べる範囲を次の行の先頭へ持っていく。
		lineRng.location = lineEndIndex;
		lineRng.length = 0;
	} while (lineRng.location < len);
	
	if (len > 0) {
		unichar c;
        c = [self characterAtIndex:len -1];
		if ('\n' == c ||'\r' == c) {
			[lines addObject:@""];
        }
	}
	return lines;
}

- (NSString *)stringByReplaceEntityReference
{
	NSMutableString *mstr_;
	if (![self containsString:@"&"]) {
        return self;
	}
	mstr_ = [self mutableCopyWithZone:[self zone]];
	[mstr_ replaceEntityReference];
	return [mstr_ autorelease];
}

- (NSString *)stringByReplaceCharacters:(NSString *)chars toString:(NSString *)replacement
{
	return [self stringByReplaceCharacters:chars toString:replacement options:NSLiteralSearch];
}

- (NSString *)stringByReplaceCharacters:(NSString *)chars toString:(NSString *)replacement options:(NSUInteger)options
{
	return [self stringByReplaceCharacters:chars toString:replacement options:options range:NSMakeRange(0, [self length])];
}

- (NSString *)stringByReplaceCharacters:(NSString *)chars toString:(NSString *)replacement options:(NSUInteger)options range:(NSRange )aRange
{
	NSMutableString *mstr_;

	if (![self containsString:chars]) {
        return self;
    }
	mstr_ = [self mutableCopyWithZone:[self zone]];
	[mstr_ replaceCharacters:chars toString:replacement options:options range:aRange];
	return [mstr_ autorelease];
}

- (NSString *)stringByStriped
{
	NSMutableString *mstr_;

	mstr_ = [self mutableCopyWithZone:[self zone]];
	[mstr_ strip];
	return [mstr_ autorelease];
}

- (NSString *)stringByStripedAtStart
{
	NSMutableString *mstr_;

	mstr_ = [self mutableCopyWithZone:[self zone]];
	[mstr_ stripAtStart];
	return [mstr_ autorelease];
}

- (NSString *)stringByStripedAtEnd
{
	NSMutableString *mstr_;

	mstr_ = [self mutableCopyWithZone:[self zone]];
	[mstr_ stripAtEnd];
	return [mstr_ autorelease];
}

- (BOOL)isSameAsString:(NSString *)other
{
	return (NSOrderedSame == [self compare:other]);
}

- (NSArray *)componentsSeparatedByTextBreak
{
    NSMutableArray  *array_ = [NSMutableArray array];
    NSUInteger length_ = [self length];
    NSUInteger i = 0;
    NSRange aRange;

    while (i < length_) {
        aRange = [self rangeOfComposedCharacterSequenceAtIndex:i];

        [array_ addObject:[self substringWithRange:aRange]];
        i = NSMaxRange(aRange);
    }

	NSAssert([array_ count], @"***ERROR*** can't locate Unicode Text Break");
    
    return array_;
}
@end
