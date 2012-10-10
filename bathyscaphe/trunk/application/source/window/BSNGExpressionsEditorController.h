//
//  BSNGExpressionsEditorController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/01.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSNGExpressionsEditorController : NSWindowController {
    IBOutlet NSArrayController *m_controller;
    IBOutlet NSTextField *m_messageTextField;

    NSString *m_targetBoardName;
    id m_delegate;
}

- (id)initWithDelegate:(id)obj boardName:(NSString *)boardName; // boardName may be nil
- (void)bindNGExpressionsArrayTo:(id)observableController withKeyPath:(NSString *)keyPath;
- (void)unbindNGExpressionsArray;

- (IBAction)openEditorSheet:(id)sender;
- (IBAction)closeEditorSheet:(id)sender;
- (IBAction)showEditorHelp:(id)sender;

- (NSString *)targetBoardName;
- (void)setTargetBoardName:(NSString *)boardName;

@property(readwrite, assign) id delegate;

@end


@interface NSObject(BSNGExpressionsEditorDelegate)
- (void)NGExpressionsEditorDidClose:(BSNGExpressionsEditorController *)controller;
- (NSWindow *)windowForNGExpressionsEditor:(BSNGExpressionsEditorController *)controller;
@end
