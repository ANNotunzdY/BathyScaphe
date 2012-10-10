//
//  be2chAuthenticator.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/01/13.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//

#import "be2chAuthenticator.h"
#import "w2chAuthenticator_p.h"

static AppDefaults *st_defaults = nil;

@implementation be2chAuthenticator
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultAuthenticator)

- (id)init
{
	if (self = [super init]) {
        [self setLastError:nil];
	}
	return self;
}

- (void)dealloc
{
    [self setLastError:nil];
	[self setCookieHeader:nil];
	[super dealloc];
}

- (BOOL)runModalForLoginWindow:(NSString **)mailAddressPtr password:(NSString **)passwordPtr shouldUseKeychain:(BOOL *)savePassPtr
{
	NSString			*account_;
	NSString			*password_;
	LoginController		*lgin_;
	BOOL				result_;
	
	if (mailAddressPtr != NULL) *mailAddressPtr = nil;
	if (passwordPtr != NULL) *passwordPtr = nil;
    
	lgin_ = [[LoginController alloc] initWithType:BSKeychainAccountBe2chAuth];
	result_ = [lgin_ runModalForLoginWindow:&account_ password:&password_ shouldUseKeychain:savePassPtr];
	[lgin_ release];
	
	if (!result_) {
        [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BS2chConnectLoginUserCanceledError userInfo:nil]];
		return NO;
	}
    
	UTILRequireCondition((account_ && [account_ length]), error_params_invalid);
	UTILRequireCondition((password_ && [password_ length]), error_params_invalid);
	
	if (mailAddressPtr != NULL) *mailAddressPtr = account_;
	if (![self mailAddress] && account_) {
        [[self preferences] setBe2chAccountMailAddress:account_];
    }
	if (passwordPtr != NULL) *passwordPtr = password_;
	return YES;
	
  error_params_invalid:
  {
    [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginParamInvalidError userInfo:nil]];
    return NO;
  }
}

- (NSData *)postingDataWithID:(NSString *)userID password:(NSString *)password
{
	NSString *forms_;		//Form形式
	
	if (!userID || !password) {
        [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginParamInvalidError userInfo:nil]];
        return NO;
    }

	forms_ = [NSString stringWithFormat:[[self preferences] be2chAuthenticationFormFormat], userID, password];
	return [forms_ dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP)];
}

- (BOOL)login:(NSString *)mailAddress password:(NSString *)password setCookieHeader:(NSString **)header
{
	NSURL				*requestURL_;		//認証用CGI
	NSMutableURLRequest *request_;
	NSURLResponse		*returningResponse_;
    NSError *connectionError;
    
	NSData				*pst_data_;			//送信するデータ
	NSData				*resource_;			//サーバの返した内容(data)
	NSInteger					statusCode_;
	
	UTILMethodLog;
	
	UTILDescription(mailAddress);
	UTILDescription(password);
	
	if (header != NULL) *header = nil;

	if (!mailAddress || !password) {
        [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginParamInvalidError userInfo:nil]];
		return NO;
	}
	
	requestURL_ = [[self preferences] be2chAuthenticationRequestURL];
	request_ = [NSMutableURLRequest requestWithURL:requestURL_ cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	[request_ setHTTPMethod:HTTP_METHOD_POST];
	[request_ setHTTPShouldHandleCookies:NO];
    
	//リクエストヘッダの設定
	pst_data_ = [self postingDataWithID:mailAddress password:password];    
	[request_ setValue:@"close" forHTTPHeaderField:HTTP_CONNECTION_KEY];
	[request_ setValue:[requestURL_ host] forHTTPHeaderField:HTTP_HOST_KEY];
//	[request_ setValue:USER_AGENT_WHEN_AUTHENTICATION forHTTPHeaderField:HTTP_USER_AGENT_KEY];
//	[request_ setValue:[NSBundle applicationUserAgent] forHTTPHeaderField:APP_HTTP_X_2CH_UA_KEY];
	[request_ setValue:HTTP_CONTENT_URL_ENCODED_TYPE forHTTPHeaderField:HTTP_CONTENT_TYPE_KEY];
	[request_ setValue:[[NSNumber numberWithInteger:[pst_data_ length]] stringValue] forHTTPHeaderField:HTTP_CONTENT_LENGTH_KEY];
	[request_ setHTTPBody:pst_data_];

    connectionError = nil;

	resource_ = [NSURLConnection sendSynchronousRequest:request_ returningResponse:&returningResponse_ error:&connectionError];
	
	if (!resource_) {
		if (connectionError) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:connectionError forKey:NSUnderlyingErrorKey];
            [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginNSURLConnectionError userInfo:userInfo]];
        } else {
            [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginUnknownError userInfo:nil]];
        }

		return NO;
	}	
    
	UTILDebugWrite1(@"\n%@", [returningResponse_ description]);
	UTILDebugWrite1(@"\n%@", [(NSHTTPURLResponse *)returningResponse_ allHeaderFields]);
	
	statusCode_ = [(NSHTTPURLResponse *)returningResponse_ statusCode];

	if ((statusCode_ != 200) && (statusCode_ != 206)) {
		[self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginServerStatusCodeError userInfo:nil]];
		return NO;
	}

    id foo = [[(NSHTTPURLResponse *)returningResponse_ allHeaderFields] objectForKey:HTTP_SET_COOKIE_HEADER_KEY];

    if (!foo) {
        NSString *contents_;
        contents_ = [[[NSString alloc] initWithData:resource_ encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP)] autorelease];
        if (contents_ && ([contents_ length] > 0)) {
            NSDictionary *userInfo2 = [NSDictionary dictionaryWithObject:contents_ forKey:NSLocalizedDescriptionKey];
            [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginServerFailedError userInfo:userInfo2]];
        } else {
            [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginUnknownError userInfo:nil]];
        }

        return NO;
    }

    if (header != NULL) *header = foo;
    return YES;
}

