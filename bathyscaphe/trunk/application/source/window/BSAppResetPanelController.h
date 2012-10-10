//
//  BSAppResetPanelController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/07/16.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSAppResetPanelController : NSWindowController {
    IBOutlet NSMatrix *m_resetTargetMatrix;
}

- (NSMatrix *)resetTargetMatrix;

- (IBAction)okOrCancel:(id)sender;
- (IBAction)help:(id)sender;
@end
