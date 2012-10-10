//
//  NoNameInputController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/09/11.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NoNameInputController.h"
#import "CocoMonar_Prefix.h"

#define kNoNameInputControllerNib   @"CMRNoNameInput"
#define kNoNameInputStrings         @"NoNameInput"
#define kNoNameInputMessage         @"NoNameInput_Message"
#define kNoNameInputHelpAnchor      @"NoNameInput_HelpAnchor"

@implementation NoNameInputController
- (id)init
{
    if (self = [super initWithWindowNibName:kNoNameInputControllerNib]) {
        [self window];
    }
    return self;
}

- (void)dealloc
{
    [m_enteredText release];
    [super dealloc];
}

- (NSTextField *)titleField
{
    return m_titleField;
}

- (NSString *)enteredText
{
    return m_enteredText;
}

- (void)setEnteredText:(NSString *)someText
{
    [someText retain];
    [m_enteredText release];
    m_enteredText = someText;
}

- (IBAction)ok:(id)sender
{
    [NSApp stopModalWithCode:NSOKButton];
}

- (IBAction)cancel:(id)sender
{
    [NSApp stopModalWithCode:NSCancelButton];
}

- (IBAction)showHelpForNoNameInput:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:NSLocalizedStringFromTable(kNoNameInputHelpAnchor, kNoNameInputStrings, @"")
                                               inBook:[NSBundle applicationHelpBookName]];
}

- (NSString *)askUserAboutDefaultNoNameForBoard:(NSString *)boardName presetValue:(NSString *)aValue
{
    NSInteger code;
    NSString *title;

    UTILAssertNotNil(boardName);
    
    [self setEnteredText:aValue];   

    title = [NSString stringWithFormat:NSLocalizedStringFromTable(kNoNameInputMessage, kNoNameInputStrings, @""), boardName];
    [[self titleField] setStringValue:title];

    code = [NSApp runModalForWindow:[self window]];

    [[self window] close];
    return (NSOKButton == code) ? [[[self enteredText] copy] autorelease] : nil;
}
@end
