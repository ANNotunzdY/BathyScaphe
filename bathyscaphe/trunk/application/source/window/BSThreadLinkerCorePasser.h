//
//  BSThreadLinkerCorePasser.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 12/08/19.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class CMRThreadSignature;

@interface BSThreadLinkerCorePasser : NSWindowController {
    // ...
    IBOutlet NSObjectController *m_linkerCoreController;
    
    IBOutlet NSTextField *m_fromThreadTitleField;
    IBOutlet NSTextField *m_toThreadTitleField;
    
    NSString *m_fromThreadTitle;
    CMRThreadSignature *m_fromThreadSignature;
    NSString *m_toThreadTitle;
    CMRThreadSignature *m_toThreadSignature;
}

- (NSObjectController *)linkerCoreController;

@property(readwrite, retain) NSString *fromThreadTitle;
@property(readwrite, retain) CMRThreadSignature *fromThreadSignature;
@property(readwrite, retain) NSString *toThreadTitle;
@property(readwrite, retain) CMRThreadSignature *toThreadSignature;

- (IBAction)cancelPassingOn:(id)sender;
- (IBAction)passOnAndClose:(id)sender;
- (IBAction)passOnHelp:(id)sender;

- (void)beginPassingLinkerCoreOnSheetForWindow:(NSWindow *)window;

- (BOOL)passLinkerCoreOnNextThread:(NSError **)errorPtr;

@end
