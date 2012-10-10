//
//  AppDefaults.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/10/29.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "AppDefaults_p.h"
#import "TS2SoftwareUpdate.h"
#import "DatabaseManager.h" // For tableNameForKey()
#import "BSReplyTextTemplateManager.h"

NSString *const AppDefaultsWillSaveNotification = @"AppDefaultsWillSaveNotification";
NSString *const AppDefaultsThreadViewThemeDidChangeNotification = @"AppDefaultsThreadViewThemeDidChangeNotification";


#define AppDefaultsDefaultReplyNameKey		    @"Reply Name"
#define AppDefaultsDefaultKoteHanListKey	    @"ReplyNameList"
#define AppDefaultsDefaultReplyMailKey		    @"Reply Mail"
#define AppDefaultsIsOnlineModeKey		        @"Online Mode ON"
#define AppDefaultsThreadSearchOptionKey		@"Thread Search Option" // Deprecated in Starlight Breaker.
#define AppDefaultsContentsSearchOptionKey		@"Contents Search Option"
static NSString *const AppDefaultsFindPanelExpandedKey = @"Find Panel Expanded";
static NSString *const AppDefaultsContentsSearchTargetKey = @"Contents Search Targets";
static NSString *const AppDefaultsTGrepSearchOptionKey = @"tGrep Search Option";
static NSString *const AppDefaultsInfoServerRemovedKey = @"BBSMenu Invalid Board Data Removed";
static NSString *const AppDefaultsResetTargetMaskKey = @"Application Reset Target Mask";
static NSString *const AppDefaultsNoNameEntityRefConvertedKey = @"NoName Entity Reference Converted";

#define AppDefaultsBrowserSplitViewIsVerticalKey		@"Browser SplitView isVertical"
#define AppDefaultsBrowserLastBoardKey					@"LastBoard"
#define AppDefaultsBrowserSortColumnIdentifierKey		@"ThreadSortKey"
#define AppDefaultsListCollectByNewKey					@"CollectByNewKey"
#define AppDefaultsBrowserSortAscendingKey				@"ThreadSortAscending"
#define AppDefaultsBrowserStatusFilteringMaskKey		@"StatusFilteringMask"

#define AppDefaultsIsFavImportedKey			@"Old Favorites Updated" // Deprecated in Starlight Breaker.
#define AppDefaultsOldMsgScrlBehvrKey		@"OldScrollingBehavior"

#define AppDefaultsOpenInBgKey				@"OpenLinkInBg"
#define AppDefaultsQuietDeletionKey			@"QuietDeletion"

#define	AppDefaultsInformDatOchiKey			@"InformWhenDatOchi"
//#define AppDefaultsMoveFocusKey				@"MoveFocusToViewerWhenShowThreadAtRow"

// History
#define AppDefaultsHistoryThreadsKey		@"ThreadHistoryItemLimit"
#define AppDefaultsHistoryBoardsKey			@"BoardHistoryItemLimit"
#define AppDefaultsHistorySearchKey			@"RecentSearchItemLimit"

// Proxy (Deprecated)
#define AppDefaultsProxyURLKey				@"ProxyURL"
#define AppDefaultsProxyPortKey				@"ProxyPort"

static NSString *const AppDefaultsTLSortDescriptorsKey = @"ThreadsList Sort Descriptors";

static NSString *const AppDefaultsUseCustomThemeKey = @"Use Custom ThreadViewTheme";
static NSString *const AppDefaultsThemeFileNameKey = @"ThreadViewTheme FileName";
//static NSString *const AppDefaultsDefaultThemeFileNameKey = @"ThreadViewerDefaultTheme"; // + ".plist"
static NSString *const AppDefaultsDefaultThemeFileNameKey = @"default_indigo"; // + ".plist"
static NSString *const AppDefaultsPreDotInvaderThemeSettingsConvertedKey = @"BSDotInvaderCustomThemeSettingsConverted";

#pragma mark -

@implementation AppDefaults
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance);

- (id)init
{
	if (self = [super init]) {
		NSNotificationCenter *center_;
		center_ = [NSNotificationCenter defaultCenter];
		[center_ addObserver:self selector:@selector(applicationWillTerminateNotified:) name:NSApplicationWillTerminateNotification object:NSApp];

		m_isThemesInfoArrayValid = NO;

		[self loadDefaults];
	}
	return self;
}

