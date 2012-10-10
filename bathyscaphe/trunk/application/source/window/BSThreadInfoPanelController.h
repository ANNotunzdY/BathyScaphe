//
//  BSThreadInfoPanelController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/01/20.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSThreadInfoPanelController : NSWindowController {
	IBOutlet NSObjectController *m_greenCube;
    IBOutlet NSSegmentedControl *m_labelChooser;
}

+ (id)sharedInstance;

+ (BOOL)nonActivatingPanel;
+ (void)setNonActivatingPanel:(BOOL)nonActivating;
@end
