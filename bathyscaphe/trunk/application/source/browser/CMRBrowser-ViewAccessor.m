//
//  CMRBrowser-ViewAccessor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/07.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRBrowser_p.h"
#import "missing.h"
#import "CMRBBSListTemplateKeys.h"
#import "NSTableColumn+CMXAdditions.h"
#import "CMRMainMenuManager.h"
#import "AddBoardSheetController.h"
#import "EditBoardSheetController.h"
#import "CMRTextColumnCell.h"
#import <SGAppKit/BSIconAndTextCell.h>
#import "BSBoardInfoInspector.h"
#import "CMRAppDelegate.h"
#import "BSLabelManager.h"
#import "BSLabelMenuItemView.h"
#import "CMXMenuHolder.h"


@implementation CMRBrowser(ViewAccessor)
- (CMRThreadViewer *)threadViewer
{
    return nil;
}

- (NSSplitView *)splitView
{
    return m_splitView;
}
/*
- (RBSplitSubview *)boardListSubView
{
    return m_boardListSubView;
}
*/
- (NSSplitView *)outerSplitView
{
    return m_outerSplitView;
}

- (NSView *)boardListSubview
{
    return [[[self outerSplitView] subviews] objectAtIndex:0];
}

- (ThreadsListTable *)threadsListTable
{
    return m_threadsListTable;
}

- (NSOutlineView *)boardListTable
{
    return m_boardListTable;
}

- (NSSearchField *)searchField
{
	return m_searchField;
}

- (NSMenu *)listContextualMenu
{
    return m_listContextualMenu;
}

- (NSMenu *)drawerContextualMenu
{
    return m_drawerContextualMenu;
}

- (AddBoardSheetController *)addBoardSheetController
{
    if (!m_addBoardSheetController) {
		m_addBoardSheetController = [[AddBoardSheetController alloc] init];
	}
	return m_addBoardSheetController;
}

- (EditBoardSheetController *)editBoardSheetController
{
    if (!m_editBoardSheetController) {
		m_editBoardSheetController = [[EditBoardSheetController alloc] initWithDelegate:self];
	}
	return m_editBoardSheetController;
}

- (NSSegmentedControl *)viewModeSwitcher
{
	return m_viewModeSwitcher;
}

- (NSSegmentedControl *)layoutSwitcher
{
    return m_layoutSwitcher;
}
@end


@implementation CMRBrowser(UIComponents)
- (BOOL)loadComponents
{
	[super loadComponents];
	return [NSBundle loadNibNamed:@"CMRBrowserComponents" owner:self];
}

- (void)setupLoadedComponents
{
/*    NSView        *containerView_;
    
    containerView_ = [self containerView];
    UTILAssertNotNil(containerView_);
    
    [containerView_ retain];
    [containerView_ removeFromSuperviewWithoutNeedingDisplay];
    
    [[self splitView] addSubview:containerView_];
    [containerView_ release];*/
    NSView		*containerView_;
	NSView		*contentView_ = [self splitView];
	NSRect		vframe_;
	
	containerView_ = [self containerView];
	vframe_ = [m_windowContentView frame];
	
	[containerView_ retain];
	[containerView_ removeFromSuperviewWithoutNeedingDisplay];
	[containerView_ setFrame:vframe_];
	
//	[contentView_ setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
//	[contentView_ setAutoresizesSubviews:YES];
	
	// ダミーのNSViewと入れ替える
	[m_windowContentView retain];
	[contentView_ replaceSubview:m_windowContentView with:containerView_];
	[m_windowContentView release];
	m_windowContentView = nil;
    
	[containerView_ release];

}
@end


@implementation CMRBrowser(TableColumnInitializer)
- (NSTableColumn *)tableColumnWithPropertyListRep:(id)plistRep
{
    NSTableColumn *column_ = [[NSTableColumn alloc] initWithPropertyListRepresentation:plistRep];
    [self setupTableColumn:column_];
    return [column_ autorelease];
}

- (void)updateMenuItemStatusForColumnsMenu:(NSMenu *)menu_
{
    NSEnumerator        *iter_;
    NSMenuItem          *rep_;
    
    iter_ = [[menu_ itemArray] objectEnumerator];
    while (rep_ = [iter_ nextObject]) {
        NSInteger state_;
                
        state_ = (-1 == [[self threadsListTable] columnWithIdentifier:[rep_ representedObject]])
                	? NSOffState
                	: NSOnState;

        [rep_ setState:state_];
    }
}

