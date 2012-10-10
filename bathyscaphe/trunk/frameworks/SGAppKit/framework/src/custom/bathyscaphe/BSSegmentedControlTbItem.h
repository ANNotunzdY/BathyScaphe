//
//  BSSegmentedControlTbItem.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/08/30.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSSegmentedControlTbItem : NSToolbarItem {
    @private
    id  _delegate;
}
// validation は delegate が行う
- (id)delegate;
- (void)setDelegate:(id)aDelegate;
@end


@interface NSObject(BSSegmentedControlTbItemValidation)
- (BOOL)segCtrlTbItem:(BSSegmentedControlTbItem *)item validateSegment:(NSInteger)segment;
@end
