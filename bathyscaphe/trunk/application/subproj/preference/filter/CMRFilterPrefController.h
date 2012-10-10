//
//  CMRFilterPrefController.h
//  BachyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/11.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "PreferencesController.h"


@interface CMRFilterPrefController : PreferencesController
{
    IBOutlet NSMatrix *m_hostSymbols;
    IBOutlet NSObjectController *m_preferencesObjectController;
}

- (NSMatrix *)hostSymbols;
- (NSObjectController *)preferencesObjectController;

- (IBAction)resetSpamDB:(id)sender;
- (IBAction)openNGExpressionsEditorSheet:(id)sender;

- (IBAction)openThemeEditorForColorSetting:(id)sender;
@end
