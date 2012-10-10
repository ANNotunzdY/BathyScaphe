//
//  Browser.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/10.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "Browser.h"

#import "AppDefaults.h"
#import "CMRThreadViewer_p.h"
#import "CMRBrowser_p.h"
#import "CMRThreadsList.h"
#import "CMRThreadAttributes.h"
#import "BoardManager.h"
#import "DatabaseManager.h"
#import "BSNewThreadMessenger.h"
#import "BSModalStatusWindowController.h"
#import "missing.h"

@implementation Browser
- (id)init
{
    if (self = [super init]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        DatabaseManager *dbm =[DatabaseManager defaultManager];
        [nc addObserver:self
               selector:@selector(updateThreadsListNow:)
                   name:DatabaseDidFinishUpdateDownloadedOrDeletedThreadInfoNotification
                 object:dbm];
        [nc addObserver:self
               selector:@selector(updateThreadsListPartially:)
                   name:DatabaseWantsThreadItemsUpdateNotification
                 object:dbm];
    }
    return self;
}

- (void)updateThreadsListNow:(NSNotification *)notification
{
    [[self currentThreadsList] updateCursor];
}

- (void)updateThreadsListPartially:(NSNotification *)notification
{
    BSDBThreadList *list = [self currentThreadsList];
    // スマート掲示板の場合は、自動ソートが無効になっていても「自動ソート」せざるを得ない。
    if ([list viewMode] == BSThreadsListShowsSmartList) {
        [list updateCursor];
        return;
    }

    NSDictionary *userInfo = [notification userInfo];
    NSArray *files = [userInfo objectForKey:UserInfoThreadPathsArrayKey];
    if (files) {
        [list cleanUpThreadItem:files];
    } else {
        BOOL isInsertion = [[userInfo objectForKey:UserInfoIsDBInsertedKey] boolValue];
        if (isInsertion && ([list viewMode] == BSThreadsListShowsStoredLogFiles)) {
            [list updateCursor];
        } else {
            [list updateThreadItem:userInfo];
        }
    }
}

- (void)dealloc
{   
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setCurrentThreadsList:nil];
    [self setSearchString:nil];
    [m_signatureForWindowRestoration release];

    [super dealloc];
}

- (NSURL *)boardURL
{
    return [[self currentThreadsList] boardURL];
}

- (BSDBThreadList *)currentThreadsList
{
    return m_currentThreadsList;
}

- (void)setCurrentThreadsList:(BSDBThreadList *)aCurrentThreadsList
{
    [self willChangeValueForKey:@"threadsListViewMode"];
    [aCurrentThreadsList retain];
    [m_currentThreadsList release];
    m_currentThreadsList = aCurrentThreadsList;
    [self didChangeValueForKey:@"threadsListViewMode"];
}

- (NSString *)searchString
{
    return m_searchString;
}

- (void)setSearchString:(NSString *)text
{
    [text retain];
    [m_searchString release];
    m_searchString = text;
}

- (NSUInteger)threadsListViewMode
{
    return ([[self currentThreadsList] viewMode] % 2);
}

- (void)setThreadsListViewMode:(NSUInteger)type
{
    SEL selector = @selector(document:willChangeThreadsListViewMode:);
    NSEnumerator *iter = [[self windowControllers] objectEnumerator];
    id winController;

    while (winController = [iter nextObject]){
        if ([winController respondsToSelector:selector]) {
            [winController document:self willChangeThreadsListViewMode:type];
        }
    }

    [[self currentThreadsList] setViewMode:type];
    [[self currentThreadsList] updateCursor];
}

- (BOOL)showsThreadDocument
{
    return m_showsThreadDocument;
}

- (void)setShowsThreadDocument:(BOOL)flag
{
    m_showsThreadDocument = flag;
}

#pragma mark NSDocument
- (void)makeWindowControllers
{
    CMRBrowser      *browser_;
    
    browser_ = [[CMRBrowser alloc] init];
    [self addWindowController:browser_];
    [browser_ release];
}

- (NSString *)displayName
{
    BSDBThreadList      *list_ = [self currentThreadsList];
    if (!list_) return [super displayName];
    NSString *foo;

    if ([self searchString]) {
        NSUInteger foundNum = [list_ numberOfFilteredThreads];

        if (0 == foundNum) {
            foo = NSLocalizedStringFromTable(kSearchListNotFoundKey, @"ThreadsList", @"");
        } else {
// #warning 64BIT: Check formatting arguments
// 2010-07-29 tsawada2 修正済
            foo = [NSString stringWithFormat:NSLocalizedStringFromTable(kSearchListResultKey, @"ThreadsList", @""), (unsigned long)foundNum];
        }
    } else {
        NSString *base_ = [self threadsListViewMode] ? NSLocalizedStringFromTable(@"Browser Title (Log Mode)", @"ThreadsList", @"")
                                                     : NSLocalizedStringFromTable(@"Browser Title (Thread Mode)", @"ThreadsList", @"");
// #warning 64BIT: Check formatting arguments
// 2010-07-29 tsawada2 修正済
        foo = [NSString stringWithFormat:base_, (unsigned long)[list_ numberOfThreads]];
    }

    return [NSString stringWithFormat:@"%@ (%@)", [list_ boardName], foo];
}

