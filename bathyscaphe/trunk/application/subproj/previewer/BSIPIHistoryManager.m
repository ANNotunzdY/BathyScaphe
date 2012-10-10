//
//  BSIPIHistoryManager.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/01/12.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIHistoryManager.h"
#import "BSIPIToken.h"
#import <SGFoundation/SGFoundation.h>
#import <SGAppKit/SGAppKit.h>
#import <CocoMonar/CMRSingletonObject.h>
#import "BSIPIDefaults.h"

@implementation BSIPIHistoryManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedManager)	

- (void)dealloc
{
    [_folderNameFormatter release];
	[_historyBacket release];
	[_dlFolderPath release];
	[super dealloc];
}

#pragma mark Key-Value Observing
- (NSUInteger)countOfTokensArray
{
	return [[self tokensArray] count];
}

- (id)objectInTokensArrayAtIndex:(NSUInteger)index
{
	return [[self tokensArray] objectAtIndex:index];
}

- (void)insertObject:(id)anObject inTokensArrayAtIndex:(NSUInteger)index
{
	[[self tokensArray] insertObject:anObject atIndex:index];
}

- (void)removeObjectFromTokensArrayAtIndex:(NSUInteger)index
{
	NSMutableArray	*tokens = [self tokensArray];
	BSIPIToken *aToken = [tokens objectAtIndex:index];

	if ([aToken isDownloading]) {
		[aToken cancelDownload];
	}

	NSString *filePath = [aToken downloadedFilePath];
	if (filePath) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
	}

	[tokens removeObjectAtIndex:index];
}

- (void)replaceObjectInTokensArrayAtIndex:(NSUInteger)index withObject:(id)anObject
{
	[[self tokensArray] replaceObjectAtIndex:index withObject:anObject];
}

- (NSMutableArray *)tokensArray
{
	if (!_historyBacket) {
		_historyBacket = [[NSMutableArray alloc] init];
	}
	return _historyBacket;
}

- (void)setTokensArray:(NSMutableArray *)newArray
{
	[newArray retain];
	[_historyBacket release];
	_historyBacket = newArray;
}

#pragma mark Utilities
- (NSString *)createDlFolder
{
	NSString *path_;
	NSString *appName = [NSBundle applicationName]; // NSBundle-SGExtensions.h
    NSString *tmpFormat = [NSString stringWithFormat:@"%@-XXXXXX", appName];
	NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:tmpFormat];

	char *cTmpDir = strdup([tmpDir fileSystemRepresentation]);

	mkdtemp(cTmpDir);
	path_ = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:cTmpDir length:strlen(cTmpDir)];

	free(cTmpDir);

	return path_;
}

- (NSDateFormatter *)folderNameFormatter
{
    if (!_folderNameFormatter) {
        _folderNameFormatter = [[NSDateFormatter alloc] init];
        [_folderNameFormatter setDateFormat:@"yyyyMMdd"];
    }
    return _folderNameFormatter;
}

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
    [[[BSIPIHistoryManager sharedManager] tokensArray] makeObjectsPerformSelector:@selector(checkDownloadedFileExistence)];
}

- (void)createFSEventStreamIfNeeded:(NSString *)path
{
    if (_currentStreamRef != NULL) {
        BOOL reset = NO;
        CFArrayRef arrayRef = FSEventStreamCopyPathsBeingWatched(_currentStreamRef);
        if (![(NSArray *)arrayRef containsObject:path]) {
            reset = YES;
        }
        CFRelease(arrayRef);
        if (reset) {
            FSEventStreamStop(_currentStreamRef);
            FSEventStreamInvalidate(_currentStreamRef);
            FSEventStreamRelease(_currentStreamRef);
            _currentStreamRef = NULL;
        } else {
            return;
        }
    }
	NSArray *pathsToWatch = [NSArray arrayWithObjects:path, nil];
	void *selfPointer = (void *)self;
	FSEventStreamContext context = {0, selfPointer, NULL, NULL, NULL};
    FSEventStreamRef stream;
    NSTimeInterval latency = 1.0; /* Latency in seconds */
    
    /* Create the stream, passing in a callback */
    stream = FSEventStreamCreate(NULL,
                                 &fsevents_callback,
                                 &context,
                                 (CFArrayRef)pathsToWatch,
                                 kFSEventStreamEventIdSinceNow,
                                 latency,
                                 kFSEventStreamCreateFlagWatchRoot /* Flags explained in reference */
                                 );
    _currentStreamRef = stream;
    
    /* Create the stream before calling this. */
    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
	FSEventStreamStart(stream);
}

