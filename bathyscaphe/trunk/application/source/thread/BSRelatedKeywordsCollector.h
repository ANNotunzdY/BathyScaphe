//
//  BSRelatedKeywordsCollector.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/02/12.
//  Copyright 2007-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface BSRelatedKeywordsCollector : NSObject {
	id				m_delegate;
	NSMutableData	*m_receivedData;
	NSURL			*m_threadURL;
	NSURLConnection	*m_currentConnection;
	BOOL			m_isInProgress;
}

- (id)initWithThreadURL:(NSURL *)threadURL delegate:(id)aDelegate;
- (void)startCollecting;
- (void)abortCollecting;
- (NSArray *)analyzeKeywordsFromData:(NSData *)data;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;
- (NSURL *)threadURL;
- (void)setThreadURL:(NSURL *)anURL;
- (NSURLConnection *)currentConnection;
- (void)setCurrentConnection:(NSURLConnection *)con;
- (NSMutableData *)receivedData;
- (BOOL)isInProgress;
@end


@interface NSObject(BSRelativeKeywordsCollectorAdditions)
- (void)collector:(BSRelatedKeywordsCollector *)aCollector didCollectKeywords:(NSArray *)keywordsDict;
- (void)collector:(BSRelatedKeywordsCollector *)aCollector didFailWithError:(NSError *)error;
@end

extern NSString *const BSRelatedKeywordsCollectionKeywordStringKey;
extern NSString *const BSRelatedKeywordsCollectionKeywordURLKey;