- (IBAction)chooseColumn:(id)sender
{
    NSString			*identifier_;
    NSTableColumn		*column_;
	ThreadsListTable	*tbView_;
        
	UTILAssertRespondsTo(sender, @selector(representedObject));
    
    identifier_ = [sender representedObject];
    UTILAssertKindOfClass(identifier_, NSString);

    tbView_ = [self threadsListTable];
    column_ = [tbView_ tableColumnWithIdentifier:identifier_];

	[tbView_ setColumnWithIdentifier:identifier_ visible:(column_ == nil)];

//	[CMRPref setThreadsListTableColumnState:[tbView_ columnState]];
    [self saveBrowserListColumnState:tbView_];
	[self updateTableColumnsMenu];
}

- (void)createDefaultTableColumnsWithTableView:(NSTableView *)tableView
{
    NSEnumerator        *iter_;
    id                  rep_;
    
    iter_ = [[CMRAppDelegate defaultColumnsArray] objectEnumerator];

    while (rep_ = [iter_ nextObject]) {
        NSTableColumn        *column_;
        
        column_ = [self tableColumnWithPropertyListRep:rep_];
        if (!column_) continue;

        [tableView addTableColumn:column_];
    }

	[(ThreadsListTable *)tableView setInitialState];
}

- (void)setupStatusColumnWithTableColumn:(NSTableColumn *)column
{
    NSImage            *statusImage_;
    NSImageCell        *imageCell_;
    
    statusImage_ = [NSImage imageAppNamed:STATUS_HEADER_IMAGE_NAME];
    imageCell_  = [[NSImageCell alloc] initImageCell:nil];

    [[column headerCell] setAlignment:NSCenterTextAlignment];
    [[column headerCell] setImage:statusImage_];

    [imageCell_ setImageAlignment:NSImageAlignCenter];
    [imageCell_ setImageScaling:NSScaleNone];
    [imageCell_ setImageFrameStyle:NSImageFrameNone];
    
    [column setDataCell:imageCell_];
    [imageCell_ release];
}

- (void)updateThreadEnergyColumn
{
    NSTableColumn *column = [(ThreadsListTable *)[self threadsListTable] initialColumnWithIdentifier:BSThreadEnergyKey];
    if (!column) {
        return;
    }
    if ([CMRPref energyUsesLevelIndicator]) {
		BSIkioiCell *cell = [[BSIkioiCell alloc] initWithLevelIndicatorStyle:NSRelevancyLevelIndicatorStyle];
		[cell setMaxValue:10.0];
		[cell setMinValue:0.0];
		[cell setEditable:NO];
		[column setDataCell:cell];
		[cell release];
    } else {
        CMRRightAlignedTextColumnCell *cell = [[CMRRightAlignedTextColumnCell alloc] initTextCell:@""];

        [cell setAlignment:NSRightTextAlignment];
        [cell setAllowsEditingTextAttributes:NO];
        [cell setBezeled:NO];
        [cell setBordered:NO];
        [cell setEditable:NO];
        [cell setScrollable:NO];

        [cell setWraps:YES];
        [cell setDrawsBackground:NO];
        [column setDataCell:cell];
        [cell release];
    }
    NSTableColumn *currentColumn = [[self threadsListTable] tableColumnWithIdentifier:BSThreadEnergyKey];
    if (currentColumn) {
        NSRect rect = NSZeroRect;
        NSUInteger idx = [[[self threadsListTable] tableColumns] indexOfObject:currentColumn];
        if (idx != NSNotFound) {
            rect = [[self threadsListTable] rectOfColumn:idx];
        }
        if (!NSEqualRects(rect, NSZeroRect)) {
            [[self threadsListTable] setNeedsDisplayInRect:rect];
        }
    }
}

- (void)setupTableColumn:(NSTableColumn *)column
{
    if ([CMRThreadStatusKey isEqualToString:[column identifier]]) {
        [self setupStatusColumnWithTableColumn:column];
        return;
    } else if ([BSThreadEnergyKey isEqualToString:[column identifier]] && [CMRPref energyUsesLevelIndicator]) {
		BSIkioiCell *cell = [[BSIkioiCell alloc] initWithLevelIndicatorStyle:NSRelevancyLevelIndicatorStyle];
		[cell setMaxValue:10.0];
		[cell setMinValue:0.0];
		[cell setEditable:NO];
		[column setDataCell:cell];
		[cell release];
        return;
    }

	Class	cellClass;
	id		newCell;
	id		dataCell;
	
	dataCell = [column dataCell];
	if ([dataCell alignment] == NSRightTextAlignment) {
		cellClass = [CMRRightAlignedTextColumnCell class];
	} else {
		cellClass = [CMRTextColumnCell class];
	}

	newCell = [[cellClass alloc] initTextCell:@""];
	[newCell setAttributesFromCell:dataCell];
	[newCell setWraps:YES];
	[newCell setDrawsBackground:NO];
	[column setDataCell:newCell];
	[newCell release];
}
@end


