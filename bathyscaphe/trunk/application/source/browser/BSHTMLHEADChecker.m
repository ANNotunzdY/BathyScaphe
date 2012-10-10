//
//  BSMachiBBSHEADChecker.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/07/18.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSHTMLHEADChecker.h"
#import "CocoMonar_Prefix.h"
#import "CMRHostHTMLHandler.h"
#import "DatabaseManager.h"

NSString *const BSHEADCheckerErrorDomain = @"jp.tsawada2.BathyScaphe.BSHEADChecker";

@implementation BSHTMLHEADChecker
#pragma mark Properties
@synthesize isChecking = m_isChecking;
@synthesize lastError = m_lastError;
@synthesize isUpdated = m_isUpdated;

#pragma mark Instance Methods
- (id)initWithBoardID:(NSUInteger)boardID threadID:(NSString *)threadID count:(NSUInteger)count
{
    if (self = [super init]) {
        // create URL
        NSURL *boardURL = [NSURL URLWithString:[[DatabaseManager defaultManager] urlStringForBoardID:boardID]];
        CMRHostHandler *handler = [CMRHostHandler hostHandlerForURL:boardURL];
        UTILAssertKindOfClass(handler, CMRHostHTMLHandler);
        m_url = [[(CMRHostHTMLHandler *)handler rawmodeURLWithBoard:boardURL
                                                            datName:threadID
                                                              start:count+1
                                                                end:count+1
                                                            nofirst:NO] retain];
    }
    return self;
}

- (void)dealloc
{
    [m_lastError release];
    m_lastError = nil;
    [m_url release];
    [super dealloc];
}

- (void)startChecking
{
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:m_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:15.0];
	[req setValue:[NSBundle monazillaUserAgent] forHTTPHeaderField:@"User-Agent"];
	[req setValue:@"no-cache" forHTTPHeaderField:HTTP_CACHE_CONTROL_KEY];
	[req setValue:@"no-cache" forHTTPHeaderField:HTTP_PRAGMA_KEY];
	[req setValue:@"Close" forHTTPHeaderField:HTTP_CONNECTION_KEY];
	[req setValue:@"text/plain" forHTTPHeaderField:HTTP_ACCEPT_KEY];
	[req setValue:@"ja" forHTTPHeaderField:HTTP_ACCEPT_LANGUAGE_KEY];

    m_isChecking = YES;
    NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    [req release];
    [con autorelease];
}

#pragma mark NSURLConnection Delegate Methods
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	if (!redirectResponse) {
        return request;
    }

	[connection cancel];
	NSDictionary *dict = [NSDictionary dictionaryWithObject:@"Invalid Request" forKey:NSLocalizedDescriptionKey];
	NSError *error = [NSError errorWithDomain:BSHEADCheckerErrorDomain code:[(NSHTTPURLResponse *)redirectResponse statusCode] userInfo:dict];
	m_lastError = [error retain];
	m_isChecking = NO;
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)resp
{
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
//    NSLog(@"check\n%@", [http allHeaderFields]);
	NSInteger status = [http statusCode];

    if (status == 200) {
        NSDictionary *headers = [http allHeaderFields];
        NSString *modified = [headers objectForKey:HTTP_CONTENT_LENGTH_KEY];
        if (!modified) {
            NSString *transferEncoding = [headers objectForKey:HTTP_TRANSFER_ENCODING_KEY];
            m_isUpdated = [transferEncoding isEqualToString:@"Identity"];
        } else {
            m_isUpdated = ![modified isEqualToString:@"0"];
        }
        m_isChecking = NO;
    } else {
        // なんか問題
        NSDictionary *dict = [NSDictionary dictionaryWithObject:@"Invalid Response" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:BSHEADCheckerErrorDomain code:status userInfo:dict];
        m_lastError = [error retain];
        m_isChecking = NO;
    }
    [connection cancel];
}

// 以下、通常は呼ばれないはず
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Do nothing...
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    m_lastError = [error retain];
	m_isChecking = NO;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	m_isChecking = NO;
}
@end