- (IBAction)saveDocumentAs:(id)sender
{
    if (![self threadAttributes]) {
        return;
    }
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *filePath = [[self threadAttributes] path];
    if (!filePath || ![fileMgr fileExistsAtPath:filePath]) {
        return;
    }
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSInteger resultCode;

//    [savePanel setRequiredFileType:CMRThreadDocumentPathExtension];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:CMRThreadDocumentPathExtension]];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setCanSelectHiddenExtension:YES];
    [savePanel setNameFieldStringValue:[[self threadAttributes] threadTitle]];

//    resultCode = [savePanel runModalForDirectory:nil file:[filePath lastPathComponent]];
    resultCode = [savePanel runModal];

    if (resultCode == NSFileHandlingPanelOKButton) {
        NSString *savePath = [[savePanel URL] path];
        if ([fileMgr copyItemAtPath:filePath toPath:savePath error:NULL]) {
            NSDate  *curDate = [NSDate date];
            NSDictionary *attributes;
            attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:[savePanel isExtensionHidden]], NSFileExtensionHidden,
                                                                    curDate, NSFileModificationDate, curDate, NSFileCreationDate, NULL];
            [fileMgr setAttributes:attributes ofItemAtPath:savePath error:NULL];
        } else {
            NSBeep();
            NSLog(@"Save failure - %@", savePath);
        }
    }
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)theItem
{
    SEL action_ = [theItem action];

    if (action_ == @selector(cleanupDatochiFiles:)) {
        return [[self currentThreadsList] isBoard] && ([self threadsListViewMode] == BSThreadsListShowsLiveThreads) && ![self searchString];
    } else if (action_ == @selector(newThread:) || action_ == @selector(rebuildThreadsList:)) {
        return [[self currentThreadsList] isBoard];
    } else if (action_ == @selector(toggleThreadsListViewMode:)) {
        BSThreadsListViewModeType type = [self threadsListViewMode];
        if (type == BSThreadsListShowsLiveThreads) {
            setUserInterfaceItemTitle(theItem, NSLocalizedStringFromTable(@"Toggle View Mode To Log", @"ThreadsList", @""));
        } else {
            setUserInterfaceItemTitle(theItem, NSLocalizedStringFromTable(@"Toggle View Mode To Thread", @"ThreadsList", @""));
        }
        return ([[self currentThreadsList] viewMode] < 2);
    }

    return [super validateUserInterfaceItem:theItem];
}

#pragma mark Window Restoration (Lion)
- (void)restoreDocumentWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    NSString *docClass = [state decodeObjectForKey:@"BS_DocumentClass"];
    if (docClass && [docClass isEqualToString:@"Browser"]) {
        id signature = [state decodeObjectForKey:@"BS_ThreadSignature"];
        if (signature) {
            m_signatureForWindowRestoration = [signature retain];
        }
    }
    [super restoreDocumentWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}

- (id)signatureForWindowRestoration
{
    return m_signatureForWindowRestoration;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:NSStringFromClass([self class]) forKey:@"BS_DocumentClass"];
    if ([self showsThreadDocument] && [self threadAttributes]) {
        [coder encodeObject:[[self threadAttributes] threadSignature] forKey:@"BS_ThreadSignature"];
    }
}

#pragma mark ThreadsList
- (void)reloadThreadsList
{
    [[self currentThreadsList] downloadThreadsList];
}

- (BOOL)searchThreadsInListWithCurrentSearchString
{
    if (![self currentThreadsList]) return NO;

    return [[self currentThreadsList] filterByString:[self searchString]];
}

- (IBAction)toggleThreadsListViewMode:(id)sender
{
    BSThreadsListViewModeType newType;
    BSThreadsListViewModeType type = [self threadsListViewMode];
    if (type == BSThreadsListShowsLiveThreads) {
        newType = BSThreadsListShowsStoredLogFiles;
    } else {
        newType = BSThreadsListShowsLiveThreads;
    }
    [self setThreadsListViewMode:newType];
}

- (IBAction)newThread:(id)sender
{
    NSString                *boardName = [[self currentThreadsList] boardName];
    BSNewThreadMessenger    *document;
    NSDocumentController    *docController = [NSDocumentController sharedDocumentController];

    UTILAssertNotNil(boardName);

    document = [[BSNewThreadMessenger alloc] initWithBoardName:boardName];

    if (document) {
        [docController addDocument:document];
        [document makeWindowControllers];
        [document showWindows];
    }
    [document release];
}

