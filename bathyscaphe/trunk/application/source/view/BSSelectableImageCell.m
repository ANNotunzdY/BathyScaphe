//
//  BSSelectableImageCell.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 10/05/10.
// Copyright 2006-2010 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "BSSelectableImageCell.h"
#import <SGAppKit/NSImage-SGExtensions.h>


@implementation BSSelectableImageCell

- (void)setIntegerValue:(NSInteger)anInt
{
	NSString *imageName = [NSString stringWithFormat:@"LabelIcon%ld", (long)anInt];
	NSImage *image = [NSImage imageNamed:imageName];	
	[self setImage:image];
}
- (void)setDrawX:(BOOL)flag
{
	drawX = flag;
}
- (BOOL)isDrawX
{
	return drawX;
}
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSRect interFrame;
	if([self isBordered]) {
		interFrame = NSInsetRect(cellFrame, 2, 2);
	} else {
		interFrame = cellFrame;
	}
	if(![self isEnabled] || ![self isBordered] || NSOnState != [self state]) {
		[self drawInteriorWithFrame:interFrame inView:controlView];
		return;
	}
	
	[NSGraphicsContext saveGraphicsState];
	
	[[NSColor lightGrayColor] set];
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset:NSMakeSize(.3, .3)];
	[shadow setShadowBlurRadius:0.5];
	[shadow set];
	NSFrameRect(cellFrame);
	
	[NSGraphicsContext restoreGraphicsState];
	
	[self drawInteriorWithFrame:interFrame inView:controlView];
}
@end