- (BOOL)invalidate
{
	NSString	*account_;
	NSString	*pw_;
	NSString	*cookie_;
	BOOL		result_;
	BOOL		usesKeychain_;
    
    [self setLastError:nil];
	[self setCookieHeader:nil];
	
	if (![self updateAccountAndPasswordIfNeeded:&account_ password:&pw_ shouldUseKeychain:&usesKeychain_]) {
		return NO;
	}
	
	UTILRequireCondition((account_ && [account_ length]), error_params_invalid);
	UTILRequireCondition((pw_ && [pw_ length]), error_params_invalid);
	
	result_ = [self login:account_ password:pw_ setCookieHeader:&cookie_];
    
	if (result_) {
		[self setCookieHeader:cookie_];
		if (usesKeychain_) {
            [[self preferences] changeAccount:account_ password:pw_ forType:BSKeychainAccountBe2chAuth];
        }
	} else {
        if (![self lastError]) {
            [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginUnknownError userInfo:nil]];
        }
	}
	
	return result_;
    
error_params_invalid:
    {
        [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BSBe2chLoginParamInvalidError userInfo:nil]];
        return NO;
    }
}

#pragma mark Preferences
+ (AppDefaults *)preferences
{
	return st_defaults;
}

- (AppDefaults *)preferences
{
	return [[self class] preferences];
}

+ (void)setPreferencesObject:(AppDefaults *)defaults
{
	st_defaults = defaults;
}

- (NSString *)mailAddress
{
	return [[[self class] preferences] be2chAccountMailAddress];
}

- (NSString *)password
{
	return [[[self class] preferences] passwordForType:BSKeychainAccountBe2chAuth];
}

#pragma mark Accessors
- (NSString *)cookieHeader
{
	return m_header;
}

- (NSError *)lastError
{
    return m_lastError;
}
@end


@implementation be2chAuthenticator(Invalidate)
- (BOOL)updateAccountAndPasswordIfNeeded:(NSString **)newAccountPtr
								password:(NSString **)newPasswordPtr
					   shouldUseKeychain:(BOOL *)savePassPtr
{	
	if ([self mailAddress] && [[self preferences] hasAccountInKeychain:BSKeychainAccountBe2chAuth]) {
		if (newAccountPtr != NULL) *newAccountPtr = [self mailAddress];
		if (newPasswordPtr != NULL) *newPasswordPtr = [self password];
		if (savePassPtr != NULL) *savePassPtr = NO;
		return YES;
	} else {
		return [self runModalForLoginWindow:newAccountPtr password:newPasswordPtr shouldUseKeychain:savePassPtr];
	}
}

- (void)setCookieHeader:(NSString *)str
{
    [str retain];
    [m_header release];
    m_header = str;
}

- (void)setLastError:(NSError *)err
{
    [err retain];
    [m_lastError release];
    m_lastError = err;
}
@end
