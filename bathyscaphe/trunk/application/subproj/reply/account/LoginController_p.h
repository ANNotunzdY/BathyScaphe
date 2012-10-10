//
//  LoginController_p.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "LoginController.h"
#import "URLConnector_Prefix.h"

#import "w2chAuthenticator.h"
#import "AppDefaults.h"


@interface LoginController(ViewAccessor)
- (NSButton *)cancelButton;
- (NSButton *)okButton;
- (NSTextField *)passwordField;
- (NSButton *)shouldSavePWBtn;
- (NSTextField *)userIDField;
@end


@interface LoginController(UISetup)
- (void)updateButtonState;
- (void)setupUIComponents;
@end
