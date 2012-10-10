//
//  BSNobiNobiToolbarItem.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/27.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSNobiNobiToolbarItem.h"
#import "RBSplitSubview.h"
#import "CMRBrowser.h"


@implementation BSNobiNobiToolbarItem
- (void)validate
{
	[(BSNobiNobiView *)[self view] setShouldDrawBorder:[[self toolbar] customizationPaletteIsRunning]];
}

- (id)copyWithZone:(NSZone *)zone
{
	BSNobiNobiView *nnView;
	id tmpcopy = [super copyWithZone:zone];
	nnView = (BSNobiNobiView *)[tmpcopy view];
	[tmpcopy setMinSize:NSMakeSize(48,22)];
	[tmpcopy setMaxSize:NSMakeSize(48,22)];
	[nnView setShouldDrawBorder:YES];
	return tmpcopy;
}

- (void)adjustWidth:(CGFloat)width
{
    if (width <= 0) {
        return;
    }

	NSSize size_ = NSMakeSize(width-8, 22);
	[self setMinSize:size_];
	[self setMaxSize:size_];
}
@end


@implementation BSNobiNobiView
- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame]) {
		m_shouldDrawBorder = NO;
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
	if ([self shouldDrawBorder]) {
		[[NSColor headerColor] set];
		NSFrameRect(rect);
	} else {
		[[NSColor clearColor] set];
		NSRectFillUsingOperation(rect, NSCompositeSourceOver); // 枠線を確実に消すために
	}
}

- (BOOL)isOpaque
{
	return NO; // YES だとダメ
}

- (BOOL)shouldDrawBorder
{
	return m_shouldDrawBorder;
}

- (void)setShouldDrawBorder:(BOOL)draw
{
	if (m_shouldDrawBorder == draw) {
        return;
    }
	m_shouldDrawBorder = draw;
	[self setNeedsDisplay:YES];
}
@end
