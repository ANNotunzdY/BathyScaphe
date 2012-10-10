//
//  CMRBrowserTbDelegate.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/27.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRBrowserTbDelegate.h"
#import "CMRToolbarDelegateImp_p.h"
#import "CMRBrowser_p.h"
#import "BSNobiNobiToolbarItem.h"

// Reload Threads List
static NSString *const st_reloadListItemIdentifier			= @"Reload List";
static NSString *const st_reloadListItemLabelKey			= @"Reload List Label";
static NSString *const st_reloadListItemPaletteLabelKey		= @"Reload List Palette Label";
static NSString *const st_reloadListItemToolTipKey			= @"Reload List ToolTip";
static NSString *const st_reloadList_ImageName				= @"ReloadList";

// Search Field
static NSString *const st_searchThreadItemIdentifier			= @"Search Thread";
static NSString *const st_searchThreadItemLabelKey				= @"Search Thread Label";
static NSString *const st_searchThreadItemPaletteLabelKey		= @"Search Thread Palette Label";
static NSString *const st_searchThreadItemToolTipKey			= @"Search Thread ToolTip";

// Collapse/Expand Boards List
static NSString *const st_COEItemIdentifier			= @"Collapse Or Expand";
static NSString *const st_COEItemLabelKey			= @"Collapse Or Expand Label";
static NSString *const st_COEItemPaletteLabelKey	= @"Collapse Or Expand Palette Label";
static NSString *const st_COEItemToolTipKey			= @"Collapse Or Expand ToolTip";

// NobiNobi Space
static NSString *const st_NobiNobiItemIdentifier = @"Boards List Space";
static NSString *const st_NobiNobiPaletteLabelKey = @"NobiNobi Palette Label";

// Toggle Threads List View Mode
// Available in Twincam Angel.
static NSString *const st_viewModeSwitcherItemIdentifier = @"Toggle View Mode";
static NSString *const st_viewModeSwitcherItemLabelKey = @"Toggle View Mode Label";
static NSString *const st_viewModeSwitcherItemPaletteLabelKey = @"Toggle View Mode Palette Label";
static NSString *const st_viewModeSwitcherItemToolTipKey = @"Toggle View Mode ToolTip";

// Quick Look
// Testing...
static NSString *const st_QLItemIdentifier = @"Quick Look";
static NSString *const st_QLItemLabelKey = @"Quick Look Label";
static NSString *const st_QLItemToolTipKey = @"Quick Look ToolTip";

// Layout Switcher
static NSString *const st_layoutSwitcherItemIdentifier = @"Layout";
static NSString *const st_layoutSwitcherItemLabelKey = @"Layout Label";
static NSString *const st_layoutSwitcherItemToolTipKey = @"Layout ToolTip";

// 新規スレッド作成
static NSString *const st_newThreadItemIdentifier = @"New Thread";
static NSString *const st_newThreadItemToolTipKey = @"NewThread ToolTip";
static NSString *const st_newThreadItemLabelKey = @"NewThread Label";

// Toolbar Identifier Constant
static NSString *const st_toolbar_identifier			= @"Browser Window Toolbar";

@implementation CMRBrowserTbDelegate
- (NSString *)identifier
{
	return st_toolbar_identifier;
}
@end


