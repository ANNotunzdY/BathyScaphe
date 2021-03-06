/**
  * $Id: CMRBrowser-List.m,v 1.2 2005-06-18 19:09:16 tsawada2 Exp $
  * 
  * CMRBrowser-List.m
  *
  * Copyright (c) 2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  */
#import "CMRBrowser_p.h"
#import "missing.h"
#import "CMRHistoryManager.h"
#import "CMRStatusLine.h"
#import "CMRNoNameManager.h"



@implementation CMRBrowser(List)
- (void) updateStatusLineBoardInfo
{
	id		text_;
	
	if([self showsSearchResult])
		return;
	
	text_ = [[self currentThreadsList] objectValueForBoardInfo];
	[[self statusLine] setBrowserInfoText : text_];
}
- (void) changeThreadsFilteringMask : (int) aMask
{
	[[self document] changeThreadsFilteringMask : aMask];
	[[self threadsListTable] reloadData];
	
	[self clearSearchFilter];
	[self updateStatusLineBoardInfo];
}
- (CMRThreadsList *) currentThreadsList
{
	return [[self document] currentThreadsList];
}
- (void) setCurrentThreadsList : (CMRThreadsList *) newList
{
	[self exchangeNotificationObserver :
						CMRThreadsListDidUpdateNotification
			selector : @selector(threadsListDidFinishUpdate:)
		 oldDelegate : [self currentThreadsList]
		 newDelegate : newList];
	[self exchangeNotificationObserver :
						CMRThreadsListDidChangeNotification
			selector : @selector(threadsListDidChange:)
		 oldDelegate : [self currentThreadsList]
		 newDelegate : newList];
	
	[[self threadsListTable] setDataSource : newList];
	[[self document] setCurrentThreadsList : newList];

	[self clearSearchFilter];
}

- (void) boardChanged : (id) aBoardIdentifier
{
	// 読み込みの完了、設定に保存
	// 履歴に登録してから、変更の通知
	[CMRPref setBrowserLastBoard : aBoardIdentifier];
	[[CMRHistoryManager defaultManager]
		addItemWithTitle : [aBoardIdentifier name]
					type : CMRHistoryBoardEntryType
				  object : aBoardIdentifier];
	UTILNotifyName(CMRBrowserDidChangeBoardNotification);
	//[[self statusLine] synchronizeHistoryTitleAndSelectedItem];
}
- (void) showThreadsListWithBBSSignature : (CMRBBSSignature *) aSignature
{
	CMRThreadsList		*list_;
	NSString			*sortColumnIdentifier_;
	BOOL				isAscending_;
	
	if(nil == aSignature) return;
	if([[[self currentThreadsList] BBSSignature] isEqual : aSignature]){
		return;
	}
	
	[[self threadsListTable] deselectAll : nil];
	[[self threadsListTable] setDataSource : nil];
	
	list_ = [CMRThreadsList threadsListWithBBSSignature : aSignature];
	if(nil == list_)
		return;
	
	[self setCurrentThreadsList : list_];
	
	// sort column change
	sortColumnIdentifier_ = [[CMRNoNameManager defaultManager] sortColumnForBoard : aSignature];
	isAscending_ = [[CMRNoNameManager defaultManager] sortColumnIsAscendingAtBoard : aSignature];
	
	[list_ setIsAscending : isAscending_];
	[self changeHighLightedTableColumnTo : sortColumnIdentifier_ isAscending : isAscending_];
	
	[self synchronizeWindowTitleWithDocumentName];
	[[self window] makeFirstResponder : [self threadsListTable]];
	
	// リストの読み込みを開始する。
	[list_ startLoadingThreadsList : [self threadLayout]];
	[self boardChanged : aSignature];
}

- (void) showThreadsListForBoard : (NSDictionary *) board;
{
	NSString			*bname_;
	CMRBBSSignature		*signature_;
	
	bname_ = [board objectForKey : BoardPlistNameKey];
	if(nil == bname_) return;
	
	signature_ = [CMRBBSSignature BBSSignatureWithName : bname_];
	[self showThreadsListWithBBSSignature : signature_];
}
@end



@implementation CMRBrowser(Table)
static NSImage *fnc_indicatorImageWithDirection(BOOL isAscending)
{
	return isAscending ? [NSImage imageNamed : @"NSAscendingSortIndicator"]
					   : [NSImage imageNamed : @"NSDescendingSortIndicator"]; 
}

- (void) changeHighLightedTableColumnTo : (NSString *) columnIdentifier_ isAscending : (BOOL) TorF
{
	NSTableView		*tableView_;
	NSTableColumn	*newColumn_;
	NSTableColumn	*oldColumn_;
	NSImage			*image_;
		
	tableView_ = [self threadsListTable];
	oldColumn_ = [tableView_ highlightedTableColumn];
	newColumn_ = [tableView_ tableColumnWithIdentifier : columnIdentifier_];
	image_ = fnc_indicatorImageWithDirection(TorF);

	if(oldColumn_ != nil && newColumn_ != oldColumn_ ) {
		[tableView_ setIndicatorImage : nil
						inTableColumn : oldColumn_];
	}

	[tableView_ setIndicatorImage : image_ inTableColumn : newColumn_]; 
	[tableView_ setHighlightedTableColumn : newColumn_];
}

/**
  * 現在、表示しているスレッドを再選択。
  * 引数maskに設定した値が初期設定で設定されていなければ選択しても、
  * 自動スクロールしない。
  *
  * @param    mask  そのときの状況
  */
- (unsigned) selectCurrentThreadWithMask : (int) mask
{
	int			pref_  = [CMRPref threadsListAutoscrollMask];
	unsigned	index_ = [self selectRowWithCurrentThread];
	
	if((pref_ & mask) > 0 && index_ != NSNotFound)
		[[self threadsListTable] scrollRowToVisible : index_];
	
	return index_;
}

- (unsigned) selectRowWithCurrentThread
{
	return [self selectRowWithThreadPath : [self path]
			 		byExtendingSelection : NO];
}
- (unsigned) selectRowWithThreadPath : (NSString *) filepath
                byExtendingSelection : (BOOL      ) flag
{
	CMRThreadsList	*tlist_ = [self currentThreadsList];
	NSTableView		*tview_ = [self threadsListTable];
	unsigned int	index_;
	int				selected_;
	
	if(nil == filepath || nil == tlist_) 
		return NSNotFound;
	
	selected_ = [tview_ selectedRow];
	index_ = [tlist_ indexOfThreadWithPath : filepath];
	
	// すでに選択済み
	if(NSNotFound == index_ || (selected_ != -1 && index_ == (unsigned)selected_))
		return index_;
	
/*
Deprecated in Mac OS X v10.3.
- [NSTableView selectRow:byExtendingSelection:]
*/
#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
{
	Class	NSIndexSet_ = NSClassFromString(@"NSIndexSet");
	id		indexes_;
	
	UTILRequireCondition((NSIndexSet_ != Nil), OLDER_SELECT_ROW);
	UTILRequireCondition(
		[NSIndexSet_ respondsToSelector : @selector(indexSetWithIndex:)],
		OLDER_SELECT_ROW);
	
	indexes_ = [NSIndexSet_ indexSetWithIndex : index_];
	UTILRequireCondition(
		[tview_ respondsToSelector : @selector(selectRowIndexes:byExtendingSelection:)],
		OLDER_SELECT_ROW);
	
	[tview_ selectRowIndexes:indexes_ byExtendingSelection:NO];
	return index_;
}
#endif

OLDER_SELECT_ROW:
	[tview_ selectRow:index_ byExtendingSelection:NO];
	return index_;
}
@end
