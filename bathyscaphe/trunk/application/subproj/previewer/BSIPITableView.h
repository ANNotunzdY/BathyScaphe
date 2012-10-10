//
//  BSIPITableView.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/07/10.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSIPITableView : NSTableView {

}

@end


@protocol BSIPITableViewDelegate
@optional
- (BOOL)tableView:(BSIPITableView *) aTableView shouldPerformKeyEquivalent:(NSEvent *)theEvent;
@end
