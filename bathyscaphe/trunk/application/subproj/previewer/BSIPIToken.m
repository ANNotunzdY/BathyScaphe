//
//  BSIPIToken.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/11/26.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIToken.h"
#import <SGFoundation/UKXattrMetadataStore.h>
#import <SGAppKit/NSWorkspace-SGExtensions.h>
#import "NSImage+QuickLook.h"

NSString *const BSIPITokenDownloadErrorNotification = @"jp.tsawada2.BathyScaphe.ImagePreviewer.BSIPITokenDownloadErrorNotification";
NSString *const BSIPITokenDownloadDidFinishNotification = @"jp.tsawada2.BathyScaphe.ImagePreviewer.BSIPITokenDownloadDidFinishNotification";

@interface BSIPIToken(Private)
+ (NSImage *)loadingIndicator;
- (BOOL)createThumbnailAndCalcImgSizeForPath:(NSString *)filePath;
- (NSString *)localizedStrForKey:(NSString *)key;
@end


@implementation BSIPIToken(Private)
+ (NSImage *)loadingIndicator
{
	static NSImage *loadingImage = nil;
	if (!loadingImage) {
		NSBundle *bundle_ = [NSBundle bundleForClass:self];
		NSString *filepath_ = [bundle_ pathForImageResource:@"IPILoading"];

		loadingImage = [[NSImage alloc] initWithContentsOfFile:filepath_];
	}
	return loadingImage;
}

