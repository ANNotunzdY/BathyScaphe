//
//  w2chAuthenticator.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "w2chConnect.h"

@class AppDefaults;

@interface w2chAuthenticator : NSObject<w2chAuthenticationStatus>
{
	NSString *m_sessionID;
	NSInteger m_recentStatusCode;
	w2chAuthenticatorErrorType m_recentErrorType;
@private
	NSDate *m_lastLoggedInDate;
}

+ (id)defaultAuthenticator;

- (BOOL)runModalForLoginWindow:(NSString **)accountPtr password:(NSString **)passwordPtr shouldUsesKeychain:(BOOL *)savePassPtr;

/**
  * 認証サーバにログインする。
  * 
  * @param    userID     ユーザID
  * @param    password   パスワード
  * @param    userAgent  認証されたUser-Agent
  * @param    sid        認証されたID
  * @return              認証に成功した場合はYES
  */
- (BOOL)login:(NSString *)userID password:(NSString *)password userAgent:(NSString **)userAgent sessionID:(NSString **)sid;

+ (AppDefaults *)preferences;
- (AppDefaults *)preferences;
+ (void)setPreferencesObject:(AppDefaults *)defaults;
- (NSString *)account;
- (NSString *)password;
@end

#define k2chAuthSessionIDKey	@"sid"
