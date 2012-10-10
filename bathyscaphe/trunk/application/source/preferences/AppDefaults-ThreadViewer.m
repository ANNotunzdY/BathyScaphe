//
// AppDefaults-ThreadsViewer.m
// BathyScaphe
//
// Updated by Tsutomu Sawada on 08/09/28.
// Copyright 2005-2011 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "AppDefaults_p.h"

#import "BSLinkDownloadManager.h"
#import "BSBeSAAPAnchorComposer.h"

#define kPrefThreadViewerWindowFrameKey		@"Default Window Frame"
#define kPrefReplyWindowFrameKey			@"Default Reply Window Frame"
#define kPrefThreadViewerSettingsKey		@"Preferences - ThreadViewerSettings"
#define kPrefThreadViewerLinkTypeKey		@"Message Link Setting"
#define kPrefMailAddressShownKey			@"mail Address Shown"
#define kPrefMailAttachmentShownKey			@"Mail Icon Shown"
#define kPrefOpenInBrowserTypeKey			@"Open In Browser Setting"
//#define kPrefShowsAllWhenDownloadedKey		@"ShowsAllWhenDownloaded"
#define kPrefShowsPoofAnimationKey			@"ShowsPoofOnInvisibleAbone"
#define kPrefPreviewLinkDirectlyKey			@"InvertPreviewerLinks"

//static NSString *const kPrefFirstVisibleKey	= @"FirstVisible";
//static NSString *const kPrefLastVisibleKey	= @"LastVisible";
static NSString *const kPrefTrackingTimeKey = @"Mousedown Tracking Time";

static NSString *const kPrefScroll2LUKey = @"ScrollToLastUpdatedHeader";

static NSString *const kPrefLinkDownloaderDestKey = @"LinkDownloaderDestination";
//static NSString *const kPrefLinkDownloaderCommentKey = @"LinkDownloaderAttachURLToComment";

static NSString *const kTVAutoReloadWhenWakeKey = @"Reload When Wake (Viewer)";
//static NSString *const kTVDefaultVisibleRangeKey = @"VisibleRange";
static NSString *const kPrefSAAPIconShownKey = @"SAAP Icon Shown";
static NSString *const kPrefConvertsItmsKey = @"Convert http To itms";
static NSString *const kPrefGestureEnabledKey = @"Multitouch Gesture Enabled";
//static NSString *const kPrefForceLayoutKey = @"Force Layout";
static NSString *const kPrefColorIDKey = @"Color ID";
static NSString *const kPrefReferencedMarkerKey = @"Referenced Marker Shown";

@implementation AppDefaults(ThreadViewerSettings)
- (NSMutableDictionary *)threadViewerDefaultsDictionary
{
	if (!m_threadViewerDictionary) {
		NSDictionary *dict_;

		dict_ = [[self defaults] dictionaryForKey:kPrefThreadViewerSettingsKey];
		m_threadViewerDictionary = [dict_ mutableCopy];
	}
	
	if (!m_threadViewerDictionary) {
		m_threadViewerDictionary = [[NSMutableDictionary alloc] init];
	}
	return m_threadViewerDictionary;
}

/* 「ウインドウの位置と領域を記憶」 */
- (NSString *)windowDefaultFrameString
{
	return [[self threadViewerDefaultsDictionary] stringForKey:kPrefThreadViewerWindowFrameKey];
}

- (void)setWindowDefaultFrameString:(NSString *)aString
{
	if (!aString) {
		[[self threadViewerDefaultsDictionary] removeObjectForKey:kPrefThreadViewerWindowFrameKey];
	} else {
		[[self threadViewerDefaultsDictionary] setObject:aString forKey:kPrefThreadViewerWindowFrameKey];
	}
}

- (NSString *)replyWindowDefaultFrameString
{
	return [[self threadViewerDefaultsDictionary] stringForKey:kPrefReplyWindowFrameKey];
}

- (void)setReplyWindowDefaultFrameString:(NSString *)aString
{
	if (!aString) {
		[[self threadViewerDefaultsDictionary] removeObjectForKey:kPrefReplyWindowFrameKey];
	} else {
		[[self threadViewerDefaultsDictionary] setObject:aString forKey:kPrefReplyWindowFrameKey];
	}
}

- (ThreadViewerLinkType)threadViewerLinkType
{
	return [[self threadViewerDefaultsDictionary] integerForKey:kPrefThreadViewerLinkTypeKey defaultValue:DEFAULT_THREAD_VIEWER_LINK_TYPE];
}

