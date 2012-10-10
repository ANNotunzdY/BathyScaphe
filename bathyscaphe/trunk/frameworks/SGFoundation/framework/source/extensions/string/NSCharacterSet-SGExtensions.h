//
//  NSCharacterSet-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface NSCharacterSet(SGExtentions)
// 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
// !"#%&'()*,-./:;?@[¥]_{}
+ (NSCharacterSet *)alphanumericPunctuationCharacterSet;


/**
  * URLとして正当な文字の集合
  * 
  * @return     文字集合
  */
+ (NSCharacterSet *)URLCharacterSet;

/**
  * 空白、タブ、改行、および、全角の空白文字を含む
  * CharacterSetを返す。
  * 
  * @return     全角の空白文字も含むwhitespaceAndNewlineCharacterSet
  */
+ (NSCharacterSet *)extraspaceAndNewlineCharacterSet;
@end
