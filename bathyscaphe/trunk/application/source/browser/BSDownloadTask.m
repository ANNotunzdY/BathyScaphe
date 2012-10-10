//
//  BSDownloadTask.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/06.
//  Copyright 2006-2009,2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSDownloadTask.h"

NSString *const BSDownloadTaskFinishDownloadNotification = @"BSDownloadTaskFinishDownloadNotification";
NSString *const BSDownloadTaskReceiveResponseNotification = @"BSDownloadTaskReceiveResponseNotification";
NSString *const BSDownloadTaskCanceledNotification = @"BSDownloadTaskCanceledNotification";
NSString *const BSDownloadTaskInternalErrorNotification = @"BSDownloadTaskInternalErrorNotification";
NSString *const BSDownloadTaskAbortDownloadNotification = @"BSDownloadTaskAbortDownloadNotification";
NSString *const BSDownloadTaskServerResponseKey = @"BSDownloadTaskServerResponseKey"; // NSURLResponse
NSString *const BSDownloadTaskStatusCodeKey = @"BSDownloadTaskStatusCodeKey"; // NSNumber (int)
NSString *const BSDownloadTaskFailDownloadNotification = @"BSDownloadTaskFailDownloadNotification";
NSString *const BSDownloadTaskErrorObjectKey = @"BSDownloadTaskErrorObjectKey"; // NSError

@interface BSDownloadTask ()
// re-declare override Writability
@property (readwrite, copy) NSString *message;

@property CGFloat currentLength;
@property CGFloat contLength;
@property (retain) id response;
@end

@implementation BSDownloadTask
// message property implementation in BSThreadListTask
@dynamic message;

@synthesize URL = m_targetURL;
@synthesize currentLength = m_currentLength;
@synthesize contLength = m_contLength;
@synthesize response = _response;

+ (id)taskWithURL:(NSURL *)url
{
	return [[[self alloc] initWithURL:url] autorelease];
}

- (id)initWithURL:(NSURL *)url
{
	if(self = [super init]) {
		if(!url) {
			[self release];
			return nil;
		}
		self.URL = url;
		self.isInProgress = YES;
        m_contLengthIsUnknown = YES;
	}
	
	return self;
}

+ (id)taskWithURL:(NSURL *)url method:(NSString *)method
{
	return [[[self alloc] initWithURL:url method:method] autorelease];
}

- (id)initWithURL:(NSURL *)url method:(NSString *)inMethod
{
	if(self = [self initWithURL:url]) {
		method = [inMethod retain];
	}
	
	return self;
}

- (void)dealloc
{
	[m_targetURL release];
	[con release];
	[receivedData release];
	[method release];
	[_response release];
	
	[super dealloc];
}

#pragma mark Accessors

- (NSData *)receivedData
{
	return receivedData;
}


