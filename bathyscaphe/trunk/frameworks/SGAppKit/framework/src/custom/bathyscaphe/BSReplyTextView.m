//
//  BSReplyTextView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/03/13.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSReplyTextView.h"


@implementation BSReplyTextView
- (id)initWithFrame:(NSRect)inFrame textContainer:(NSTextContainer *)inTextContainer
{
    if (self = [super initWithFrame:inFrame textContainer:inTextContainer]) {
		[self setAlphaValue:1.0];
	}
	return self;
}

- (CGFloat)alphaValue
{
	return m_alphaValue;
}

- (void)setAlphaValue:(float)floatValue
{
	m_alphaValue = floatValue;
}

- (void)setBackgroundColor:(NSColor *)opaqueColor withAlphaComponent:(CGFloat)alpha
{
	NSColor	*actualColor = [opaqueColor colorWithAlphaComponent:alpha];
	[self setBackgroundColor:actualColor];
}

- (void)setBackgroundColor:(NSColor *)aColor
{
	if (aColor) {
		[self setAlphaValue:[aColor alphaComponent]];
	}
	[[self window] setOpaque:([self alphaValue] < 1.0) ? NO : YES];
	[super setBackgroundColor:aColor];
}

- (void)drawRect:(NSRect)aRect
{
	[super drawRect:aRect];
	
	if ([self alphaValue] < 1.0) {
		[[self window] invalidateShadow];
	}
}

static inline BOOL delegateCheck(id delegate)
{
	if (!delegate) return NO;
	if (![delegate respondsToSelector:@selector(availableCompletionPrefixesForTextView:)]) return NO;
	if (![delegate respondsToSelector:@selector(textView:completedStringForCompletionPrefix:)]) return NO;
	return YES;
}

- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
	id delegate = [self delegate];
	if (delegateCheck(delegate)) {
		NSString *partialString = [[self string] substringWithRange:charRange];
		NSArray *prefixes = [delegate availableCompletionPrefixesForTextView:self];

		if (prefixes && [prefixes containsObject:partialString]) {
			NSString *replacement = [delegate textView:self completedStringForCompletionPrefix:partialString];
			if (replacement && [self shouldChangeTextInRange:charRange replacementString:replacement]) {
				[self replaceCharactersInRange:charRange withString:replacement];
				[self didChangeText];
				return nil;
			}
		}
	}
	return [super completionsForPartialWordRange:charRange indexOfSelectedItem:index];
}
@end