- (NSString *)createExifInfoStringFromMetaData:(NSDictionary *)dict
{
	NSDictionary *exifDict;
	exifDict = [dict objectForKey:(NSString *)kCGImagePropertyExifDictionary];
    if (!exifDict) {
        return nil;
    }

    CFMutableStringRef infoString = CFStringCreateMutable(kCFAllocatorDefault, 0);
    NSString *dateTimeStr;
    NSString *exposureTimeStr;

    dateTimeStr = [exifDict objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal];
    if (dateTimeStr) {
        CFStringAppend(infoString, (CFStringRef)dateTimeStr);
    }

    NSNumber *focalLengthObj = [exifDict objectForKey:(NSString *)kCGImagePropertyExifFocalLength];
    if (focalLengthObj) {
        CFStringAppend(infoString, CFSTR(", "));
        CFStringAppend(infoString, (CFStringRef)[focalLengthObj stringValue]);
        CFStringAppend(infoString, CFSTR("mm"));
    }

    NSNumber *fNumberObj = [exifDict objectForKey:(NSString *)kCGImagePropertyExifFNumber];
    if (fNumberObj) {
        CFStringAppend(infoString, CFSTR(", F"));
        CFStringAppend(infoString, (CFStringRef)[fNumberObj stringValue]);
    }

    NSNumber *exposureTimeObj = (NSNumber *)[exifDict objectForKey:(NSString *)kCGImagePropertyExifExposureTime];
    if (exposureTimeObj) {
        exposureTimeStr = [NSString stringWithFormat:@"1/%.0f", (1/[exposureTimeObj doubleValue])];
        CFStringAppend(infoString, CFSTR(", "));
        CFStringAppend(infoString, (CFStringRef)exposureTimeStr);
    }
    
    NSArray *isoSpeedObj = [exifDict objectForKey:(NSString *)kCGImagePropertyExifISOSpeedRatings];
    if (isoSpeedObj && [isoSpeedObj count] > 0) {
        CFStringAppend(infoString, CFSTR(", ISO"));
        CFStringAppend(infoString, (CFStringRef)[[isoSpeedObj objectAtIndex:0] stringValue]);
    }
    
    NSDictionary *tiffDict;
	tiffDict = [dict objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
    
    if (tiffDict) {
        CFMutableStringRef cameraNameStr;
        CFStringRef cameraMakerStr;
        cameraNameStr = (CFMutableStringRef)[[[tiffDict objectForKey:(NSString *)kCGImagePropertyTIFFModel] mutableCopy] autorelease];
        if (cameraNameStr) {
            CFStringTrimWhitespace(cameraNameStr);
            CFStringAppend(infoString, CFSTR(", "));
            CFStringAppend(infoString, (CFMutableStringRef)cameraNameStr);
        }

        cameraMakerStr = (CFStringRef)[tiffDict objectForKey:(NSString *)kCGImagePropertyTIFFMake];
        if (cameraMakerStr) {
            CFStringAppend(infoString, CFSTR(", "));
            CFStringAppend(infoString, cameraMakerStr);
        }
    }

    return [(NSString *)infoString autorelease];
}

- (BOOL)createThumbnailAndCalcImgSizeForPath:(NSString *)filePath
{
    if ([[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL] fileSize] == 0) {
        [self setStatusMessage:[self localizedStrForKey:@"Zero size File"]];
        [self setThumbnail:[[NSWorkspace sharedWorkspace] systemIconForType:kQuestionMarkIcon]];
        return NO;
    }
    CGImageSourceRef cgImageSource = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:filePath], NULL);
    if (CGImageSourceGetStatus(cgImageSource) != kCGImageStatusComplete) {
        CFRelease(cgImageSource);
        [self setStatusMessage:[self localizedStrForKey:@"Can't get imageRep"]];
        [self setThumbnail:[[NSWorkspace sharedWorkspace] systemIconForType:kQuestionMarkIcon]];
        return NO;
    }
    [self setThumbnail:nil];

    CFStringRef uti = CGImageSourceGetType(cgImageSource);
    if (UTTypeConformsTo(uti, kUTTypePDF)) {
        // PDF...
        NSInteger pageCount = CGImageSourceGetCount(cgImageSource);
        [self setStatusMessage:[NSString stringWithFormat:[self localizedStrForKey:@"%ld pages"], (long)pageCount]];
        [self setThumbnail:[[NSWorkspace sharedWorkspace] iconForFile:filePath]];
    } else if (UTTypeConformsTo(uti, kUTTypeImage)) {
        // Image...
        NSDictionary *metaDataDict;
        CGFloat width;
        CGFloat height;
        metaDataDict = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(cgImageSource, 0, NULL);
        if (metaDataDict) {
            NSNumber *w = [metaDataDict objectForKey:(NSString *)kCGImagePropertyPixelWidth];
            NSNumber *h = [metaDataDict objectForKey:(NSString *)kCGImagePropertyPixelHeight];
            [self setExifInfoString:[self createExifInfoStringFromMetaData:metaDataDict]];

            CFRelease((CFDictionaryRef)metaDataDict);
            width = [w floatValue];
            height = [h floatValue];
        } else {
            width = 0;
            height = 0;
        }

        // ここではまだサムネイルを set せず、-thumbnail が呼ばれたときに生成する。（See -thumbnail）
        [self setStatusMessage:[NSString stringWithFormat:[self localizedStrForKey:@"%.0f*%.0f pixel"], width, height]];
        
    } else {
        // Unknown...
        CFStringRef utiDescRef = UTTypeCopyDescription(uti);
        [self setStatusMessage:(NSString *)utiDescRef];
        CFRelease(utiDescRef);
        [self setThumbnail:[[NSWorkspace sharedWorkspace] iconForFile:filePath]];
    }
    CFRelease(cgImageSource);

    // Appending Metadata
    NSArray *plist = [NSArray arrayWithObject:[[self sourceURL] absoluteString]];
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
    [UKXattrMetadataStore setData:data forKey:@"com.apple.metadata:kMDItemWhereFroms" atPath:filePath traverseLink:NO];

    return YES;
}


- (NSString *)localizedStrForKey:(NSString *)key
{
	NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
	return [selfBundle localizedStringForKey:key value:key table:nil];
}
@end


@implementation BSIPIToken
- (id)initWithURL:(NSURL *)anURL destination:(NSString *)aPath
{
	if (self = [super init]) {
		ipit_curDownload = [[BSURLDownload alloc] initWithURL:anURL delegate:self destination:aPath];
		if (!ipit_curDownload) {
            return nil;
        }
//        [ipit_curDownload setAllowsOverwriteDownloadedFile:YES]; // Since 3.1 Auto-Collecting Mode 対策

		[self setSourceURL:anURL];
		[self setThumbnail:[[self class] loadingIndicator]];
		[self setStatusMessage:[self localizedStrForKey:@"Start Downloading..."]];
		ipit_downloadedSize = 0;
		ipit_contentSize = 0;
		shouldIndeterminate = YES;
	}
	return self;
}