- (void)dealloc
{
	m_installedPreviewer = nil;
	[m_backgroundColorDictionary release];
	[m_threadsListDictionary release];
	[m_threadViewerDictionary release];
	[m_imagePreviewerDictionary release];
	[_dictAppearance release];
	[m_soundsDictionary release];
	[m_boardWarriorDictionary release];
	[m_threadViewTheme release];
	[super dealloc];
}

- (NSUserDefaults *)defaults
{
	return [NSUserDefaults standardUserDefaults];
}

- (void)postLayoutSettingsUpdateNotification
{
	UTILNotifyName(AppDefaultsLayoutSettingsUpdatedNotification);
}

- (void)cleanUpDeprecatedKeyAndValues
{
	NSUserDefaults *defaults_ = [self defaults];
	// threadSearchOption
	if ([defaults_ objectForKey:AppDefaultsThreadSearchOptionKey]) {
		[defaults_ removeObjectForKey:AppDefaultsThreadSearchOptionKey];
		NSLog(@"Unused key %@ removed.", AppDefaultsThreadSearchOptionKey);
	}
	// oldFavoritesUpdated
	if ([defaults_ objectForKey:AppDefaultsIsFavImportedKey]) {
		[defaults_ removeObjectForKey:AppDefaultsIsFavImportedKey];
		NSLog(@"Unused key %@ removed.", AppDefaultsIsFavImportedKey);
	}
	// proxy
	if ([defaults_ objectForKey:@"UsesBSsOwnProxySettings"]) {
		[defaults_ removeObjectForKey:@"UsesBSsOwnProxySettings"];
		NSLog(@"Unused key UsesBSsOwnProxySettings removed.");
	}
	if ([defaults_ objectForKey:AppDefaultsProxyURLKey]) {
		[defaults_ removeObjectForKey:AppDefaultsProxyURLKey];
		NSLog(@"Unused key %@ removed.", AppDefaultsProxyURLKey);
	}
	if ([defaults_ objectForKey:AppDefaultsProxyPortKey]) {
		[defaults_ removeObjectForKey:AppDefaultsProxyPortKey];
		NSLog(@"Unused key %@ removed.", AppDefaultsProxyPortKey);
	}	
	if ([defaults_ objectForKey:@"DisablesHistoryButtonPopupMenu"]) {
		[defaults_ removeObjectForKey:@"DisablesHistoryButtonPopupMenu"];
		NSLog(@"Unused key DisablesHistoryButtonPopupMenu removed.");
	}
}

- (NSString *)preTenoriTigerCustomThemeFilePath
{
	NSString *dirPath = [[[CMRFileManager defaultManager] supportDirectoryWithName:BSThemesDirectory] filepath];
	return [dirPath stringByAppendingPathComponent:@"CustomTheme.plist"];
}

- (void)convertOldCustomThemeSettings
{
	NSString *customThemeFile = [self preTenoriTigerCustomThemeFilePath];
	BOOL isDir;
	if ([[NSFileManager defaultManager] fileExistsAtPath:customThemeFile isDirectory:&isDir] && !isDir) {
		NSString *newName = NSLocalizedString(@"Copied Custom Theme File", @"");
		NSString *newPath = [self createFullPathFromThemeFileName:newName];
		if ([[NSFileManager defaultManager] copyItemAtPath:customThemeFile toPath:newPath error:NULL]) {
			BSThreadViewTheme *newTheme = [[BSThreadViewTheme alloc] initWithContentsOfFile:newPath];
			[newTheme setIdentifier:NSLocalizedString(@"Old Custom Theme", @"")];
			[newTheme writeToFile:newPath atomically:YES];
			[newTheme release];

			[[self defaults] setObject:newName forKey:AppDefaultsThemeFileNameKey];
		} else {
			[[self defaults] removeObjectForKey:AppDefaultsThemeFileNameKey];
		}
	} else {
		[[self defaults] removeObjectForKey:AppDefaultsThemeFileNameKey];
	}
	[[self defaults] removeObjectForKey:AppDefaultsUseCustomThemeKey];
}

