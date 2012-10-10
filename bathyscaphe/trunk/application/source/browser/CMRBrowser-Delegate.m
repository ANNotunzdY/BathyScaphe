//
//  CMRBrowser-Delegate.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/09/18.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRBrowser_p.h"
#import "BoardManager.h"
#import "missing.h"
#import "BSNobiNobiToolbarItem.h"
#import "BSQuickLookPanelController.h"
#import "DatabaseManager.h"
#import "BSLabelManager.h"

extern NSString *const ThreadsListDownloaderShouldRetryUpdateNotification;

@implementation CMRBrowser(Delegate)
BOOL isOptionKeyDown(void)
{
    NSUInteger flag_ = [NSEvent modifierFlags];
    if (flag_ & NSAlternateKeyMask) {
        return YES;
    } else {
        return NO;
    }
}

- (void)fixThreadsListTableScroller:(NSNotification *)aNotification
{
    NSScrollerStyle preferredStyle = [NSScroller preferredScrollerStyle];
    if ([[[self threadsListTable] enclosingScrollView] scrollerStyle] != preferredStyle) {
        [[[self threadsListTable] enclosingScrollView] setScrollerStyle:preferredStyle];
    }
}

#pragma mark NSControl Delegate (SearchField)
// Available in RainbowJerk and later.
// 検索フィールドで return などを押したとき、フォーカスをスレッド一覧に移動させる
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    if ([aNotification object] == [self searchField]) {
        [[self window] makeFirstResponder:[self threadsListTable]];
    }
}

#pragma mark NSSplitView Delegate
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    if (splitView == [self splitView]) {
        return (subview == bottomSubview);
    } else if (splitView == [self outerSplitView]) {
        return (subview == [self boardListSubview]);
    }
    return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
    if (splitView == [self splitView]) {
        return (subview == bottomSubview && dividerIndex == 0);
    }
    return NO;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
    if (splitView == [self splitView]) {
        return (dividerIndex == 0) ? (proposedMin + 100) : proposedMin;
    } else if (splitView == [self outerSplitView]) {
        return (dividerIndex == 0) ? 48 : proposedMin; 
    }
    return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    if (splitView == [self splitView]) {
        return (proposedMax > 22) ? (proposedMax - 22) : proposedMax;
    } else {
        return proposedMax;
    }
}

- (void)newLazilyAdjust:(NSView *)fixedView
{
    id nobinobiItem = [[self toolbarDelegate] itemForItemIdentifier:@"Boards List Space"];
    [nobinobiItem adjustWidth:[fixedView bounds].size.width];
    // 進行状況表示も位置調整
    NSRect currentRect = [[self statusMessageField] frame];
    CGFloat maxX = currentRect.origin.x + currentRect.size.width;
    CGFloat newOriginX = [fixedView bounds].size.width + 8;
    CGFloat newWidth = maxX - newOriginX;
    currentRect.origin.x = newOriginX;
    currentRect.size.width = newWidth;
    [[self statusMessageField] setFrame:currentRect];
    
    // スレッドタイトルバーのにじみ、テキストビューの微細なガクガク横揺れを防ぐ
    [[self splitView] adjustSubviews];
}

- (void)splitViewWillResizeSubviews:(NSNotification *)notification
{
    id splitView = [notification object];
    if (splitView == [self splitView]) {
        BOOL isCollapsed = [splitView isSubviewCollapsed:bottomSubview];
        if (!isCollapsed && ([[self window] firstResponder] == [self textView])) {
            m_isFirstResponderMayCollapsed = YES;
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resizeSync:) object:[NSNumber numberWithBool:isCollapsed]];
    } else if (splitView == [self outerSplitView]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(newLazilyAdjust:) object:[self boardListSubview]];
    }
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification
{
    id splitView = [notification object];
    if (splitView == [self splitView]) {
        BOOL isCollapsed = [splitView isSubviewCollapsed:bottomSubview];
        // first responder 状態のテキストビューが collapse されるとフォーカスが検索フィールドにふっ飛んでしまうのでスレッド一覧にフォーカスを戻す
        if (isCollapsed && m_isFirstResponderMayCollapsed) {
            [[self window] makeFirstResponder:[[self threadsListTable] enclosingScrollView]];
            m_isFirstResponderMayCollapsed = NO;
        }
        [self performSelector:@selector(resizeSync:) withObject:[NSNumber numberWithBool:isCollapsed] afterDelay:0.3];    
    } else if (splitView == [self outerSplitView]) {
        [self performSelector:@selector(newLazilyAdjust:) withObject:[self boardListSubview] afterDelay:0.1];
    }
}

