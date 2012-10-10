//
//  BSQuickLookPanel.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/02/02.
//  Copyright 2008-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSQuickLookPanel.h"
#import "BSQuickLookPanelController.h"

@implementation BSQuickLookPanel
- (void)sendEvent:(NSEvent *)theEvent
{
	NSEventType	type_ = [theEvent type];
    //  Offer key-down events to the delegate
    if (type_ == NSKeyDown) {
		NSString	*pressedKey = [theEvent charactersIgnoringModifiers];

        if ([pressedKey isEqualToString:@" "]) {
			[self performClose:nil];
			return;
		}

		// 上／下矢印キーイベントを親ウインドウにスルー
		// 注：-[NSWindow parentWindow] は予めどこかで -[NSWindow setParentWindow:] で設定しておかないと
		// 意味が無い（See CMRThreadsList-DataSource.m）
		unichar		keyChar = 0;
		keyChar = [pressedKey characterAtIndex:0];
		if (keyChar == NSUpArrowFunctionKey || keyChar == NSDownArrowFunctionKey) {
//			[[self parentWindow] sendEvent:theEvent];
			[[[self windowController] qlPanelParent] sendEvent:theEvent];
			return;
		} else if (keyChar == NSCarriageReturnCharacter) {
//			[self performClose:nil];
//			[NSApp sendAction:@selector(showOrOpenSelectedThread:) to:[[self parentWindow] windowController] from:self];
			[NSApp sendAction:@selector(fromQuickLook:) to:[[[self windowController] qlPanelParent] windowController] from:self];
			[self performClose:nil];
			return;
		}
	}
	[super sendEvent:theEvent];
}
@end
