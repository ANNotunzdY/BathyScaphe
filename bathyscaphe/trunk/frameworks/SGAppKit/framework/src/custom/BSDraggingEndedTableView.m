//
//  BSDraggingEndedTableView.m
//  SGAppKit
//
//  Created by Tsutomu Sawada on 10/08/08.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSDraggingEndedTableView.h"


@implementation BSDraggingEndedTableView
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    id dataSource = [self dataSource];
    if (dataSource && [dataSource respondsToSelector:@selector(tableView:draggingEnded:)]) {
        [dataSource tableView:self draggingEnded:operation];
    }
}
@end