- (void)convertOldCustomThemeSettingsDotInvader
{
    id entry = [[self defaults] objectForKey:AppDefaultsThemeFileNameKey];
//    NSString *informativeTextKey;
    if (entry) {
        [self setUsesCustomTheme:YES];
//        informativeTextKey = @"UpdatedNotifyAlertMsg2";
    } else {
        // Default Theme...
        [[self defaults] setObject:AppDefaultsDefaultThemeFileNameKey forKey:AppDefaultsThemeFileNameKey];
        [self setUsesCustomTheme:NO];
//        informativeTextKey = @"UpdatedNotifyAlertMsg1";
    }
/*    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:NSLocalizedString(@"UpdatedNotifyAlertTitle", @"UpdatedNotifyAlertTitle")];
    [alert setInformativeText:NSLocalizedString(informativeTextKey, informativeTextKey)];
    [alert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];*/

    [[self defaults] setBool:YES forKey:AppDefaultsPreDotInvaderThemeSettingsConvertedKey];
}

- (void)loadThreadViewTheme
{
	NSString *themeFileName = [self themeFileName];
	NSString *finalFilePath;

    if ([self usesCustomTheme]) {
        finalFilePath = [self createFullPathFromThemeFileName:themeFileName];
    } else {
        finalFilePath = [[NSBundle mainBundle] pathForResource:[themeFileName stringByDeletingPathExtension] ofType:@"plist" inDirectory:@"Themes"];
    }

	if (!finalFilePath) {
		finalFilePath = [self defaultThemeFilePath];
        [self setUsesCustomTheme:NO];
	}

	BSThreadViewTheme *defaultTheme = [[BSThreadViewTheme alloc] initWithContentsOfFile:finalFilePath];
	[self setThreadViewTheme:defaultTheme];
	[defaultTheme release];
}

- (BOOL)loadDefaults
{
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], TS2SoftwareUpdateCheckKey,
							[NSNumber numberWithUnsignedInteger:TS2SUCheckWeekly], TS2SoftwareUpdateCheckIntervalKey,
							[NSNumber numberWithBool:NO], AppDefaultsUseCustomThemeKey,
							[NSNumber numberWithBool:NO], AppDefaultsOldFontsAndColorsConvertedKey,
                            [NSNumber numberWithBool:NO], BSUserDebugEnabledKey,
                            [NSNumber numberWithBool:NO], @"BSMoveToTrashWithFinder",
                          [NSNumber numberWithBool:NO], AppDefaultsPreDotInvaderThemeSettingsConvertedKey, NULL];
	[[self defaults] registerDefaults: dict];

	if (![[self defaults] boolForKey:AppDefaultsOldFontsAndColorsConvertedKey])
		[self convertOldFCToThemeFile];

	if ([[self defaults] boolForKey:AppDefaultsUseCustomThemeKey]) {
		[self convertOldCustomThemeSettings];
	}
    
    if (![[self defaults] boolForKey:AppDefaultsPreDotInvaderThemeSettingsConvertedKey]) {
        [self convertOldCustomThemeSettingsDotInvader];
    }

	[self loadThreadViewTheme];

	[self cleanUpDeprecatedKeyAndValues];

	[self _loadBackgroundColors];
	[self _loadFontAndColor];
	[self _loadFilter];
	[self _loadThreadsListSettings];
	[self _loadThreadViewerSettings];
	[self _loadImagePreviewerSettings];
	[self loadAccountSettings];
	[self _loadSoundsSettings];
	[self _loadBWSettings];
	
	return YES;
}

- (BOOL)saveDefaults
{
	BOOL syncResult = NO;

	UTILNotifyName(AppDefaultsWillSaveNotification);

    @try {
        [self _saveBackgroundColors];
        [self _saveFontAndColor];
        [self _saveThreadsListSettings];
        [self _saveThreadViewerSettings];
        [self _saveImagePreviewerSettings];
        [self _saveFilter];
        [self _saveSoundsSettings];
        [self _saveBWSettings];

        syncResult = [[self defaults] synchronize];
    } @catch (NSException *localException) {
        NSLog(@"***EXCEPTION*** in %@:\n%@", self, [localException description]);
	}

	return syncResult;
}

- (void)applicationWillTerminateNotified:(NSNotification *)notification
{
	UTILAssertNotificationName(notification, NSApplicationWillTerminateNotification);
	UTILAssertNotificationObject(notification, NSApp);	
	[self saveDefaults];
}

#pragma mark General
- (BOOL)isOnlineMode
{
	return [[self defaults] boolForKey:AppDefaultsIsOnlineModeKey defaultValue:kPreferencesDefault_OnlineMode];
}