- (void)resizeSync:(NSNumber *)numberWithBool
{
    BOOL isCollapsed = [numberWithBool boolValue];
    [self synchronizeLayoutSwitcher];
    [[self indexingNavigator] setHidden:isCollapsed];
    [[self numberOfMessagesField] setHidden:isCollapsed];
    [[self document] setShowsThreadDocument:!isCollapsed];
    // Lion で、リサイズ中にスクローラーが突然レガシースタイルに切り替わってしまう問題の強引な Fix...
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
        [self fixThreadsListTableScroller:nil];
    }
    // Mountain Lion の奇妙な振る舞い（テキストビューがリサイズしなくなる）の強引な Fix...
    if ([[self splitView] isVertical] && (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7)) {
        [[self textView] resizeWithOldSuperviewSize:[[self textView] bounds].size];
    }
    // リサイズ後文字がにじんだり重なる（テキストビューで）事象を予防
    [[self textView] setNeedsDisplay:YES];
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
    if ([splitView isVertical] && ([splitView dividerStyle] == NSSplitViewDividerStyleThin)) {
        NSRect extendedRect = NSInsetRect(proposedEffectiveRect, -2, 0);
        return extendedRect;
    }
    return proposedEffectiveRect;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
    if (splitView == [self splitView]) {
        if (!m_isTogglingFullScreen && ![splitView isVertical]) {
            return YES;
        } else if (!m_isTogglingFullScreen && [splitView isVertical]) {
            if (subview == topSubview) {
                if ([topSubview bounds].size.width == [splitView frame].size.width) {
                    return YES;
                }
                if ([bottomSubview bounds].size.width < 22) {
                    return YES;
                }
            }
        }
        return (subview != topSubview);
    } else if (splitView == [self outerSplitView]) {
        return (subview != [self boardListSubview]);
    }
}

#pragma mark NSOutlineView Delegate
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger                 rowIndex_;
    NSOutlineView       *brdListTable_;
    NSDictionary        *item_;
    
    brdListTable_ = [notification object];

    UTILAssertNotificationName(
        notification,
        NSOutlineViewSelectionDidChangeNotification);
    UTILAssertNotificationObject(
        notification,
        [self boardListTable]);
    
    rowIndex_ = [brdListTable_ selectedRow];
    
    if ([brdListTable_ numberOfSelectedRows] > 1) return;
    if (rowIndex_ < 0) return;
    if (rowIndex_ >= [brdListTable_ numberOfRows]) return;

    item_ = [brdListTable_ itemAtRow:rowIndex_];

    if (!item_) return;
    if (![item_ hasURL] && ![BoardListItem isFavoriteItem:item_] && ![BoardListItem isSmartItem:item_]) return;

    [self showThreadsListForBoard:item_];
}

- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([[tableColumn identifier] isEqualToString:BoardPlistNameKey]) {
        NSImage *image;
        if (![CMRPref boardListShowsIcon]) {
            image = nil;
        } else {
            NSInteger style = [CMRPref boardListRowSizeStyle];
            NSString *iconName = [item iconBaseName];
            if (style == 2) {
                iconName = [iconName stringByAppendingString:@"Medium"];
            } else if (style == 3) {
                iconName = [iconName stringByAppendingString:@"Large"];
            }
            if ([cell isHighlighted]) {
                iconName = [iconName stringByAppendingString:@"Selected"];
            }
            image = [NSImage imageAppNamed:iconName];
        }
        [cell setImage:image];
    }
}

#pragma mark Type-To-Select Support
- (NSIndexSet *)outlineView:(BSBoardListView *)boardListView findForString:(NSString *)aString
{
    SmartBoardList       *source;
    BoardListItem   *matchedItem;
    NSInteger             index;

    source = (SmartBoardList *)[boardListView dataSource];
    
    matchedItem = [source itemWithNameHavingPrefix:aString];

    if (!matchedItem) {
        return nil;
    }
        
    index = [self searchRowForItemInDeep:matchedItem inView:boardListView];
    if (-1 == index) return nil;
    return [NSIndexSet indexSetWithIndex:index];
}