@implementation CMRBrowserTbDelegate(Protected)
- (void)initializeToolbarItems:(NSWindow *)aWindow
{
	NSToolbarItem			*item_;
	CMRBrowser				*wcontroller_;
	
	[super initializeToolbarItems:aWindow];

    BOOL loadNibSuccess = [NSBundle loadNibNamed:@"CMRBrowserTbItems" owner:self];
    NSAssert(loadNibSuccess, @"Fail to load CMRBrowserTbItems.nib!");

	wcontroller_ = (CMRBrowser*)[aWindow windowController];
	UTILAssertNotNil(wcontroller_);
    
    [self appendButton:m_reloadListButton
        withIdentifier:st_reloadListItemIdentifier
                 label:st_reloadListItemLabelKey
          paletteLabel:st_reloadListItemPaletteLabelKey
               toolTip:st_reloadListItemToolTipKey
                action:@selector(reloadThreadsList:)
          customizable:YES];
    
	[self appendButton:m_quickLookButton
        withIdentifier:st_QLItemIdentifier
                 label:st_QLItemLabelKey
          paletteLabel:st_QLItemLabelKey
               toolTip:st_QLItemToolTipKey
                action:@selector(quickLook:)
          customizable:NO];
    
	[self appendButton:m_boardListButton
        withIdentifier:st_COEItemIdentifier
                 label:st_COEItemLabelKey
          paletteLabel:st_COEItemPaletteLabelKey
               toolTip:st_COEItemToolTipKey
                action:@selector(collapseOrExpandBoardList:)
          customizable:YES];
    
	[self appendButton:m_newThreadButton
        withIdentifier:st_newThreadItemIdentifier
                 label:st_newThreadItemLabelKey
          paletteLabel:st_newThreadItemLabelKey
               toolTip:st_newThreadItemToolTipKey
                action:@selector(newThread:)
          customizable:YES];

	item_ = [self appendToolbarItemWithItemIdentifier:st_searchThreadItemIdentifier
									localizedLabelKey:st_searchThreadItemLabelKey
							 localizedPaletteLabelKey:st_searchThreadItemPaletteLabelKey
								  localizedToolTipKey:st_searchThreadItemToolTipKey
											   action:NULL
											   target:wcontroller_];
	[self setupSearchToolbarItem:item_ itemView:[wcontroller_ searchField]];

	item_ = [self appendToolbarItemWithClass:[BSSegmentedControlTbItem class]
							  itemIdentifier:st_viewModeSwitcherItemIdentifier
						   localizedLabelKey:st_viewModeSwitcherItemLabelKey
					localizedPaletteLabelKey:st_viewModeSwitcherItemPaletteLabelKey
						 localizedToolTipKey:st_viewModeSwitcherItemToolTipKey
									  action:NULL
									  target:nil];
	[self setupSwitcherToolbarItem:item_ itemView:[wcontroller_ viewModeSwitcher] delegate:wcontroller_];

	item_ = [self appendToolbarItemWithClass:[BSNobiNobiToolbarItem class]
							  itemIdentifier:st_NobiNobiItemIdentifier
						   localizedLabelKey:@""
					localizedPaletteLabelKey:st_NobiNobiPaletteLabelKey
						 localizedToolTipKey:@""
									  action:NULL
									  target:nil];
	[self setupNobiNobiToolbarItem:item_];

	item_ = [self appendToolbarItemWithItemIdentifier:st_layoutSwitcherItemIdentifier
									localizedLabelKey:st_layoutSwitcherItemLabelKey
							 localizedPaletteLabelKey:st_layoutSwitcherItemLabelKey
								  localizedToolTipKey:st_layoutSwitcherItemToolTipKey
											   action:NULL
											   target:nil];
	[self setupLayoutSwitcherToolbarItem:item_ itemView:[wcontroller_ layoutSwitcher]];
}
@end


@implementation CMRBrowserTbDelegate(Private)
static NSMenuItem* searchToolbarItemMenuFormRep(NSString *labelText)
{
	NSMenuItem		*menuItem_;
	
	menuItem_ = [[NSMenuItem alloc] initWithTitle:labelText action:@selector(showSearchThreadPanel:) keyEquivalent:@""];
//	[menuItem_ setImage:[NSImage imageAppNamed:@"Find"]];

	return [menuItem_ autorelease];
}

- (void)setupLayoutSwitcherToolbarItem:(NSToolbarItem *)anItem itemView:(NSView *)aView
{
    [self customizeSegmentedControlIcons:(NSSegmentedControl *)aView];
    NSSize size;

    [anItem setView:aView];
    size = [aView bounds].size;
    [anItem setMinSize:size];
    [anItem setMaxSize:size];
}

- (void)setupSearchToolbarItem:(NSToolbarItem *)anItem itemView:(NSView *)aView
{
	NSMenuItem *menuItem_;
	NSSize size_;
	
	[aView retain];

	[aView removeFromSuperviewWithoutNeedingDisplay];
	[anItem setView:aView];
	size_ = [aView bounds].size;
    size_.width = 140;
	[anItem setMinSize:size_];
	size_.width = 240;
	[anItem setMaxSize:size_];

	[aView release];
	
	menuItem_ = searchToolbarItemMenuFormRep([anItem label]);
	if (menuItem_) {
		[anItem setMenuFormRepresentation:menuItem_];
	}
}

