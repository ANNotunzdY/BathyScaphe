//
//  BSIconAndTextCell.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/09/19.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIconAndTextCell.h"


@implementation BSIconAndTextCell
static BOOL g_usesShadowDrawing = NO;

+ (void)initialize
{
    if (self == [BSIconAndTextCell class]) {
        g_usesShadowDrawing = (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6);
    }
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    id			path;
    NSRect		pathRect;
    
    NSImage		*iconImage;
    NSSize		iconSize;
    NSPoint		iconPoint;
    
    BOOL shouldAdjust = NO;

    if ([controlView respondsToSelector:@selector(rowSizeStyle)]) {
        shouldAdjust = ([(NSTableView *)controlView rowSizeStyle] == 2);
    } else if ([controlView respondsToSelector:@selector(rowHeight)]) {
        shouldAdjust = ([(NSTableView *)controlView rowHeight] == 18);
    }

    iconImage = [self image];
    iconSize = NSZeroSize;
    iconPoint.x = cellFrame.origin.x;
    iconPoint.y = cellFrame.origin.y;
    
    if (iconImage) {
        iconSize = [iconImage size];
        iconPoint.x += 3.0;
		iconPoint.y += ceil((cellFrame.size.height - iconSize.height) /2.0);
        
        if ([controlView isFlipped]) {
            iconPoint.y += iconSize.height;
        }
        
        [iconImage compositeToPoint:iconPoint operation:NSCompositeSourceOver];
	}
    

    path = (NSMutableAttributedString *)[self objectValue];
    pathRect.origin.x = cellFrame.origin.x + 4.0;
    if (iconSize.width > 0) {
        pathRect.origin.x += iconSize.width + 4.0;
    }
    pathRect.origin.y = cellFrame.origin.y + ceil((cellFrame.size.height - [path size].height) /2.0);
    if (shouldAdjust) {
        pathRect.origin.y += [controlView isFlipped] ? -1.0 : 1.0;
    }
    pathRect.size.width = cellFrame.size.width - (pathRect.origin.x - cellFrame.origin.x);
    pathRect.size.height = [path size].height;
    
    if (path) {
		if([self isHighlighted]) {
            NSMutableAttributedString *highlightedPath = [[path mutableCopy] autorelease];
            NSRange pathRange = NSMakeRange(0, [path length]);
            if (g_usesShadowDrawing) {
                static NSShadow *shadow = nil;
                if (!shadow) {
                    shadow = [[NSShadow alloc] init];
                    [shadow setShadowBlurRadius:2.0];
                    [shadow setShadowColor:[[NSColor shadowColor] colorWithAlphaComponent:0.5]];
                    [shadow setShadowOffset:NSMakeSize(0, -1)];
                }
                [highlightedPath addAttribute:NSShadowAttributeName value:shadow range:pathRange];
                [highlightedPath addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:pathRange];
                [highlightedPath drawInRect:pathRect];                
            } else {
                // Mail のような視覚効果の実現方法を検証、発見してくれた 915@6th に感謝。
                NSDictionary *highlightedAttr;
                NSDictionary *backgroundAttr;

                highlightedAttr = [NSDictionary dictionaryWithObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
                backgroundAttr  = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];

                // まず、グレーの文字を y軸方向に 1px ずらして描く
                [highlightedPath removeAttribute:NSForegroundColorAttributeName range:pathRange];
                [highlightedPath addAttributes:backgroundAttr range:pathRange];
                [highlightedPath applyFontTraits:NSBoldFontMask range:pathRange];

                [highlightedPath drawInRect:NSOffsetRect(pathRect, 0.0,1.0)];

                // そして、白い文字で重ねて描く
                [highlightedPath removeAttribute:NSForegroundColorAttributeName range:pathRange];
                [highlightedPath addAttributes:highlightedAttr range:pathRange];
                [highlightedPath drawInRect:pathRect];
            }
		} else {
			[path drawInRect:pathRect];
		}
    }
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	return NSCellHitContentArea;
}
@end