#pragma mark NSTableView Delegate
- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
    static BOOL hasOptionClicked = NO;
    BoardManager *bm = [BoardManager defaultManager];
    NSString *boardName = [[self currentThreadsList] boardName];

    // Sort:
    // カラムヘッダをクリックしたとき、まず
    // -[NSObject(NSTableDataSource) tableView:sortDescriptorsDidChange:] が送られ、
    // その後で -[NSObject(NSTableViewDelegate) tableView:didClickTableColumn:] が送られる。

    // Sort:
    // Mac OS標準的ソート変更 (Finderのリスト表示参照)
    // ソートの向きは各カラムごとに保存されており、
    // ハイライトされているカラムヘッダがクリックされた時以外は、
    // 保存されている向きでソートされる。
    // 既にハイライトされているヘッダをクリックした場合は
    // 昇順／降順の切り替えと見なす。

    // Sort:
    // option キーを押しながらヘッダをクリックした場合は、変更後の設定を CMRPref に保存する（グローバルな設定の変更）。
    // ただし、option キーを押しながらクリックした場合、sortDescriptorDidChange: は呼ばれない。
    // それどころか、カラムのハイライトも更新されない。
    // 仕方がないので、option キーを押しながらクリックされた場合は、
    // ここでダミーのクリックイベントをもう一度発生させ、通常のカラムヘッダクリックをシミュレートする。
    // ダミーイベントによってもう一度 -tableView:didClickTableColumn: が発生するので、
    // そこで必要な処理を行なう。
    if (isOptionKeyDown()) {
        NSEvent *dummyEvent = [NSApp currentEvent];
        hasOptionClicked = YES;
        // このへん、Thousand のコード（THTableHeaderView.m）を参考にした
        NSEvent *downEvent = [NSEvent mouseEventWithType:NSLeftMouseDown
                                                location:[dummyEvent locationInWindow]
                                           modifierFlags:0
                                               timestamp:[dummyEvent timestamp]
                                            windowNumber:[dummyEvent windowNumber]
                                                 context:[dummyEvent context]
                                             eventNumber:[dummyEvent eventNumber]+1
                                              clickCount:1
                                                pressure:1.0];
        NSEvent *upEvent = [NSEvent mouseEventWithType:NSLeftMouseUp
                                              location:[dummyEvent locationInWindow]
                                         modifierFlags:0
                                             timestamp:[dummyEvent timestamp]
                                          windowNumber:[dummyEvent windowNumber]
                                               context:[dummyEvent context]
                                           eventNumber:[dummyEvent eventNumber]+2
                                            clickCount:1
                                              pressure:1.0];
        [NSApp postEvent:upEvent atStart:NO];
        [NSApp postEvent:downEvent atStart:YES];

        return;
    }

    // 設定の保存
    [bm setSortDescriptors:[tableView sortDescriptors] forBoard:boardName];

    if (hasOptionClicked) {
        [CMRPref setThreadsListSortDescriptors:[tableView sortDescriptors]];
        hasOptionClicked = NO;
    }

    NSInteger selected = [tableView selectedRow];
    if (selected != -1) {
        CMRAutoscrollCondition prefMask = [CMRPref threadsListAutoscrollMask];
        if (prefMask & CMRAutoscrollWhenTLSort) {
            [tableView scrollRowToVisible:selected];
        } else {
            [tableView scrollRowToVisible:0];
        }
    } else {
        [tableView scrollRowToVisible:0];
    }

    UTILDebugWrite(@"Catch tableView:didClickTableColumn:");
}

- (void)saveBrowserListColumnState:(NSTableView *)targetTableView
{
    [CMRPref setThreadsListTableColumnState:[targetTableView columnState]];
}