- (void)showBrowserCriticalAlertMessage:(NSString *)messageTemplate informative:(NSString *)informativeText help:(NSString *)helpAnchor didEndSel:(SEL)didEndSelector
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert setMessageText:[NSString stringWithFormat:NSLocalizedStringFromTable(messageTemplate, @"ThreadsList", nil), [[self currentThreadsList] boardName]]];
    [alert setInformativeText:NSLocalizedStringFromTable(informativeText, @"ThreadsList", nil)];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"DragDropTrashOK", @"ThreadsList", nil)];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"DragDropTrashCancel", @"ThreadsList", nil)];
    [alert setShowsHelp:YES];
    [alert setHelpAnchor:NSLocalizedStringFromTable(helpAnchor, @"ThreadsList", nil)];
    [alert setDelegate:[NSApp delegate]];
    [alert beginSheetModalForWindow:[self windowForSheet]
                      modalDelegate:self
                     didEndSelector:didEndSelector
                        contextInfo:NULL];
}

- (IBAction)cleanupDatochiFiles:(id)sender
{
    [self showBrowserCriticalAlertMessage:@"CleanupDatochiFilesAlert(BoardName %@)"
                              informative:@"CleanupDatochiFilesMessage"
                                     help:@"CleanupDatochiFilesHelpAnchor"
                                didEndSel:@selector(cleanupDatochiFilesAlertDidEnd:returnCode:contextInfo:)];
}

- (IBAction)rebuildThreadsList:(id)sender
{
    [self showBrowserCriticalAlertMessage:@"RebuildThreadsListAlert(BoardName %@)"
                              informative:@"RebuildThreadsListMessage"
                                     help:@"RebuildThreadsListHelpAnchor"
                                didEndSel:@selector(rebuildThreadsListAlertDidEnd:returnCode:contextInfo:)];
}

- (void)cleanupDatochiFilesAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertFirstButtonReturn) {
        [[self currentThreadsList] removeDatochiFiles];
    }
}

- (void)rebuildDoneAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertSecondButtonReturn) {
        NSArray *files = (NSArray *)contextInfo;
        [[NSWorkspace sharedWorkspace] revealFilesInFinder:files];
        [files release];
    }
}

- (void)rebuildThreadsListAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode != NSAlertFirstButtonReturn) {
        // Canceled. Nothing to do.
        return;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuildingDidEnd:) name:CMRThreadsListDidChangeNotification object:[self currentThreadsList]];

    [[alert window] orderOut:nil];

    BSModalStatusWindowController *controller = [[BSModalStatusWindowController alloc] init];
    [[controller progressIndicator] setIndeterminate:YES];
    [[controller messageTextField] setStringValue:NSLocalizedString(@"Rebuild Database Msg", nil)];
    [[controller infoTextField] setStringValue:[[self currentThreadsList] boardName]];

    NSModalSession session = [NSApp beginModalSessionForWindow:[controller window]];
    [[controller progressIndicator] startAnimation:nil];

    [[self currentThreadsList] rebuildThreadsList];
    while (1) {
        if ([NSApp runModalSession:session] != NSRunContinuesResponse) {
            break;
        }
    }
    [[controller progressIndicator] stopAnimation:nil];
    [controller close];
    [controller release];
    [NSApp endModalSession:session];

    NSAlert *alert2;
    NSError *rebuildError = [self currentThreadsList].rebuildError;
    NSArray *invalidFiles;
    if (rebuildError) {
        invalidFiles = [[NSArray alloc] initWithArray:[[rebuildError userInfo] objectForKey:DatabaseManagerInvalidFilePathsArrayKey]];
        alert2 = [NSAlert alertWithError:(rebuildError)];
        [self currentThreadsList].rebuildError = nil;
    } else {
        invalidFiles = nil;
        alert2 = [[[NSAlert alloc] init] autorelease];
        [alert2 setAlertStyle:NSInformationalAlertStyle];
        [alert2 setMessageText:NSLocalizedStringFromTable(@"RebuildingEndAlert", @"ThreadsList", nil)];        
    }

    [alert2 beginSheetModalForWindow:[self windowForSheet]
                       modalDelegate:self
                      didEndSelector:@selector(rebuildDoneAlertDidEnd:returnCode:contextInfo:)
                         contextInfo:(invalidFiles ? (void *)invalidFiles : NULL)];
}

- (void)rebuildingDidEnd:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CMRThreadsListDidChangeNotification object:nil];
    [NSApp abortModal];
}
@end


@implementation Browser(ScriptingSupport)
- (NSTextStorage *)selectedText
{
    return [super selectedText];
}

- (NSString *)tListBoardURL
{
    return [[self boardURL] stringValue];
}

- (NSString *)tListBoardName
{
    return [[self currentThreadsList] boardName];
}

- (void)setTListBoardName:(NSString *)boardNameStr
{
    CMRBrowser *wc_ = [[self windowControllers] lastObject];
    if (!wc_) return;

    [wc_ showThreadsListWithBoardName:boardNameStr];
    [wc_ selectRowOfName:boardNameStr forceReload:NO];
}

- (void)handleReloadListCommand:(NSScriptCommand *)command
{
    [self reloadThreadsList];
}

- (void)handleReloadThreadCommand:(NSScriptCommand *)command
{
    CMRBrowser *wc_ = [[self windowControllers] lastObject];
    if (!wc_) return;

    [wc_ reloadThread:nil];
}
@end
