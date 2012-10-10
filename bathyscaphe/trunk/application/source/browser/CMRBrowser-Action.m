//
//  CMRBrowser-Action.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/10.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRBrowser_p.h"
#import "CMRMainMenuManager.h"
#import "CMRHistoryManager.h"
#import "CMRThreadsList_p.h"
#import "FolderBoardListItem.h"
#import "CMRDocumentController.h"
#import "BoardListItem.h"
#import "BSBoardInfoInspector.h"
#import "BSQuickLookPanelController.h"

extern BOOL isOptionKeyDown(void); // described in CMRBrowser-Delegate.m

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6
@interface NSResponder(LionStub)
- (void)invalidateRestorableState;
@end
#endif

@implementation CMRBrowser(Action)
static NSInteger expandAndSelectItem(BoardListItem *selected, NSArray *anArray, NSOutlineView *bLT)
{
	NSEnumerator *iter_ = [anArray objectEnumerator];
	id	eachItem;
	NSInteger index = -1;
	while (eachItem = [iter_ nextObject]) {
		// 「閉じているカテゴリ」だけに興味がある
		if (NO == [SmartBoardList isCategory: eachItem] || NO == [(FolderBoardListItem *)eachItem hasChildren]) continue;

		if (NO == [bLT isItemExpanded: eachItem]) [bLT expandItem: eachItem];

		index = [bLT rowForItem: selected];
		if (-1 != index) { // 当たり！
			return index;
		} else { // カテゴリ内のサブカテゴリを開いて検査する
			index = expandAndSelectItem(selected, [(FolderBoardListItem *)eachItem items], bLT);
			if (-1 == index) // このカテゴリのどのサブカテゴリにも見つからなかった
				[bLT collapseItem: eachItem]; // このカテゴリは閉じる
		}
	}
	return index;
}

- (NSInteger)searchRowForItemInDeep:(BoardListItem *)boardItem inView:(NSOutlineView *)olView
{
	NSInteger	index = [olView rowForItem:boardItem];
	
	if (index == -1) {
		index = expandAndSelectItem(boardItem, [(SmartBoardList *)[olView dataSource] boardItems], olView);
	}
	
	return index;
}

#pragma mark -
- (IBAction)focus:(id)sender
{
    [[self window] makeFirstResponder:[[self threadsListTable] enclosingScrollView]];
}

- (void)selectRowOfName:(NSString *)boardName forceReload:(BOOL)flag
{
	NSOutlineView	*outlineView = [self boardListTable];
    SmartBoardList  *dataSource = [outlineView dataSource];
	BoardListItem	*selectedItem;
    NSInteger				index;

	UTILAssertNotNil(dataSource);

    selectedItem = [dataSource itemForName:boardName];

    if (!selectedItem) { // 必要なら掲示板を自動的に追加
		SmartBoardList	*defaultList = [[BoardManager defaultManager] defaultList];
		BoardListItem	*newItem = [defaultList itemForName:boardName];
		if (!newItem) {
			NSBeep();
			NSLog(@"No BoardListItem for board %@ found.", boardName);
			return;
		} else {
			[dataSource addItem:newItem afterObject:nil];
			selectedItem = [dataSource itemForName:boardName];
		}
	}

	index = [self searchRowForItemInDeep:selectedItem inView:outlineView];	
	if (index == -1) return;
	if ([outlineView isRowSelected:index]) { // すでに選択したい行が選択されている
		if (flag) {
			[self reloadThreadsList:self];
		} else {
            [self notifyBrowserThListUpdateDelegateNotification];
		}
	} else {
		[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
	}

	[outlineView scrollRowToVisible:index];
}

- (IBAction)reloadThreadsList:(id)sender
{
    [self storeKeepPath:CMRAutoscrollWhenTLUpdate];
	[[self document] reloadThreadsList];
}

- (void)openThreadsInThreadWindow:(NSArray *)threads
{
    NSString *path;
    NSDictionary *boardInfo;
    for (id thread in threads) {
        if ([thread isKindOfClass:[CMRThreadSignature class]]) {
            path = [(CMRThreadSignature *)thread threadDocumentPath];
            boardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[(CMRThreadSignature *)thread boardName], ThreadPlistBoardNameKey,
                                                                   [(CMRThreadSignature *)thread identifier], ThreadPlistIdentifierKey,
                         NULL];
        } else {
            path = [CMRThreadAttributes pathFromDictionary:thread];
            boardInfo = [NSDictionary dictionaryWithDictionary:thread];
        }
		if ([self shouldShowContents] && [path isEqualToString:[self path]]) {
			continue;
		}
        [[CMRDocumentController sharedDocumentController] showDocumentWithContentOfFile:[NSURL fileURLWithPath:path] boardInfo:boardInfo];
    }
}

