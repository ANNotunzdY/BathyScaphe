//
//  SGHTMLView-Link.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/06/12.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGHTMLView_p.h"
#import "CMRAttachmentCell.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"



@implementation SGHTMLView(Link)
- (NSTrackingArea *)visibleArea
{
    return bs_visibleArea;
}

- (void)resetCursorRectsImp
{
	if (![self window]) {
        return;
    }

	[self removeAllLinkTrackingRects];
	[self resetTrackingVisibleRect];
	[self updateAnchoredRectsInBounds:[self visibleRect] forAttribute:NSLinkAttributeName];
//	[self updateAnchoredRectsInBounds:[self visibleRect] forAttribute:NSAttachmentAttributeName];
	[self updateAnchoredRectsInBounds:[self visibleRect] forAttribute:CMRMessageIndexAttributeName];
}

/*** Event Handling ***/
- (void)responseMouseEvent:(NSEvent *)theEvent mouseEntered:(BOOL)isEntered
{
	if ((isEntered ? NSMouseEntered : NSMouseExited) != [theEvent type]) {
		return;
	}

    NSTrackingArea *area = [theEvent trackingArea];
    if (!area) {
        return;
    }

    // View
    if ([area isEqual:[self visibleArea]]) {
		[self mouseEventInVisibleRect:theEvent entered:isEntered];
		return;
	}

    // Link
    id userData = [(id)[theEvent userData] objectForKey:@"Link"];
	[self processMouseEvent:userData trackingRect:[area rect] withEvent:theEvent mouseEntered:isEntered];
}

- (BOOL)shouldUpdateAnchoredRectsInBounds:(NSRect)aBounds
{
	return !([[self textStorage] isEmpty] || [self inLiveResize]);
}

- (void)updateAnchoredRectsInBounds:(NSRect)aBounds forAttribute:(NSString *)attributeName
{
	NSTextStorage		*storage_	= [self textStorage];
	NSLayoutManager		*lm			= [self layoutManager];
	NSTextContainer		*container_	= [self textContainer];

	NSUInteger			toIndex_;
	NSUInteger			charIndex_;
	NSRange				glyphRange_;
	NSRange				charRange_;
	NSRange				linkRange_;
	id					v = nil;

	if (![self shouldUpdateAnchoredRectsInBounds:aBounds]) {
		return;
    }

	glyphRange_ = [lm glyphRangeForBoundingRectWithoutAdditionalLayout:aBounds inTextContainer:container_];
	charRange_ = [lm characterRangeForGlyphRange:glyphRange_ actualGlyphRange:NULL];
	charIndex_ = charRange_.location;
	toIndex_ = NSMaxRange(charRange_);
	if (0 == toIndex_) {
        return;
	}

	while (charIndex_ < toIndex_) {
		v = [storage_ attribute:attributeName
						atIndex:charIndex_
		  longestEffectiveRange:&linkRange_
						inRange:charRange_];

		do {
            if (v) {
                NSRange			actualRange_;
                NSRectArray		rects_;
                NSUInteger		i, rectCount_;

                glyphRange_ = [lm glyphRangeForCharacterRange:linkRange_ actualCharacterRange:&actualRange_];

                linkRange_ = actualRange_;

                rects_ = [lm rectArrayForGlyphRange:glyphRange_
                           withinSelectedGlyphRange:kNFRange
                                    inTextContainer:container_
                                          rectCount:&rectCount_];
                for (i = 0; i < rectCount_; i++) {
                    [self addLinkTrackingArea:rects_[i] link:v];
                }
            }
		} while (0);

		charIndex_ = NSMaxRange(linkRange_);
	}
}

- (void)setVisibleArea:(NSTrackingArea *)area
{
    [area retain];
    [bs_visibleArea release];
    bs_visibleArea = area;
}

