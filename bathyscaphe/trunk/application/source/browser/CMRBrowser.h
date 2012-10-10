//
//  CMRBrowser.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/08/21.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CMRThreadViewer.h"
#import "EditBoardSheetController.h"

@class ThreadsListTable;
@class BSDBThreadList;
@class AddBoardSheetController;
@class BoardListItem;

@interface CMRBrowser : CMRThreadViewer<NSTableViewDelegate, NSOutlineViewDelegate, NSSplitViewDelegate, EditBoardSheetControllerDelegate> {
    IBOutlet NSSplitView *m_outerSplitView;

	IBOutlet NSSplitView		*m_splitView;
	
	IBOutlet ThreadsListTable	*m_threadsListTable;
	
	IBOutlet NSOutlineView		*m_boardListTable;
	
	IBOutlet NSMenu				*m_listContextualMenu;
	IBOutlet NSMenu				*m_drawerContextualMenu;

    // View Toolbar Items
	IBOutlet NSSearchField		*m_searchField;
	IBOutlet NSSegmentedControl *m_viewModeSwitcher;
    IBOutlet NSSegmentedControl *m_layoutSwitcher;

	AddBoardSheetController		*m_addBoardSheetController; // added in Lemonade.
	EditBoardSheetController	*m_editBoardSheetController; // added in MeteorSweeper.

    // note - these can't be connected in IB
    // you'll get, for example, a text view where you meant to get
    // its enclosing scroll view
    id topSubview;
    id bottomSubview;

    NSArray *m_keepPaths;
    CMRAutoscrollCondition m_keepCondition;
    
    // フルスクリーンとの切り替え中のみ true になる
    BOOL m_isTogglingFullScreen;
    // First Responder のビューが2ペイン＜ー＞3ペインの切り替えで隠される可能性がある場合に true
    BOOL m_isFirstResponderMayCollapsed;
    // Lion only. ウインドウの「復元」直後であることを示す
    BOOL m_hasWindowsRestorationJustFinished;
}

- (NSArray *)keepPaths;
- (void)setKeepPaths:(NSArray *)array;
- (void)storeKeepPath:(CMRAutoscrollCondition)type;
- (CMRAutoscrollCondition)keepCondition;
- (void)setKeepCondition:(CMRAutoscrollCondition)type;

- (void)notifyBrowserThListUpdateDelegateNotification;
@end


@interface CMRBrowser(SelectingThreads)
- (NSArray *)selectedThreadsReallySelected;
- (NSArray *)clickedThreadsReallyClicked;
@end


@interface CMRBrowser(Action)
// KeyBinding...
- (IBAction)openSelectedThreads:(id)sender;
- (IBAction)selectThread:(id)sender;
- (IBAction)showSelectedThread:(id)sender;
- (IBAction)reloadThreadsList:(id)sender;
- (IBAction)showOrOpenSelectedThread:(id)sender;

- (void)synchronizeWithSearchField;

- (IBAction)searchThread:(id)sender;
- (IBAction)showSearchThreadPanel:(id)sender;
- (IBAction)toggleLayout:(id)sender;

- (IBAction)collapseOrExpandBoardList:(id)sender;

- (IBAction)selectNextUpdatedThread:(id)sender;
- (IBAction)showOrOpenNextUpdatedThread:(id)sender;

// make threadsList view to be first responder;
- (IBAction)focus:(id)sender;

- (void)selectRowOfName:(NSString *)boardName forceReload:(BOOL)flag; // Available in SilverGull and later.
- (NSInteger)searchRowForItemInDeep:(BoardListItem *)boardItem inView:(NSOutlineView *)olView; // Available in SilverGull and later.
@end


@interface CMRBrowser(BoardListEditor)
- (IBAction)addBoardListItem:(id)sender;
- (IBAction)addSmartItem:(id)sender;
- (IBAction)addCategoryItem:(id)sender;
- (IBAction)editBoardListItem:(id)sender;
- (IBAction)removeBoardListItem:(id)sender;
@end


//:CMRBrowser-List.m
@interface CMRBrowser(List)
- (BSDBThreadList *)currentThreadsList;
- (void)setCurrentThreadsList:(BSDBThreadList *)newList;

- (void)showThreadsListForBoard:(id)board;
- (void)showThreadsListForBoard:(id)board forceReload:(BOOL)force;
- (void)showThreadsListWithBoardName:(NSString *)boardName;
@end


@interface CMRBrowser(Table)
- (NSUInteger)selectRowWithCurrentThread:(BOOL)scroll;
- (NSUInteger)selectRowWithThreadPath:(NSString *)filepath byExtendingSelection:(BOOL)flag scrollToVisible:(BOOL)scroll; // available in Levantine
// Available in BathyScaphe 1.6.3 "Hinagiku" and later.
- (NSUInteger)selectRowIndexesWithThreadPaths:(NSArray *)paths byExtendingSelection:(BOOL)extend scrollToVisible:(BOOL)scroll;
@end


extern NSString *const CMRBrowserDidChangeBoardNotification;
extern NSString *const CMRBrowserThListUpdateDelegateTaskDidFinishNotification; // avaiable in Levantine