- (void)tableViewColumnDidMove:(NSNotification *)aNotification
{
    [self saveBrowserListColumnState:[aNotification object]];
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
    [self saveBrowserListColumnState:[aNotification object]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    BSQuickLookPanelController *qlc = [BSQuickLookPanelController sharedInstance];
    NSTableView *tableView = [aNotification object];
    if ([qlc isLooking]) {
        [[tableView dataSource] tableView:self quickLookAtRowIndexes:[tableView selectedRowIndexes] keepLook:YES];
    }
}

#pragma mark NSWindow Fullscreen Delegate
- (void)windowWillEnterFullScreen:(NSNotification *)notification
{
    m_isTogglingFullScreen = YES;
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
    m_isTogglingFullScreen = NO;
}

- (void)windowWillExitFullScreen:(NSNotification *)notification
{
    m_isTogglingFullScreen = YES;
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
    m_isTogglingFullScreen = NO;
}
@end


@implementation CMRBrowser(NotificationPrivate)
- (void)registerToNotificationCenter
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    DatabaseManager *db = [DatabaseManager defaultManager];
    [nc addObserver:self
           selector:@selector(boardManagerUserListDidChange:)
               name:CMRBBSManagerUserListDidChangeNotification
             object:[BoardManager defaultManager]];
    [nc addObserver:self
           selector:@selector(threadsListDownloaderShouldRetryUpdate:)
               name:ThreadsListDownloaderShouldRetryUpdateNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(threadDocumentDidToggleDatOchiStatus:)
               name:CMRAbstractThreadDocumentDidToggleDatOchiNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(threadDocumentDidToggleLabel:)
               name:CMRAbstractThreadDocumentDidToggleLabelNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(databaseWillUpdateThreadItem:)
               name:DatabaseWillUpdateThreadItemNotification
             object:db];
    [nc addObserver:self
           selector:@selector(databaseWillDeleteThreadItems:)
               name:DatabaseWillDeleteThreadItemsNotification
             object:db];

    [nc addObserver:self
           selector:@selector(labelDisplayNamesUpdated:)
               name:BSLabelManagerDidUpdateDisplayNamesNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(labelColorsUpdated:)
               name:BSLabelManagerDidUpdateBackgroundColorsNotification
             object:nil];
    
    // Lion
    [nc addObserver:self
           selector:@selector(windowsRestorationDidFinish:)
               name:@"NSApplicationDidFinishRestoringWindowsNotification"
             object:NSApp];
    [nc addObserver:self
           selector:@selector(fixThreadsListTableScroller:)
               name:@"NSPreferredScrollerStyleDidChangeNotification"
             object:nil];
    
    [super registerToNotificationCenter];
}

- (void)removeFromNotificationCenter
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    DatabaseManager *db = [DatabaseManager defaultManager];

    // Lion
    [nc removeObserver:self name:@"NSPreferredScrollerStyleDidChangeNotification" object:nil];
    [nc removeObserver:self name:@"NSApplicationDidFinishRestoringWindowsNotification" object:NSApp];

    [nc removeObserver:self name:BSLabelManagerDidUpdateBackgroundColorsNotification object:nil];
    [nc removeObserver:self name:BSLabelManagerDidUpdateDisplayNamesNotification object:nil];

    [nc removeObserver:self name:DatabaseWillDeleteThreadItemsNotification object:db]; 
    [nc removeObserver:self name:DatabaseWillUpdateThreadItemNotification object:db];
    [nc removeObserver:self name:CMRAbstractThreadDocumentDidToggleLabelNotification object:nil];
    [nc removeObserver:self name:CMRAbstractThreadDocumentDidToggleDatOchiNotification object:nil];
    [nc removeObserver:self name:ThreadsListDownloaderShouldRetryUpdateNotification object:nil];
    [nc removeObserver:self name:CMRBBSManagerUserListDidChangeNotification object:[BoardManager defaultManager]];

    [super removeFromNotificationCenter];
}

- (void)boardManagerUserListDidChange:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, CMRBBSManagerUserListDidChangeNotification);
    UTILAssertNotificationObject(notification, [BoardManager defaultManager]);

    [[self boardListTable] reloadData];
    id item = [[self currentThreadsList] boardListItem];
    [self reselectBoard:item];
}

- (void)appDefaultsLayoutSettingsUpdated:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, AppDefaultsLayoutSettingsUpdatedNotification);
    UTILAssertNotificationObject(notification, CMRPref);
    
    [BSDBThreadList resetDataSourceTemplates];
    [BSDBThreadList resetDataSourceTemplateForDateColumn];

    [self updateThreadsListTableWithNeedingDisplay:YES];
    [self updateBoardListViewWithNeedingDisplay:YES];
    [self updateThreadEnergyColumn];
    
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super appDefaultsLayoutSettingsUpdated:notification];
    }
}

- (void)labelDisplayNamesUpdated:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, BSLabelManagerDidUpdateDisplayNamesNotification);

    NSInteger column = [[self threadsListTable] columnWithIdentifier:BSThreadLabelKey];
    if (column != -1) {
        NSRect rect = [[self threadsListTable] rectOfColumn:column];
        [[self threadsListTable] setNeedsDisplayInRect:rect];
    }

    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super labelDisplayNamesUpdated:notification];
    }
}

- (void)labelColorsUpdated:(NSNotification *)notification
{
    [[self threadsListTable] reloadData];
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super labelColorsUpdated:notification];
    }
}

