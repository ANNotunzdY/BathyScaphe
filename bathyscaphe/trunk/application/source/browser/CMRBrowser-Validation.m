//
//  CMRBrowser-Validation.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/09/04.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRBrowser_p.h"
#import "SmartBoardList.h"
#import "missing.h"

@implementation CMRBrowser(Validation)
- (BOOL)segCtrlTbItem:(BSSegmentedControlTbItem *)item validateSegment:(NSInteger)segment
{
	if ([[item itemIdentifier] isEqualToString:@"Toggle View Mode"]) {
		return [[self currentThreadsList] viewMode] < 2;
	}
	return [super segCtrlTbItem:item validateSegment:segment];
}

#pragma mark Validation Helpers
- (BOOL)validateBBSActionItems
{
    NSView *focusedView_ = (NSView *)[[self window] firstResponder];
    if (focusedView_ == [self textView]) {
        return ([self threadAttributes] != nil);
    } else if (focusedView_ == [self threadsListTable]) {
        return [[self currentThreadsList] isBoard];
    } else if (focusedView_ == [self boardListTable]) {
        NSInteger selectedRow = [[self boardListTable] selectedRow];
        if (selectedRow != -1) {
            id item = [[self boardListTable] itemAtRow:selectedRow];
            return [BoardListItem isBoardItem:(BoardListItem *)item];
        }
    }
    return NO;
}

- (BOOL)validateDeleteThreadItemsEnabling:(NSArray *)threads
{
	NSEnumerator		*iter_;
	NSDictionary		*thread_;

	if (!threads || [threads count] == 0) {
        return NO;
	}

	iter_ = [threads objectEnumerator];
	while (thread_ = [iter_ nextObject]){
		NSNumber	*status_;
		
		status_ = [thread_ objectForKey:CMRThreadStatusKey];
		if (!status_) {
            continue;
		}
		if (ThreadLogCachedStatus & [status_ unsignedIntegerValue]) {
			return YES;
		}
	}

	return NO;
}

- (BOOL)validateCollapseOrExpandBoardListItem:(id)theItem
{
	if ([theItem isKindOfClass:[NSMenuItem class]]) {
        BOOL hoge = [[self outerSplitView] isSubviewCollapsed:[[[self outerSplitView] subviews] objectAtIndex:0]];
		[theItem setTitle:(hoge ? NSLocalizedString(@"Expand Boards List", @"")
                                                                 : NSLocalizedString(@"Collapse Boards List", @""))];
	}
	return YES;
}

- (BOOL)validateDeleteBoardFromListItem:(NSInteger)tag_
{
	NSOutlineView	*bLT = [self boardListTable];
	NSInteger numOfSelectedRow = [bLT numberOfSelectedRows];
	switch (numOfSelectedRow) {
		case 0:
			return NO;
		case 1:
			return (![SmartBoardList isFavorites:[bLT itemAtRow:[bLT selectedRow]]]);
		default:
			return (tag_ == kBLDeleteItemViaMenubarItemTag);
	}
}

- (BOOL)validateBoardListContextualMenuItem:(id)menuItem
{
	NSOutlineView *view = [self boardListTable];
	NSInteger clickedRow = [view clickedRow];

	if (clickedRow == -1) {
		return NO;
	} else {
		NSIndexSet *selectedRows = [view selectedRowIndexes];
		if ([selectedRows count] > 1 && [selectedRows containsIndex:clickedRow]) {
			return ([menuItem tag] == kBLDeleteItemViaContMenuItemTag);
		}
		id item = [view itemAtRow:clickedRow];
		if (!item) {
            return NO;
        }
        NSInteger tag = [menuItem tag];
        if (tag == kBLShowInspectorViaContMenuItemTag) {
            [self validateShowBoardInspectorPanelItemTitle:menuItem];
            return [BoardListItem isBoardItem:item];
        } else if (tag == kBLShowLocalRulesViaContMenuItemTag || tag == kBLOpenBoardItemViaContMenuItemTag) {
            return [BoardListItem isBoardItem:item];
        } else {
            return ![BoardListItem isFavoriteItem:item];
        }
	}
	return NO;
}

static BOOL isThreadContextualMenu(id item)
{
    return ([item isKindOfClass:[NSMenuItem class]] && ![[(NSMenuItem *)item menu] supermenu]);
}

