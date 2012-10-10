//
//  CMRBrowser.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/26.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRBrowser_p.h"
#import "BSBoardInfoInspector.h"
#import "BSQuickLookPanelController.h"

NSString *const CMRBrowserDidChangeBoardNotification = @"CMRBrowserDidChangeBoardNotification";
NSString *const CMRBrowserThListUpdateDelegateTaskDidFinishNotification = @"CMRBrThListUpdateDelgTaskDidFinishNotification";

static NSString *const kObservingKey = @"isSplitViewVertical";

/*
 * current main browser instance.
 * @see CMRExports.h 
 */
CMRBrowser *CMRMainBrowser = nil;

@implementation CMRBrowser
- (id)init
{
	if (self = [super init]) {
        [self setShouldCascadeWindows:YES];

		if (!CMRMainBrowser) {
			CMRMainBrowser = self;
		}

        [self setKeepPaths:nil];
        [self setKeepCondition:CMRAutoscrollNone];
        
        m_isTogglingFullScreen = NO;
        m_isFirstResponderMayCollapsed = NO;
        m_hasWindowsRestorationJustFinished = NO;
	}
	return self;
}

- (void)document:(NSDocument *)document willChangeThreadsListViewMode:(NSUInteger)newMode
{
    if (document == [self document]) {
        [self storeKeepPath:CMRAutoscrollWhenTLVMChange];
    }
}

- (NSString *)windowNibName
{
	return @"BSBrowser";
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	// スーパークラス（CMRThreadViewer）が行なっている処理は CMRBrowser では不要なので、単に displayName を返す。
	return displayName;
}

#pragma mark -
- (void)exchangeOrDisposeMainBrowser
{
	NSArray *curWindows = [NSApp orderedWindows];
	if (!curWindows || [curWindows count] == 0) {
		// Dispose...
		CMRMainBrowser = nil;
		return;
	}

	NSEnumerator *iter_ = [curWindows objectEnumerator];
	NSWindow *eachItem;
	
	while (eachItem = [iter_ nextObject]) {
		NSWindowController *winController = [eachItem windowController];

		if (winController == self) {
			continue;
		}

		if ([winController isKindOfClass:[self class]]) {
			// exchange...
			CMRMainBrowser = (CMRBrowser *)winController;
			break;
		}
	}

	// Dispose...
	if (CMRMainBrowser == self) {
		CMRMainBrowser = nil;
	}
}

- (void)dealloc
{
	if ([[[BSQuickLookPanelController sharedInstance] qlPanelParent] windowController] == self) {
		[[BSQuickLookPanelController sharedInstance] setQlPanelParent:nil];
	}

	// dispose main browser...
	if (CMRMainBrowser == self) {
		[self exchangeOrDisposeMainBrowser];
	}

    [self setKeepPaths:nil];
	[m_addBoardSheetController release];
	[m_editBoardSheetController release];

	[super dealloc];
}

#pragma mark -
- (void)didChangeThread
{
	[super didChangeThread];
	// 履歴メニューから選択した可能性もあるので、
	// 表示したスレッドを一覧でも選択させる
	[self selectRowWithCurrentThread:YES];
}

- (void)document:(NSDocument *)aDocument willRemoveController:(NSWindowController *)aController
{
	[self setCurrentThreadsList:nil];
	[super document:aDocument willRemoveController:aController];
}

- (BOOL)shouldShowContents
{
    return ![[self splitView] isSubviewCollapsed:bottomSubview];
}

- (BOOL)shouldLoadWindowFrameUsingCache
{
	return NO;
}

- (void)closeWindowOfAlert:(NSAlert *)alert
{
    UTILDebugWrite(@"Override to block!");
    [self cleanUpItemsToBeRemoved:nil];
}

- (NSArray *)keepPaths
{
    return m_keepPaths;
}

- (void)setKeepPaths:(NSArray *)array
{
    [array retain];
    [m_keepPaths release];
    m_keepPaths = array;
}