- (void)setThreadViewerLinkType:(ThreadViewerLinkType)aType
{
	[[self threadViewerDefaultsDictionary] setInteger:aType forKey:kPrefThreadViewerLinkTypeKey];
}

// メールアドレス
- (BOOL)mailAttachmentShown
{
	return (PFlags.mailAttachmentShown != 0);
}

- (void)setMailAttachmentShown:(BOOL)flag
{
	[[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefMailAttachmentShownKey];
	
	PFlags.mailAttachmentShown = flag ? 1 : 0;
}

- (BOOL)mailAddressShown
{
	return (PFlags.mailAddressShown != 0);
}

- (void)setMailAddressShown:(BOOL)flag
{
	[[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefMailAddressShownKey];
	
	PFlags.mailAddressShown = flag ? 1 : 0;
}

- (BSOpenInBrowserType)openInBrowserType
{
	return [[self threadViewerDefaultsDictionary] integerForKey:kPrefOpenInBrowserTypeKey defaultValue:DEFAULT_OPEN_IN_BROWSER_TYPE];
}

- (void)setOpenInBrowserType:(BSOpenInBrowserType)aType
{
	[[self threadViewerDefaultsDictionary] setInteger:aType forKey:kPrefOpenInBrowserTypeKey];
}

- (BOOL)showsPoofAnimationOnInvisibleAbone
{
	// Terminal などから変更しやすいように、このエントリはトップレベルに作る
	return [[self defaults] boolForKey:kPrefShowsPoofAnimationKey defaultValue:DEFAULT_SHOWS_POOF_ON_ABONE];
}

- (void)setShowsPoofAnimationOnInvisibleAbone:(BOOL)showsPoof
{
	[[self defaults] setBool:showsPoof forKey:kPrefShowsPoofAnimationKey];
}

- (BOOL)previewLinkWithNoModifierKey
{
	return [[self defaults] boolForKey:kPrefPreviewLinkDirectlyKey defaultValue:DEFAULT_TV_PREVIEW_WITH_NO_MODIFIER];
}

- (void)setPreviewLinkWithNoModifierKey:(BOOL)previewDirectly
{
	[[self defaults] setBool:previewDirectly forKey:kPrefPreviewLinkDirectlyKey];
}

- (double)mouseDownTrackingTime
{
	return [[self threadViewerDefaultsDictionary] doubleForKey:kPrefTrackingTimeKey defaultValue:DEFAULT_TV_MOUSEDOWN_TIME];
}

- (void)setMouseDownTrackingTime:(double)aValue
{
	[[self threadViewerDefaultsDictionary] setDouble:aValue forKey:kPrefTrackingTimeKey];
}

- (BOOL)scrollToLastUpdated
{
	return [[self threadViewerDefaultsDictionary] boolForKey:kPrefScroll2LUKey defaultValue:DEFAULT_TV_SCROLL_TO_NEW];
}

- (void)setScrollToLastUpdated:(BOOL)flag
{
	[[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefScroll2LUKey];
}

#pragma mark Link Downloader
- (NSString *)linkDownloaderDestination
{
	BOOL	isDir;
	NSString *path = [[self threadViewerDefaultsDictionary] stringForKey:kPrefLinkDownloaderDestKey];
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
		return path;
	} else {
		return [[CMRFileManager defaultManager] userDomainDownloadsFolderPath];
	}
}

- (void)setLinkDownloaderDestination:(NSString *)path
{
	[[self threadViewerDefaultsDictionary] setObject:path forKey:kPrefLinkDownloaderDestKey];
}

- (NSMutableArray *)linkDownloaderDictArray
{
	return [[BSLinkDownloadManager defaultManager] downloadableTypes];
}

- (void)setLinkDownloaderDictArray:(NSMutableArray *)array
{
	[[BSLinkDownloadManager defaultManager] setDownloadableTypes:array];
}

- (NSArray *)linkDownloaderExtensionTypes
{
	return [[self linkDownloaderDictArray] valueForKey:@"extension"];
}

- (NSArray *)linkDownloaderAutoopenTypes
{
	return [[self linkDownloaderDictArray] valueForKey:@"autoopen"];
}
/*
- (BOOL)linkDownloaderAttachURLToComment
{
	return [[self threadViewerDefaultsDictionary] boolForKey:kPrefLinkDownloaderCommentKey defaultValue:DEFAULT_LINK_DOWNLOADER_ATTACH_COMMENT];
}

- (void)setLinkDownloaderAttachURLToComment:(BOOL)flag
{
	[[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefLinkDownloaderCommentKey];
}
*/
- (BOOL)autoReloadViewerWhenWake
{
	return [[self threadViewerDefaultsDictionary] boolForKey:kTVAutoReloadWhenWakeKey defaultValue:DEFAULT_TV_AUTORELOAD_WHEN_WAKE];
}

- (void)setAutoReloadViewerWhenWake:(BOOL)flag
{
	[[self threadViewerDefaultsDictionary] setBool:flag forKey:kTVAutoReloadWhenWakeKey];
}

- (BOOL)showsSAAPIcon
{
	return [[self threadViewerDefaultsDictionary] boolForKey:kPrefSAAPIconShownKey defaultValue:DEFAULT_TV_SAAP_ICON_SHOWN];
}

- (void)setShowsSAAPIcon:(BOOL)flag
{
	[[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefSAAPIconShownKey];
	[BSBeSAAPAnchorComposer setShowsSAAPIcon:flag];
}

- (BOOL)convertsHttpToItmsIfNeeded
{
    return [[self threadViewerDefaultsDictionary] boolForKey:kPrefConvertsItmsKey defaultValue:DEFAULT_TV_CONVERTS_ITMS];
}

- (void)setConvertsHttpToItmsIfNeeded:(BOOL)flag
{
    [[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefConvertsItmsKey];
}

- (BOOL)multitouchGestureEnabled
{
    return [[self threadViewerDefaultsDictionary] boolForKey:kPrefGestureEnabledKey defaultValue:DEFAULT_TV_GESTURE_ENABLED];
}

- (void)setMultitouchGestureEnabled:(BOOL)flag
{
    [[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefGestureEnabledKey];
}

/*- (BOOL)shouldForceLayoutForLoadedMessages
{
//    return [[self threadViewerDefaultsDictionary] boolForKey:kPrefForceLayoutKey defaultValue:DEFAULT_TV_FORCE_LAYOUT];
    return [[self defaults] boolForKey:@"BSForceEntireLayout" defaultValue:DEFAULT_TV_FORCE_LAYOUT];
}

- (void)setShouldForceLayoutForLoadedMessages:(BOOL)flag
{
    NSLog(@"Deprecated!");
//    [[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefForceLayoutKey];
}*/
- (BOOL)shouldColorIDString
{
    return [[self threadViewerDefaultsDictionary] boolForKey:kPrefColorIDKey defaultValue:DEFAULT_TV_COLOR_ID];
}

- (void)setShouldColorIDString:(BOOL)flag
{
    [[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefColorIDKey];
}

- (BOOL)showsReferencedMarker
{
    return [[self threadViewerDefaultsDictionary] boolForKey:kPrefReferencedMarkerKey defaultValue:DEFAULT_TV_SHOWS_REF_MARKER];
}

- (void)setShowsReferencedMarker:(BOOL)flag
{
    [[self threadViewerDefaultsDictionary] setBool:flag forKey:kPrefReferencedMarkerKey];
}

#pragma mark -
- (void)_loadThreadViewerSettings
{
	NSMutableDictionary *dict_ = [self threadViewerDefaultsDictionary];
	BOOL flag_;

    // .Invader Addition
    // Hidden Option に必要ならコンバート
/*    id oldValue = [dict_ objectForKey:kPrefForceLayoutKey];
    if (oldValue) {
        if (![oldValue boolValue]) {
            [[self defaults] setBool:NO forKey:@"BSForceEntireLayout"];
        }
        [dict_ removeObjectForKey:kPrefForceLayoutKey];
    }*/
	
	flag_ = [dict_ boolForKey:kPrefMailAttachmentShownKey defaultValue:kPreferencesDefault_MailAttachmentShown];
	[self setMailAttachmentShown:flag_];
	flag_ = [dict_ boolForKey:kPrefMailAddressShownKey defaultValue:kPreferencesDefault_MailAddressShown];
	[self setMailAddressShown:flag_];
}

- (BOOL)_saveThreadViewerSettings
{
	NSMutableDictionary *dict_;
	dict_ = [self threadViewerDefaultsDictionary];
	UTILAssertNotNil(dict_);
    
	[[self defaults] setObject:dict_ forKey:kPrefThreadViewerSettingsKey];

	[[BSLinkDownloadManager defaultManager] writeToFileNow];
	return YES;
}
@end
