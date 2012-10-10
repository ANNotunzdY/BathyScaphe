//
//  LoginController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "LoginController_p.h"


@implementation LoginController
- (id)initWithType:(BSKeychainAccountType)type
{
    if (self = [super initWithWindowNibName:@"LoginWindow"]) {
        m_type = type;
    }
    return self;
}

- (void)awakeFromNib
{
    [self setupUIComponents];
}

- (AppDefaults *)preferences
{
    return [w2chAuthenticator preferences];
}

- (BOOL)runModalForLoginWindow:(NSString **)accountPtr
                      password:(NSString **)passwordPtr
             shouldUseKeychain:(BOOL *)savePassPtr
{
    NSInteger returnCode_;
    
    if (accountPtr != NULL) {
        *accountPtr = nil;
    }
    if (passwordPtr != NULL) {
        *passwordPtr = nil;
    }
    if (savePassPtr != NULL) {
        *savePassPtr = NO;
    }
    [self setupUIComponents];

    returnCode_ = [NSApp runModalForWindow:[self window]];
    if (returnCode_ != NSOKButton) {
        return NO;
    }
    if (accountPtr != NULL) {
        *accountPtr = [[self userIDField] stringValue];
    }
    if (passwordPtr != NULL) {
        *passwordPtr = [[self passwordField] stringValue];
    }
    if (savePassPtr != NULL) {
        *savePassPtr = (NSOnState == [[self shouldSavePWBtn] state]);
    }
    return YES;
}
@end


@implementation LoginController(Action)
- (IBAction)okLogin:(id)sender
{
    [NSApp stopModalWithCode:NSOKButton];
    [self close];
}

- (IBAction)cancelLogin:(id)sender
{
    [NSApp stopModalWithCode:NSCancelButton];
    [self close];
}

- (IBAction)changeShouldSavePW:(id)sender
{
    ;
}
@end