- (void)storeKeepPath:(CMRAutoscrollCondition)type
{
    NSIndexSet *rows = [[self threadsListTable] selectedRowIndexes];
    NSArray *tmp = nil;
    if (rows && ([rows count] > 0)) {
        tmp = [[self currentThreadsList] tableView:[self threadsListTable] threadFilePathsArrayAtRowIndexes:rows];
    }
    [self setKeepPaths:tmp];
    [self setKeepCondition:type];
}

- (CMRAutoscrollCondition)keepCondition
{
    return m_keepCondition;
}

- (void)setKeepCondition:(CMRAutoscrollCondition)type
{
    m_keepCondition = type;
}

- (void)notifyBrowserThListUpdateDelegateNotification
{
    UTILNotifyName(CMRBrowserThListUpdateDelegateTaskDidFinishNotification);
    if (m_hasWindowsRestorationJustFinished) {
        id signature = [[self document] signatureForWindowRestoration];
        if (signature) {
            NSString *path = [(CMRThreadSignature *)signature threadDocumentPath];
            NSDictionary *boardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[(CMRThreadSignature *)signature boardName], ThreadPlistBoardNameKey, [(CMRThreadSignature *)signature identifier], ThreadPlistIdentifierKey, NULL];
            [self setThreadContentWithFilePath:path boardInfo:boardInfo];
            // フォーカス
            [[self window] makeFirstResponder:[self textView]];
            [self synchronizeWindowTitleWithDocumentName];
        }
        m_hasWindowsRestorationJustFinished = NO;
    }
}

- (void)controller:(EditBoardSheetController *)controller didEndSheetWithReturnCode:(NSInteger)code
{
    // Do nothing
}
@end


@implementation CMRBrowser(ThreadContents)
- (void)addThreadTitleToHistory
{
	NSString *threadTitleAndBoardName;
	BSTitleRulerView *ruler = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];

	[super addThreadTitleToHistory];

	threadTitleAndBoardName = [self titleForTitleBar];
	[ruler setTitleStr:(threadTitleAndBoardName ? threadTitleAndBoardName : @"")];
	[ruler setPathStr:[self path]];
}
@end


@implementation CMRBrowser(SelectingThreads)
- (NSUInteger)numberOfSelectedThreads
{
	NSUInteger count = [[self threadsListTable] numberOfSelectedRows];

	// 選択していないが表示している
	if ((count == 0) && [self shouldShowContents]) {
		return [super numberOfSelectedThreads];
	}
	return count;
}

- (NSArray *)selectedThreads
{
    NSTableView *tv = [self threadsListTable];
    NSString *path = [self shouldShowContents] ? [self path] : nil;
    NSArray *array = [[self currentThreadsList] tableView:tv threadAttibutesArrayAtRowIndexes:[tv selectedRowIndexes] exceptingPath:path];
    if (!array) {
        array = [NSArray array];
    }
    if ([self shouldShowContents] && [self path]) {
        id obj = [super selectedThread];
        if (obj) {
            return [array arrayByAddingObject:obj];
        }
    }
    return array;
}

- (NSArray *)selectedThreadsReallySelected
{
	NSTableView *tableView = [self threadsListTable];
	NSIndexSet	*selectedRows = [tableView selectedRowIndexes];
	CMRThreadsList	*threadsList = [self currentThreadsList];
	if (!threadsList || !selectedRows || [selectedRows count] == 0) {
		return [NSArray array];
	}

	return [threadsList tableView:tableView threadAttibutesArrayAtRowIndexes:selectedRows exceptingPath:nil];
}

- (NSArray *)clickedThreadsReallyClicked
{
    NSTableView *tableView = [self threadsListTable];
    NSInteger clickedRow = [tableView clickedRow];
    BOOL clickedOnMultipleItems = NO;
    
    if (clickedRow != -1) {
        clickedOnMultipleItems = [tableView isRowSelected:clickedRow] && ([tableView numberOfSelectedRows] > 1);
    } else {
        return [NSArray empty];
    }
    
    if (!clickedOnMultipleItems) {
        NSDictionary *attributes = [[self currentThreadsList] threadAttributesAtRowIndex:clickedRow inTableView:tableView];
        return [NSArray arrayWithObject:attributes];
    } else {
        return [self selectedThreadsReallySelected];
    }
}
@end