- (void)dealloc
{
	[ipit_curDownload release];
	[ipit_statusMsg release];
	[ipit_thumbnail release];
	[ipit_downloadedFilePath release];
	[ipit_sourceURL release];
    [ipit_exifInfoStr release];
	[super dealloc];
}

- (NSURL *)sourceURL
{
	return ipit_sourceURL;
}

- (void)setSourceURL:(NSURL *)anURL
{
	[anURL retain];
	[ipit_sourceURL release];
	ipit_sourceURL = anURL;
}

// Since 3.1 Auto-Collecting Mode: ダウンロードされたファイルが移動されたり勝手に削除されているかもしれないので対策
- (void)checkDownloadedFileExistence
{
    if (![self downloadedFilePath]) {
        return;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:ipit_downloadedFilePath]) {
        [self setDownloadedFilePath:nil];
        [self setThumbnail:[[NSWorkspace sharedWorkspace] systemIconForType:kQuestionMarkIcon]];
		[self setStatusMessage:[self localizedStrForKey:@"Missing File"]];
    }
}

- (NSString *)downloadedFilePath
{
	return ipit_downloadedFilePath;
}

- (void)setDownloadedFilePath:(NSString *)aString
{
	[aString retain];
	[ipit_downloadedFilePath release];
	ipit_downloadedFilePath = aString;
}

- (NSImage *)thumbnail
{
    if (!ipit_thumbnail) {
        ipit_thumbnail = [[NSImage imageWithPreviewOfFileAtPath:[self downloadedFilePath] ofSize:NSMakeSize(64, 36) asIcon:NO] retain];
    }
	return ipit_thumbnail;
}

- (void)setThumbnail:(NSImage *)anImage
{
	[anImage retain];
	[ipit_thumbnail release];
	ipit_thumbnail = anImage;
}

- (NSString *)statusMessage
{
	return ipit_statusMsg;
}

- (void)setStatusMessage:(NSString *)aString
{
	[aString retain];
	[ipit_statusMsg release];
	ipit_statusMsg = aString;
}

- (NSString *)exifInfoString
{
	return ipit_exifInfoStr;
}

- (void)setExifInfoString:(NSString *)aString
{
	[aString retain];
	[ipit_exifInfoStr release];
	ipit_exifInfoStr = aString;
}

- (BSURLDownload *)currentDownload
{
	return ipit_curDownload;
}

- (void)setCurrentDownload:(BSURLDownload *)aDownload
{
	[self willChangeValueForKey:@"isDownloading"];
	[aDownload retain];
	[ipit_curDownload release];
	ipit_curDownload = aDownload;
	[self didChangeValueForKey:@"isDownloading"];
}

- (BOOL)isFileExists
{
	return ([self downloadedFilePath] != nil);
}

- (BOOL)isDownloading
{
	return ([self currentDownload] != nil);
}

- (void)postErrorNotification:(BOOL)flag
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:flag] forKey:@"forceLeaving"];
	[[NSNotificationCenter defaultCenter] postNotificationName:BSIPITokenDownloadErrorNotification object:self userInfo:userInfo];
}

- (void)cancelDownload
{
	BSURLDownload *curDl = [self currentDownload];
	if (curDl) {
		[[self currentDownload] cancel];
        [[self currentDownload] setDelegate:nil];
		[self setCurrentDownload:nil];
		[self setThumbnail:[[NSWorkspace sharedWorkspace] systemIconForType:kQuestionMarkIcon]];
		[self setStatusMessage:[self localizedStrForKey:@"Download Canceled"]];
		[self postErrorNotification:NO];
	}
}

