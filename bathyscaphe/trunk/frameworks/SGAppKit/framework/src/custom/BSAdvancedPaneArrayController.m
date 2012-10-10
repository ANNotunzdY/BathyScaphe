//
//  BSAdvancedPaneArrayController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/08/06.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSAdvancedPaneArrayController.h"


@implementation BSAdvancedPaneArrayController
- (NSTableView *)tableView
{
	return m_tableView;
}

- (NSInteger)firstColumnOfTextFieldCell
{
	NSArray *columns = [[self tableView] tableColumns];
	NSInteger i;
	NSInteger numOfColumns = [columns count];
	NSTableColumn *column;

	for (i = 0; i < numOfColumns; i++) {
		column = [columns objectAtIndex:i];
		if ([[column dataCell] isKindOfClass:[NSTextFieldCell class]]) {
			return i;
		}
	}
	return 0;
}		

- (void)addObject:(id)object
{
	NSTableView *tv = [self tableView];
	[super addObject:object];
	[tv editColumn:[self firstColumnOfTextFieldCell] row:[tv selectedRow] withEvent:nil select:YES];
}
@end
