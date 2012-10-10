//
//  IndexField.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/09.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "IndexField.h"

@implementation IndexField
- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [self selectText:nil];
}

- (void)selectText:(id)sender
{
    id delegate = [self delegate];
    [super selectText:sender];

    if (delegate && [delegate respondsToSelector:@selector(selectRangeWithTextField:)]) {
        NSRange selectedRange = [delegate selectRangeWithTextField:self];
        [[self currentEditor] setSelectedRange:selectedRange];
    }
}
@end
