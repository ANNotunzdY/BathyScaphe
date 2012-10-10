//
//  NSPasteboard-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/05/28.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSPasteboard-SGExtensions.h"
#import <SGFoundation/NSString-SGExtensions.h>
#import "UTILKit.h"


@implementation NSAttributedString(CMXAdditions)
- (void)writeToPasteboard:(NSPasteboard *)pboard
{
	BOOL succeed_;
	NSData *data_t;

#if DEBUG_LOG
	NSLog(@"writeToPasteboard: %@", pboard);
#endif

	// attributed string にいくつか加工を行うため、まず mutableCopy する
	NSMutableAttributedString *str_attr = [[self mutableCopy] autorelease];

	// NSAttachmentCharacter を除去
	NSMutableString *mString = [str_attr mutableString];
	// +[NSString stringWithChatacter:] is declared in SGFoundation.
	[mString replaceOccurrencesOfString:[NSString stringWithCharacter:NSAttachmentCharacter]
							 withString:@""
							    options:NSLiteralSearch
								  range:NSMakeRange(0, [mString length])];

	// Text
	NSString *string = [NSString stringWithString:mString];
	succeed_ = [pboard setString:string forType:NSStringPboardType];
	UTILRequireCondition(succeed_, ErrNotWritable);
	
#if DEBUG_LOG
// #warning 64BIT: Check formatting arguments
// 2010-03-07 tsawada2 修正済
	NSLog(@"pboard NSStringPboardType: %@", succeed_ ? @"YES" : @"NO");
#endif
	
	// RTF
	// 色削除
	NSRange range = NSMakeRange(0, [str_attr length]);
	[str_attr removeAttribute:NSForegroundColorAttributeName range:range];
	// 色を追加
	NSDictionary *dic;
			
	dic = [[NSDictionary alloc] initWithObjectsAndKeys:[NSColor textColor], NSForegroundColorAttributeName, NULL];
	[str_attr addAttributes:dic range:range];
	[dic release];

/*#if 0
	[str_attr fixParagraphStyleAttributeInRange: NSMakeRange(0, [self length])];
	[str_attr fixAttachmentAttributeInRange: NSMakeRange(0, [self length])];
	[str_attr fixFontAttributeInRange: NSMakeRange(0, [self length])];
	[str_attr fixAttributesInRange: NSMakeRange(0, [self length])];
#endif*/
		
	data_t = [str_attr RTFFromRange:range documentAttributes:nil];

	succeed_ = [pboard setData:data_t forType:NSRTFPboardType];
	UTILRequireCondition(succeed_, ErrNotWritable);
	
#if DEBUG_LOG
// #warning 64BIT: Check formatting arguments
// 2010-03-07 tsawada2 修正済
	NSLog(@"pboard NSRTFPboardType: %@", succeed_ ? @"YES" : @"NO");
#endif

ErrNotWritable:
	return;
}
@end
