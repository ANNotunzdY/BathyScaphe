//
//  BSIPIToken.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/11/26.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSURLDownload;

@interface BSIPIToken : NSObject<NSPasteboardWriting> {
	@private
	NSURL		*ipit_sourceURL;
	NSString	*ipit_downloadedFilePath;
	NSImage		*ipit_thumbnail;
	NSString	*ipit_statusMsg;
	NSString	*ipit_exifInfoStr;
	BSURLDownload	*ipit_curDownload;
	
	NSUInteger	ipit_contentSize;
	NSUInteger  ipit_downloadedSize;
	BOOL		shouldIndeterminate;
}

- (id)initWithURL:(NSURL *)anURL destination:(NSString *)aPath;

- (NSURL *)sourceURL;
- (void)setSourceURL:(NSURL *)anURL;
- (NSString *)downloadedFilePath;
- (void)setDownloadedFilePath:(NSString *)aString;
- (NSImage *)thumbnail;
- (void)setThumbnail:(NSImage *)anImage;
- (NSString *)statusMessage;
- (void)setStatusMessage:(NSString *)aString;
- (NSString *)exifInfoString;
- (void)setExifInfoString:(NSString *)aString;

- (BSURLDownload *)currentDownload;

- (BOOL)isFileExists;
- (BOOL)isDownloading;

- (NSUInteger)contentSize;
- (NSUInteger)downloadedSize;

- (void)cancelDownload;
- (void)retryDownload:(id)destination; // Available in 2.6.1 and later.
@end

extern NSString *const BSIPITokenDownloadErrorNotification;
extern NSString *const BSIPITokenDownloadDidFinishNotification;
