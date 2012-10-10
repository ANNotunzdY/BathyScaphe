//
//  CMRAppDelegate.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/19.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAppDelegate_p.h"
#import "BoardWarrior.h"
#import "CMRBrowser.h"
#import "BoardListItem.h"
#import "CMRDocumentController.h"
#import "TS2SoftwareUpdate.h"
#import "CMRDocumentController.h"
#import "BSDateFormatter.h"
#import "DatabaseManager.h"
#import "CookieManager.h"
#import "BSTGrepClientWindowController.h"
#import "BSAppResetPanelController.h"

static NSString *const kOnlineItemKey = @"On Line";
static NSString *const kOfflineItemKey = @"Off Line";
//static NSString *const kOnlineItemImageName = @"online";
//static NSString *const kOfflineItemImageName = @"offline";

static NSString *const kWhatsNewHelpAnchorKey = @"WhatsNewHelpAnchor";

static NSString *const kSWCheckURLKey = @"System - Software Update Check URL";
static NSString *const kSWDownloadURLKey = @"System - Software Update Download Page URL";

@implementation CMRAppDelegate
- (void)awakeFromNib
{
    [self setupMenu];
}

- (NSString *)threadPath
{
	return m_threadPath;
}

- (void)setThreadPath:(NSString *)aString
{
	[aString retain];
	[m_threadPath release];
	m_threadPath = aString;
}

- (void)dealloc
{
	[self setThreadPath:nil];
	[super dealloc];
}

#pragma mark IBAction
- (IBAction)checkForUpdate:(id)sender
{
	[[TS2SoftwareUpdate sharedInstance] startUpdateCheck:sender];
}

- (IBAction)showPreferencesPane:(id)sender
{
	[NSApp sendAction:@selector(showWindow:) to:[CMRPref sharedPreferencesPane] from:sender];
}

- (IBAction)toggleOnlineMode:(id)sender
{   
	[CMRPref setIsOnlineMode:(![CMRPref isOnlineMode])];
}

- (IBAction)resetApplication:(id)sender
{
    BSAppResetPanelController *resetController = [[BSAppResetPanelController alloc] init];
    NSWindow *window = [resetController window];
    NSInteger returnCode = [NSApp runModalForWindow:window];
    NSUInteger mask = [CMRPref appResetTargetMask];
    [window orderOut:self];

    if (returnCode == NSOKButton) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:mask] forKey:@"targetMask"];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:CMRApplicationWillResetNotification object:self userInfo:userInfo];
        
        if (mask & BSAppResetCookie) {
            [[CookieManager defaultManager] removeAllCookies];
        }
        if (mask & BSAppResetCache) {
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
        }
        if (mask & BSAppResetHistory) {
            [[CMRHistoryManager defaultManager] removeAllItems];
        }
        if (mask & BSAppResetWindow) {
            [self closeAll:self];
        }
        if (mask & BSAppResetPreviewer) {
            [NSApp sendAction:@selector(resetPreviewer:) to:[CMRPref sharedLinkPreviewer] from:sender];
        }

		[nc postNotificationName:CMRApplicationDidResetNotification object:self userInfo:userInfo];
    }
    [resetController release];
}

- (IBAction)vacuumAndTerminate:(id)sender
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:[self localizedString:@"VacuumMsg"]];
	[alert setInformativeText:[self localizedString:@"VacuumInfo"]];
	[alert addButtonWithTitle:[self localizedString:@"VacuumOK"]];
	[alert addButtonWithTitle:[self localizedString:@"VacuumQuit"]];
	[alert addButtonWithTitle:[self localizedString:@"VacuumCancel"]];
	NSInteger choice = [alert runModal];
	if (choice == NSAlertFirstButtonReturn) {
		[[DatabaseManager defaultManager] doVacuum];
		[NSApp terminate:sender];
	} else if (choice == NSAlertSecondButtonReturn) {
		[NSApp terminate:sender];
	}
}

- (IBAction)customizeTextTemplates:(id)sender
{
	[[CMRPref sharedPreferencesPane] showSubpaneWithIdentifier:PPReplyTemplatesSubpaneIdentifier atPaneIdentifier:PPReplyDefaultIdentifier];
}

- (IBAction)togglePreviewPanel:(id)sender
{
    id previewer = [CMRPref sharedLinkPreviewer];
    if (!previewer) {
        previewer = [CMRPref sharedImagePreviewer];
    }
    if (!previewer) {
        return;
    }
	[NSApp sendAction:@selector(togglePreviewPanel:) to:previewer from:sender];
}

- (IBAction)showTaskInfoPanel:(id)sender
{
    [[CMRTaskManager defaultManager] showWindow:sender];
}

- (IBAction)showTGrepClientWindow:(id)sender
{
    [[BSTGrepClientWindowController sharedInstance] showWindow:sender];
}

