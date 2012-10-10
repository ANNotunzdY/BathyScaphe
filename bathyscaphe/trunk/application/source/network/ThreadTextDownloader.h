//
//  ThreadTextDownloader.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRDownloader.h"

@class CMRThreadSignature;

@interface ThreadTextDownloader : CMRDownloader
{
    @private
    NSUInteger            m_nextIndex;
    NSDictionary        *m_localThreadsDict;
    NSString            *m_threadTitle;
    NSDate  *m_lastDateStore;
}

+ (id)downloaderWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle nextIndex:(NSUInteger)aNextIndex;
- (id)initWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle nextIndex:(NSUInteger)aNextIndex;

- (NSUInteger)nextIndex;
- (void)setNextIndex:(NSUInteger)aNextIndex;

- (NSDate *)lastDate;
- (void)setLastDate:(NSDate *)date;

+ (BOOL)canInitWithURL:(NSURL *)url;
- (NSStringEncoding)encodingForLoadedData;
- (NSString *)contentsWithData:(NSData *)theData;

- (CMRThreadSignature *)threadSignature;
- (NSString *)threadTitle;
- (void)setThreadTitle:(NSString *)title;
- (NSURL *)threadURL;
- (NSDictionary *)localThreadsDict;

// ----------------------------------------
// Partial contents
// ----------------------------------------
- (BOOL)partialContentsRequested;
- (void)cancelDownloadWithInvalidPartial;

- (BOOL)useMaru;

- (CFStringEncoding)CFEncodingForLoadedData;
@end

extern NSString *const ThreadTextDownloaderDidFinishLoadingNotification;
// some messages has been aboned?
extern NSString *const ThreadTextDownloaderInvalidPerticalContentsNotification;

// Available in Starlight Breaker.
extern NSString *const CMRDownloaderUserInfoAdditionalInfoKey;