- (NSString *)dlDateFolderPath
{
    SGFileRef *baseRef = [SGFileRef fileRefWithPath:[[BSIPIDefaults sharedIPIDefaults] saveDirectory]];
    SGFileRef *subFolderRef = [baseRef fileRefWithChildName:@"BathyScaphe Preview" createDirectory:YES];
    subFolderRef = [subFolderRef fileRefResolvingLinkIfNeeded];
    if (!subFolderRef || ![subFolderRef isDirectory]) {
        return nil;
    }

    if ([[BSIPIDefaults sharedIPIDefaults] tidyUpByDate]) {
        NSString *dateFolderName = [[self folderNameFormatter] stringFromDate:[NSDate date]];
        SGFileRef *dateFolderRef = [subFolderRef fileRefWithChildName:dateFolderName createDirectory:YES];
        dateFolderRef = [dateFolderRef fileRefResolvingLinkIfNeeded];
        
        if (!dateFolderRef || ![dateFolderRef isDirectory]) {
            return nil;
        }
        NSString *path = [dateFolderRef filepath];
        [self createFSEventStreamIfNeeded:path];
        return path;
    } else {
        NSString *path2 = [subFolderRef filepath];
        [self createFSEventStreamIfNeeded:path2];
        return path2;
    }
}

- (NSString *)dlFolderPath
{
	if (!_dlFolderPath) {
		_dlFolderPath = [[self createDlFolder] retain];
	}
	return _dlFolderPath;
}

- (void)flushCache
{
	[self setTokensArray:[NSMutableArray array]];
	
	[[NSFileManager defaultManager] removeItemAtPath:[self dlFolderPath] error:NULL];
	[_dlFolderPath release];
	_dlFolderPath = nil;
}

- (NSArray *)arrayOfURLs
{
	NSMutableArray *tmp = [self tokensArray];
	return ([tmp count] > 0) ? [tmp valueForKey:@"sourceURL"] : nil;
}

- (NSArray *)arrayOfPaths
{
	NSMutableArray *tmp = [self tokensArray];
	return ([tmp count] > 0) ? [tmp valueForKey:@"downloadedFilePath"] : nil;
}

#pragma mark Token Accessors
- (BSIPIToken *)searchCachedTokenBy:(NSArray *)array forKey:(id)key
{
	if (!array || !key) {
        return nil;
    }
	NSUInteger idx = [array indexOfObject:key];
	if (idx == NSNotFound) {
        return nil;
	}
	return [[self tokensArray] objectAtIndex:idx];
}

- (BOOL)isTokenCachedForURL:(NSURL *)anURL
{
	return ([self cachedTokenForURL:anURL] != nil);
}

- (BSIPIToken *)cachedTokenForURL:(NSURL *)anURL
{
	return [self searchCachedTokenBy:[self arrayOfURLs] forKey:anURL];
}

- (BSIPIToken *)cachedTokenAtIndex:(NSUInteger)index
{
	if (index == NSNotFound) {
        return nil;
    }
	return [[self tokensArray] objectAtIndex:index];
}

- (NSUInteger)cachedTokenIndexForURL:(NSURL *)anURL
{
	if (![self arrayOfURLs]) {
		return NSNotFound;
	}
	return [[self arrayOfURLs] indexOfObject:anURL];
}

- (NSArray *)cachedTokensArrayAtIndexes:(NSIndexSet *)indexes
{
	if (!indexes) {
        return nil;
    }
	return [[self tokensArray] objectsAtIndexes:indexes];
}

- (BOOL)cachedTokensArrayContainsNotNullObjectAtIndexes:(NSIndexSet *)indexes
{
	NSArray *tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	
	if (!tokenArray) {
        return NO;
	}
	NSArray *pathArray = [tokenArray valueForKey:@"downloadedFilePath"];
	NSEnumerator *iter_ = [pathArray objectEnumerator];
	NSString *eachPath;

	while (eachPath = [iter_ nextObject]) {
		if (![eachPath isEqual:[NSNull null]]) {
            return YES;
        }
	}
	
	return NO;
}

- (BOOL)cachedTokensArrayContainsDownloadingTokenAtIndexes:(NSIndexSet *)indexes
{
	NSArray *tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	
	if (!tokenArray) {
        return NO;
	}
	NSArray	*boolArray = [tokenArray valueForKey:@"isDownloading"];
	NSEnumerator *iter_ = [boolArray objectEnumerator];
	NSNumber *eachStatus;
	
	while (eachStatus = [iter_ nextObject]) {
		if ([eachStatus boolValue]) {
            return YES;
        }
	}
	
	return NO;
}

