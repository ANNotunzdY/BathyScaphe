//
//  SG2chConnector.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SG2chConnector_p.h"

// for debugging only
#define UTIL_DEBUGGING      1
#import "UTILDebugging.h"

@implementation SG2chConnector
+ (Class *)classClusters
{
    static Class classes[3] = {Nil, };
    
    if (Nil == classes[0]) {
        classes[0] = [(id)[w2chReply_2ch class] retain];
        classes[1] = [(id)[w2chReply_shita class] retain];
        classes[2] = Nil;
    }
    
    return classes;
}

+ (id)connectorWithURL:(NSURL *)anURL additionalProperties:(NSDictionary *)properties
{
    return [[[[self class] alloc] initWithURL:anURL additionalProperties:properties] autorelease];
}

- (id)initClusterWithURL:(NSURL *)anURL additionalProperties:(NSDictionary *)properties
{
    if (self = [super init]) {
        NSMutableURLRequest *req;
        NSMutableDictionary *headers_;

        req = [[NSMutableURLRequest alloc] initWithURL:anURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
        [req setHTTPMethod:HTTP_METHOD_POST];
        [req setHTTPShouldHandleCookies:NO];
        [self setRequest:req];
        [req release];

        headers_ = [[self requestHeaders] mutableCopy];
        [headers_ addEntriesFromDictionary:properties];
        
        if (![self isRequestHeadersComplete:headers_]) {
            [headers_ release];
            headers_ = nil;
            [self release];
            return nil;
        }

        [[self request] setAllHTTPHeaderFields:headers_];

        [headers_ release];
        headers_ = nil;

        [self setAllowsCharRef:YES];
    }
    return self;
}

- (id)initWithURL:(NSURL *)anURL additionalProperties:(NSDictionary *)properties
{
    Class           *p;
    SG2chConnector  *messenger_ = nil;
    
    for (p = [[self class] classClusters]; *p != Nil; p++) {
        if ([*p canInitWithURL:anURL]) {
            messenger_ = [[*p alloc] initClusterWithURL:anURL additionalProperties:properties];
            break;
        }
    }
    // 対応するクラスがない場合も利便性を優先して、
    // デフォルトで 2ch のものを返す。
    if (!messenger_) {
        messenger_ = [[w2chReply_2ch alloc] initClusterWithURL:anURL additionalProperties:properties];
    }

    [self release];
    return messenger_;
}

- (void)dealloc
{
    [m_data release];
    [m_response release];
    [m_req release];
    [m_connector release];
    [m_delegate release];
    [super dealloc];
}

+ (BOOL)canInitWithURL:(NSURL *)anURL
{
    Class           *p;
    
    for (p = [self classClusters]; *p != Nil; p++) {
        if ([*p canInitWithURL:anURL])
            return YES;
    }
    // 対応するクラスがない場合も利便性を優先して、
    // デフォルトで 2ch のものを返す。
    return YES;
}

+ (NSString *)userAgent
{
    return [NSBundle monazillaUserAgent];
}

- (void)loadInBackground
{
    NSURLConnection *con;
    con = [[NSURLConnection alloc] initWithRequest:[self request] delegate:self];
    [self setConnector:con];
    [con release];
}

#pragma mark Form, Encodings
- (BOOL)writeForm:(NSDictionary *)forms
{
    NSString        *params_;
    NSString        *length_;
    NSData          *selialized_;
    NSMutableURLRequest *req = [self request];
    
    if (!forms || [forms count] == 0) return NO;
    
    params_ = [self parameterWithForm:forms];
    if (!params_) return NO;

    UTILMethodLog;
    UTILDescription([self requestURL]);
    UTILDescription([[self requestURL] absoluteString]);
    UTILDescription(params_);

    // すでにURLエンコードされていることを期待
    selialized_ = [params_ dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//    length_ = [[NSNumber numberWithInteger:[selialized_ length]] stringValue];
    length_ = [NSString stringWithFormat:@"%lu", (unsigned long)[selialized_ length]];
    if (!selialized_ || !length_) return NO;
    
    [req setValue:HTTP_CONTENT_URL_ENCODED_TYPE forHTTPHeaderField:HTTP_CONTENT_TYPE_KEY];
    [req setValue:length_ forHTTPHeaderField:HTTP_CONTENT_LENGTH_KEY];
    [req setHTTPBody:selialized_];
    return YES;
}

+ (const CFStringEncoding)encodingForParameters
{
    UTILAbstractMethodInvoked;
    return kCFStringEncodingDOSJapanese;
}

- (NSString *)stringWithDataUsingParametersEncoding:(NSData *)data
{
    const CFStringEncoding enc = [[self class] encodingForParameters];
    return [NSString stringWithData:data encoding:CF2NSEncoding(enc)];
}

static void addErrorDescriptionForKey(NSString *key, NSMutableDictionary *dict)
{
    if ([key isEqualToString:@"FROM"]) {
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorMsgName", nil, nil) forKey:NSLocalizedDescriptionKey];
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorSuggestion2", nil, nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
    } else if ([key isEqualToString:@"mail"]) {
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorMsgMail", nil, nil) forKey:NSLocalizedDescriptionKey];
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorSuggestion2", nil, nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
    } else if ([key isEqualToString:@"MESSAGE"]) {
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorMsgBody", nil, nil) forKey:NSLocalizedDescriptionKey];
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorSuggestion2", nil, nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
    } else if ([key isEqualToString:@"subject"]) {
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorMsgSubject", nil, nil) forKey:NSLocalizedDescriptionKey];
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorSuggestion2", nil, nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
    } else {
// #warning 64BIT: Check formatting arguments
// 2010-03-22 tsawada2 検討済
        [dict setObject:[NSString stringWithFormat:PluginLocalizedStringFromTable(@"URLEncodingErrorUnknown", nil, nil), key] forKey:NSLocalizedDescriptionKey];
        [dict setObject:PluginLocalizedStringFromTable(@"URLEncodingErrorSuggestion", nil, nil) forKey:NSLocalizedRecoverySuggestionErrorKey];
    }

    [dict setObject:key forKey:BS2chConnectFailedParameterNameErrorKey];
}

- (NSString *)parameterWithForm:(NSDictionary *)forms
{
    NSMutableString *params_;
    NSEnumerator    *iter_;
    NSString        *key_;
    const CFStringEncoding enc = [[self class] encodingForParameters];
    
    if (!forms || [forms count] == 0) return nil;
    
    params_ = [NSMutableString string];
    iter_ = [forms keyEnumerator];
    while (key_ = [iter_ nextObject]) {
        NSString        *value_ = nil;
        NSString        *encoded_ = nil;
        NSIndexSet      *indexes_ = nil;
        
        value_ = [forms objectForKey:key_];
        UTILAssertKindOfClass(value_, NSString);
        // hoge
        NSMutableString *tmp = [NSMutableString stringWithString:value_];
        CFStringNormalize((CFMutableStringRef)tmp, kCFStringNormalizationFormC);

//        encoded_ = [value_ stringByURIEncodedUsingCFEncoding:enc convertToCharRefIfNeeded:[self allowsCharRef] unableToEncode:&indexes_];
        encoded_ = [tmp stringByURIEncodedUsingCFEncoding:enc convertToCharRefIfNeeded:[self allowsCharRef] unableToEncode:&indexes_];
        if (!encoded_) {
            id delegate_ = [self delegate];
            if (delegate_ && [delegate_ respondsToSelector:@selector(connector:didFailURLEncoding:)]) {
                NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                addErrorDescriptionForKey(key_, userInfo);
                if (indexes_) {
                    [userInfo setObject:indexes_ forKey:BS2chConnectInvalidCharIndexSetErrorKey];
                }
                [userInfo setObject:[NSNumber numberWithUnsignedInteger:enc] forKey:BS2chConnectCFStringEncodingErrorKey];
                NSError *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BS2chConnectDidFailURLEncodingError userInfo:userInfo];
                [delegate_ connector:self didFailURLEncoding:error];
            }
            return nil;
        }
        
        [params_ appendFormat:@"%@=%@&", key_, encoded_];
    }

    if ([params_ length] > 0) {
        [params_ deleteCharactersInRange:NSMakeRange([params_ length]-1, 1)];
    }
    return params_;
}

#pragma mark Accessors
- (NSURLConnection *)connector
{
    return m_connector;
}

- (void)setConnector:(NSURLConnection *)aConnector
{
    [aConnector retain];
    [m_connector release];
    m_connector = aConnector;
}

- (NSMutableURLRequest *)request
{
    return m_req;
}

- (void)setRequest:(NSMutableURLRequest *)aRequest
{
    [aRequest retain];
    [m_req release];
    m_req = aRequest;
}

- (NSURLResponse *)response
{
    return m_response;
}

- (void)setResponse:(NSURLResponse *)response
{
    [response retain];
    [m_response release];
    m_response = response;
}

- (id)delegate
{
    return m_delegate;
}

- (void)setDelegate:(id)newDelegate
{
    [newDelegate retain];
    [m_delegate release];
    m_delegate = newDelegate;
}

- (NSMutableData *)availableResourceData
{
    if (!m_data) {
        m_data = [[NSMutableData alloc] init];
    }
    return m_data;
}

- (void)setAvailableResourceData:(NSMutableData *)data
{
    [data retain];
    [m_data release];
    m_data = data;
}

- (NSURL *)requestURL
{
    return [[self request] URL];
}

- (BOOL)allowsCharRef
{
    return m_allowsCharRef;
}

- (void)setAllowsCharRef:(BOOL)flag
{
    m_allowsCharRef = flag;
}

#pragma mark NSURLConnection Delegate
// Leopard 対策
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if (!redirectResponse) {
        return request;
    }
    if ([(NSHTTPURLResponse *)redirectResponse statusCode] == 302) {
        // 「書き込みました。」の遷移
//      [connection cancel];
        if ([self delegate] && [[self delegate] respondsToSelector:@selector(connectorResourceDidFinishLoading:)]) {
            [[self delegate] connectorResourceDidFinishLoading:self];
        }
        return nil;
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self setResponse:response];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id<w2chErrorHandling>   handler_;
    NSString                *contents_;
    NSError                 *error_;
    SEL                     delegateSEL = NULL;
    BOOL    hoge;

    contents_ = [self stringWithDataUsingParametersEncoding:[self availableResourceData]];

    // Error handling
    handler_ = [SG2chErrorHandler handlerWithURL:[self requestURL]];
    error_ = [handler_ handleErrorWithContents:contents_];
    hoge = (handler_ && [[error_ domain] isEqualToString:SG2chErrorHandlerErrorDomain] && [error_ code] != k2chNoneErrorType);
    delegateSEL =  hoge ? @selector(connector:resourceDidFailLoadingWithErrorHandler:)
                        : @selector(connectorResourceDidFinishLoading:);

    if (![self delegate]) return;
    if (![[self delegate] respondsToSelector:delegateSEL]) return;
    
    if (hoge) {
        [[self delegate] connector:self resourceDidFailLoadingWithErrorHandler:handler_];
    } else { 
        [[self delegate] connectorResourceDidFinishLoading:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self availableResourceData] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    id delegate_ = [self delegate];
    if (delegate_ && [delegate_ respondsToSelector:@selector(connector:resourceDidFailLoadingWithError:)]) {
        [delegate_ connector:self resourceDidFailLoadingWithError:error];
    }
}
@end


@implementation SG2chConnector(RequestHeaders)
- (NSDictionary *)requestHeaders
{
    UTILAbstractMethodInvoked;
    return nil;
}
- (BOOL)isRequestHeadersComplete:(NSDictionary *)headers
{
    UTILAbstractMethodInvoked;
    return NO;
}
@end