- (NSArray *)targetBoardsForAction:(SEL)action sender:(id)sender
{
    if (sender && [sender respondsToSelector:@selector(tag)]) {
        NSInteger senderTag = [sender tag];
        if ((senderTag > kBLContMenuItemTagMin) && (senderTag < kBLContMenuItemTagMax)) {
            NSInteger clickedRow = [[self boardListTable] clickedRow];
            id clickedItem = [[self boardListTable] itemAtRow:clickedRow];
            if ([BoardListItem isBoardItem:clickedItem]) {
                NSURL *clickedBoardURL = [(BoardListItem *)clickedItem url];
                return [NSArray arrayWithObject:clickedBoardURL];
            }
        }
    }

    NSArray *result = nil;

    NSView *focusedView = (NSView *)[[self window] firstResponder];

    if (focusedView == [self textView]) {
        result = [super targetBoardsForAction:action sender:sender];
    } else if (focusedView == [self boardListTable]) {
        // 掲示板リスト…
        NSInteger selectedRow = [[self boardListTable] selectedRow];
        id item_ = [[self boardListTable] itemAtRow:selectedRow];
        if ([BoardListItem isBoardItem:item_]) {
            NSURL *url3 = [(BoardListItem *)item_ url];
            result = [NSArray arrayWithObject:url3];
        }
    } else {
        NSURL *listUrl = [[self currentThreadsList] boardURL];
        result = listUrl ? [NSArray arrayWithObject:listUrl] : [NSArray array];
    }

    return result;
}

- (NSArray *)targetThreadsForAction:(SEL)action sender:(id)sender
{
    if (sender && [sender respondsToSelector:@selector(tag)]) {
        NSInteger senderTag = [sender tag];
        if (senderTag > 779 && senderTag < 784) {
            return [self clickedThreadsReallyClicked];
        }
    }

	NSArray *result = nil;

    // メニューバーもしくはキーイベントから
    // あるいはツールバーボタンから
    // スレッドリストにフォーカスが当たっているかどうかで対象をスイッチする。
    NSView *focusedView_ = (NSView *)[[self window] firstResponder];
    if (focusedView_ == [self textView]) {
        // フォーカスがスレッド本文領域にある
        id selected = [self selectedThread];
        if (!selected) {
            result = [NSArray empty];
        } else {
            result = [NSArray arrayWithObject:selected];
        }
    } else { // フォーカスがそれ以外の領域にある：スレッドリストの選択項目を優先
        result = [self selectedThreadsReallySelected];
        if ([result count] == 0) {
            result = [self selectedThreads];
        }
    }	

	return result;
}

- (IBAction)openSelectedThreads:(id)sender
{
	[self openThreadsInThreadWindow:[self targetThreadsForAction:_cmd sender:sender]];
}

- (IBAction)selectThread:(id)sender
{
	// 特定のモディファイア・キーが押されているときは
	// クリックで項目を選択してもスレッドを読み込まない
	if (![self shouldShowContents] || isOptionKeyDown()) return;
	
	[self showSelectedThread:self];
}

- (BOOL)shouldLoadThreadAtPath:(NSString *)filepath
{
	if (![self shouldShowContents]) return NO;
	
	return (![filepath isSameAsString:[self path]] || ![[NSFileManager defaultManager] fileExistsAtPath:filepath]);
}

