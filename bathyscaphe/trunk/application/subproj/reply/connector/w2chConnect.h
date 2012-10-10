//
//  w2chConnect.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/15.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

// Error Handling
// 対応表はReplyErrorCode.plistを参照
enum {
	k2chNoneErrorType 				= 0,		// 正常
	k2chEmptyDataErrorType			= 1,		// データなし
	k2chAnyErrorType				= 2,		// ＥＲＲＯＲ！
	k2chContributionCheckErrorType	= 3,		// 投稿確認

	k2chRequireNameErrorType		= 4,		// 名前いれてちょ
	k2chRequireContentsErrorType	= 5,		// 本文がありません。
	k2chSPIDCookieErrorType			= 6,		// クッキー確認！
	k2chDoubleWritingErrorType		= 7,		// 二重書き込み
	k2chWarningType					= 8,		// 注意事項
	k2chUnknownErrorType,
    // 以下のエラーは、タイトルでなく本文の内容で判定する
    k2chNinjaFirstAlertType         =11,        // 冒険の書を作成しています。引き返すなら今だ。Available in BathyScaphe 2.0.2 and later.

    k2chBeLoginErrorType            =21,        // Beユーザー情報エラー。ログインしなおしてください Available in BathyScaphe 2.0.2 and later.
};

// w2chAuthenticator
//エラーの種類
enum {
	w2chNoError = 0,			// エラーなし
	w2chNetworkError,			// サーバがエラーを返した
	w2chLoginError,				// 認証エラー
	w2chConnectionError,		// 接続時のエラー
	w2chLoginCanceled,			// ユーザによるキャンセル
	w2chLoginParamsInvalid,		// IDかPassが空
};
typedef NSUInteger w2chAuthenticatorErrorType;


@protocol w2chConnect<NSObject>
- (NSURLConnection *)connector;

- (NSURLResponse *)response;
- (void)setResponse:(NSURLResponse *)response;

- (NSURL *)requestURL;

- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (NSMutableData *)availableResourceData;

- (void)loadInBackground;

- (BOOL)writeForm:(NSDictionary *)forms;

- (BOOL)allowsCharRef;
- (void)setAllowsCharRef:(BOOL)flag;
@end

//Error Handling
@protocol w2chErrorHandling<NSObject>
- (NSURL *)requestURL;
- (NSError *)recentError;

- (NSDictionary *)additionalFormsData;
- (void)setAdditionalFormsData:(NSDictionary *)anAdditionalFormsData;

- (NSError *)handleErrorWithContents:(NSString *)contents;
@end

// w2chAuthenticator
@protocol w2chAuthenticationStatus
- (NSString *)sessionID;

- (NSInteger)recentStatusCode;
- (void)setRecentStatusCode:(NSInteger)aRecentStatusCode;

- (w2chAuthenticatorErrorType)recentErrorType;
- (void)setRecentErrorType:(w2chAuthenticatorErrorType)aRecentErrorType;
@end

// be2chAuthenticator
@protocol be2chAuthenticationStatus
- (BOOL)invalidate;
- (NSString *)cookieHeader;
- (NSError *)lastError;
@end

// Delegate
@interface NSObject(w2chConnectDelegate)
- (void)connector:(id<w2chConnect>)sender didFailURLEncoding:(NSError *)error;

- (void)connectorResourceDidCancelLoading:(id<w2chConnect>)sender;
- (void)connectorResourceDidFinishLoading:(id<w2chConnect>)sender;
  
- (void)connector:(id<w2chConnect>)sender resourceDidFailLoadingWithError:(NSError *)error;
- (void)connector:(id<w2chConnect>)sender resourceDidFailLoadingWithErrorHandler:(id<w2chErrorHandling>)handler;
@end

// NSError code enum
enum {
    BS2chConnectDidFailURLEncodingError = 5001,
    BS2chConnectLoginUserCanceledError = 5128,
    BSBe2chLoginParamInvalidError = 5501,
    BSBe2chLoginServerStatusCodeError = 5502,
    BSBe2chLoginServerFailedError = 5503,
    BSBe2chLoginNSURLConnectionError = 5504,
    BSBe2chLoginUnknownError = 5599,
};

// NSError domain constant
#define SG2chErrorHandlerErrorDomain	@"SG2chErrorHandlerErrorDomain"

// NSError userInfo constants
#define SG2chErrorTitleErrorKey		@"SG2chErrorHandler_Title"
#define SG2chErrorMessageErrorKey	@"SG2chErrorHandler_Message"
#define BS2chConnectFailedParameterNameErrorKey  @"bs_failedParameterName" // NSString
#define BS2chConnectInvalidCharIndexSetErrorKey  @"bs_invalidCharIndexSet" // NSIndexSet
#define BS2chConnectCFStringEncodingErrorKey    @"bs_CFStringEncoding" // NSNumber as CFStringEncoding