- (void)resetTrackingVisibleRect
{
    if ([self visibleArea]) {
        [self removeTrackingArea:[self visibleArea]];
    }
    // ポップアップはアプリケーション非アクティブ時には見えないのだから、NSTrackingActiveInActiveApp で十分なはず。
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self visibleRect]
                                                        options:(NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp)
                                                          owner:self
                                                       userInfo:nil];
    [self setVisibleArea:area];
    [area release];
    [self addTrackingArea:[self visibleArea]];
}

- (void)addLinkTrackingArea:(NSRect)aRect link:(id)aLink
{
    NSTrackingArea *area;
    area = [[NSTrackingArea alloc] initWithRect:aRect
                                        options:(NSTrackingMouseEnteredAndExited|NSTrackingCursorUpdate|NSTrackingActiveInActiveApp)
                                          owner:self
                                       userInfo:[NSDictionary dictionaryWithObject:aLink forKey:@"Link"]];
    [self addTrackingArea:area];
    [area release];
}

- (void)cursorUpdate:(NSEvent *)event
{
    NSPoint mousePoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
    if ([self mouse:mousePoint inRect:[[event trackingArea] rect]]) {
        [[NSCursor pointingHandCursor] set];
    } else {
        [[NSCursor IBeamCursor] set];
    }
}

- (void)removeAllLinkTrackingRects
{
    NSArray *copied = [[self trackingAreas] copy];
    for (NSTrackingArea *area in copied) {
        [self removeTrackingArea:area];
    }
    [copied release];
}
@end


@implementation SGHTMLView(DelegateSupport)
- (void)processMouseEvent:(id)userData trackingRect:(NSRect)aRect withEvent:(NSEvent *)anEvent mouseEntered:(BOOL)flag
{
	id<SGHTMLViewDelegate> delegate_;
	SEL performSelector_;

	if ([userData isKindOfClass:[NSTextAttachment class]]) {
		id cell_ = [userData attachmentCell];

		// TextAttachement
		if (![cell_ wantsToTrackMouseForEvent:anEvent inRect:aRect ofView:self atCharacterIndex:NSNotFound]) {
			return;
		}
		[cell_ trackMouse:anEvent inRect:aRect ofView:self atCharacterIndex:NSNotFound untilMouseUp:NO];
		return;
	} else if ([userData isKindOfClass:[NSNumber class]]) {
		// Message Index
		return;
	}

	delegate_ = [self delegate];
	if (!delegate_) {
        return;
	}
	performSelector_ = flag 
		? @selector(HTMLView:mouseEnteredInLink:inTrackingRect:withEvent:)
		: @selector(HTMLView:mouseExitedFromLink:inTrackingRect:withEvent:);
	if (![delegate_ respondsToSelector:performSelector_]) {
		return;
    }
	if (flag) {
		[delegate_ HTMLView:self mouseEnteredInLink:userData inTrackingRect:aRect withEvent:anEvent];
	} else {
		[delegate_ HTMLView:self mouseExitedFromLink:userData inTrackingRect:aRect withEvent:anEvent];
	}
}

- (void)mouseEventInVisibleRect:(NSEvent *)anEvent entered:(BOOL)isMouseEntered
{
	UTILNotifyName(isMouseEntered ? SGHTMLViewMouseEnteredNotification : SGHTMLViewMouseExitedNotification);
}

- (BOOL)shouldHandleContinuousMouseDown:(NSEvent *)theEvent
{
    id<SGHTMLViewDelegate> delegate = [self delegate];
	if (!delegate || ![delegate respondsToSelector:@selector(HTMLView:shouldHandleContinuousMouseDown:)]) {
		return NO;
	}
	return [delegate HTMLView:self shouldHandleContinuousMouseDown:theEvent];
}

- (BOOL)handleContinuousMouseDown:(NSEvent *)theEvent
{
    id<SGHTMLViewDelegate> delegate = [self delegate];
	if (!delegate || ![delegate respondsToSelector:@selector(HTMLView:continuousMouseDown:)]) {
		return NO;
	}
	return [delegate HTMLView:self continuousMouseDown:theEvent];
}
@end