- (void)setIsOnlineMode:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:AppDefaultsIsOnlineModeKey];
//	[[CMRMainMenuManager defaultManager] synchronizeIsOnlineModeMenuItemState];
}

- (IBAction)toggleOnlineMode:(id)sender
{
	[self setIsOnlineMode:(![self isOnlineMode])];
}

- (BOOL)isSplitViewVertical
{
	return [[self defaults] boolForKey:AppDefaultsBrowserSplitViewIsVerticalKey defaultValue:DEFAULT_IS_BROWSER_VERTICAL];
}

- (void)setIsSplitViewVertical:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:AppDefaultsBrowserSplitViewIsVerticalKey];
}

- (BOOL)quietDeletion
{
    return [[self defaults] boolForKey:AppDefaultsQuietDeletionKey defaultValue:NO];
}

- (void)setQuietDeletion:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:AppDefaultsQuietDeletionKey];
}

- (BOOL)openInBg
{
	return [[self defaults] boolForKey:AppDefaultsOpenInBgKey defaultValue:NO];
}

- (void)setOpenInBg:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:AppDefaultsOpenInBgKey];
}


- (BOOL)saveThreadDocAsBinaryPlist
{
	return [[self defaults] boolForKey:@"UseBinaryFormat" defaultValue:DEFAULT_USE_BINARY_FORMAT];
}

- (void)setSaveThreadDocAsBinaryPlist:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:@"UseBinaryFormat"];
}

#pragma mark Search Options
- (CMRSearchMask)contentsSearchOption
{
	return [[self defaults] integerForKey:AppDefaultsContentsSearchOptionKey defaultValue:DEFAULT_CONTENTS_SEARCH_OPTION];
}

- (void)setContentsSearchOption:(CMRSearchMask)option
{
	[[self defaults] setInteger:option forKey:AppDefaultsContentsSearchOptionKey];
}

- (BOOL)findPanelExpanded
{
	return [[self defaults] boolForKey:AppDefaultsFindPanelExpandedKey defaultValue:DEFAULT_SEARCH_PANEL_EXPANDED];
}

- (void)setFindPanelExpanded:(BOOL)isExpanded
{
	[[self defaults] setBool:isExpanded forKey:AppDefaultsFindPanelExpandedKey];
}

- (NSArray *)contentsSearchTargetArray
{
	NSArray *array = [[self defaults] arrayForKey:AppDefaultsContentsSearchTargetKey];
	if (!array) {
		NSNumber *tmp = [NSNumber numberWithInteger:NSOnState];
		array = [NSArray arrayWithObjects:tmp, tmp, tmp, tmp, tmp, nil];
	}
	return array;
}

- (void)setContentsSearchTargetArray:(NSArray *)array
{
	[[self defaults] setObject:array forKey:AppDefaultsContentsSearchTargetKey];
}

- (BSTGrepSearchOptionType)tGrepSearchOption
{
    return [[self defaults] integerForKey:AppDefaultsTGrepSearchOptionKey defaultValue:DEFAULT_TGREP_SEARCH_OPTION];
}

- (void)setTGrepSearchOption:(BSTGrepSearchOptionType)tagValue
{
    [[self defaults] setInteger:tagValue forKey:AppDefaultsTGrepSearchOptionKey];
}

#pragma mark Reply
- (NSString *)defaultReplyName
{
	NSString *name_;
	name_ = [[self defaults] stringForKey:AppDefaultsDefaultReplyNameKey];
	return name_ ? name_ : @"";
}

- (void)setDefaultReplyName:(NSString *)name
{
	if (!name) {
		[[self defaults] removeObjectForKey:AppDefaultsDefaultReplyNameKey];
		return;
	}
	[[self defaults] setObject:name forKey:AppDefaultsDefaultReplyNameKey];
}

- (NSString *)defaultReplyMailAddress
{
	NSString *mail_;
	mail_ = [[self defaults] stringForKey:AppDefaultsDefaultReplyMailKey];
	return mail_ ? mail_ : @"";
}

- (void)setDefaultReplyMailAddress:(NSString *)mail
{
	if (!mail) {
		[[self defaults] removeObjectForKey:AppDefaultsDefaultReplyMailKey];
		return;
	}
	[[self defaults] setObject:mail forKey:AppDefaultsDefaultReplyMailKey];
}

- (NSArray *)defaultKoteHanList
{
    return [[self defaults] stringArrayForKey:AppDefaultsDefaultKoteHanListKey];
}