@implementation CMRBrowser(ViewInitializer)
+ (Class)toolbarDelegateImpClass
{
    return NSClassFromString(@"CMRBrowserTbDelegate");
}

+ (BOOL)shouldShowTitleRulerView
{
	return YES;
}

+ (BSTitleRulerModeType)rulerModeForInformDatOchi
{
	return BSTitleRulerShowTitleAndInfoMode;
}

- (void)cleanUpTitleRuler:(NSTimer *)aTimer
{
	[super cleanUpTitleRuler:aTimer];
	[[[self scrollView] horizontalRulerView] setNeedsDisplay:YES];
}

- (void)setupSplitView
{
	BOOL			isGoingToVertical = [CMRPref isSplitViewVertical];
	NSSplitView	*splitView_ = [self splitView];
	NSArray			*subviewsAry_ = [splitView_ subviews];

    [splitView_ setDividerStyle:(isGoingToVertical ? NSSplitViewDividerStyleThin : NSSplitViewDividerStylePaneSplitter)];
    [splitView_ setVertical:isGoingToVertical];

    topSubview = [subviewsAry_ objectAtIndex:0];
    bottomSubview = [subviewsAry_ objectAtIndex:1];
}

#pragma mark ThreadsList
- (void)updateThreadsListTableWithNeedingDisplay:(BOOL)display
{
	NSTableView *tv = [self threadsListTable];
	AppDefaults *pref = CMRPref;
	BOOL	dontDrawBgColor = [pref threadsListTableUsesAlternatingRowBgColors];

    [tv setRowHeight:[pref threadsListRowHeight]];
    [tv setFont:[pref threadsListFont]];
    
    [tv setUsesAlternatingRowBackgroundColors:dontDrawBgColor];
	
	if (!dontDrawBgColor) { // do draw bg color
		[tv setBackgroundColor:[pref threadsListBackgroundColor]];
	}

	[tv setGridStyleMask:([pref threadsListDrawsGrid] ? NSTableViewSolidVerticalGridLineMask : NSTableViewGridNone)];
	
	[tv setNeedsDisplay:display];
}

- (void)updateTableColumnsMenu
{
	[self updateMenuItemStatusForColumnsMenu:[[[CMRMainMenuManager defaultManager] browserListColumnsMenuItem] submenu]];
	[self updateMenuItemStatusForColumnsMenu:[[[self threadsListTable] headerView] menu]];
}

- (void)setupThreadsListTable
{
    ThreadsListTable    *tbView_ = [self threadsListTable];
	id	tmp2;
	id	tmp;
    [[[self threadsListTable] enclosingScrollView] setBackgroundColor:[[self threadsListTable] backgroundColor]];

    [self createDefaultTableColumnsWithTableView:tbView_];

    tmp = SGTemplateResource(kThreadsListTableICSKey);
    UTILAssertRespondsTo(tmp, @selector(stringValue));
    [tbView_ setIntercellSpacing:NSSizeFromString([tmp stringValue])];

	[self updateThreadsListTableWithNeedingDisplay:NO];

	tmp2 = [CMRPref threadsListTableColumnState];
	if (tmp2) {
		[tbView_ restoreColumnState:tmp2];
	}

    [tbView_ setTarget:self];
    [tbView_ setDelegate:self];

    // dispatch in listViewAction:
    [tbView_ setAction:@selector(listViewAction:)];
    [tbView_ setDoubleAction:@selector(listViewDoubleAction:)];

	// Favorites Item's Drag & Drop operation support:
	[tbView_ registerForDraggedTypes:[NSArray arrayWithObjects:BSFavoritesIndexSetPboardType, nil]];

	[tbView_ setAutosaveTableColumns:NO];
    [tbView_ setVerticalMotionCanBeginDrag:NO];
        
    // Menu and Contextual Menus
    [tbView_ setMenu:[self listContextualMenu]];
	[[tbView_ headerView] setMenu:[(CMRAppDelegate *)[NSApp delegate] browserListColumnsMenuTemplate]];

	// Leopard
    [tbView_ setAllowsTypeSelect:NO];

	[self updateTableColumnsMenu];
}

#pragma mark BoardList
- (void)updateBoardListViewWithNeedingDisplay:(BOOL)display
{
	NSOutlineView	*boardListTable = [self boardListTable];

    NSInteger rowSizeStyle = [CMRPref boardListRowSizeStyle];
    if ([boardListTable respondsToSelector:@selector(setRowSizeStyle:)]) { // Lion
        [boardListTable setRowSizeStyle:rowSizeStyle];
    } else { // 10.6
        CGFloat height = 20;
        if (rowSizeStyle == 3) {
            height = 34;
        } else if (rowSizeStyle == 2) {
            height = 24;
        }
        [boardListTable setRowHeight:height];
    }

	if (display) {
		[boardListTable setNeedsDisplay:display];
	}
}

