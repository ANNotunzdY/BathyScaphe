//
//  LabelsPrefController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/15.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"


@interface LabelsPrefController : PreferencesController {
    IBOutlet NSForm *labelNamesForm;

    IBOutlet NSView *labelColorsView;
    IBOutlet NSButton *restoreButton;

    NSArray *m_currentNamesSnapshot;
    NSArray *m_currentColorsSnapshot;
}

@property(readwrite, copy) NSArray *currentNamesSS;
@property(readwrite, copy) NSArray *currentColorsSS;

- (IBAction)restoreDefaults:(id)sender;

@end