// For Help Menu
- (IBAction)openURL:(id)sender
{
    NSURL *url;
    
    UTILAssertRespondsTo(sender, @selector(representedObject));
    if ((url = [sender representedObject])) {
        UTILAssertKindOfClass(url, NSURL);
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (IBAction)showWhatsnew:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:[self localizedString:kWhatsNewHelpAnchorKey] inBook:[NSBundle applicationHelpBookName]];
}

- (IBAction)showAcknowledgment:(id)sender
{
	NSBundle	*mainBundle;
    NSString	*fileName;
	NSString	*appName;
	NSWorkspace	*ws = [NSWorkspace sharedWorkspace];

    mainBundle = [NSBundle mainBundle];
    fileName = [mainBundle pathForResource:@"Acknowledgments" ofType:@"rtf"];
	appName = [ws absolutePathForAppBundleWithIdentifier:@"com.apple.TextEdit"];
	
    [ws openFile:fileName withApplication:appName];
}

- (IBAction)openURLPanel:(id)sender
{
	if (![NSApp isActive]) [NSApp activateIgnoringOtherApps:YES];
	[[CMROpenURLManager defaultManager] askUserURL];
}

- (IBAction)closeAll:(id)sender
{
	NSArray *allWindows = [NSApp windows];
	if (!allWindows) return;
	NSEnumerator	*iter = [allWindows objectEnumerator];
	NSWindow		*window;
	while (window = [iter nextObject]) {
		if ([window isVisible] && ![window isSheet]) {
			[window performClose:sender];
		}
	}
}

- (IBAction)clearHistory:(id)sender
{
	[[CMRHistoryManager defaultManager] removeAllItems];
}

- (IBAction)showThreadFromHistoryMenu:(id)sender
{
	UTILAssertRespondsTo(sender, @selector(representedObject));
    [[CMRDocumentController sharedDocumentController] showDocumentWithHistoryItem:[sender representedObject]];
}

- (IBAction)showBoardFromHistoryMenu:(id)sender
{
    UTILAssertRespondsTo(sender, @selector(representedObject));

	BoardListItem *boardListItem = [sender representedObject];
	if (boardListItem && [boardListItem respondsToSelector: @selector(representName)]) {
		[self showThreadsListForBoard:[boardListItem representName] selectThread:nil addToListIfNeeded:YES];
	}
}

- (IBAction)startHEADCheckDirectly:(id)sender
{
	BOOL	hasBeenOnline = [CMRPref isOnlineMode];

	// 簡単のため、いったんオンラインモードを切る
	if (hasBeenOnline) [self toggleOnlineMode:sender];
	
	[self showThreadsListForBoard:CMXFavoritesDirectoryName selectThread:nil addToListIfNeeded:NO];
	[CMRMainBrowser reloadThreadsList:sender];

	// 必要ならオンラインに復帰
	if (hasBeenOnline) [self toggleOnlineMode:sender];
}

- (IBAction)runBoardWarrior:(id)sender
{
	[[BoardWarrior warrior] syncBoardLists];
}

- (IBAction)openAEDictionary:(id)sender
{
	NSString *selfPath = [[NSBundle mainBundle] bundlePath];
	NSString *toysPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.ScriptEditor2"];
	if (selfPath && toysPath) {
		[[NSWorkspace sharedWorkspace] openFile:selfPath withApplication:toysPath];
	}
}

- (void)mainBrowserDidFinishShowThList:(NSNotification *)aNotification
{
	UTILAssertNotificationName(
		aNotification,
		CMRBrowserThListUpdateDelegateTaskDidFinishNotification);

	[CMRMainBrowser selectRowWithThreadPath:[self threadPath]
					   byExtendingSelection:NO
							scrollToVisible:YES];

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:CMRBrowserThListUpdateDelegateTaskDidFinishNotification
												  object:CMRMainBrowser];
}

- (void)showThreadsListForBoard:(NSString *)boardName selectThread:(NSString *)path addToListIfNeeded:(BOOL)addToList
{
	if (CMRMainBrowser) {
		[CMRMainBrowser showWindow:self];
	} else {
		[[CMRDocumentController sharedDocumentController] newDocument:self];
	}

	if (path) {
		[self setThreadPath:path];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mainBrowserDidFinishShowThList:)
													 name:CMRBrowserThListUpdateDelegateTaskDidFinishNotification
												   object:CMRMainBrowser];
	}
	// addBrdToUsrListIfNeeded オプションは当面の間無視（常に YES 扱いで）
	[CMRMainBrowser selectRowOfName:boardName forceReload:NO]; // この結果として outlineView の selectionDidChange: が「確実に」
													 // 呼び出される限り、そこから showThreadsListForBoardName: が呼び出される
}

- (IBAction)openWebSiteForUpdate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SGTemplateResource(kSWDownloadURLKey)]];
}

