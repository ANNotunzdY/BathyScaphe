//
//  BSTGrepClientTableView.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/09/20.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSTGrepClientTableView : NSTableView {

}

@end


@protocol BSTGrepClientTableViewDelegate
@optional
- (BOOL)tableView:(NSTableView *)aTableView shouldPerformKeyEquivalent:(NSEvent *)theEvent;
@end
