//
//  BSIPIHistoryManager.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/01/12.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import <CoreServices/CoreServices.h>

@class BSIPIToken;

@interface BSIPIHistoryManager : NSObject {
	NSMutableArray	*_historyBacket;
	NSString		*_dlFolderPath;
    NSDateFormatter *_folderNameFormatter;
    FSEventStreamRef _currentStreamRef;
}

+ (id)sharedManager;

// For Key-Value Observing
- (NSUInteger)countOfTokensArray;
- (id)objectInTokensArrayAtIndex:(NSUInteger)index;
- (void)insertObject:(id)anObject inTokensArrayAtIndex:(NSUInteger)index;
- (void)removeObjectFromTokensArrayAtIndex:(NSUInteger)index;
- (void)replaceObjectInTokensArrayAtIndex:(NSUInteger)index withObject:(id)anObject;

- (NSMutableArray *)tokensArray;
- (void)setTokensArray:(NSMutableArray *)newArray;

- (NSString *)dlFolderPath;
- (NSString *)dlDateFolderPath;

- (NSDateFormatter *)folderNameFormatter;

- (void)flushCache;

- (NSArray *)arrayOfURLs;
- (NSArray *)arrayOfPaths;

- (BOOL)isTokenCachedForURL:(NSURL *)anURL;
- (BSIPIToken *)cachedTokenForURL:(NSURL *)anURL;
- (NSUInteger)cachedTokenIndexForURL:(NSURL *)anURL;
- (NSArray *)cachedTokensArrayAtIndexes:(NSIndexSet *)indexes;

- (BOOL)cachedTokensArrayContainsNotNullObjectAtIndexes:(NSIndexSet *)indexes;
- (BOOL)cachedTokensArrayContainsDownloadingTokenAtIndexes:(NSIndexSet *)indexes;
- (BOOL)cachedTokensArrayContainsFailedTokenAtIndexes:(NSIndexSet *)indexes; // Available in 2.6.1 and later.

- (void)openURLForTokenAtIndexes:(NSIndexSet *)indexes inBackground:(BOOL)inBg;
- (void)makeTokensCancelDownloadAtIndexes:(NSIndexSet *)indexes;
- (void)makeTokensRetryDownloadAtIndexes:(NSIndexSet *)indexes; // Available in 2.6.1 and later.

- (void)openCachedFileForTokenAtIndexesWithPreviewApp:(NSIndexSet *)indexes;
- (void)copyCachedFileForTokenAtIndexes:(NSIndexSet *)indexes intoFolder:(NSString *)folderPath;

- (BOOL)copyCachedFileForPath:(NSString *)cacheFilePath toPath:(NSString *)copiedFilePath;

- (void)saveCachedFileForTokenAtIndex:(NSUInteger)index savePanelAttachToWindow:(NSWindow *)aWindow;

- (void)revealCachedFileForTokenAtIndexes:(NSIndexSet *)indexes; // Available in 3.1 and later.

- (NSString *)toolTipStringAtIndex:(NSUInteger)index;

- (BOOL)writeTokensAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard;
@end
