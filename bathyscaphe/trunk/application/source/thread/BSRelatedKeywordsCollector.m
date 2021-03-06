//
//  BSRelativeKeywordsCollector.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/02/12.
//  Copyright 2007-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSRelatedKeywordsCollector.h"
//#import <OgreKit/OgreKit.h>
#import <CocoMonar_Prefix.h>
#import <CocoaOniguruma/OnigRegexp.h>

NSString *const BSRelatedKeywordsCollectionKeywordStringKey = @"BSRKC_STR";
NSString *const BSRelatedKeywordsCollectionKeywordURLKey = @"BSRKC_URL";
//NSString *const BSRelativeKeywordsCollectorErrorDomain = @"BSRelativeKeywordsCollectorErrorDomain";

static NSString *const kBSRelativeKeywordsCollectorCgiURLKey = @"System - relatedKeywords URL";

@implementation BSRelatedKeywordsCollector
static NSString				*g_cgiURLString = nil;
//static OGRegularExpression	*g_regExp = nil;
static OnigRegexp *g_regExp2 = nil;

#pragma mark Accessors
- (id) delegate
{
	return m_delegate;
}
- (void) setDelegate: (id) aDelegate
{
	m_delegate = aDelegate;
}
- (NSURL *) threadURL
{
	return m_threadURL;
}
- (void) setThreadURL: (NSURL *) anURL
{
	[anURL retain];
	[m_threadURL release];
	m_threadURL = anURL;
}
- (NSMutableData *) receivedData
{
	return m_receivedData;
}
- (NSURLConnection *) currentConnection
{
	return m_currentConnection;
}
- (void) setCurrentConnection: (NSURLConnection *) con
{
	[con retain];
	[m_currentConnection release];
	m_currentConnection = con;
}
- (BOOL) isInProgress
{
	return m_isInProgress;
}
- (void) setIsInProgress: (BOOL) boolValue
{
	m_isInProgress = boolValue;
}

#pragma mark Public Methods
- (id) initWithThreadURL: (NSURL *) threadURL delegate: (id) aDelegate
{
	self = [super init];
	if (self != nil) {
		m_delegate = aDelegate;
		m_threadURL = [threadURL retain];
		m_receivedData = [[NSMutableData alloc] init];
		m_currentConnection = nil;
		m_isInProgress = NO;
	}
	return self;
}

- (void) startCollecting
{
    NSMutableURLRequest	*req;
    NSURLConnection		*connection;
	NSString			*strValue;
	NSURL				*convertedURL;

	if ([self threadURL] == nil) return;
	strValue = [[self threadURL] absoluteString];
	convertedURL = [NSURL URLWithString: [NSString stringWithFormat: g_cgiURLString, strValue]];

    req = [NSMutableURLRequest requestWithURL: convertedURL
                                  cachePolicy: NSURLRequestReloadIgnoringCacheData
                              timeoutInterval: 15.0];
    
	[req setValue: [NSBundle monazillaUserAgent] forHTTPHeaderField: @"User-Agent"];

	connection = [[NSURLConnection alloc] initWithRequest: req delegate: self];
    [self setCurrentConnection: connection];
	[connection release];
}

- (void) abortCollecting
{
	if ([self currentConnection] == nil) return;

	[[self currentConnection] cancel];
	[self setCurrentConnection: nil];
	[self setIsInProgress: NO];

	[m_receivedData release];
	m_receivedData = nil;
	m_receivedData = [[NSMutableData alloc] init];
}

