//
//  NSCell-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSCell-SGExtensions.h"

@implementation NSCell(SGExtensions)
- (void)setAttributesFromCell:(NSCell *)aCell
{
	if (!aCell) {
        return;
	}
	[self setAction:[aCell action]];
	[self setAlignment:[aCell alignment]];
	[self setAllowsEditingTextAttributes:[aCell allowsEditingTextAttributes]];
	[self setAllowsMixedState:[aCell allowsMixedState]];
	[self setBezeled:[aCell isBezeled]];
	[self setBordered:[aCell isBordered]];
	[self setContinuous:[aCell isContinuous]];
	[self setEditable:[aCell isEditable]];
	[self setEnabled:[aCell isEnabled]];
	[self setFocusRingType: [aCell focusRingType]];
	[self setFont:[aCell font]];
	[self setFormatter:[aCell formatter]];
	[self setImage:[aCell image]];
	[self setImportsGraphics:[aCell importsGraphics]];
    [self setLineBreakMode:[aCell lineBreakMode]];
	[self setMenu:[aCell menu]];
	[self setObjectValue:[aCell objectValue]];
	[self setRefusesFirstResponder:[aCell refusesFirstResponder]];
	[self setRepresentedObject:[aCell representedObject]];
	[self setScrollable:[aCell isScrollable]];
	[self setSelectable:[aCell isSelectable]];
	[self setSendsActionOnEndEditing:[aCell sendsActionOnEndEditing]];
	[self setShowsFirstResponder:[aCell showsFirstResponder]];
	[self setState:[aCell state]];
	[self setTag:[aCell tag]];
	[self setTarget:[aCell target]];
	[self setType:[aCell type]];
	[self setWraps:[aCell wraps]];
}
@end