#pragma mark NSUserInterfaceValidations Protocol
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)theItem
{
	NSInteger tag_ = [theItem tag];

	if (tag_ == kBrowserMenuItemAlwaysEnabledTag) {
        return YES;
    }
	if (tag_ == kBLEditItemViaMenubarItemTag || tag_ == kBLDeleteItemViaMenubarItemTag) {
		return [self validateDeleteBoardFromListItem:tag_];
	}
	if ((tag_ > kBLContMenuItemTagMin) && (tag_ < kBLContMenuItemTagMax)) {
		return [self validateBoardListContextualMenuItem:theItem];
	}
    if (tag_ == 782) {
        return YES;
    }

	SEL action_ = [theItem action];

	if (action_ == @selector(showSearchThreadPanel:) || action_ == @selector(chooseColumn:)) {
		return ([self currentThreadsList] != nil);
	} else if (action_ == @selector(saveAsDefaultFrame:)) {
		return NO;
	} else if (action_ == @selector(openSelectedThreads:)) {
        if (tag_ == 783) {
            NSArray *array = [self clickedThreadsReallyClicked];
            if ([array count] == 1 && [self shouldShowContents] && [self path]) {
                return ![[[array lastObject] objectForKey:CMRThreadLogFilepathKey] isEqualToString:[self path]];
            }
        }
        // 今のところスレッド一覧のコンテキストメニュー以外には無いので…
		return YES;
	} else if (action_ == @selector(collapseOrExpandBoardList:)) {
		return [self validateCollapseOrExpandBoardListItem:theItem];
	} else if (action_ == @selector(reloadThreadsList:)) {
		return YES; // [self validateReloadThreadsListItem:theItem];
	}

	if (action_ == @selector(addFavorites:)) {
		CMRFavoritesOperation	operation_;

		if (tag_ == 781) { // Browser Contextual Menu
			operation_ = [self favoritesOperationForThreads:[self clickedThreadsReallyClicked]];
		} else {
			if(isThreadContextualMenu(theItem)) { // Thread Contextual Menu
				operation_ = [[CMRFavoritesManager defaultManager] availableOperationWithPath:[self path]];
			} else {
				NSView *focusedView_ = (NSView *)[[self window] firstResponder];
				if (focusedView_ == [self textView]) {
					operation_ = [[CMRFavoritesManager defaultManager] availableOperationWithPath:[self path]];
				} else {
					operation_ = [self favoritesOperationForThreads:[self selectedThreadsReallySelected]];
				}
			}
        }
		return [self validateAddFavoritesItem:theItem forOperation:operation_];
	}

	if(action_ == @selector(deleteThread:)) {

		[self validateDeleteThreadItemTitle:theItem];
		
		if (tag_ == 780) { // Browser Contextual Menu
			return [self validateDeleteThreadItemsEnabling:[self clickedThreadsReallyClicked]];
		} else {
			if (isThreadContextualMenu(theItem)) { // Thread Contexual Menu
				return [super validateDeleteThreadItemEnabling:[self path]];
			} else {
				NSView *focusedView_ = (NSView *)[[self window] firstResponder];
				if (focusedView_ == [self textView]) {
					return [super validateDeleteThreadItemEnabling:[self path]];
				} else {
					return [self validateDeleteThreadItemsEnabling:[self selectedThreadsReallySelected]];
				}
			}
		}
		
		return NO;
	}
	
	if (action_ == @selector(reloadThread:)) {
        if (isThreadContextualMenu(theItem)) { // Thread Contextual Menu
            return [self threadAttributes] && ![[self document] isDatOchiThread];
        } else {
            NSView *focusedView_ = (NSView *)[[self window] firstResponder];
            if (focusedView_ == [self textView]) {
                return [self threadAttributes] && ![[self document] isDatOchiThread];
            } else {
                return ([[self selectedThreadsReallySelected] count] > 0);
            }
        }
		
		return NO;
	}

    if (action_ == @selector(retrieveThread:)) {
        NSView *focusedView_ = (NSView *)[[self window] firstResponder];
        if (focusedView_ == [self textView]) {
            return [super validateUserInterfaceItem:theItem];
        } else {
            // 2010-09-26 不具合あるので使用停止（再取得時 dat 落ちだった場合に何も出ず静かに再取得が止まってしまう）
            return NO; //([[self selectedThreadsReallySelected] count] > 0);
        }
    }

    if (action_ == @selector(toggleLayout:)) {
        NSInteger current = [[self layoutSwitcher] selectedSegment];
        if (current == [theItem tag]) {
            [(NSMenuItem *)theItem setState:NSOnState];
        } else {
            [(NSMenuItem *)theItem setState:NSOffState];
        }
        return YES;
    }
	
	return [super validateUserInterfaceItem:theItem];
}
@end
