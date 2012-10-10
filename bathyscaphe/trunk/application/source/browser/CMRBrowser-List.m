//
//  CMRBrowser-List.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/07.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRBrowser_p.h"
#import "missing.h"
#import "CMRHistoryManager.h"

@implementation CMRBrowser(List)
- (BSDBThreadList *)currentThreadsList
{
	return [[self document] currentThreadsList];
}

- (void)setCurrentThreadsList:(BSDBThreadList *)newList
{
	BSDBThreadList *oldList = [self currentThreadsList];
	[self exchangeNotificationObserver:CMRThreadsListDidChangeNotification
							  selector:@selector(threadsListDidChange:)
		 				   oldDelegate:oldList
		 				   newDelegate:newList];
	[self exchangeNotificationObserver:BSDBThreadListWantsPartialReloadNotification
							  selector:@selector(threadsListWantsPartialReload:)
		 				   oldDelegate:oldList
		 				   newDelegate:newList];

	[[self threadsListTable] setDataSource:newList];
	[[self document] setCurrentThreadsList:newList];
	[[self document] setSearchString:nil];
}

- (void)boardChanged:(id)boardListItem
{
	NSString *name = [boardListItem representName];
	// 読み込みの完了、設定に保存
	// 履歴に登録してから、変更の通知
	[CMRPref setBrowserLastBoard:name];
	[[CMRHistoryManager defaultManager] addItemWithTitle:name type:CMRHistoryBoardEntryType object:boardListItem];

	UTILNotifyName(CMRBrowserDidChangeBoardNotification);
}

- (void)showThreadList:(id)threadList forceReload:(BOOL)force
{
	NSString	*boardName;
	
	if (!threadList) return;
	if (!force && [[[self currentThreadsList] boardListItem] isEqual:[threadList boardListItem]]) {
		// 2006-08-19 「掲示板を表示」処理の関係上この通知をここで発行しておく
        [self notifyBrowserThListUpdateDelegateNotification];
		return;
	}

	NSTableView *table = [self threadsListTable];
//	[table deselectAll:nil];
//	[table setDataSource:nil];

	[self setCurrentThreadsList:threadList];

	// sort column change
	boardName = [threadList boardName];
	NSArray *foo = [table sortDescriptors];
	NSArray *bar = [[BoardManager defaultManager] sortDescriptorsForBoard:boardName];
	[table setSortDescriptors:[[BoardManager defaultManager] sortDescriptorsForBoard:boardName]];
	// SortDescriptors が変わらない時は tableView:sortDescriptorsDidChange: が呼ばれない。
	// これは困るので、無理矢理呼ぶ。
	if ([foo isEqualToArray:bar]) {
		[[table dataSource] tableView:table sortDescriptorsDidChange:foo];
	}

	[self synchronizeWindowTitleWithDocumentName];
	[[self window] makeFirstResponder:table];
	
	// リストの読み込みを開始する。
	[threadList startLoadingThreadsList:[self threadLayout]];
	[self boardChanged:[threadList boardListItem]];
}

- (void)showThreadsListWithBoardName:(NSString *)boardName
{
	id item = [[BoardManager defaultManager] itemForName:boardName];
	if (!item) return;
	[self showThreadsListForBoard:item];
}

- (void)showThreadsListForBoard:(id)board
{
	[self showThreadList:[BSDBThreadList threadListWithBoardListItem:board] forceReload:NO];
}

- (void)showThreadsListForBoard:(id)board forceReload:(BOOL)force
{
	[self showThreadList:[BSDBThreadList threadListWithBoardListItem:board] forceReload:force];
}
@end


@implementation CMRBrowser(Table)
- (NSUInteger)selectRowWithCurrentThread:(BOOL)scroll
{
    NSString *boardName = [self boardName];
    NSString *threadsListBoardName = [[self currentThreadsList] boardName];
    if ([boardName isEqualToString:threadsListBoardName]) {
        return [self selectRowWithThreadPath:[self path] byExtendingSelection:NO scrollToVisible:scroll];
    } else {
        return NSNotFound;
    }
}

- (NSUInteger)selectRowWithThreadPath:(NSString *)filepath byExtendingSelection:(BOOL)flag scrollToVisible:(BOOL)scroll
{
    if (!filepath) {
        return NSNotFound;
    }
    return [self selectRowIndexesWithThreadPaths:[NSArray arrayWithObject:filepath] byExtendingSelection:flag scrollToVisible:scroll];
}

- (NSUInteger)selectRowIndexesWithThreadPaths:(NSArray *)paths byExtendingSelection:(BOOL)extend scrollToVisible:(BOOL)scroll
{
    if (!paths || [paths count] == 0) {
        return NSNotFound;
    }

    NSIndexSet *indexes = nil;
    indexes = [[self currentThreadsList] indexesOfFilePathsArray:paths ignoreFilter:NO];

    if (!indexes || [indexes count] == 0) {
        if (!extend) {
            [[self threadsListTable] deselectAll:nil];
            [[self threadsListTable] scrollRowToVisible:0];
        }
        return NSNotFound;
    }

    NSUInteger index = [indexes lastIndex];
    if (![[[self threadsListTable] selectedRowIndexes] containsIndexes:indexes]) { // すでに選択されているか確認
        [[self threadsListTable] selectRowIndexes:indexes byExtendingSelection:extend];
    }
    if (scroll) {
        [[self threadsListTable] scrollRowToVisible:index];
    } else {
        CMRAutoscrollCondition type = [self keepCondition];
        if (type != CMRAutoscrollWhenThreadUpdate && type != CMRAutoscrollWhenThreadDelete) {
            [[self threadsListTable] scrollRowToVisible:0];
        }
    }
    return index;
}
@end