#pragma mark Overrides
- (void)excute
{
	[self synchronousDownLoad];
}
- (void)synchronousDownLoad
{
	NSRunLoop *loop = [NSRunLoop currentRunLoop];
		
	[receivedData release];
	receivedData = nil;
	self.currentLength = 0;
	self.contLength = 0;
	self.amount = -1;
	self.message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Download url(%@)", @"Downloader", @""), [self.URL absoluteString]];

	NSMutableURLRequest *request;
	
	request = [NSMutableURLRequest requestWithURL:self.URL];
	if (!request) {
		[self postNotificationWithName:BSDownloadTaskInternalErrorNotification userInfo:nil];
		return;
	}
	[request setValue:[NSBundle monazillaUserAgent] forHTTPHeaderField:@"User-Agent"];
	if (method) {
		[request setHTTPMethod:method];
	}

	con = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (!con) {
		[self postNotificationWithName:BSDownloadTaskInternalErrorNotification userInfo:nil];
		return;
	}
	
	while (self.isInProgress) {
		id pool = [[NSAutoreleasePool alloc] init];
		[loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		[pool release];
	}
}

#pragma mark CMRTask
- (void)cancel:(id)sender
{
	[con cancel];
	[self postNotificationWithName:BSDownloadTaskCanceledNotification userInfo:nil];

	[super cancel:sender];
}

- (NSString *)title
{
	return NSLocalizedStringFromTable(@"Download.", @"Downloader", @"");
}

@end


@implementation BSDownloadTask(NSURLConnectionDelegate)
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
{
	// Leopard
	if (!response) {
		return request;
	}
	self.response = response;
	[self postNotificaionWithResponse:response];
	[connection cancel];
	return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	BOOL disconnect = NO;
	
	self.response = response;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
        NSLog(@"** USER DEBUG **\n%@", [(NSHTTPURLResponse *)response allHeaderFields]);
	}
	switch ([(NSHTTPURLResponse *)response statusCode]) {
		case 200:
		case 206:
			break;
		case 304:
			NSLog(@"Content is not modified.");
			disconnect = YES;
			break;
		case 404:
			NSLog(@"Content has not found.");
			disconnect = YES;
			break;
		case 416:
			NSLog(@"Range is mismatch.");
			disconnect = YES;
			break;
		default:
			NSLog(@"Unknown error.");
			disconnect = YES;
			break;
	}
	if (disconnect) {
		[connection cancel];
		[self postNotificaionWithResponse:response];
		
		return;
	}
	
//	[self postNotificaionWithResponseDontFinish:response]; // 2009-03-24 今は誰も受け取っていないので発行を休止中。
    CGFloat length = [response expectedContentLength];
    if (length <= 0) {
        CGFloat assumedLength = [[[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Length"] doubleValue];
        if (assumedLength > 0) {
			self.contLength = assumedLength*1.7; // gzip 圧縮を考慮、適当
            m_contLengthIsUnknown = NO;
        }
    } else {
        m_contLengthIsUnknown = NO;
		self.contLength = length;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (!receivedData) {
		receivedData = [[NSMutableData alloc] init];
	}

	if (!receivedData) {
		// abort
		[connection cancel];
		[self postNotificationWithName:BSDownloadTaskInternalErrorNotification userInfo:nil];
		
		return;
	}
	
	[receivedData appendData:data];
	self.currentLength = [receivedData length];

	if (!m_contLengthIsUnknown && (self.contLength > 0)) {
		CGFloat bar = self.currentLength/self.contLength*100.0;
		self.amount = bar;
		self.message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Download url(%@) (%.0fk of %.0fk)", @"Downloader", @""),
						[self.URL absoluteString], (CGFloat)self.currentLength/1024, (CGFloat)self.contLength/1024];
    } else {
		self.message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Download url(%@) (%.0fk)", @"Downloader", @""),
						[self.URL absoluteString], (CGFloat)self.currentLength/1024];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self postNotificationWithName:BSDownloadTaskFinishDownloadNotification userInfo:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// abort
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:BSDownloadTaskErrorObjectKey];
    [self postNotificationWithName:BSDownloadTaskFailDownloadNotification userInfo:userInfo];
	self.isInProgress = NO;
}
@end


@implementation BSDownloadTask(TaskNotification)
- (void)postNotificationWithName:(NSString *)name userInfo:(NSDictionary *)info
{
	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:info];
	self.isInProgress = NO;
}

- (void)postNotificaionWithResponse:(NSURLResponse *)response
{
	NSDictionary			*info;
	
	info = [NSDictionary dictionaryWithObjectsAndKeys:response, BSDownloadTaskServerResponseKey,
					[NSNumber numberWithInteger:[(NSHTTPURLResponse *)response statusCode]], BSDownloadTaskStatusCodeKey,
					NULL];
    [self postNotificationWithName:BSDownloadTaskAbortDownloadNotification userInfo:info];
}

- (void)postNotificaionWithResponseDontFinish:(NSURLResponse *)response
{
	NSDictionary			*info;
	
	info = [NSDictionary dictionaryWithObjectsAndKeys:response, BSDownloadTaskServerResponseKey,
					[NSNumber numberWithInteger:[(NSHTTPURLResponse *)response statusCode]], BSDownloadTaskStatusCodeKey,
					NULL];
    [self postNotificationWithName:BSDownloadTaskReceiveResponseNotification userInfo:info];
}
@end
