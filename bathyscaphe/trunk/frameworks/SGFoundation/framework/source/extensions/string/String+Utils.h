//
//  String+Utils.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/15.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface NSObject(SGStringUtils)
- (NSString *)stringValue;
@end


@interface NSString(SGStringUtils)
+ (NSString *)yenmark;
+ (NSString *)backslash;

- (BOOL)isEmpty;
- (NSRange)range;

- (NSString *)stringValue;

- (NSUInteger)unsignedIntegerValue;
@end


@interface NSAttributedString(SGStringUtils)
- (BOOL)isEmpty;
- (NSRange)range;
- (NSString *)stringValue;
@end


@interface NSString(SGNetEncoding)
- (NSString *)stringByURLEncodingUsingEncoding:(NSStringEncoding)encoding;
// Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
// Deprecated in BathyScaphe 1.7 "Prima Aspalas" and later. Use -stringByURIEncodedUsingCFEncoding:convertToCharRefIfNeeded:unableToEncode: instead.
// (Note that at the new method type of 1st paramater is changed to CFStringEncoding, not NSStringEncoding.)
//- (NSString *)stringByURLEncodingUsingEncoding:(NSStringEncoding)encoding convertToCharRefIfNeeded:(BOOL)flag unableToEncode:(NSIndexSet **)indexes;
// Available in BathyScaphe 1.7 "Prima Aspalas" and later.
- (NSString *)stringByURIEncodedUsingCFEncoding:(CFStringEncoding)encoding convertToCharRefIfNeeded:(BOOL)flag unableToEncode:(NSIndexSet **)indexes;

// V2C に習った対策
// http://v2c.s50.xrea.com/manual/write.html の最下部の表参照
- (NSString *)stringByReplacingSomeCharactersLikeV2C; // Available in BathyScaphe 1.6.3 "Hinagiku" and later.
@end