- (NSArray *) analyzeKeywordsFromData: (NSData *) data
{
	NSString *str;
	NSMutableString *ampStr;
//	NSEnumerator *iter_;
	NSMutableArray	*result_;
	NSString *url_;
	NSString *name_;
//	OGRegularExpressionMatch *match;
    OnigResult *match;

	str = [NSString stringWithDataUsingTEC: data encoding: kCFStringEncodingDOSJapanese];
	if (!str) return nil;
	ampStr = [[str mutableCopy] autorelease];
	[ampStr replaceOccurrencesOfString: @"&amp;" withString: @"&" options: NSLiteralSearch range: NSMakeRange(0, [ampStr length])];

	result_ = [NSMutableArray array];
			
//	iter_ = [g_regExp matchEnumeratorInString: ampStr];

    int start = 0;
    int length = [ampStr length];
    while (start < length) {
        match = [g_regExp2 search:ampStr start:start];
        if (match) {
            url_ = [match stringAt:1];
            name_ = [match stringAt:2];
            [result_ addObject:[NSDictionary dictionaryWithObjectsAndKeys:url_, BSRelatedKeywordsCollectionKeywordURLKey,
																		name_, BSRelatedKeywordsCollectionKeywordStringKey, NULL]];
            start = NSMaxRange([match bodyRange]);
        } else {
            break;
        }
    }

//	while (match = [iter_ nextObject]) {
//		url_ = [match substringAtIndex:1];
//		name_ = [match substringAtIndex:2];
//		
//		[result_ addObject: [NSDictionary dictionaryWithObjectsAndKeys: url_, BSRelatedKeywordsCollectionKeywordURLKey,
//																		name_, BSRelatedKeywordsCollectionKeywordStringKey, NULL]];
//	}

	return result_;
}

#pragma mark Override
+ (void) initialize
{
	if (self == [BSRelatedKeywordsCollector class]) {
		g_cgiURLString = SGTemplateResource(kBSRelativeKeywordsCollectorCgiURLKey);
//		g_regExp = [[OGRegularExpression alloc] initWithString: @"<a href=\"(.*)\".*>(.*)</a>"];
        g_regExp2 = [[OnigRegexp compile:@"<a href=\"(.*)\".*>(.*)</a>"] retain];
	}
}

- (id) init
{
	return [self initWithThreadURL: nil delegate: nil];
}

- (void) dealloc
{
	[m_currentConnection cancel];
	[m_currentConnection release];
	[m_receivedData release];
	[m_threadURL release];
	m_delegate = nil;
	[super dealloc];
}

#pragma mark NSURLConnection Delegates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)resp
{
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
	int status = [http statusCode];

    switch (status) {
    case 200:
        break;
    default:
		[connection cancel];
		[self setCurrentConnection:nil];
		[self setIsInProgress:NO];

		id delegate_ = [self delegate];
		if (delegate_ && [delegate_ respondsToSelector:@selector(collector:didFailWithError:)]) {
//			NSError *error = [NSError errorWithDomain: BSRelativeKeywordsCollectorErrorDomain code: status userInfo: nil];
            NSError *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSRelatedKeywordsCollectorInvalidResponseError userInfo:nil];
			[delegate_ collector:self didFailWithError:error];
		}

        break;
    }
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data
{
    [[self receivedData] appendData: data];
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error
{
	[m_receivedData release];
	m_receivedData = nil;
	m_receivedData = [[NSMutableData alloc] init];

	[self setCurrentConnection: nil];
	[self setIsInProgress: NO];

	id delegate_ = [self delegate];
	if (delegate_ && [delegate_ respondsToSelector: @selector(collector:didFailWithError:)]) {
		[delegate_ collector: self didFailWithError: error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	id delegate_ = [self delegate];
	SEL delegateSelector;
	id keywordsDict = [self analyzeKeywordsFromData:[self receivedData]];
	[m_receivedData release];
	m_receivedData = nil;
	m_receivedData = [[NSMutableData alloc] init];

	[self setCurrentConnection:nil];
	[self setIsInProgress:NO];
	
	if ([keywordsDict isKindOfClass:[NSArray class]]) {
		delegateSelector = @selector(collector:didCollectKeywords:);
	} else {
		delegateSelector = @selector(collector:didFailWithError:);
//		keywordsDict = [NSError errorWithDomain: BSRelativeKeywordsCollectorErrorDomain code: -1 userInfo: nil];
        keywordsDict = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSRelatedKeywordsCollectorDidFailParsingError userInfo:nil];
	}

	if (delegate_ && [delegate_ respondsToSelector:delegateSelector]) {
		[delegate_ performSelector:delegateSelector withObject:self withObject:keywordsDict];
	}
}
@end
