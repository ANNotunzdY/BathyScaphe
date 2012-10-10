//
//  BSReplyTextView.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/03/13.
//  Copyright 2006-2007 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSReplyTextView : NSTextView {
	@private
	CGFloat	m_alphaValue;
}

- (CGFloat)alphaValue;
- (void)setAlphaValue:(float)floatValue;

- (void)setBackgroundColor:(NSColor *)color withAlphaComponent:(CGFloat)alpha;
@end


@interface NSObject(BSReplyTextViewDelegateAddition)
- (NSArray *)availableCompletionPrefixesForTextView:(NSTextView *)aTextView;
- (NSString *)textView:(NSTextView *)aTextView completedStringForCompletionPrefix:(NSString *)prefix;
@end