- (void)setDefaultKoteHanList:(NSArray *)anArray
{
	if (!anArray) {
		[[self defaults] removeObjectForKey:AppDefaultsDefaultKoteHanListKey];
	} else {
		[[self defaults] setObject:anArray forKey:AppDefaultsDefaultKoteHanListKey];
	}
}

- (BSReplyTextTemplateManager *)RTTManager
{
	return [BSReplyTextTemplateManager defaultManager];
}

- (NSTimeInterval)timeIntervalForNinjaFirstWait
{
    id templateValue = SGTemplateResource(@"Reply - Ninja FirstWaitSeconds");
    UTILAssertKindOfClass(templateValue, NSNumber);
    return [(NSNumber *)templateValue doubleValue];
}

- (BOOL)autoRetryAfterNinjaFirstWait
{
    return [[self defaults] boolForKey:@"Reply Ninja Auto Retry" defaultValue:DEFAULT_NINJA_AUTO_RETRY];
}

- (void)setAutoRetryAfterNinjaFirstWait:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:@"Reply Ninja Auto Retry"];
}

#pragma mark Software Update Support
- (BOOL)autoCheckForUpdate
{
	return [[self defaults] boolForKey:TS2SoftwareUpdateCheckKey];
}

- (void)setAutoCheckForUpdate:(BOOL)autoCheck
{
	[[self defaults] setBool:autoCheck forKey:TS2SoftwareUpdateCheckKey];
}

- (NSInteger)softwareUpdateCheckInterval
{
	return [[self defaults] integerForKey:TS2SoftwareUpdateCheckIntervalKey];
}

- (void)setSoftwareUpdateCheckInterval:(NSInteger)type
{
	[[self defaults] setInteger:type forKey:TS2SoftwareUpdateCheckIntervalKey];
}

#pragma mark Browser
- (NSString *)browserLastBoard
{
	NSString *rep_;
	rep_ = [[self defaults] objectForKey:AppDefaultsBrowserLastBoardKey];

	UTILRequireCondition(rep_, default_browserLastBoard);
	return rep_;
	
default_browserLastBoard:
	return CMXFavoritesDirectoryName;
}

- (void)setBrowserLastBoard:(NSString *)boardName
{
	if (!boardName) {
		[[self defaults] removeObjectForKey:AppDefaultsBrowserLastBoardKey];
		return;
	}
	[[self defaults] setObject:boardName forKey:AppDefaultsBrowserLastBoardKey];
}

- (NSArray *)threadsListSortDescriptors
{
	NSArray *descs = nil;
	id obj = [[self defaults] objectForKey:AppDefaultsTLSortDescriptorsKey];
	if (obj && [obj isKindOfClass:[NSData class]]) {
		@try {
			descs = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
		}
		@catch (NSException *e) {
			NSLog(@"Warning: -[AppDefaults threadsListSortDescriptors]: The data is corrupted.");
		} 
	}

	if (!descs) {
		NSSortDescriptor *desc1
			= [[NSSortDescriptor alloc] initWithKey:tableNameForKey(CMRThreadStatusKey) ascending:NO selector:@selector(numericCompare:)];
		NSSortDescriptor *desc2
			= [[NSSortDescriptor alloc] initWithKey:tableNameForKey(CMRThreadSubjectIndexKey) ascending:YES selector:@selector(numericCompare:)];
		descs = [NSArray arrayWithObjects:desc1, desc2, nil];
		[desc1 release];
		[desc2 release];
	}

	return descs;
}

- (void)setThreadsListSortDescriptors:(NSArray *)desc
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:desc];
	[[self defaults] setObject:data forKey:AppDefaultsTLSortDescriptorsKey];
}

- (BOOL)collectByNew
{
	return [[self defaults] boolForKey:AppDefaultsListCollectByNewKey defaultValue:YES];
}

- (void)setCollectByNew:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:AppDefaultsListCollectByNewKey];
}

#pragma mark Hidden Options
- (NSInteger)maxCountForThreadsHistory
{
	return [[self defaults] integerForKey:AppDefaultsHistoryThreadsKey defaultValue:DEFAULT_MAX_FOR_THREADS_HISTORY];
}

- (void)setMaxCountForThreadsHistory:(NSInteger)counts
{
	[[self defaults] setInteger:counts forKey:AppDefaultsHistoryThreadsKey];
}

