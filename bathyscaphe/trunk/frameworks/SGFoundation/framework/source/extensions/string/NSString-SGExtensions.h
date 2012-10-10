//
//  NSString-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/23.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>


//
// CFStringEncoding <--> NSStringEncoding
//
#define CF2NSEncoding(x)	CFStringConvertEncodingToNSStringEncoding(x)
#define NS2CFEncoding(x)	CFStringConvertNSStringEncodingToEncoding(x)

//
// CFStringEncoding <--> TextEncoding
//
#define CF2TextEncoding(x)	x
#define Text2CFEncoding(x)	x


@interface NSString(SGExtensionTEC)
// Using TEC
- (id)initWithDataUsingTEC:(NSData *)theData encoding:(TextEncoding)encoding;
+ (id)stringWithDataUsingTEC:(NSData *)theData encoding:(TextEncoding)encoding;
@end


@interface NSString(SGExtensions)
+ (id)stringWithData:(NSData *) data encoding:(NSStringEncoding)encoding;

+ (id)stringWithCharacter:(unichar)aCharacter;
- (id)initWithCharacter:(unichar)aCharacter;

- (NSString *)stringByDeletingURLScheme:(NSString *)aScheme;

/**
  * レシーバが引数aStringに指定した文字列を含む場合にYESを返す。
  * 
  * @param    aString  探索文字列
  * @return            レシーバが引数aStringに指定した文字列を含む場合にYES
  */
- (BOOL)containsString:(NSString *)aString;

- (NSRange)rangeOfCharacterSequenceFromSet:(NSCharacterSet *)aSet options:(NSUInteger)mask range:(NSRange)aRange;
- (NSArray *)componentsSeparatedByCharacterSequenceFromSet:(NSCharacterSet *)aCharacterSet;

/*!
 * @method      componentsSeparatedByNewline
 * @abstract    改行で区切る
 *
 * @discussion  指定された文字列を改行(またはUnicodeの段落区切り文字)
 *              で区切り、それぞれ改行文字を含まない文字列を要素とする
 *              配列を返す。改行を含まない、または末尾が改行の文字列の
 *              場合は、要素がひとつの配列を返す。
 *
 * @result      個々の要素を含む配列オブジェクト
 */
- (NSArray *)componentsSeparatedByNewline;

- (NSString *)stringByReplaceEntityReference;

/**
  * 指定されたcharsをすべて、文字列replacement
  * で置き換える。
  * 
  * @param    chars        置き換えられる文字列
  * @return                新しい文字列
  */
- (NSString *)stringByReplaceCharacters:(NSString *) chars toString:(NSString *)replacement;

/**
  * 指定されたcharsをすべて、文字列replacement
  * で置き換える。
  * 
  * @param    chars        置き換えられる文字列
  * @param    replacement  置換後の文字列
  * @param    options      検索時のオプション
  * @return                新しい文字列
  */
- (NSString *)stringByReplaceCharacters:(NSString *)chars toString:(NSString *)replacement options:(NSUInteger)options;

/**
  * 指定されたcharsをすべて、文字列replacement
  * で置き換える。
  * 
  * @param    chars        置き換えられる文字列
  * @param    replacement  置換後の文字列
  * @param    options      検索時のオプション
  * @param    range        置き換える範囲
  * @return                新しい文字列
  */
- (NSString *)stringByReplaceCharacters:(NSString *)chars toString:(NSString *)replacement options:(NSUInteger)options range:(NSRange)aRange;

/**
  * 先頭と末尾の連続する空白文字、タブ、改行を削除
  * した文字列を返す。
  *
  * @return     新しい文字列
  */
- (NSString *)stringByStriped;

/**
  * 先頭の連続する空白文字、タブ、改行を削除
  * した文字列を返す。
  *
  * @return     新しい文字列
  */
- (NSString *)stringByStripedAtStart;

/**
  * 末尾の連続する空白文字、タブ、改行を削除
  * した文字列を返す。
  *
  * @return     新しい文字列
  */
- (NSString *)stringByStripedAtEnd;

- (BOOL)isSameAsString:(NSString *)other;

- (NSArray *)componentsSeparatedByTextBreak;
@end
