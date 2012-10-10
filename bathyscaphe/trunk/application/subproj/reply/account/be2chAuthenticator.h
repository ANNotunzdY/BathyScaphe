//
//  be2chAuthenticator.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/01/13.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "w2chConnect.h"

@class AppDefaults;

@interface be2chAuthenticator : NSObject<be2chAuthenticationStatus> {
    NSString *m_header;
    NSError *m_lastError;
}
+ (id)defaultAuthenticator;

- (BOOL)runModalForLoginWindow:(NSString **)mailAddressPtr password:(NSString **)passwordPtr shouldUseKeychain:(BOOL *)savePassPtr;

- (BOOL)login:(NSString *)mailAddress password:(NSString *)password setCookieHeader:(NSString **)header;

+ (AppDefaults *)preferences;
- (AppDefaults *)preferences;
+ (void)setPreferencesObject:(AppDefaults *)defaults;
- (NSString *)mailAddress;
- (NSString *)password;
@end


@interface be2chAuthenticator(Invalidate)
- (BOOL)updateAccountAndPasswordIfNeeded:(NSString **)newAccountPtr
								password:(NSString **)newPasswordPtr
					   shouldUseKeychain:(BOOL *)savePassPtr;

- (void)setCookieHeader:(NSString *)str;
- (void)setLastError:(NSError *)err;
@end
