//
//  BSIPIHUDView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/08/04.
//  Copyright 2008 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIHUDView.h"


@implementation BSIPIHUDView
/*
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.

    }
    return self;
}
*/
- (void)dealloc
{
	[m_cachedPath release];
	m_cachedPath = nil;
	[super dealloc];
}

- (void)awakeFromNib
{
	m_cachedRect = [self frame];
}

- (NSBezierPath *)calcRoundedRectForRect:(NSRect)bgRect
{
	if (m_cachedPath && NSEqualRects(bgRect, m_cachedRect)) {
		return m_cachedPath;
	}

    NSInteger minX = NSMinX(bgRect);
    NSInteger midX = NSMidX(bgRect);
    NSInteger maxX = NSMaxX(bgRect);
    NSInteger minY = NSMinY(bgRect);
    NSInteger midY = NSMidY(bgRect);
    NSInteger maxY = NSMaxY(bgRect);
    CGFloat radius = 6.0;
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:bgRect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];

	m_cachedRect = bgRect;
	m_cachedPath = [bgPath retain];
    
    return m_cachedPath;
}

- (void)drawRect:(NSRect)rect
{
	static NSColor *g_HUDBgColor = nil;
	if (!g_HUDBgColor) {
		g_HUDBgColor = [[NSColor colorWithCalibratedWhite:0.1 alpha:0.75] retain];
	}
	[g_HUDBgColor set];
	[[self calcRoundedRectForRect:rect] fill];
	[super drawRect:rect];
}
@end