- (void)windowsRestorationDidFinish:(NSNotification *)notification
{
    m_hasWindowsRestorationJustFinished = YES;
/*    id signature = [[self document] signatureForWindowRestoration];
    if (signature) {
        NSString *path = [(CMRThreadSignature *)signature threadDocumentPath];
        NSDictionary *boardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[(CMRThreadSignature *)signature boardName], ThreadPlistBoardNameKey,
                                   [(CMRThreadSignature *)signature identifier], ThreadPlistIdentifierKey,
                                   NULL];
        [self setThreadContentWithFilePath:path boardInfo:boardInfo];
		// フォーカス
        [[self window] makeFirstResponder:[self textView]];
		[self synchronizeWindowTitleWithDocumentName];
    }*/
}

- (void)cleanUpItemsToBeRemoved:(NSArray *)files
{
    BSTitleRulerView *ruler = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];
    [ruler setTitleStr:NSLocalizedString(@"titleRuler default title", @"Startup Message")];
    [ruler setPathStr:nil];

    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super cleanUpItemsToBeRemoved:files];
    }
}

- (void)threadsListDidChange:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, CMRThreadsListDidChangeNotification);

    [[self threadsListTable] reloadData];
    [self synchronizeWindowTitleWithDocumentName];
    [self reselectThreadIfNeeded];

    [self notifyBrowserThListUpdateDelegateNotification];
}

- (void)threadsListWantsPartialReload:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, BSDBThreadListWantsPartialReloadNotification);
    id indexes = [[notification userInfo] objectForKey:@"Indexes"];

    if (indexes == [NSNull null]) {
        [[self threadsListTable] reloadData];
    } else {
        NSIndexSet *allColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self threadsListTable] numberOfColumns])];
        [[self threadsListTable] reloadDataForRowIndexes:indexes columnIndexes:allColumnIndexes];
    }

    [self synchronizeWindowTitleWithDocumentName];

    if ([self keepPaths]) {
        [self setKeepPaths:nil];
        [self setKeepCondition:CMRAutoscrollNone];
    }
}

- (void)threadsListDownloaderShouldRetryUpdate:(NSNotification *)notification
{
    [self reloadThreadsList:nil];
}

- (void)threadDocumentDidToggleDatOchiStatus:(NSNotification *)aNotification
{
    NSString *path = [[aNotification userInfo] objectForKey:@"path"];
    [[self currentThreadsList] toggleDatOchiThreadItemWithPath:path];
}

- (void)threadDocumentDidToggleLabel:(NSNotification *)aNotification
{
    NSString *path = [[aNotification userInfo] objectForKey:@"path"];
    NSUInteger code = [[[aNotification userInfo] objectForKey:@"code"] unsignedIntegerValue];
    [[self currentThreadsList] setLabel:code forThreadItemWithPath:path];
}

- (void)databaseWillUpdateThreadItem:(NSNotification *)aNotification
{
    [self storeKeepPath:CMRAutoscrollWhenThreadUpdate];
}

- (void)databaseWillDeleteThreadItems:(NSNotification *)aNotification
{
    [self storeKeepPath:CMRAutoscrollWhenThreadDelete];
}

- (void)sleepDidEnd:(NSNotification *)aNotification
{
    if (![CMRPref isOnlineMode]) return;
    NSTimeInterval delay = [CMRPref delayForAutoReloadAtWaking];

    if ([CMRPref autoReloadViewerWhenWake] && [self shouldShowContents] && [self threadAttributes]) {
        [self performSelector:@selector(reloadThread:) withObject:nil afterDelay:delay];
    }

    if ([CMRPref autoReloadListWhenWake] && [BoardListItem isBoardItem:[[self currentThreadsList] boardListItem]]) {
        [self performSelector:@selector(reloadThreadsList:) withObject:nil afterDelay:delay];
    }
}

- (void)reselectThreadIfNeeded
{
    CMRAutoscrollCondition type = [self keepCondition];
    if ([self keepPaths]) {
        CMRAutoscrollCondition mask = [CMRPref threadsListAutoscrollMask];
        [self selectRowIndexesWithThreadPaths:[self keepPaths] byExtendingSelection:NO scrollToVisible:(mask & type)];
        [self setKeepPaths:nil];
        [self setKeepCondition:CMRAutoscrollNone];
    } else {
        // 3ペインで、掲示板を切り替えた場合に、表示中のスレッドを再選択するために
        if (type == CMRAutoscrollNone && [self shouldShowContents] && [self path]) {
            [self selectRowWithCurrentThread:NO];
            return;
        }
        if (type != CMRAutoscrollWhenThreadUpdate && type != CMRAutoscrollWhenThreadDelete) {
            [[self threadsListTable] scrollRowToVisible:0];
        }
    }
}
@end