#pragma mark Validation
- (BOOL)validateNSControlToolbarItem:(NSToolbarItem *)item
{
	SEL action = [(NSControl *)[item view] action];
	if (action == @selector(toggleOnlineMode:)) {
		BOOL			isOnline = [CMRPref isOnlineMode];
		NSString		*title_;
		
		title_ = isOnline ? [self localizedString:kOnlineItemKey] : [self localizedString:kOfflineItemKey];
		
		[(NSButton *)[item view] setState:(isOnline ? NSOnState : NSOffState)];
		[item setLabel:title_];
		return YES;
	}
	return YES;
}
/*
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	SEL action_ = [theItem action];

	if (action_ == @selector(toggleOnlineMode:)) {
		BOOL			isOnline = [CMRPref isOnlineMode];
		NSString		*title_;
		NSImage			*image_;
		
		title_ = isOnline ? [self localizedString:kOnlineItemKey] : [self localizedString:kOfflineItemKey];
		image_ = isOnline ? [NSImage imageAppNamed:kOnlineItemImageName] : [NSImage imageAppNamed:kOfflineItemImageName];
		
		[theItem setImage:image_];
		[theItem setLabel:title_];
		return YES;
	}

	return YES;
}
*/
- (BOOL)validateMenuItem:(NSMenuItem *)theItem
{
	SEL action_ = [theItem action];

	if (action_ == @selector(closeAll:)) {
		return ([NSApp makeWindowsPerform:@selector(isVisible) inOrder:YES] != nil);
	} else if (action_ == @selector(togglePreviewPanel:)) {
        id newPreviewer = [CMRPref sharedLinkPreviewer];
        if (!newPreviewer) {
            id oldPreviewer = [CMRPref sharedImagePreviewer];
            if (!oldPreviewer) {
                return NO;
            }
            return [oldPreviewer respondsToSelector:@selector(togglePreviewPanel:)];
        }
        return [newPreviewer respondsToSelector:@selector(togglePreviewPanel:)];
	} else if (action_ == @selector(startHEADCheckDirectly:)) {
		return YES;
	} else if (action_ == @selector(toggleOnlineMode:)) {
		[theItem setState:[CMRPref isOnlineMode] ? NSOnState : NSOffState];
		return YES;
	}
	return YES;
}

#pragma mark NSAlert delegate
- (BOOL)alertShowHelp:(NSAlert *)alert
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[alert helpAnchor] inBook:[NSBundle applicationHelpBookName]];
	return YES;
}

#pragma mark NSApplication Delegates
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	BSStringFromDateTransformer *transformer;
	NSAppleEventManager	*aeMgr = [NSAppleEventManager sharedAppleEventManager];

	[aeMgr setEventHandler:[CMROpenURLManager defaultManager]
			   andSelector:@selector(handleGetURLEvent:withReplyEvent:)
			 forEventClass:'GURL'
				andEventID:'GURL'];

	TS2SoftwareUpdate *checker = [TS2SoftwareUpdate sharedInstance];
	[checker setUpdateInfoURL:[NSURL URLWithString:SGTemplateResource(kSWCheckURLKey)]];
	[checker setUpdateNowSelector:@selector(openWebSiteForUpdate:)];

	transformer = [[[BSStringFromDateTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"BSStringFromDateTransformer"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	AppDefaults *defaults_ = CMRPref;

    /* Service menu */
    [NSApp setServicesProvider:[CMROpenURLManager defaultManager]];

	/* Remove Debug menu if needed */
    [[CMRMainMenuManager defaultManager] removeDebugMenuItemIfNeeded];
    
    [[CMRMainMenuManager defaultManager] removeFullScreenMenuItemIfNeeded];

    if (![defaults_ invalidSortDescriptorFixed]) {
        [self fixInvalidSortDescriptors];
    }

	/* BoardWarrior Task */
//	if ([defaults_ isOnlineMode] && [defaults_ autoSyncBoardList]) {
//		NSDate *lastDate = [defaults_ lastSyncDate];
//		if (!lastDate || [[NSDate date] timeIntervalSinceDate: lastDate] > [defaults_ timeIntervalForAutoSyncPrefs]) {
//			[self runBoardWarrior:nil];
//		}
//	}
    if (![defaults_ invalidBoardDataRemoved]) {
        [self removeInfoServerData];
    }
    
    if (![defaults_ noNameEntityReferenceConverted]) {
        [self fixUnconvertedNoNameEntityReference];
    }

    /* Software Update */
    [TS2SoftwareUpdate setShowsDebugLog:[[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]];
	if ([defaults_ isOnlineMode]) {
        [[TS2SoftwareUpdate sharedInstance] startUpdateCheck:nil];
    }
}
@end


@implementation CMRAppDelegate(CMRLocalizableStringsOwner)
+ (NSString *)localizableStringsTableName
{
    return APP_MAINMENU_LOCALIZABLE_FILE_NAME;
}
@end
