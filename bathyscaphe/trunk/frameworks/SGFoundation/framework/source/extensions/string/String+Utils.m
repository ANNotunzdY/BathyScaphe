//
//  String+Utils.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/15.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/String+Utils.h>
#import <SGFoundation/NSString-SGExtensions.h>
#import <SGFoundation/NSMutableString-SGExtensions.h>
#import <SGFoundation/NSCharacterSet-SGExtensions.h>
//#import <SGFoundation/SGURLEscape.h>
#import "UTILKit.h"



@implementation NSObject(SGStringUtils)
- (NSString *)stringValue
{
	return [self description];
}
@end


@implementation NSString(SGStringUtils)
+ (NSString *)yenmark
{
	static NSString *yen = nil;
	if (!yen) {
		yen = [[NSString alloc] initWithCharacter:0xa5];
	}
	return yen;
}

+ (NSString *)backslash
{
	return @"\\";
}

- (BOOL)isEmpty
{
	return (0 == [self length]);
}

- (NSRange)range
{
	return NSMakeRange(0, [self length]);
}

- (NSString *)stringValue
{
	return self;
}

- (NSUInteger)unsignedIntegerValue
{
	NSInteger		tmp;
	
	tmp = [self integerValue];
	if (tmp < 0) {
		return 0;
	}
	return (NSUInteger)tmp;
}
@end


@implementation NSAttributedString(SGStringUtils)
- (BOOL)isEmpty
{
	return (0 == [self length]);
}

- (NSRange)range
{
	return NSMakeRange(0, [self length]);
}

- (NSString *)stringValue
{
	return [self string];
}
@end


@implementation NSString(SGNetEncoding)
- (NSString *)stringByURLEncodingUsingEncoding:(NSStringEncoding)encoding
{
    return [self stringByURIEncodedUsingCFEncoding:NS2CFEncoding(encoding) convertToCharRefIfNeeded:YES unableToEncode:NULL];
}

- (NSString *)stringByURLEncodingUsingEncoding:(NSStringEncoding)encoding convertToCharRefIfNeeded:(BOOL)flag unableToEncode:(NSIndexSet **)indexes
{	
    return [self stringByURIEncodedUsingCFEncoding:NS2CFEncoding(encoding) convertToCharRefIfNeeded:flag unableToEncode:indexes];
}

- (NSString *)stringByURIEncodedUsingCFEncoding:(CFStringEncoding)encoding convertToCharRefIfNeeded:(BOOL)flag unableToEncode:(NSIndexSet **)indexes
{
    if ([self isEmpty]) {
		return self;
	}
    CFStringRef esc = CFSTR(";,/?:@&=+$#");
    CFStringRef result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, esc, encoding);
	if (result != NULL) {
		return [(NSString *)result autorelease];
	}
	if (!flag && indexes == NULL) {
		return nil;
	}

    NSMutableString *mString = [NSMutableString string];
    NSMutableIndexSet *mIndexes = nil;
    if (indexes != NULL) {
        mIndexes = [NSMutableIndexSet indexSet];
    }

    NSUInteger length_ = [self length];
    NSUInteger i = 0;
    NSRange aRange;

	NSString *each;
    CFStringRef eachRef;

    while (i < length_) {
        aRange = [self rangeOfComposedCharacterSequenceAtIndex:i];
        each = [self substringWithRange:aRange];
        eachRef = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)each, NULL, esc, encoding);
        if (eachRef == NULL) {
            if (mIndexes) {
                [mIndexes addIndex:i];
            }
            if (flag) {
                CFMutableStringRef tmp = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, (CFStringRef)each);
                CFStringTransform(tmp, NULL, kCFStringTransformToXMLHex, false);
                CFStringRef converted = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, tmp, NULL, esc, encoding);
                [mString appendString:(NSString *)converted];
                CFRelease(converted);
                CFRelease(tmp);
            }
		} else {
            [mString appendString:(NSString *)eachRef];
            CFRelease(eachRef);
		}
        i = NSMaxRange(aRange);
    }

    if (indexes != NULL) {
        *indexes = mIndexes;
    }
	return flag ? mString : nil;
}

- (NSString *)stringByReplacingSomeCharactersLikeV2C
{
    if ([self isEmpty]) {
        return self;
    }
    NSMutableString *mString = [self mutableCopyWithZone:[self zone]];
    unichar fromChar = 0xfffc;
    unichar toChar;
    [mString replaceCharacters:[NSString stringWithCharacters:&fromChar length:1] toString:@""];
    fromChar = 0x301c;
    toChar = 0xff5e;
    [mString replaceCharacters:[NSString stringWithCharacters:&fromChar length:1] toString:[NSString stringWithCharacters:&toChar length:1]];
    fromChar = 0x203e;
    toChar = 0xffe3;
    [mString replaceCharacters:[NSString stringWithCharacters:&fromChar length:1] toString:[NSString stringWithCharacters:&toChar length:1]];
    fromChar = 0x2014;
    toChar = 0x2015;
    [mString replaceCharacters:[NSString stringWithCharacters:&fromChar length:1] toString:[NSString stringWithCharacters:&toChar length:1]];
    fromChar = 0x2016;
    toChar = 0x2225;
    [mString replaceCharacters:[NSString stringWithCharacters:&fromChar length:1] toString:[NSString stringWithCharacters:&toChar length:1]];
    fromChar = 0x2212;
    toChar = 0xff0d;
    [mString replaceCharacters:[NSString stringWithCharacters:&fromChar length:1] toString:[NSString stringWithCharacters:&toChar length:1]];
    NSString *string = [NSString stringWithString:mString];
    [mString release];
    return string;
}
@end