- (void)setupBoardListTableDefaults
{
	NSOutlineView *blt = [self boardListTable];    
	NSTableColumn    *column_;
	BSIconAndTextCell	*cell_;


	// D & D
    [blt registerForDraggedTypes:[NSArray arrayWithObjects:BSPasteboardTypeBoardListItem, BSPasteboardTypeThreadSignature, nil]];
	[blt setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationGeneric | NSDragOperationMove) forLocal:YES];
	[blt setDraggingSourceOperationMask:NSDragOperationGeneric forLocal:NO];

    [blt setDataSource:[[BoardManager defaultManager] userList]];
    [blt setDelegate:self];

	[blt setAutosaveName:APP_BROWSER_THREADSLIST_TABLE_AUTOSAVE_NAME];
    [blt setAutosaveExpandedItems:YES];
    [blt setDoubleAction:@selector(boardListViewDoubleAction:)];
	[blt setMenu:[self drawerContextualMenu]];

	column_ = [blt tableColumnWithIdentifier:BoardPlistNameKey];
	cell_ = [[BSIconAndTextCell alloc] init];
	[cell_ setEditable:NO];
	[column_ setDataCell:cell_];
	[cell_ release];
	[column_ setEditable:NO];

    [blt setAutoresizesOutlineColumn:NO];
    [blt setIndentationMarkerFollowsCell:YES];

	[self updateBoardListViewWithNeedingDisplay:NO];
}

- (void)selectLastBBS:(NSNotification *)aNotification
{
	NSString *lastBoard = [CMRPref browserLastBoard];
	if (lastBoard) {
		[self selectRowOfName:lastBoard forceReload:NO];
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kSelectLastBBSNotification object:self];
}

- (void)setupBoardListTable
{
    [self setupBoardListTableDefaults];

    // Since selecting board kick-start another thread,
    // we should run this task after application did finish
    // launching.    
    NSNotification *notification = [NSNotification notificationWithName:kSelectLastBBSNotification object:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(selectLastBBS:)
												 name:kSelectLastBBSNotification
											   object:self];

    [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle];
}

#pragma mark Window, KeyLoop, and Search Menu
- (void)setupFrameAutosaveName
{
    [[self window] setFrameAutosaveName:APP_BROWSER_WINDOW_AUTOSAVE_NAME];
	[[self window] setFrameUsingName:APP_BROWSER_WINDOW_AUTOSAVE_NAME];

    [[self outerSplitView] setAutosaveName:APP_BROWSER_OUTER_SPVIEW_AUTOSAVE_NAME];

    [self setupSplitView];

    [[self splitView] setAutosaveName:APP_BROWSER_SPVIEW_AUTOSAVE_NAME_211];
}

- (void)setWindowFrameUsingCache
{
	;
}

- (void)setupSearchField
{
	BOOL	isIncremental = [CMRPref useIncrementalSearch];
    id		searchCell	= [[self searchField] cell];

	[searchCell setSendsWholeSearchString:(NO == isIncremental)];	
	if (isIncremental) [searchCell setSearchMenuTemplate:nil];
}

- (void)synchronizeLayoutSwitcher
{
    NSSegmentedControl *switcher = [self layoutSwitcher];
    if (![self shouldShowContents]) {
        [switcher setSelectedSegment:0];
    } else {
        [switcher setSelectedSegment:([CMRPref isSplitViewVertical] ? 2 : 1)];
    }
}

- (void)setupBrowserContextualMenuLabelNames
{
    NSMenuItem *tmp = [[self listContextualMenu] itemWithTag:kTLContMenuLabelMenuTag];
    [tmp setView:[BSLabelMenuItemHolder labelMenuItemView]];
    [(BSLabelMenuItemView *)[tmp view] setTarget:[self threadsListTable]];
}    
@end


@implementation CMRBrowser(NibOwner)
- (void)setupUIComponents
{
    [super setupUIComponents];
    [self setupThreadsListTable];
	[self setupSearchField];
    [self setupFrameAutosaveName];
    [self setupBoardListTable];
    [self setupBrowserContextualMenuLabelNames];

    [self synchronizeLayoutSwitcher];

    [[self document] setShowsThreadDocument:[self shouldShowContents]];
}


+ (NSUInteger)defaultWindowCollectionBehaviorForLion
{
    return 1 << 7;
}
@end