- (void)showThreadAtRow:(NSInteger)rowIndex
{
	NSTableView				*tbView_ = [self threadsListTable];
	NSDictionary			*thread_;
	NSString				*path_;
	
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 修正済
	NSAssert2(
		(rowIndex >= 0 && rowIndex < [tbView_ numberOfRows]),
		@"  rowIndex was over. size = %ld but was %ld",
		(long)[tbView_ numberOfRows],
		(long)rowIndex);
	
	thread_ = [[self currentThreadsList] threadAttributesAtRowIndex:rowIndex inTableView:tbView_];
	path_ = [CMRThreadAttributes  pathFromDictionary:thread_];
	
	if ([self shouldLoadThreadAtPath:path_]) {
		[self setThreadContentWithFilePath:path_ boardInfo:thread_];
		// フォーカス
		//if ([CMRPref moveFocusToViewerWhenShowThreadAtRow]) {
			[[self window] makeFirstResponder:[self textView]];
		//}
		[self synchronizeWindowTitleWithDocumentName];
        if ([[self document] respondsToSelector:@selector(invalidateRestorableState)]) {
            [[self document] invalidateRestorableState]; // For Window Restoration (Lion)
        }
	}
}

- (NSUInteger)indexOfNextUpdatedThread
{
    NSInteger index = [[self threadsListTable] selectedRow];
    if (index == -1) {
        index = NSNotFound;
    }
    return [[self currentThreadsList] indexOfNextUpdatedThread:index];
}

- (IBAction)showSelectedThread:(id)sender
{
	if (-1 == [[self threadsListTable] selectedRow]) return;
	if ([[self threadsListTable] numberOfSelectedRows] != 1) return;
	
	[self showThreadAtRow:[[self threadsListTable] selectedRow]];
}

/*
	2005-06-06 tsawada2 <ben-sawa@td5.so-net.ne.jp>
	Key Binding の便宜を図るためだけのメソッド。
	return キーに対応するアクションにこれを指定しておくと、2ペインのとき、3ペインのとき
	それぞれに応じて自動的に適切な動作（別窓で開く、下部に表示する）を呼び出せるという仕掛け。
*/
- (IBAction)showOrOpenSelectedThread:(id)sender
{
	if ([self shouldShowContents]) {
		[self showSelectedThread:sender];
	} else {
		[self openSelectedThreads:sender];
	}
}

- (IBAction)fromQuickLook:(id)sender
{
    NSObjectController *oc = [(BSQuickLookPanelController *)[sender windowController] objectController];
    id obj = [oc valueForKeyPath:@"selection.threadSignature"];
    if (!obj || ![obj isKindOfClass:[CMRThreadSignature class]]) {
        return;
    }

    if ([self shouldShowContents]) {
        NSString *path = [(CMRThreadSignature *)obj threadDocumentPath];
        if ([self shouldLoadThreadAtPath:path]) {
            [self setThreadContentWithThreadIdentifier:obj];
            [[self window] makeFirstResponder:[self textView]];
            [self synchronizeWindowTitleWithDocumentName];
        }
    } else {
        [self openThreadsInThreadWindow:[NSArray arrayWithObject:obj]];
    }
}

- (IBAction)selectThreadOnly:(id)sender
{
	// do nothing.
}

