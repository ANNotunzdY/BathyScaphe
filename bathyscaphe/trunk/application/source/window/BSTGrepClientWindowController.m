//
//  BSTGrepClientWindowController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/09/20.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSTGrepClientWindowController.h"
#import "CocoMonar_Prefix.h"
#import "AppDefaults.h"
#import <SGAppKit/SGAppKit.h>
#import "BSQuickLookPanelController.h"
#import "BSQuickLookObject.h"
#import "CMRThreadSignature.h"
#import "CMRDocumentController.h"
#import "BSTGrepSoulGem.h"
#import "missing.h"


@interface NSObject(BSTGrepCLientArrayControllerStub)
- (void)quickLook:(NSIndexSet *)indexes parent:(NSWindow *)parentWindow keepLook:(BOOL)flag;
@end


@interface BSTGrepClientWindowController(Private)
- (void)setupSearchOptionButton;
- (NSString *)createDestinationFolder;
- (void)cleanupDownloadTask;
- (void)openThreadsWithNewWindow:(NSArray *)threadSignatures;
- (void)searchFinished:(NSArray *)searchResult;
- (NSArray *)targetThreadsForActionSender:(id)sender;
@end


@implementation BSTGrepClientWindowController

@synthesize lastQuery = m_lastQuery;

APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance)

