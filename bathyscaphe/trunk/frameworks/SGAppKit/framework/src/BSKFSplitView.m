//
//  BSKFSplitView.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/09.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSKFSplitView.h"

@implementation BSKFSplitView

#pragma mark Override
- (void)kfSetupResizeCursors
{
	// Mac OS X 10.3 以降なので、より適切なカーソルを使用することができる。
    if (!kfIsVerticalResizeCursor) {
        kfIsVerticalResizeCursor = [[NSCursor resizeLeftRightCursor] retain];
    }
    if (!kfNotIsVerticalResizeCursor) {
        kfNotIsVerticalResizeCursor = [[NSCursor resizeUpDownCursor] retain];
    }
}
@end