- (NSInteger)maxCountForBoardsHistory
{
	return [[self defaults] integerForKey:AppDefaultsHistoryBoardsKey defaultValue:DEFAULT_MAX_FOR_BOARDS_HISTORY];
}

- (void)setMaxCountForBoardsHistory:(NSInteger)counts
{
	[[self defaults] setInteger:counts forKey:AppDefaultsHistoryBoardsKey];
}

- (NSInteger)maxCountForSearchHistory
{
	return [[self defaults] integerForKey:AppDefaultsHistorySearchKey defaultValue:DEFAULT_MAX_FOR_SEARCH_HISTORY];
}

- (void)setMaxCountForSearchHistory:(NSInteger)counts
{
	[[self defaults] setInteger:counts forKey:AppDefaultsHistorySearchKey];
}

- (BOOL)informWhenDetectDatOchi
{
	return [[self defaults] boolForKey:AppDefaultsInformDatOchiKey defaultValue:DEFAULT_INFORM_WHEN_DAT_OCHI];
}

- (void)setInformWhenDetectDatOchi:(BOOL)shouldInform
{
	[[self defaults] setBool:shouldInform forKey:AppDefaultsInformDatOchiKey];
}

- (BOOL)oldMessageScrollingBehavior
{
	return [[self defaults] boolForKey:AppDefaultsOldMsgScrlBehvrKey defaultValue:DEFAULT_OLD_SCROLLING];
}

- (void)setOldMessageScrollingBehavior: (BOOL) flag
{
	[[self defaults] setBool:flag forKey:AppDefaultsOldMsgScrlBehvrKey];
}

- (BOOL)invalidBoardDataRemoved
{
    return [[self defaults] boolForKey:AppDefaultsInfoServerRemovedKey defaultValue:DEFAULT_INFO_SERVER_DATA_REMOVED];
}

- (void)setInvalidBoardDataRemoved:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:AppDefaultsInfoServerRemovedKey];
}

- (BOOL)noNameEntityReferenceConverted
{
    return [[self defaults] boolForKey:AppDefaultsNoNameEntityRefConvertedKey defaultValue:DEFAULT_NONAME_ENTITYREF_CONVERTED];
}

- (void)setNoNameEntityReferenceConverted:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:AppDefaultsNoNameEntityRefConvertedKey];
}

/*#pragma mark MeteorSweeper Addition
- (BOOL)moveFocusToViewerWhenShowThreadAtRow
{
	return [[self defaults] boolForKey:AppDefaultsMoveFocusKey defaultValue:YES];
}
- (void)setMoveFocusToViewerWhenShowThreadAtRow:(BOOL)shouldMove
{
	[[self defaults] setBool:shouldMove forKey:AppDefaultsMoveFocusKey];
}
*/
- (NSTimeInterval)delayForAutoReloadAtWaking
{
	NSTimeInterval delay;
	id value = [[self defaults] objectForKey:@"DelayForAutoReloadAtWaking"];

	if (!value || ![value isKindOfClass:[NSNumber class]]) {
        delay = 0;
	} else {
		delay = [(NSNumber *)value doubleValue];
	}

	return delay;
}

- (void)setDelayForAutoReloadAtWaking:(NSTimeInterval)doubleValue
{
	[[self defaults] setObject:[NSNumber numberWithDouble:doubleValue] forKey:@"DelayForAutoReloadAtWaking"];
}

- (NSUInteger)appResetTargetMask
{
    return [[self defaults] integerForKey:AppDefaultsResetTargetMaskKey defaultValue:DEFAULT_APP_RESET_TARGET_MASK];
}

- (void)setAppResetTargetMask:(NSUInteger)mask
{
    [[self defaults] setInteger:mask forKey:AppDefaultsResetTargetMaskKey];
}
@end


@implementation AppDefaults(ThreadViewTheme)
- (BSThreadViewTheme *)threadViewTheme
{
	return m_threadViewTheme;
}

- (void)setThreadViewTheme:(BSThreadViewTheme *)aTheme
{
	[aTheme retain];
	[m_threadViewTheme release];
	m_threadViewTheme = aTheme;
	UTILNotifyName(AppDefaultsThreadViewThemeDidChangeNotification);
}

- (BOOL)usesCustomTheme
{
    return [[self defaults] boolForKey:@"UsesCustomTheme"];
}

- (void)setUsesCustomTheme:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:@"UsesCustomTheme"];
}

