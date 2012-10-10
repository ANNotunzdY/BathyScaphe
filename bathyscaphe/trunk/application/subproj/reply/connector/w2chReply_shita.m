//
//  w2chReply_shita.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/17.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "w2chReply_shita.h"
#import "SG2chConnector_p.h"

@implementation w2chReply_shita(RequestHeaders)
- (NSDictionary *)requestHeaders
{
    UTILAssertNotNil([self requestURL]);
    return [NSDictionary dictionaryWithObjectsAndKeys:
                    [[self requestURL] host],       HTTP_HOST_KEY,
                    @"close",                       HTTP_CONNECTION_KEY,
                    @"text/html, text/plain, */*",  HTTP_ACCEPT_KEY,
                    @"shift_jis, x-euc-jp",         HTTP_ACCEPT_CHARSET_KEY,
                    [[self class] userAgent],       HTTP_USER_AGENT_KEY,
                    @"NAME=; EMAIL=; Path=/",       HTTP_COOKIE_HEADER_KEY,
                    nil];
}

- (BOOL)isRequestHeadersComplete:(NSDictionary *)headers
{
    UTILAssertNotNil([headers objectForKey:HTTP_REFERER_KEY]);
    return YES;
}
@end


@implementation w2chReply_shita
+ (BOOL)canInitWithURL:(NSURL *)anURL
{
    NSString    *filename_;
    const char  *host_;
    
    if (!anURL) {
        return NO;  
    }
    filename_ = [[anURL absoluteString] lastPathComponent];
    host_ = [[anURL host] UTF8String];
    if (!filename_ || NULL == host_) {
        return NO;
    }

    if (is_jbbs_livedoor(host_)) {
        return [filename_ isEqualToString:@"write.cgi"];
    }
    
    return NO;
}

+ (const CFStringEncoding)encodingForParameters
{
    return kCFStringEncodingEUC_JP;
}
@end