- (BOOL)cachedTokensArrayContainsFailedTokenAtIndexes:(NSIndexSet *)indexes
{
	NSArray *tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	if (!tokenArray) {
        return NO;
    }
	NSEnumerator	*iter_ = [tokenArray objectEnumerator];
	BSIPIToken		*eachToken;

	while (eachToken = [iter_ nextObject]) {
		if (![eachToken isDownloading] && ![eachToken isFileExists]) {
            return YES;
        }
	}

	return NO;
}

#pragma mark URL Operations
- (void)openURLForTokenAtIndexes:(NSIndexSet *)indexes inBackground:(BOOL)inBg
{
	NSArray	*tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	
	if (tokenArray) {
		NSArray *urlArray = [tokenArray valueForKey:@"sourceURL"];

		NSWorkspaceLaunchOptions options = NSWorkspaceLaunchDefault;
		if (inBg) {
            options |= NSWorkspaceLaunchWithoutActivation;
        }
		[[NSWorkspace sharedWorkspace] openURLs:urlArray
						withAppBundleIdentifier:nil
										options:options
				 additionalEventParamDescriptor:nil
							  launchIdentifiers:nil];
	}
}

- (void)makeTokensCancelDownloadAtIndexes:(NSIndexSet *)indexes
{
	NSArray	*tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	
	if (tokenArray) {
		[tokenArray makeObjectsPerformSelector:@selector(cancelDownload)];
	}
}

- (void)makeTokensRetryDownloadAtIndexes:(NSIndexSet *)indexes
{
	NSArray *tokenArray = [self cachedTokensArrayAtIndexes:indexes];

	if (tokenArray) {
		[tokenArray makeObjectsPerformSelector:@selector(retryDownload:) withObject:([[BSIPIDefaults sharedIPIDefaults] autoCollectImages] ?
                                                                                     [self dlDateFolderPath] : [self dlFolderPath])];
	}
}

#pragma mark File Operations
- (NSArray *)convertFilePathArrayToURLArray:(NSArray *)pathArray
{
	NSMutableArray	*urlArray = [NSMutableArray array];
	NSEnumerator *iter_ = [pathArray objectEnumerator];
	NSString	*eachPath;

	while (eachPath = [iter_ nextObject]) {
		if ([eachPath isEqual:[NSNull null]]) {
            continue;
		}
		NSURL *url_ = (NSURL *)CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)eachPath, kCFURLPOSIXPathStyle, false);
		[urlArray addObject:url_];

		CFRelease((CFURLRef)url_);
	}

	return urlArray;
}

- (void)openCachedFileForTokenAtIndexesWithPreviewApp:(NSIndexSet *)indexes
{
	NSArray	*tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	
	if (tokenArray) {
		NSArray *pathArray_ = [tokenArray valueForKey:@"downloadedFilePath"];
		NSArray *fileURLArray_ = [self convertFilePathArrayToURLArray:pathArray_];

		if ([fileURLArray_ count] > 0) {
			[[NSWorkspace sharedWorkspace] openURLs:fileURLArray_
							withAppBundleIdentifier:@"com.apple.Preview"
											options:NSWorkspaceLaunchDefault
					 additionalEventParamDescriptor:nil
								  launchIdentifiers:nil];
		}
	}
}

- (void)copyCachedFileForTokenAtIndexes:(NSIndexSet *)indexes intoFolder:(NSString *)folderPath
{
	NSArray	*tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	if (!tokenArray || [tokenArray count] == 0) {
        return;
    }
	NSEnumerator	*iter_ = [tokenArray objectEnumerator];
	BSIPIToken		*eachToken;

	while (eachToken = [iter_ nextObject]) {
		NSString *path = [eachToken downloadedFilePath];
		if (!path) {
            continue;
        }
		NSString *destPath = [folderPath stringByAppendingPathComponent:[path lastPathComponent]];
		[self copyCachedFileForPath:path toPath:destPath];
	}
}

