//
//  CMRResourceFileReader.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface CMRResourceFileReader : NSObject
{
    @private
    id          bs_contents;
    NSString    *bs_filepath;
}
+ (id)readerWithContentsOfFile:(NSString *)filePath;
+ (id)readerWithContents:(id)fileContents;
- (id)initWithContentsOfFile:(NSString *)filePath;
- (id)initWithContents:(id)fileContents;

/*!
 * @method      resourceClass
 * @abstract    リソースのクラスを指定
 *
 * @discussion  サブクラス側でリソースのクラスを指定するのに使う
 * @result      リソースのクラス(-initWithContentsOfFile: に応答できるクラス)
 */
+ (Class)resourceClass;
- (id)fileContents;
- (void)setFileContents:(id)aFileContents;

- (NSString *)filepath;
@end

/*!
 * @exception CMRReaderUnsupportedFormatException
 * @abstract  サポートしていないファイルフォーマットを読もうとした
 */
extern NSString *const CMRReaderUnsupportedFormatException;
