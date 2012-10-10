//
//  CMXTextParser.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/06/13.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class CMRThreadMessage;

enum {
    k2chDATNameIndex            = 0,
    k2chDATMailIndex            ,
    k2chDATDateExtraFieldIndex  ,
    k2chDATMessageIndex         ,
    
    // Optional
    k2chDATTitleIndex           
};


@interface CMXTextParser : NSObject
/**
  *
  * 行を"<>"または","で分割した配列を返す。
  * 区切り文字が","の場合はフィールド中の'@｀'を","に変換
  *
  * 区切り文字が存在しない場合は不当な文字列と見なし、nilを返す。
  *
  * @param    line  行
  * @return         区切り文字で分割した配列
  *
  */
+ (NSArray *)separatedLine:(NSString *)line;

// DAT文字列 --> レスオブジェクト
+ (NSArray *)messageArrayWithDATContents:(NSString *)DatContents
                               baseIndex:(NSUInteger)baseIndex
                                   title:(NSString **)titlePtr;
+ (CMRThreadMessage *)messageWithDATLine:(NSString *)theString;
+ (CMRThreadMessage *)messageWithInvalidDATLineDetected:(NSString *)line;

+ (CMRThreadMessage *)messageWithDATLineComponentsSeparatedByNewline:(NSArray *)aComponents;

// Entity Reference
// "&amp" --> "&amp;"
+ (void)replaceEntityReferenceWithString:(NSMutableString *)aString;
+ (NSString *)stringByReplacingEntityReference:(NSString *)baseString;

/*
レスの本文のうち変換できるものは変換してしまう。
不要なHTMLタグを取り除き、改行タグを変換
*/
+ (NSString *)cachedMessageWithMessageSource:(NSString *)aSource;
+ (void)convertMessageSourceToCachedMessage:(NSMutableString *)aSource;



// ----------------------------------------
// CES (Code Encoding Scheme)
// ----------------------------------------
/*
Shift JIS については対応する符号化文字集合として三つの
候補が考えられる。

  - JIS 規格に忠実な JIS X 0208:1997
  - MicroSoft 社の仕様
  - Apple 社の仕様

これらは以下の CFStringEncodings に対応する（括弧内は
CFStringConvertEncodingToIANACharSetName() の返す名前）

  - kCFStringEncodingShiftJIS (SHIFT_JIS)
  - kCFStringEncodingDOSJapanese (CP932)
  - kCFStringEncodingMacJapanese (X-MAC-JAPANESE)

BathyScaphe の場合、たとえば新・mac 板では Mac Japanese の
コードが使われるケースもあるため、Shift JIS に関しては
これらすべてに対応するのが現実的だと思われる。

そのため、以下のメソッドでこれらの CFStringEncoding を
返した場合は
(1) まず、そのエンコーディングを試し
(2) それで変換できなければ残りのエンコーディングを次の順番で試す。
(3) 結果的に変換できなければエラー

  - kCFStringEncodingDOSJapanese
  - kCFStringEncodingMacJapanese
  - kCFStringEncodingShiftJIS
----------------------------------------
*/
+ (NSString *)stringWithData:(NSData *)aData CFEncoding:(CFStringEncoding)enc;
@end