- (IBAction)selectNextUpdatedThread:(id)sender
{
    NSUInteger index = [self indexOfNextUpdatedThread];
    if (index == NSNotFound) {
        NSBeep();
        return;
    }
    [[self threadsListTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [[self window] makeFirstResponder:[self threadsListTable]];
}

- (IBAction)showOrOpenNextUpdatedThread:(id)sender
{
    NSUInteger index = [self indexOfNextUpdatedThread];
    if (index == NSNotFound) {
        NSBeep();
        return;
    }
    [[self threadsListTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self showOrOpenSelectedThread:sender];
}

/*
#pragma mark MeteorSweeper Key Binding Action Additions
- (IBAction) scrollPageDownThViewOrThListProperly: (id) sender
{
	if ([CMRPref moveFocusToViewerWhenShowThreadAtRow] || ![self shouldShowContents]) {
		[[[self threadsListTable] enclosingScrollView] pageDown: sender];
	} else {
		[[self textView] scrollPageDown: sender];
	}
}

- (IBAction) scrollPageUpThViewOrThListProperly: (id) sender
{
	if ([CMRPref moveFocusToViewerWhenShowThreadAtRow] || ![self shouldShowContents]) {
		[[[self threadsListTable] enclosingScrollView] pageUp: sender];
	} else {
		[[self textView] scrollPageUp: sender];
	}
}

- (IBAction) scrollPageDownThreadViewWithoutFocus: (id) sender
{
	if(![self shouldShowContents]) {
		NSBeep();
		return;
	}
	
	[[self textView] scrollPageDown: sender];
}

- (IBAction) scrollPageUpThreadViewWithoutFocus: (id) sender
{
	if(![self shouldShowContents]) {
		NSBeep();
		return;
	}
	
	[[self textView] scrollPageUp: sender];
}
*/

#pragma mark -
- (void)synchronizeWithSearchField
{
	[[self document] searchThreadsInListWithCurrentSearchString];
	[self synchronizeWindowTitleWithDocumentName];

	[[self threadsListTable] reloadData];
}

- (NSUInteger)isToolbarContainsSearchField
{
	NSToolbar	*toolbar = [[self window] toolbar];
	UTILAssertNotNil(toolbar);
    
	if (![toolbar isVisible]) {
		[toolbar setVisible:YES];
	}
    
	NSEnumerator *iter = [[toolbar visibleItems] objectEnumerator];
	id	item;
	while (item = [iter nextObject]) {
		if ([[item itemIdentifier] isEqualToString:kToolbarSearchFieldItemKey]) {
			return [toolbar displayMode] == NSToolbarDisplayModeLabelOnly ? 1 : 0;
		}
	}
    
	return 2;
}

- (void)collapseSplitView
{
    CGFloat position = [[self splitView] maxPossiblePositionOfDividerAtIndex:0];
    [[self splitView] setPosition:position ofDividerAtIndex:0];
    [[self splitView] adjustSubviews];
}

- (void)expandSplitView
{
    CGFloat altPosition = [[self splitView] minPossiblePositionOfDividerAtIndex:0];
    CGFloat calcPosition;
    if ([[self splitView] isVertical]) {
        calcPosition = [[self splitView] frame].size.width - [[[self textView] enclosingScrollView] bounds].size.width - [[self splitView] dividerThickness];
    } else {
        calcPosition = [[self splitView] frame].size.height - [[[self textView] enclosingScrollView] bounds].size.height - [[self splitView] dividerThickness];
    }
    CGFloat position = (calcPosition < altPosition) ? altPosition : calcPosition;
    [[self splitView] setPosition:position ofDividerAtIndex:0];
    [[self splitView] adjustSubviews];
}

#pragma mark -
- (IBAction)searchThread:(id)sender
{
	[self synchronizeWithSearchField];
}

- (IBAction)toggleLayout:(id)sender
{
    NSInteger idx;
    BOOL needsSync = NO;
    BOOL isExpanded = [self shouldShowContents];
    if (sender == [self layoutSwitcher]) {
        idx = [[self layoutSwitcher] selectedSegment];
    } else if ([sender isKindOfClass:[NSMenuItem class]]) {
        idx = [sender tag];
        needsSync = YES;
    } else {
        return;
    }

    if (idx == 0) {
        if (isExpanded) {
            [self collapseSplitView];
            if (needsSync) {
                [self synchronizeLayoutSwitcher];
            }
        }
        return;
    }

    if (idx == 1) {
        if ([CMRPref isSplitViewVertical]) {
            [CMRPref setIsSplitViewVertical:NO];
            [[self splitView] setVertical:NO];
            [[self splitView] setDividerStyle:NSSplitViewDividerStylePaneSplitter];
        }
        if (!isExpanded) {
            [self expandSplitView];
        } else {
            [[self splitView] resizeSubviewsWithOldSize:[[self splitView] frame].size];
        }
        if (needsSync) {
            [self synchronizeLayoutSwitcher];
        }
        return;
    }

    if (idx == 2) {
        if (![CMRPref isSplitViewVertical]) {
            [CMRPref setIsSplitViewVertical:YES];
            [[self splitView] setVertical:YES];
            [[self splitView] setDividerStyle:NSSplitViewDividerStyleThin];
        }
        if (!isExpanded) {
            [self expandSplitView];
        } else {
            [[self splitView] resizeSubviewsWithOldSize:[[self splitView] frame].size];        
        }
        if (needsSync) {
            [self synchronizeLayoutSwitcher];
        }
        return;
    }
}

- (IBAction)showSearchThreadPanel:(id)sender
{
	NSUInteger toolbarState = [self isToolbarContainsSearchField];

	switch (toolbarState) {
	case 0:
		[[self searchField] selectText:sender];
		break;
	case 1:
		[[[self window] toolbar] setDisplayMode:NSToolbarDisplayModeIconAndLabel];
		[[self searchField] selectText:sender];
		break;
	default:
		NSBeep();
		break;
	}
}

- (IBAction)collapseOrExpandBoardList:(id)sender
{
    BOOL isCollapsed = [[self outerSplitView] isSubviewCollapsed:[self boardListSubview]];
    CGFloat position;
    if (isCollapsed) {
        CGFloat altPosition = [[self outerSplitView] maxPossiblePositionOfDividerAtIndex:0];
        CGFloat boardListWidth = [[self boardListSubview] bounds].size.width;
        position = (boardListWidth < altPosition) ? boardListWidth : altPosition;
    } else {
        position = [[self outerSplitView] minPossiblePositionOfDividerAtIndex:0];
    }
    [[self outerSplitView] setPosition:position ofDividerAtIndex:0];
    [[self outerSplitView] adjustSubviews];
}

#pragma mark -

/*
NSTableView action, doubleAction はカラムのクリックでも
発生するので、以下のメソッドでフックする。
*/
- (IBAction)tableViewActionDispatch:(id)sender actionKey:(NSString *)aKey defaultAction:(SEL)defaultAction
{
	SEL action_;

	// カラムのクリック
	if (-1 == [[self threadsListTable] clickedRow]) return;

	// 設定されたアクションにディスパッチ
	action_ = SGTemplateSelector(aKey);
	if (NULL == action_ || _cmd == action_) {
		action_ = defaultAction;
	}
	[NSApp sendAction:action_ to:self from:sender];
}

- (IBAction)listViewAction:(id)sender
{
    // 時間内に二度目のクリックが発生した場合は、ダブルクリックと判断し、クリックの action を実行しない
    NSTimeInterval interval = [NSEvent bs_doubleClickInterval];
    NSEvent *nextEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask
                                                    untilDate:[NSDate dateWithTimeIntervalSinceNow:interval]
                                                       inMode:NSEventTrackingRunLoopMode
                                                      dequeue:NO];
    NSEventType type = [nextEvent type];
    if (NSLeftMouseUp == type) {
        return;
    }
	[self tableViewActionDispatch:sender
						actionKey:kThreadsListTableActionKey
					defaultAction:@selector(selectThread:)];
}

- (IBAction)listViewDoubleAction:(id)sender
{
	[self tableViewActionDispatch:sender
						actionKey:kThreadsListTableDoubleActionKey
					defaultAction:@selector(openSelectedThreads:)];
}

- (IBAction)boardListViewDoubleAction:(id)sender
{
	UTILAssertKindOfClass(sender, NSOutlineView);

	NSInteger	rowNum = [sender clickedRow];
	if (-1 == rowNum) return;
	
	id item_ = [sender itemAtRow:rowNum];

	if ([sender isExpandable:item_]) {
		if ([sender isItemExpanded:item_]) {
			[sender collapseItem:item_];
		} else {
			[sender expandItem:item_];
		}
	}
}	
@end

#pragma mark -
@implementation CMRBrowser(DeletionAndRetrieving)
- (void)closeWindowIfNeededAtPath:(NSString *)path
{
    ;
}
@end
