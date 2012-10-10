//
//  CMRHostHandler.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/27.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface CMRHostHandler : NSObject
{

}
+ (id)hostHandlerForURL:(NSURL *)anURL;

// Managing subclasses
+ (BOOL)canHandleURL:(NSURL *)anURL;
+ (void)registerHostHandlerClass:(Class)aHostHandlerClass;

- (NSDictionary *)properties;
- (NSString *)name;
- (NSString *)identifier;

- (BOOL)canReadDATFile;

/*
----------------------------------------
CES (Code Encoding Scheme)
----------------------------------------
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

NOTE:
実際の変換ルーチンは CMXTextParser.h にある。
----------------------------------------
*/
- (CFStringEncoding)subjectEncoding;
- (CFStringEncoding)threadEncoding;

/* 
    anURL = 掲示板URLを含むURL
    bbs = 掲示板ディレクトリ名 
*/
- (NSURL *)boardURLWithURL:(NSURL *)anURL bbs:(NSString *)bbs;
- (NSURL *)datURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName;

- (NSDictionary *)readCGIProperties;

- (NSURL *)readURLWithBoard:(NSURL *)boardURL;
- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName;
- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                latestCount:(NSInteger)count;
- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                  headCount:(NSInteger)count;
- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                      start:(NSUInteger)startIndex
                        end:(NSUInteger)endIndex
                    nofirst:(BOOL)nofirst;

- (NSString *)makeURLStringWithBoard:(NSURL *)boardURL datName:(NSString *)datName;

- (BOOL)parseParametersWithReadURL:(NSURL *)link
                               bbs:(NSString **)bbs
                               key:(NSString **)key
                             start:(NSUInteger *)startIndex
                                to:(NSUInteger *)endIndex
                         showFirst:(BOOL *)showFirst;
@end


@interface CMRHostHandler(WriteCGI)
/* write.cgi parameter names */
#define CMRHostFormSubmitKey    @"submit"
#define CMRHostFormNameKey      @"name"
#define CMRHostFormMailKey      @"mail"
#define CMRHostFormMessageKey   @"message"
#define CMRHostFormBBSKey       @"bbs"
#define CMRHostFormIDKey        @"key"
#define CMRHostFormDirectoryKey @"directory"
#define CMRHostFormTimeKey      @"time"
#define CMRHostFormSubjectKey   @"subject" // Available in SilverGull and later.

- (NSDictionary *)formKeyDictionary;

- (NSURL *)writeURLWithBoard:(NSURL *)boardURL;
- (NSURL *)threadCreationWriteURLWithBoard:(NSURL *)boardURL; // Available in SilverGull and later.
- (NSString *)submitValue;
- (NSString *)submitNewThreadValue; // Available in SilverGull and later.
@end
