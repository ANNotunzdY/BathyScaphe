//
//  BSTGrepClientTableView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/09/20.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSTGrepClientTableView.h"


@implementation BSTGrepClientTableView
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(tableView:shouldPerformKeyEquivalent:)]) {
		return [delegate tableView:self shouldPerformKeyEquivalent:theEvent];
	}
    
	return [super performKeyEquivalent:theEvent];
}
@end