- (void)setupSwitcherToolbarItem:(NSToolbarItem *)anItem itemView:(NSView *)aView delegate:(id)delegate
{
	NSSize size_;
	NSMenuItem *menuFormRep;

	menuFormRep = [[NSMenuItem alloc] initWithTitle:[anItem label] action:@selector(toggleThreadsListViewMode:) keyEquivalent:@""];

	[aView retain];
	[aView removeFromSuperviewWithoutNeedingDisplay];	
    [self customizeSegmentedControlIcons:(NSSegmentedControl *)aView];
	[anItem setView:aView];
	[anItem setMenuFormRepresentation:menuFormRep];
	[menuFormRep release];

	size_ = [aView bounds].size;
	[anItem setMinSize:size_];
	[anItem setMaxSize:size_];

	[aView release];
	[(BSSegmentedControlTbItem *)anItem setDelegate:delegate];
}

- (void)setupNobiNobiToolbarItem:(NSToolbarItem *)anItem
{
	BSNobiNobiView *aView = [[BSNobiNobiView alloc] initWithFrame:NSMakeRect(0,0,48,22)];
	NSSize size_ = NSMakeSize(48, 22);

	[anItem setView:aView];
	[anItem setMinSize:size_];
	[anItem setMaxSize:size_];

	[aView release];
}
@end


@implementation CMRBrowserTbDelegate(NSToolbarDelegate)
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemId willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
	NSToolbarItem *item;
	item = [super toolbar:toolbar itemForItemIdentifier:itemId willBeInsertedIntoToolbar:willBeInserted];
	if (item && [itemId isEqualToString:st_NobiNobiItemIdentifier]) {
		[(BSNobiNobiView *)[item view] setShouldDrawBorder:!willBeInserted];
	}
	return item;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    if (floor(NSAppKitVersionNumber) > 1138) {
	return [NSArray arrayWithObjects:
				st_reloadListItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
				st_viewModeSwitcherItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				[self reloadThreadItemIdentifier],
				[self deleteItemIdentifier],
				[self addFavoritesItemIdentifier],
                [self sharingServiceItemIdentifer],
				[self replyItemIdentifier],
				NSToolbarFlexibleSpaceItemIdentifier,
                [self threadTitleSearchIdentifier],
				st_searchThreadItemIdentifier,
				nil];
    } else {
        return [NSArray arrayWithObjects:
				st_reloadListItemIdentifier,
                NSToolbarFlexibleSpaceItemIdentifier,
				st_viewModeSwitcherItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				[self reloadThreadItemIdentifier],
				[self deleteItemIdentifier],
				[self addFavoritesItemIdentifier],
				[self replyItemIdentifier],
				NSToolbarFlexibleSpaceItemIdentifier,
                [self threadTitleSearchIdentifier],
				st_searchThreadItemIdentifier,
				nil];
    }
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    if (floor(NSAppKitVersionNumber) > 1138) {
        return [NSArray arrayWithObjects:
				st_reloadListItemIdentifier,
				[self reloadThreadItemIdentifier],
				[self stopTaskIdentifier],
				[self addFavoritesItemIdentifier],
				[self deleteItemIdentifier],
				[self replyItemIdentifier],
				st_searchThreadItemIdentifier,
				st_COEItemIdentifier,
				[self toggleOnlineModeIdentifier],
				[self scaleSegmentedControlIdentifier],
				[self historySegmentedControlIdentifier],
				st_NobiNobiItemIdentifier,
				st_viewModeSwitcherItemIdentifier,
                st_layoutSwitcherItemIdentifier,
				st_QLItemIdentifier,
                [self sharingServiceItemIdentifer],
                [self threadTitleSearchIdentifier],
                st_newThreadItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				nil];
    } else {
        return [NSArray arrayWithObjects:
				st_reloadListItemIdentifier,
				[self reloadThreadItemIdentifier],
				[self stopTaskIdentifier],
				[self addFavoritesItemIdentifier],
				[self deleteItemIdentifier],
				[self replyItemIdentifier],
				st_searchThreadItemIdentifier,
				st_COEItemIdentifier,
				[self toggleOnlineModeIdentifier],
				[self scaleSegmentedControlIdentifier],
				[self historySegmentedControlIdentifier],
				st_NobiNobiItemIdentifier,
				st_viewModeSwitcherItemIdentifier,
                st_layoutSwitcherItemIdentifier,
				st_QLItemIdentifier,
                [self threadTitleSearchIdentifier],
                st_newThreadItemIdentifier,
				NSToolbarSeparatorItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				nil];
    }
}
@end
