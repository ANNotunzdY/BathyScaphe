//
//  BSIPITableView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/07/10.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPITableView.h"

@implementation BSIPITableView
- (BOOL)needsPanelToBecomeKey
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(tableView:shouldPerformKeyEquivalent:)]) {
		return [delegate tableView:self shouldPerformKeyEquivalent:theEvent];
	}

	return [super performKeyEquivalent:theEvent];
}

- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationCopy;
}
/*
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];

	if (![self isRowSelected:row]) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	}

	if (row >= 0) {
		return [self menu];
	} else {
		return nil;
	}
}*/
@end
