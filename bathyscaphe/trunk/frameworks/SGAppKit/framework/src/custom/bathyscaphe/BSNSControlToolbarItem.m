//
//  BSNSControlToolbarItem.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/02/02.
//  Copyright 2008-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSNSControlToolbarItem.h"


@implementation BSNSControlToolbarItem
- (void)validate
{
	NSView *view = [self view];
	if (![view isKindOfClass:[NSControl class]]) {
		return;
	}

	id targetObject = [NSApp targetForAction:[(NSControl *)view action] to:[(NSControl *)view target] from:self];
	if (targetObject && [targetObject respondsToSelector:@selector(validateNSControlToolbarItem:)]) {
		BOOL flag = [targetObject validateNSControlToolbarItem:self];
		[(NSControl *)view setEnabled:flag];
		[[self menuFormRepresentation] setEnabled:flag];
    } else if (targetObject && [targetObject respondsToSelector:@selector(validateUserInterfaceItem:)]) {
        BOOL flag = [targetObject validateUserInterfaceItem:self];
        [(NSControl *)view setEnabled:flag];
        [[self menuFormRepresentation] setEnabled:flag];
	} else {
		[(NSControl *)view setEnabled:NO];
		[[self menuFormRepresentation] setEnabled:NO];
	}
}
@end
