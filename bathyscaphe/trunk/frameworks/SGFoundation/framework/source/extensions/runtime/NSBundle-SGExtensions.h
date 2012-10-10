//
//  NSBundle-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface NSBundle(SGExtentions)
+ (NSDictionary *)applicationInfoDictionary;
+ (NSDictionary *)localizedAppInfoDictionary; // added in BathyScaphe 1.1 and later.
+ (NSString *)applicationName;
+ (NSString *)applicationVersion;
+ (NSString *)applicationHelpBookName; // added in BathyScaphe 1.1 and later.

- (NSString *)pathForResourceWithName:(NSString *)filename;
- (NSString *)pathForResourceWithName:(NSString *)filename inDirectory:(NSString *)dirName;
@end


@interface NSBundle(SGApplicationSupport)
// ~/Library/Application Support/(ExecutableName)
+ (NSBundle *)applicationSpecificBundle;
/*!
 * @method      mergedDictionaryWithName
 * @discussion
	Contents/Resources/
	~/Library/Application Support/CocoMonar/Resources
	にある辞書ファイルをマージ
 * @result      マージした辞書
 */
+ (NSDictionary *)mergedDictionaryWithName:(NSString *)filename;
@end


@interface NSBundle(UserAgentString)
+ (NSString *)applicationUserAgent; // e.g. "BathyScaphe/277.5"
+ (NSString *)monazillaUserAgent; // e.g. "Monazilla(1.00) BathyScaphe/277.5"
@end