- (BOOL)copyCachedFileForPath:(NSString *)cacheFilePath toPath:(NSString *)copiedFilePath
{
/*	NSFileManager	*fm_ = [NSFileManager defaultManager];
    NSError *error;
    BOOL isDir;

    if ([fm_ fileExistsAtPath:copiedFilePath isDirectory:&isDir]) {
        if (!isDir) {
            BOOL isSameFile = [fm_ contentsEqualAtPath:cacheFilePath andPath:copiedFilePath];
            if (isSameFile) { // コピーしない
                NSLog(@"[BSIPIHistoryManager] Same File Exists; Copy cancelled.\nFrom:%@\n  To:%@", cacheFilePath, copiedFilePath);
                return YES;
            }
        }
    }

    if (![fm_ copyItemAtPath:cacheFilePath toPath:copiedFilePath error:&error]) {
        NSBeep();
        NSLog(@"[BSIPIHistoryManager] Copy failed:\nFrom:%@\n  To:%@", cacheFilePath, copiedFilePath);
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return NO;
    }
	return YES;*/
    OSStatus err;
    
	err = FSPathCopyObjectSync([cacheFilePath fileSystemRepresentation],
                               [[copiedFilePath stringByDeletingLastPathComponent] fileSystemRepresentation],
                               (CFStringRef)[copiedFilePath lastPathComponent],
                               NULL,
                               (kFSFileOperationDefaultOptions|kFSFileOperationOverwrite)
                               );
    
	return (err == noErr);
}

- (void)saveCachedFileForTokenAtIndex:(NSUInteger)index savePanelAttachToWindow:(NSWindow *)aWindow
{
	if (index == NSNotFound) {
        return;
    }
	BSIPIToken	*aToken = [self objectInTokensArrayAtIndex:index];
	NSString	*filePath_ = [aToken downloadedFilePath];
	if (!filePath_) {
        return;
    }
//	NSString	*extension_ = [filePath_ pathExtension];

	NSSavePanel *sP = [NSSavePanel savePanel];
//	[sP setRequiredFileType:([extension_ isEqualToString:@""] ? nil : extension_)];
    [sP setAllowedFileTypes:[NSArray arrayWithObject:[[NSWorkspace sharedWorkspace] typeOfFile:filePath_ error:NULL]]];
    [sP setNameFieldStringValue:[filePath_ lastPathComponent]];
	[sP setAllowsOtherFileTypes:YES];
	[sP setCanCreateDirectories:YES];
	[sP setCanSelectHiddenExtension:YES];

    [sP beginSheetModalForWindow:aWindow completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSString *savePath = [[sP URL] path];
            if ([self copyCachedFileForPath:filePath_ toPath:savePath]) {
                NSDictionary *tmpDict;
                NSNumber *extensionIsHidden = [NSNumber numberWithBool:[sP isExtensionHidden]];
                tmpDict = [NSDictionary dictionaryWithObject:extensionIsHidden forKey:NSFileExtensionHidden];
                [[NSFileManager defaultManager] setAttributes:tmpDict ofItemAtPath:savePath error:NULL];
            }
        }
    }];
/*	[sP beginSheetForDirectory:nil
						  file:[filePath_ lastPathComponent]
				modalForWindow:aWindow
				 modalDelegate:self
				didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
				   contextInfo:[aToken retain]];*/
}

/*- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString *savePath = [sheet filename];
		if ([self copyCachedFileForPath:[(BSIPIToken *)contextInfo downloadedFilePath] toPath:savePath]) {
			NSDictionary *tmpDict;
            NSNumber *extensionIsHidden = [NSNumber numberWithBool:[sheet isExtensionHidden]];
			tmpDict = [NSDictionary dictionaryWithObject:extensionIsHidden forKey:NSFileExtensionHidden];

//			[[NSFileManager defaultManager] changeFileAttributes:tmpDict atPath:savePath];
            [[NSFileManager defaultManager] setAttributes:tmpDict ofItemAtPath:savePath error:NULL];
		}
	}
	[(BSIPIToken *)contextInfo release];
}*/

- (void)revealCachedFileForTokenAtIndexes:(NSIndexSet *)indexes
{
	NSArray	*tokenArray = [self cachedTokensArrayAtIndexes:indexes];
	if (!tokenArray || [tokenArray count] == 0) {
        return;
    }
    NSMutableArray *array = [NSMutableArray array];
    NSFileManager *fm = [NSFileManager defaultManager];
    for (BSIPIToken *token in tokenArray) {
        NSString *path = [token downloadedFilePath];
        if (path && [fm fileExistsAtPath:path]) {
            [array addObject:path];
        }
    }
	if ([array count] > 0) {
        [[NSWorkspace sharedWorkspace] revealFilesInFinder:array];
    }
}

#pragma mark NSTableDataSource
- (NSString *)toolTipStringAtIndex:(NSUInteger)index
{
	NSString *string = [[self cachedTokenAtIndex:index] exifInfoString];
	return string ? string : [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"No Exif data available" value:@"" table:nil];
}

- (BOOL)writeTokensAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard
{
    [pboard clearContents];
    return [pboard writeObjects:[self cachedTokensArrayAtIndexes:indexes]];
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	return [self writeTokensAtIndexes:rowIndexes toPasteboard:pboard];
}
@end
