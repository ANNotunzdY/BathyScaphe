//
//  SG2chConnector.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "w2chConnect.h"


@interface SG2chConnector : NSObject<w2chConnect>
{
	NSURLConnection		*m_connector;
	NSMutableURLRequest *m_req;
	NSMutableData		*m_data;
	NSURLResponse		*m_response;

	id					m_delegate; // We Retain & Release the Delegate!!

    BOOL m_allowsCharRef;
}

+ (id)connectorWithURL:(NSURL *)anURL additionalProperties:(NSDictionary *)properties;
- (id)initWithURL:(NSURL *)anURL additionalProperties:(NSDictionary *)properties;

+ (BOOL)canInitWithURL:(NSURL *)anURL;
+ (NSString *)userAgent;

- (void)setConnector:(NSURLConnection *)aConnector;
- (NSMutableURLRequest *)request;
- (void)setRequest:(NSMutableURLRequest *)aRequest;
- (NSURLResponse *)response;
- (void)setResponse:(NSURLResponse *)response;

- (void)setAvailableResourceData:(NSMutableData *)data;

// zero-terminated list
//+ (const CFStringEncoding *)availableURLEncodings;
+ (const CFStringEncoding)encodingForParameters;
// @"%@=%@&" from dictionary
- (NSString *)parameterWithForm:(NSDictionary *)forms;

//- (NSString *)stringByURLEncodedWithString:(NSString *)str;
//- (NSString *)stringWithDataUsingAvailableURLEncodings:(NSData *)data;
- (NSString *)stringWithDataUsingParametersEncoding:(NSData *)data;
@end
