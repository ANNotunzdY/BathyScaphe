//
//  w2chReply_2ch.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/17.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "w2chReply_2ch.h"
#import "SG2chConnector_p.h"

@implementation w2chReply_2ch
+ (BOOL)canInitWithURL:(NSURL *)anURL
{
    const char  *host_;
    NSString    *cgiName_;
    
    host_ = [[anURL host] UTF8String];
    if (NULL == host_) {
        return NO;
    }

    cgiName_ = [[anURL absoluteString] lastPathComponent];
    if (can_readcgi(host_)) {
        return [cgiName_ isEqualToString:@"bbs.cgi"];
    }
    if (is_machi(host_)) {
        return [cgiName_ isEqualToString:@"write.cgi"];
    }

    return NO;
}

+ (const CFStringEncoding)encodingForParameters
{
    return kCFStringEncodingDOSJapanese;
}

// 認証が必要な場合もある
- (BOOL)writeForm:(NSDictionary *)forms
{
    NSString    *sessionID_ = [[w2chAuthenticator defaultAuthenticator] sessionID];

    if (sessionID_) {
        NSMutableDictionary *params_ = [[forms mutableCopy] autorelease];
        [params_ setObject:sessionID_ forKey:k2chAuthSessionIDKey];
        return [super writeForm:params_];
    } else if ([[w2chAuthenticator defaultAuthenticator] recentErrorType] != w2chNoError) {
        return NO;
    }
    
    return [super writeForm:forms];
}
@end


@implementation w2chReply_2ch(RequestHeaders)
- (NSDictionary *)requestHeaders
{
    UTILAssertNotNil([self requestURL]);
    return [NSDictionary dictionaryWithObjectsAndKeys:
                    [[self requestURL] host],       HTTP_HOST_KEY,
                    @"close",                       HTTP_CONNECTION_KEY,
                    @"text/html, text/plain, */*",  HTTP_ACCEPT_KEY,
                    @"shift_jis",                   HTTP_ACCEPT_CHARSET_KEY,
                    [[self class] userAgent],       HTTP_USER_AGENT_KEY,
                    @"NAME=; Path=/",               HTTP_COOKIE_HEADER_KEY,
                    NULL];
}

- (BOOL)isRequestHeadersComplete:(NSDictionary *)headers
{
    UTILAssertNotNil([headers objectForKey:HTTP_REFERER_KEY]);
    UTILAssertNotNil([headers objectForKey:HTTP_COOKIE_HEADER_KEY]);

    return YES;
}
@end