- (id)init
{
    if (self = [super initWithWindowNibName:@"BSTGrepClientWindow"]) {
        m_soulGem = [[BSFind2chSoulGem alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [m_soulGem release];
    [m_cacheIndex release];
    [m_lastQuery release];
    [m_download release];
    // nib top-level object
    [m_searchResultsController setContent:nil];
    [m_searchResultsController release];

    [super dealloc];
}

- (void)windowDidLoad
{
    [[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
    [[self window] setContentBorderThickness:22 forEdge:NSMinYEdge];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:) 
                                                 name:NSApplicationWillTerminateNotification 
                                               object:NSApp];
    [self setupSearchOptionButton];
    [m_tableView setDoubleAction:@selector(tableViewDoubleClick:)];
    [m_tableView setVerticalMotionCanBeginDrag:NO];
    [m_tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    [m_tableView setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
    [[m_infoField cell] setBackgroundStyle:NSBackgroundStyleRaised];
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
    [[self window] makeFirstResponder:[self searchField]];
}

- (NSArrayController *)searchResultsController
{
    return m_searchResultsController;
}

- (NSSearchField *)searchField
{
    return m_searchField;
}

- (NSPopUpButton *)searchOptionButton
{
    return m_searchOptionButton;
}

- (NSProgressIndicator *)progressIndicator
{
    return m_progressIndicator;
}

- (NSMutableArray *)cacheIndex
{
    if (!m_cacheIndex) {
        m_cacheIndex = [[NSMutableArray alloc] init];
    }
    return m_cacheIndex;
}

- (BSTGrepSoulGem *)soulGem
{
    return m_soulGem;
}

- (void)bsURLDownloadDidFinish:(BSURLDownload *)aDownload
{
    NSError *error = nil;
    NSString *path = [aDownload downloadedFilePath];
    NSString *downloadedContents = [[self soulGem] HTMLSourceAtPath:path];
    NSArray *searchResult = [[self soulGem] parseHTMLSource:downloadedContents error:&error];
    [self searchFinished:searchResult];
    if ([searchResult count] > 0) {
        [[self cacheIndex] addObject:[NSDictionary dictionaryWithObjectsAndKeys:self.lastQuery, @"Query",
                                      path, @"Path", [NSDate dateWithTimeIntervalSinceNow:[[self soulGem] cacheTimeInterval]], @"ExpiredDate", NULL]];
    }
    [self cleanupDownloadTask];
    if (error) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:NSLocalizedString(@"BSTGrepClientWindowController Error", @"")];
        [alert setInformativeText:NSLocalizedString(@"BSFind2chSoulGem Error Description", @"")];
        [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
    }
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didFailWithError:(NSError *)aError
{    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setMessageText:NSLocalizedString(@"BSTGrepClientWindowController Error", @"")];
    [alert setInformativeText:[aError localizedDescription]];

    [self cleanupDownloadTask];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

#pragma mark IBActions
- (IBAction)chooseSearchOption:(id)sender
{
    [CMRPref setTGrepSearchOption:[[sender selectedItem] tag]];
}

- (IBAction)startTGrep:(id)sender
{
    if (m_download) {
        NSBeep();
        return;
    }

    [self soulGem].searchOptionType = [[[self searchOptionButton] selectedItem] tag];
    NSString *queryString = [[self soulGem] queryStringForSearchString:[sender stringValue]];
    if (!queryString) {
        [[self searchResultsController] setContent:nil];
        return;
    }

    [[self progressIndicator] startAnimation:self];

    self.lastQuery = [NSURL URLWithString:queryString];
    // Search cache
    NSArray *queries = [[self cacheIndex] valueForKey:@"Query"];
    NSUInteger index = [queries indexOfObject:self.lastQuery];
    if (index != NSNotFound) {
        NSDictionary *cache = [[self cacheIndex] objectAtIndex:index];
        NSDate *expiredDate = [cache objectForKey:@"ExpiredDate"];
        if ([expiredDate compare:[NSDate date]] != NSOrderedAscending) {
            NSString *cachedHTMLPath = [cache objectForKey:@"Path"];
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:cachedHTMLPath isDirectory:&isDir] && !isDir) {
                // Use cache.
                NSString *cachedContents = [[self soulGem] HTMLSourceAtPath:cachedHTMLPath];
                NSArray *searchResult = [[self soulGem] parseHTMLSource:cachedContents error:NULL];
                [self searchFinished:searchResult];
                [[self progressIndicator] stopAnimation:self];
                return;
            } else {
                // Invalid cache.
                NSString *dirPath = [cachedHTMLPath stringByDeletingLastPathComponent];
                [[NSFileManager defaultManager] removeItemAtPath:dirPath error:NULL];
                [[self cacheIndex] removeObjectAtIndex:index];
            }
        } else {
            // Expired cache.
            NSString *dirPath = [[cache objectForKey:@"Path"] stringByDeletingLastPathComponent];
            [[NSFileManager defaultManager] removeItemAtPath:dirPath error:NULL];
            [[self cacheIndex] removeObjectAtIndex:index];
        }
    }

    m_download = [[BSURLDownload alloc] initWithURL:self.lastQuery
                                           delegate:self
                                        destination:[self createDestinationFolder]];
}

- (IBAction)cancelCurrentTask:(id)sender
{
    if (m_download) {
        [m_download cancel];
        [self cleanupDownloadTask];
    }
}

- (IBAction)openSelectedThreads:(id)sender
{
    [self openThreadsWithNewWindow:[[self targetThreadsForActionSender:sender] valueForKey:@"threadSignature"]];
}

- (IBAction)openInBrowser:(id)sender
{
    NSArray *urls = [[self targetThreadsForActionSender:sender] valueForKey:@"threadURL"];
    [[NSWorkspace sharedWorkspace] openURLs:urls inBackground:[CMRPref openInBg]];
}

- (IBAction)quickLook:(id)sender
{
    NSIndexSet *indexes;
    if ([sender tag] == 700) {
        NSInteger clickedRow = [m_tableView clickedRow];
        if (clickedRow != -1) {
            if ([m_tableView isRowSelected:clickedRow] && ([m_tableView numberOfSelectedRows] > 1)) {
                indexes = [[self searchResultsController] selectionIndexes];
            } else {
                indexes = [NSIndexSet indexSetWithIndex:clickedRow];
            }
        } else {
            indexes = [[self searchResultsController] selectionIndexes];
        }
    } else {
        indexes = [[self searchResultsController] selectionIndexes];
    }

    [[self searchResultsController] quickLook:indexes parent:[self window] keepLook:NO];
}

- (IBAction)showMainBrowser:(id)sender
{
    id object = [[self targetThreadsForActionSender:sender] objectAtIndex:0];
    CMRThreadSignature *signature = [object valueForKey:@"threadSignature"];
    if (!signature) {
        NSBeep();
        return;
    }
    [[NSApp delegate] showThreadsListForBoard:[signature boardName] selectThread:[signature threadDocumentPath] addToListIfNeeded:YES];
}

- (IBAction)openBBSInBrowser:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:self.lastQuery inBackground:[CMRPref openInBg]];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
    SEL action = [anItem action];
    if (action == @selector(cancelCurrentTask:)) {
        return (m_download != nil);
    }

    if (action == @selector(openSelectedThreads:) || 
        action == @selector(openInBrowser:) || 
        action == @selector(quickLook:) || 
        action == @selector(showMainBrowser:)) {
        if ([anItem tag] == 700) { // Contexual Menu Item
            NSInteger clickedRow = [m_tableView clickedRow];
            if (clickedRow != -1) {
                return YES;
            }
        }
        return ([[[self searchResultsController] selectionIndexes] count] > 0);
    }

    if (action == @selector(openBBSInBrowser:)) {
        if ([(id)anItem isKindOfClass:[NSMenuItem class]]) {
            [(NSMenuItem *)anItem setTitle:NSLocalizedString(@"Open Search Results in Browser", @"")];
        }
        return (m_lastQuery != nil);
    }
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{       
    NSString *cacheDir = [[[CMRFileManager defaultManager] supportDirectoryWithName:@"tGrep cache"] filepath];
    [[NSFileManager defaultManager] removeItemAtPath:cacheDir error:NULL];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Table View Delegate
- (BOOL)tableView:(NSTableView *)aTableView shouldPerformKeyEquivalent:(NSEvent *)theEvent
{
    if ([aTableView selectedRow] == -1) {
        return NO;
    }

    NSString *whichKey = [theEvent charactersIgnoringModifiers];

    if ([whichKey isEqualToString:@" "]) { // space key
        [self quickLook:aTableView];
        return YES;
    }
    
    if ([whichKey isEqualToString:[NSString stringWithCharacter:NSCarriageReturnCharacter]]) { // return key
        [self openSelectedThreads:aTableView];
        return YES;
    }
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    BSQuickLookPanelController *qlc = [BSQuickLookPanelController sharedInstance];
    if ([qlc isLooking]) {
        [[self searchResultsController] quickLook:[[self searchResultsController] selectionIndexes] parent:[self window] keepLook:YES];
    }
}
@end


@implementation BSTGrepClientWindowController(Private)
- (void)setupSearchOptionButton
{
    NSArray *items = [[self searchOptionButton] itemArray];
    for (NSMenuItem *item in items) {
        [item setHidden:![[self soulGem] canHandleSearchOptionType:[item tag]]];
    }
    
    BSTGrepSearchOptionType type = [CMRPref tGrepSearchOption];
    if (![[self soulGem] canHandleSearchOptionType:type]) {
        type = [[self soulGem] defaultSearchOptionType];
    }
    [[self searchOptionButton] selectItemWithTag:type];
    [[self searchOptionButton] synchronizeTitleAndSelectedItem];    
}

- (NSString *)createDestinationFolder
{
    NSString *path_;

    NSString *cacheDir = [[[CMRFileManager defaultManager] supportDirectoryWithName:@"tGrep cache"] filepath];
    NSString *tmpDir = [cacheDir stringByAppendingPathComponent:@"rskXXXXXX"];

    char *cTmpDir = strdup([tmpDir fileSystemRepresentation]);
    
    mkdtemp(cTmpDir);
    path_ = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:cTmpDir length:strlen(cTmpDir)];
    
    free(cTmpDir);
    
    return path_;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)code contextInfo:(void *)contextInfo
{
    ;
}

- (void)cleanupDownloadTask
{
    [[self progressIndicator] stopAnimation:nil];
    [m_download release];
    m_download = nil;
}

- (IBAction)fromQuickLook:(id)sender
{
    NSObjectController *oc = [(BSQuickLookPanelController *)[sender windowController] objectController];
    id obj = [oc valueForKeyPath:@"selection.threadSignature"];
    if (!obj) {
        return;
    }
    
    [self openThreadsWithNewWindow:[NSArray arrayWithObject:obj]];
}

- (IBAction)tableViewDoubleClick:(id)sender
{
    if ([sender clickedRow] == -1) {
        return;
    }
    [self openSelectedThreads:sender];
}

- (void)openThreadsWithNewWindow:(NSArray *)threadSignatures
{
    NSString *path;
    NSDictionary *boardInfo;
    for (id thread in threadSignatures) {
        if (![thread isKindOfClass:[CMRThreadSignature class]]) {
            continue;
        }
        path = [thread threadDocumentPath];
        boardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[thread boardName], ThreadPlistBoardNameKey,
                     [thread identifier], ThreadPlistIdentifierKey,
                     NULL];
        [[CMRDocumentController sharedDocumentController] showDocumentWithContentOfFile:[NSURL fileURLWithPath:path] boardInfo:boardInfo];
    }
}

- (void)searchFinished:(NSArray *)searchResult
{
    [[self searchResultsController] setContent:searchResult];
    if ([searchResult count] > 0) {
        [[self window] makeFirstResponder:[m_tableView enclosingScrollView]];
    }
}

- (NSArray *)targetThreadsForActionSender:(id)sender
{
    if ([sender tag] == 700) {
        NSInteger clickedRow = [m_tableView clickedRow];
        if (clickedRow != -1) {
            if ([m_tableView isRowSelected:clickedRow] && ([m_tableView numberOfSelectedRows] > 1)) {
                return [[self searchResultsController] selectedObjects];
            } else {
                return [NSArray arrayWithObject:[[[self searchResultsController] arrangedObjects] objectAtIndex:clickedRow]];
            }
        }        
    }
    return [[self searchResultsController] selectedObjects];
}    
@end