- (NSString *)defaultThemeFilePath
{
    return [[NSBundle mainBundle] pathForResource:AppDefaultsDefaultThemeFileNameKey ofType:@"plist" inDirectory:@"Themes"];
}

- (NSArray *)defaultThemeFilePaths
{
    return [[NSBundle mainBundle] pathsForResourcesOfType:@"plist" inDirectory:@"Themes"];
}

- (NSString *)createFullPathFromThemeFileName:(NSString *)fileName
{
	NSString *dirPath = [[[CMRFileManager defaultManager] supportDirectoryWithName:BSThemesDirectory] filepath];
	return [dirPath stringByAppendingPathComponent:fileName];
}

- (NSString *)themeFileName
{
	NSString *recordedFileName = [[self defaults] stringForKey:AppDefaultsThemeFileNameKey];
	if (recordedFileName) {
        if (![self usesCustomTheme]) {
            NSArray *paths = [self defaultThemeFilePaths];
            for (NSString *path in paths) {
                if ([[path lastPathComponent] isEqualToString:recordedFileName]) {
                    return recordedFileName;
                }
            }
        } else {        
            BOOL	isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:[self createFullPathFromThemeFileName:recordedFileName] isDirectory:&isDir]
                    && !isDir) {
                return recordedFileName;
            }
            [self setUsesCustomTheme:NO]; // ここまで来たら、なんらかの理由でカスタムテーマが使えない＝使わないということなので、矛盾のないように…
        }
	}

    return [AppDefaultsDefaultThemeFileNameKey stringByAppendingPathExtension:@"plist"];
}

- (void)setThemeFileNameWithFullPath:(NSString *)fullPath isCustomTheme:(BOOL)isCustom
{
    [[self defaults] setObject:[fullPath lastPathComponent] forKey:AppDefaultsThemeFileNameKey];
    [self setUsesCustomTheme:isCustom];

	BSThreadViewTheme *theme = [[BSThreadViewTheme alloc] initWithContentsOfFile:fullPath];
	[self setThreadViewTheme:theme];
	[theme release];
}

- (NSArray *)installedThemes
{
    if (!m_isThemesInfoArrayValid) {
        NSString *themeDir = [[[CMRFileManager defaultManager] supportDirectoryWithName:BSThemesDirectory] filepath];
        NSMutableArray *tmp = [NSMutableArray array];
        NSArray *defaultThemeFiles = [self defaultThemeFilePaths];
        for (NSString *defaultThemeFilePath in defaultThemeFiles) {
            BSThreadViewTheme *defaultTheme = [[BSThreadViewTheme alloc] initWithContentsOfFile:defaultThemeFilePath];
            if (!defaultTheme) {
                continue;
            }
            [tmp addObject:[NSDictionary dictionaryWithObjectsAndKeys:defaultThemeFilePath, @"ThemeFilePath", [defaultTheme identifier], @"Identifier",
                            [NSNumber numberWithBool:YES], @"IsInternalTheme", NULL]];
            [defaultTheme release];
        }

        if (themeDir) {
            NSDirectoryEnumerator *tmpEnum = [[NSFileManager defaultManager] enumeratorAtPath:themeDir];
            NSString *file, *fullpath;

            while (file = [tmpEnum nextObject]) {
                if ([[file pathExtension] isEqualToString: @"plist"]) {
                    fullpath = [themeDir stringByAppendingPathComponent:file];
                    BSThreadViewTheme *theme = [[BSThreadViewTheme alloc] initWithContentsOfFile:fullpath];
                    if (!theme) continue;

                    NSString *id_ = [theme identifier];
                    if (!id_) {
                        id_ = @"(No Name)";
                    } else if ([id_ isEqualToString:kThreadViewThemeCustomThemeIdentifier]) {
                        [theme release];
                        continue;
                    }

                    [tmp addObject:[NSDictionary dictionaryWithObjectsAndKeys:fullpath, @"ThemeFilePath", id_, @"Identifier", [NSNumber numberWithBool:NO], @"IsInternalTheme", NULL]];
                    [theme release];
                }
            }
        }
        [m_themesInfoArray release];
        m_themesInfoArray = [[NSArray arrayWithArray:tmp] retain];
        m_isThemesInfoArrayValid = YES;
    }
	return m_themesInfoArray;
}

- (void)invalidateInstalledThemes
{
    m_isThemesInfoArrayValid = NO;
}
@end