- (void)retryDownload:(id)destination
{
	if ([self currentDownload]) return;

    BSURLDownload *download = [[BSURLDownload alloc] initWithURL:[self sourceURL] delegate:self destination:destination];
    if ([self downloadedFilePath] && [[NSFileManager defaultManager] fileExistsAtPath:[self downloadedFilePath]]) {
        [download setAllowsOverwriteDownloadedFile:YES];
    }
	[self setCurrentDownload:download];
    [download release];
	[self setThumbnail:[[self class] loadingIndicator]];
	[self setStatusMessage:[self localizedStrForKey:@"Start Downloading..."]];
	ipit_downloadedSize = 0;
	ipit_contentSize = 0;
	shouldIndeterminate = YES;
}

- (NSUInteger)contentSize
{
	return ipit_contentSize;
}

- (NSUInteger)downloadedSize
{
	return ipit_downloadedSize;
}

#pragma mark BSURLDownload Delegates
- (BOOL)bsURLDownload:(BSURLDownload *)download shouldDownloadWithMIMEType:(NSString *)type
{
    static NSArray *abortTypes = nil;
    if (!abortTypes) {
        abortTypes = [[NSArray alloc] initWithObjects:@"text/html", @"application/xhtml+xml", nil];
    }
    return ![abortTypes containsObject:type];
}

- (void)bsURLDownloadDidAbortForDenyingResponsedMIMEType:(BSURLDownload *)download
{
	[self setThumbnail:[[NSWorkspace sharedWorkspace] systemIconForType:kQuestionMarkIcon]];
	[self setCurrentDownload:nil];
	[self setStatusMessage:[self localizedStrForKey:@"MIME type Mismatch"]];
	[self postErrorNotification:YES];
}

