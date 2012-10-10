//
//  w2chAuthenticator_p.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "w2chAuthenticator.h"
#import "URLConnector_Prefix.h"
#import "SG2chConnector.h"
#import "AppDefaults.h"
#import "LoginController.h"


#define USER_AGENT_WHEN_AUTHENTICATION		@"DOLIB/1.00"
#define APP_HTTP_X_2CH_UA_KEY				@"X-2ch-UA"
#define APP_X2CH_ID_PW_FORMAT				@"ID=%@&PW=%@"


#define APP_AUTHENTICATER_ERR_NW_TITLE		@"ERROR_NETWORK"
#define APP_AUTHENTICATER_ERR_NW_MSG		@"Error_Network"
#define APP_AUTHENTICATER_ERR_LOGIN_TITLE	@"ERROR_LOGIN"
#define APP_AUTHENTICATER_ERR_LOGIN_MSG		@"Error_Couldnt_Login"
#define APP_AUTHENTICATER_ERR_CONNECT_TITLE	@"ERROR_CONNECTION"
#define APP_AUTHENTICATER_ERR_CONNECT_MSG	@"Error_Connection_Fail"


@interface w2chAuthenticator(Invalidate)
- (BOOL)updateAccountAndPasswordIfNeeded:(NSString **)newAccountPtr
								password:(NSString **)newPasswordPtr
					   shouldUseKeychain:(BOOL *)savePassPtr;
- (BOOL)invalidate;
@end
