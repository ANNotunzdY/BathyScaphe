//
//  BSAddNGExWindowController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/07.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class CMRThreadSignature, BSNGExpression;

@interface BSAddNGExWindowController : NSWindowController {
    CMRThreadSignature *m_signature;
    BSNGExpression *m_NGExpression;

    IBOutlet NSObjectController *m_NGExpressionController;
    IBOutlet NSMatrix *m_scopeSelector;
    IBOutlet NSButton *m_runSpamFilterImmediatelyButton;
}

- (id)init;

- (NSObjectController *)ngExpressionController;
- (NSMatrix *)scopeSelector;
- (NSButton *)runSpamFilterImmediatelyButton;

- (void)showAddNGExpressionSheetForWindow:(NSWindow *)window
                          threadSignature:(CMRThreadSignature *)signature
                               expression:(NSString *)expression;

- (IBAction)cancelAddingNGEx:(id)sender;
- (IBAction)addNGExAndClose:(id)sender;
- (IBAction)addNGExHelp:(id)sender;
- (IBAction)selectScope:(id)sender;
- (IBAction)toggleRunImmediately:(id)sender;

@property(readwrite, retain) BSNGExpression *ngExpression;

@end
