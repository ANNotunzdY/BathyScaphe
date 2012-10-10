//
//  NoNameInputController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/09/11.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface NoNameInputController : NSWindowController {
    IBOutlet NSTextField *m_titleField;
    NSString *m_enteredText;
}

- (NSTextField *)titleField;

- (NSString *)enteredText;
- (void)setEnteredText:(NSString *)someText;

- (NSString *)askUserAboutDefaultNoNameForBoard:(NSString *)boardName presetValue:(NSString *)aValue;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)showHelpForNoNameInput:(id)sender;
@end
