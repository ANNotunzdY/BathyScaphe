//
//  CMRKeychainManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/01/13.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRKeychainManager.h"
#import "CocoMonar_Prefix.h"
#import "AppDefaults.h"
#import <AppKit/NSApplication.h>
#import <Security/Security.h>

@implementation CMRKeychainManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

#pragma mark Accessors
- (BOOL)shouldCheckHasAccountInKeychain
{
    return m_shouldCheckHasAccountInKeychain;
}
- (void)setShouldCheckHasAccountInKeychain:(BOOL)flag
{
    m_shouldCheckHasAccountInKeychain = flag;
}

- (NSURL *)x2chAuthenticationRequestURL
{
    return [CMRPref x2chAuthenticationRequestURL];
}

- (NSURL *)be2chAuthenticationRequestURL
{
    return [CMRPref be2chAuthenticationRequestURL];
}

- (NSString *)x2chUserAccount
{
    return [CMRPref x2chUserAccount];
}

- (NSString *)be2chAccountMailAddress
{
    return [CMRPref be2chAccountMailAddress];
}

#pragma mark Public Methods
- (id)init
{
    if (self = [super init]) {
        [self setShouldCheckHasAccountInKeychain:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:NSApp];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)checkHasAccountInKeychainImpl:(BSKeychainAccountType)type
{
    BOOL result_ = NO;
    NSString *account_;
    NSURL *url_;
    SecProtocolType protocolType;
    if (type == BSKeychainAccountX2chAuth) {
        account_ = [self x2chUserAccount];
        url_ = [self x2chAuthenticationRequestURL];
        protocolType = kSecProtocolTypeHTTPS;
    } else if (type == BSKeychainAccountBe2chAuth) {
        account_ = [self be2chAccountMailAddress];
        url_ = [self be2chAuthenticationRequestURL];
        protocolType = kSecProtocolTypeHTTP;
    } else {
        return;
    }
    
    if (account_ && url_) {
        OSStatus err;
        SecKeychainItemRef item = nil;        
        NSString    *host_ = [url_ host];
        NSString    *path_ = [url_ path];

        const char  *accountUTF8 = [account_ UTF8String];
        const char  *hostUTF8 = [host_ UTF8String];
        const char  *pathUTF8 = [path_ UTF8String];

        err = SecKeychainFindInternetPassword(NULL,
                                              strlen(hostUTF8),
                                              hostUTF8,
                                              0,
                                              NULL,
                                              strlen(accountUTF8),
                                              accountUTF8,
                                              strlen(pathUTF8),
                                              pathUTF8,
                                              0,
                                              protocolType,
                                              kSecAuthenticationTypeDefault,
                                              NULL,
                                              NULL,
                                              &item);

        if (err == noErr) {
            CFRelease(item);
            result_ = YES;
        }
    }

    [CMRPref setHasAccountInKeychain:result_ forType:type];
}    

- (void)checkHasAccountInKeychainIfNeeded
{
    if ([self shouldCheckHasAccountInKeychain]) {
        [self checkHasAccountInKeychainImpl:BSKeychainAccountX2chAuth];
        [self checkHasAccountInKeychainImpl:BSKeychainAccountBe2chAuth];
        [self setShouldCheckHasAccountInKeychain:NO];
    }
}

- (NSString *)passwordFromKeychain:(BSKeychainAccountType)type
{
    NSString *account_;
    NSURL *url_;
    SecProtocolType protocolType;
    if (type == BSKeychainAccountX2chAuth) {
        account_ = [self x2chUserAccount];
        url_ = [self x2chAuthenticationRequestURL];
        protocolType = kSecProtocolTypeHTTPS;
    } else if (type == BSKeychainAccountBe2chAuth) {
        account_ = [self be2chAccountMailAddress];
        url_ = [self be2chAuthenticationRequestURL];
        protocolType = kSecProtocolTypeHTTP;
    } else {
        return nil;
    }

    if (account_ && url_) {
        OSStatus err;
        NSString        *host_ = [url_ host];
        NSString        *path_ = [url_ path];

        const char      *accountUTF8 = [account_ UTF8String];
        const char      *hostUTF8 = [host_ UTF8String];
        const char      *pathUTF8 = [path_ UTF8String];
        char *passwordData;
        UInt32 passwordLength;
        
        NSString *result_;

        err = SecKeychainFindInternetPassword(NULL,
                                              strlen(hostUTF8),
                                              hostUTF8,
                                              0,
                                              NULL,
                                              strlen(accountUTF8),
                                              accountUTF8,
                                              strlen(pathUTF8),
                                              pathUTF8,
                                              0,
                                              protocolType,
                                              kSecAuthenticationTypeDefault,
                                              &passwordLength,
                                              (void **)&passwordData,
                                              NULL);

        if (err == noErr) {
            result_ = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
            SecKeychainItemFreeContent(NULL, passwordData);
            return [result_ autorelease];
        }
    }
    return nil;
}

- (BOOL)createKeychainWithPassword:(NSString *)password forType:(BSKeychainAccountType)type
{
    NSString *account_;
    NSURL *url_;
    SecProtocolType protocolType;
    if (type == BSKeychainAccountX2chAuth) {
        account_ = [self x2chUserAccount];
        url_ = [self x2chAuthenticationRequestURL];
        protocolType = kSecProtocolTypeHTTPS;
    } else if (type == BSKeychainAccountBe2chAuth) {
        account_ = [self be2chAccountMailAddress];
        url_ = [self be2chAuthenticationRequestURL];
        protocolType = kSecProtocolTypeHTTP;
    } else {
        return NO;
    }
    
    if (!account_ || !url_) {
        return NO;
    }

    OSStatus err;

    NSString        *host_ = [url_ host];
    NSString        *path_ = [url_ path];

    const char      *accountUTF8 = [account_ UTF8String];
    const char      *hostUTF8 = [host_ UTF8String];
    const char      *pathUTF8 = [path_ UTF8String];
    const char      *passwordUTF8 = [password UTF8String];

    err = SecKeychainAddInternetPassword(NULL,
                                         strlen(hostUTF8),
                                         hostUTF8,
                                         0,
                                         NULL,
                                         strlen(accountUTF8),
                                         accountUTF8,
                                         strlen(pathUTF8),
                                         pathUTF8,
                                         0,
                                         protocolType,
                                         kSecAuthenticationTypeDefault,
                                         strlen(passwordUTF8),
                                         passwordUTF8,
                                         NULL);
 
    if (err == noErr) {
        [CMRPref setHasAccountInKeychain:YES forType:type];
        return YES;
    } else if (err == errSecDuplicateItem) {
        SecKeychainItemRef item = nil;
        err = SecKeychainFindInternetPassword(NULL,
                                              strlen(hostUTF8),
                                              hostUTF8,
                                              0,
                                              NULL,
                                              strlen(accountUTF8),
                                              accountUTF8,
                                              strlen(pathUTF8),
                                              pathUTF8,
                                              0,
                                              protocolType,
                                              kSecAuthenticationTypeDefault,
                                              NULL,
                                              NULL,
                                              &item);

        if (err == noErr) {
            err = SecKeychainItemModifyContent(item, NULL, strlen(passwordUTF8), passwordUTF8);
            if (err == noErr) {
                [CMRPref setHasAccountInKeychain:YES forType:type];
                CFRelease(item);
                return YES;
            }
            CFRelease(item);
        }
    }
    return NO;
}

#pragma mark Notifications
- (void)applicationDidBecomeActive:(NSNotification *)theNotification
{
    UTILAssertNotificationName(theNotification, NSApplicationDidBecomeActiveNotification);
    UTILAssertNotificationObject(theNotification, NSApp);

    [self setShouldCheckHasAccountInKeychain:YES];
}
@end
