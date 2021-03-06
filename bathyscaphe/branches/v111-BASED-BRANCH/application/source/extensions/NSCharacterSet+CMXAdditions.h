//: NSCharacterSet+CMXAdditions.h
/**
  * $Id: NSCharacterSet+CMXAdditions.h,v 1.1.1.1.4.1 2006-02-27 17:31:49 masakih Exp $
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.
  * See the file LICENSE for copying permission.
  */

#import <Foundation/Foundation.h>

@class CMRFileManager;

@interface NSCharacterSet(CMRCharacterSetAddition)
+ (NSCharacterSet *) innerLinkPrefixCharacterSet;
+ (NSCharacterSet *) innerLinkRangeCharacterSet;
+ (NSCharacterSet *) innerLinkSeparaterCharacterSet;

/*
0 - 9 ０ - ９
日本語以外の環境だとdecimalDigitCharacterSetが
全角数字を認識しないようなので
*/
+ (NSCharacterSet *) numberCharacterSet_JP;
@end

#define k_JP_0_Unichar	0xff10
#define k_JP_9_Unichar	0xff19

FOUNDATION_STATIC_INLINE BOOL CMRCharacterIsMemberOfNumeric(unichar c)
{
	return (('0' <= c && c <= '9') || (k_JP_0_Unichar <= c && c <= k_JP_9_Unichar));
}
FOUNDATION_STATIC_INLINE unichar CMRConvertToNumericCharacter(unichar c)
{
	return ((k_JP_0_Unichar <= c && c <= k_JP_9_Unichar) ? (c - (k_JP_0_Unichar - '0')) : c);
}
