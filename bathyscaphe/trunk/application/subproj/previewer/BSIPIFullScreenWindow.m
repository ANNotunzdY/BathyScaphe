//
//  BSIPIFullScreenWindow.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/01/14.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIFullScreenWindow.h"


@implementation BSIPIFullScreenWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	NSRect screenFrame = [[NSScreen mainScreen] frame];
    id result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

    [result setBackgroundColor:[NSColor blackColor]];
	[result setOpaque:YES];
    [result setHasShadow:NO];
    [result setLevel:NSScreenSaverWindowLevel];

	[self setFrame:screenFrame display:YES];

    return result;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

//  Ask our delegate if it wants to handle keystroke or mouse events before we route them.
- (void)sendEvent:(NSEvent *)theEvent
{
	NSEventType	type_ = [theEvent type];
	id delegate_ = [self delegate];
    // Offer key-down events to the delegate
    if (type_ == NSKeyDown) {
        if ([delegate_ respondsToSelector:@selector(handlesKeyDown:inWindow:)]) {
            if ([delegate_ handlesKeyDown:theEvent inWindow:self]) {
                return;
            }
        }
	}
	// Offer scroll wheel events to the delegate
    if (type_ == NSScrollWheel) {
        if ([delegate_ respondsToSelector:@selector(handlesScrollWheel:inWindow:)]) {
            if ([delegate_ handlesScrollWheel:theEvent inWindow:self]) {
                return;
            }
        }
	}
    //  Offer mouse-down events (lefty or righty) to the delegate
	if (type_ == NSLeftMouseDown) {
		if ([delegate_ respondsToSelector:@selector(handlesMouseDown:inWindow:)]) {
			[delegate_ handlesMouseDown:theEvent inWindow:self];
        }
	}
	//  Offer swipe events to the delegate
	if (type_ == NSEventTypeSwipe) {
		if ([delegate_ respondsToSelector:@selector(handlesSwipe:inWindow:)]) {
			[delegate_ handlesSwipe:theEvent inWindow:self];
		}
	}
    //  Delegate wasn't interested, so do the usual routing.
    [super sendEvent:theEvent];
}
@end