- (void)bsURLDownload:(BSURLDownload *)aDownload willDownloadContentOfSize:(NSUInteger)expectedLength
{
	[self setStatusMessage:[self localizedStrForKey:@"Downloading..."]];
	[self willChangeValueForKey:@"shouldIndeterminate"];
	shouldIndeterminate = NO;
	[self didChangeValueForKey:@"shouldIndeterminate"];
	[self willChangeValueForKey:@"contentSize"];
	ipit_contentSize = expectedLength;
	[self didChangeValueForKey:@"contentSize"];
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didDownloadContentOfSize:(NSUInteger)downloadedLength
{
	NSString *tmp;
    double rate = 1024;
	[self willChangeValueForKey:@"downloadedSize"];
	ipit_downloadedSize = downloadedLength;
	[self didChangeValueForKey:@"downloadedSize"];
// #warning 64BIT: Check formatting arguments
// 2010-07-04 tsawada2 修正済
	tmp = [NSString stringWithFormat:@"%.0f KB / %.0f KB", ipit_downloadedSize/rate, ipit_contentSize/rate];
	[self setStatusMessage:tmp];
}

- (void)bsURLDownloadDidFinish:(BSURLDownload *)aDownload
{
	[self setDownloadedFilePath:[aDownload downloadedFilePath]];
	[self setCurrentDownload:nil];
	if (![self createThumbnailAndCalcImgSizeForPath:[self downloadedFilePath]]) {
		[self postErrorNotification:NO];
	} else {
        [[NSNotificationCenter defaultCenter] postNotificationName:BSIPITokenDownloadDidFinishNotification object:self];
    }
}

- (BOOL)bsURLDownload:(BSURLDownload *)aDownload shouldRedirectToURL:(NSURL *)newURL
{
	CFStringRef extensionRef = CFURLCopyPathExtension((CFURLRef)newURL);
	if (!extensionRef) {
		return NO;
	}

	NSString *extension = [(NSString *)extensionRef lowercaseString];
	CFRelease(extensionRef);
		
	return [[NSImage imageFileTypes] containsObject:extension];
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didAbortRedirectionToURL:(NSURL *)anURL
{
	NSBeep();

	[self setStatusMessage:[self localizedStrForKey:@"Download Canceled"]];
	[self setThumbnail:[[NSWorkspace sharedWorkspace] systemIconForType:kQuestionMarkIcon]];
	[self setCurrentDownload:nil];
	[self setStatusMessage:[self localizedStrForKey:@"Redirection Aborted"]];
	[self postErrorNotification:NO];
}

- (BOOL)bsURLDownload:(BSURLDownload *)aDownload shouldDownloadWithDestinationFileName:(NSString *)filename
{
    NSString *extension = [[filename pathExtension] lowercaseString];
    if (![[NSImage imageFileTypes] containsObject:extension]) {
        return NO;
    }
    // 同名ファイルの存在を確認
    NSString *fullPath = [[aDownload destination] stringByAppendingPathComponent:filename];
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir) {
        // 同名ファイルが存在する場合
        if ([aDownload allowsOverwriteDownloadedFile]) {
            // -retryDownload: によるダウンロードなので、常に上書きする
            return YES;
        }
        // 初回ダウンロード（BathyScaphe の起動／終了を跨いで同じ URL をプレビューしようとしている場合などが考えられる）
        // 埋め込んでおいた（はずの）メタデータから同一性を判断
        NSData *data = [UKXattrMetadataStore dataForKey:@"com.apple.metadata:kMDItemWhereFroms" atPath:fullPath traverseLink:NO];
        if (data) {
            id plist = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
            if (plist && [plist isKindOfClass:[NSArray class]] && ([plist count] > 0)) {
                id url = [plist objectAtIndex:0];
                if ([url isKindOfClass:[NSString class]]) {
                    NSURL *url2 = [NSURL URLWithString:url];
                    if (url2 && [[self sourceURL] isEqual:url2]) {
                        // プレビューしようとしているものと同じファイルと見なし、ダウンロードを中止してこのファイルをそのまま使用する
                        // （-bsURLDownloadDidAbortForDenyingSuggestedFileName: に遷移）
                        [self setDownloadedFilePath:fullPath];
                        return NO;
                    }
                }
            }
        }
    }
    return YES;
}

- (void)bsURLDownloadDidAbortForDenyingSuggestedFileName:(BSURLDownload *)aDownload
{
    [self setCurrentDownload:nil];
    if ([self downloadedFilePath]) {
        if (![self createThumbnailAndCalcImgSizeForPath:[self downloadedFilePath]]) {
            [self postErrorNotification:NO];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:BSIPITokenDownloadDidFinishNotification object:self];
        }
    } else {
        [self postErrorNotification:YES];
    }
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didFailWithError:(NSError *)aError
{
	NSBeep();

    NSString *errorStr = [NSString stringWithFormat:[self localizedStrForKey:@"Download Failed %ld"], (long)[aError code]];
	[self setStatusMessage:errorStr];
	[self setThumbnail:[[NSWorkspace sharedWorkspace] systemIconForType:kAlertCautionIcon]];
	[self setCurrentDownload:nil];
	[self postErrorNotification:NO];
}

#pragma mark NSPasteboardWriting
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    NSString *name = [pasteboard name];

    if ([name isEqualToString:NSGeneralPboard]) {
        static NSArray *writableTypesForGeneral = nil;
        if (!writableTypesForGeneral) {
            writableTypesForGeneral = [[NSArray alloc] initWithObjects:NSPasteboardTypeString, (NSString *)kUTTypeURL, nil];
        }
        return writableTypesForGeneral;
    } else if ([name isEqualToString:NSDragPboard]) {
        static NSArray *writableTypesForDrag = nil;
        if (!writableTypesForDrag) {
            writableTypesForDrag = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeFileURL, NSPasteboardTypeString, nil];
        }
        return writableTypesForDrag;
    }
    return nil;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    
    if ([type isEqualToString:(NSString *)kUTTypeFileURL]) {
        if (![self downloadedFilePath]) {
            return nil;
        }
        return [[NSURL fileURLWithPath:[self downloadedFilePath] isDirectory:NO] pasteboardPropertyListForType:type];
    }
    
    if ([type isEqualToString:(NSString *)kUTTypeURL]) {
        return [[self sourceURL] pasteboardPropertyListForType:type];
    }
    
    if ([type isEqualToString:NSPasteboardTypeString]) {
        return [[self sourceURL] absoluteString];
    }

    return nil;
}
@end
