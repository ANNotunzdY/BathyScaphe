/**
  * $Id: CMRTextColumnCell.m,v 1.1.1.1 2005-05-11 17:51:04 tsawada2 Exp $
  * 
  * CMRTextColumnCell.m
  *
  * Copyright (c) 2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  */
#import "CMRTextColumnCell.h"
#import "CocoMonar_Prefix.h"

static id rightParagraphStyle(void)
{
	static id pstyle = nil;
	if(nil == pstyle){
		pstyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[pstyle setAlignment : NSRightTextAlignment];
		[pstyle setLineBreakMode : NSLineBreakByTruncatingTail];
	}
	return pstyle;
}


@implementation CMRTextColumnCell
- (NSAttributedString *) attributedStringValue
{
	NSMutableAttributedString		*as;

	as = SGTemporaryAttributedString();
	[as setAttributedString : [super attributedStringValue]];
	
	if(NSRightTextAlignment == [self alignment]){
		[as addAttribute : NSParagraphStyleAttributeName
				   value : rightParagraphStyle()];
	}
	return as;
}
@end
