//
//  BSIPIArrayController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/11.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIArrayController.h"
#import <AppKit/NSToolbarItem.h>


@implementation BSIPIArrayController
- (IBAction)removeAll:(id)sender
{
    [self removeObjects:[self arrangedObjects]];
}

- (IBAction)selectFirst:(id)sender
{
    [self setSelectionIndex:0];
}

- (IBAction)selectLast:(id)sender
{
    NSUInteger count = [self countOfArrangedObjects];
    if (count == 0) {
        return;
    }
    [self setSelectionIndex:(count-1)];
}

- (NSUInteger)countOfArrangedObjects
{
    return [[self arrangedObjects] count];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
    if ([item action] == @selector(removeAll:)) {
        return ([self countOfArrangedObjects] > 0);
    }
    return [super validateUserInterfaceItem:item];
}
@end
