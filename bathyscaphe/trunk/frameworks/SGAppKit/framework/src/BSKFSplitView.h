//
//  BSKFSplitView.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/09.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "KFSplitView.h"

@interface BSKFSplitView : KFSplitView {
}

// Overrides private method.
- (void)kfSetupResizeCursors;
@end
