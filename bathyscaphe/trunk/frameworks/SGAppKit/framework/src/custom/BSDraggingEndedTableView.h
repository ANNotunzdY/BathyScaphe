//
//  BSDraggingEndedTableView.h
//  SGAppKit
//
//  Created by Tsutomu Sawada on 10/08/08.
//  Copyright BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSDraggingEndedTableView : NSTableView {

}

@end


@interface NSObject(BSDraggingEndedTableDataSource)
- (void)tableView:(NSTableView *)aTableView draggingEnded:(NSDragOperation)operation;
@end
