//
//  LoginController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//


#import <Cocoa/Cocoa.h>
#import "AppDefaults.h"

@class w2chAuthenticator;

@interface LoginController : NSWindowController
{
    IBOutlet NSButton    *m_cancelButton;
    IBOutlet NSButton    *m_okButton;
    IBOutlet NSTextField *m_passwordField;
    IBOutlet NSButton    *m_shouldSavePWBtn;
    IBOutlet NSTextField *m_userIDField;
    IBOutlet NSTextField *m_messageTextField;
    IBOutlet NSTextField *m_informativeTextField;
    IBOutlet NSTextField *m_accountLabelField;
    BSKeychainAccountType m_type;
}

- (id)initWithType:(BSKeychainAccountType)type;

- (AppDefaults *)preferences;

- (BOOL)runModalForLoginWindow:(NSString **)accountPtr
                      password:(NSString **)passwordPtr
             shouldUseKeychain:(BOOL *)savePassPtr;
@end


@interface LoginController(Action)
- (IBAction)okLogin:(id)sender;
- (IBAction)cancelLogin:(id)sender;
- (IBAction)changeShouldSavePW:(id)sender;
@end
