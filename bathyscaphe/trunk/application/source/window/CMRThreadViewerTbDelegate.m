//
//  CMRThreadViewerTbDelegate.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/05.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewerTbDelegate.h"
#import "CMRToolbarDelegateImp_p.h"
#import "AppDefaults.h"

// スレッドの更新
static NSString *const st_reloadItem_Identifier				= @"Reload Thread";
static NSString *const st_reloadItem_LabelKey				= @"Reload Thread Label";
static NSString *const st_reloadItem_PaletteLabelKey		= @"Reload Thread Palette Label";
static NSString *const st_reloadItem_ToolTipKey				= @"Reload Thread ToolTip";
//static NSString *const st_reloadThread_imageName			= @"ReloadThread";

// レス
static NSString *const st_ReplyItem_Identifier			= @"Reply";
static NSString *const st_ReplyItem_LabelKey			= @"Reply Label";
static NSString *const st_ReplyItem_PaletteLabelKey		= @"Reply Palette Label";
static NSString *const st_ReplyItem_ToolTipKey			= @"Reply ToolTip";
//static NSString *const st_ReplyItem_imageName			= @"ResToThread";

//「お気に入りに追加」
static NSString *const st_favoritesIdentifier			= @"AddFavorites";
static NSString *const st_favoritesLabelKey				= @"AddFavorites Label";
static NSString *const st_favoritesPaletteLabelKey		= @"AddFavorites Palette Label";
static NSString *const st_favoritesToolTipKey			= @"AddFavorites ToolTip";
//static NSString *const st_favorites_imageName			= @"AddFavorites";

// 削除
static NSString *const st_deleteItemItemIdentifier			= @"Delete";
static NSString *const st_deleteItemItemLabelKey			= @"Delete Label";
static NSString *const st_deleteItemItemPaletteLabelKey		= @"Delete Palette Label";
static NSString *const st_deleteItemItemToolTipKey			= @"Delete ToolTip";
//static NSString *const st_deleteItem_ImageName				= @"Delete";

// オンライン
static NSString *const st_onlineModeIdentifier			= @"OnlineMode";
static NSString *const st_onlineModeLabelKey			= @"OnlineMode Label";
static NSString *const st_onlineModePaletteLabelKey		= @"OnlineMode Palette Label";
static NSString *const st_onlineModeToolTipKey			= @"OnlineMode ToolTip";
//static NSString *const st_onlineMode_ImageName			= @"online";

// Launch CMLogFinder (Removed in Twincam Angel.)
static NSString *const st_launchCMLFIdentifier			= @"Launch CMLF";

// 停止
static NSString *const st_stopTaskIdentifier			= @"stopTask";
static NSString *const st_stopTaskLabelKey				= @"stopTask Label";
static NSString *const st_stopTaskPaletteLabelKey		= @"stopTask Palette Label";
static NSString *const st_stopTaskToolTipKey			= @"stopTask ToolTip";
//static NSString *const st_stopTask_ImageName			= @"stopSign";

// 戻る／進む
static NSString *const st_historySegmentedControlIdentifier			= @"historySC";	
static NSString *const st_historySegmentedControlLabelKey			= @"historySC Label";
static NSString *const st_historySegmentedControlPaletteLabelKey	= @"historySC Palette Label";

// 拡大／縮小
static NSString *const st_scaleSegmentedControlIdentifier			= @"scaleSC";	
static NSString *const st_scaleSegmentedControlLabelKey			= @"scaleSC Label";
static NSString *const st_scaleSegmentedControlPaletteLabelKey	= @"scaleSC Palette Label";

// ブラウザ
static NSString *const st_browserItemIdentifier			= @"Main Browser";
static NSString *const st_browserItemLabelKey			= @"Main Browser Label";
static NSString *const st_browserItemPaletteLabelKey	= @"Main Browser Palette Label";
static NSString *const st_browserItemToolTipKey			= @"Main Browser ToolTip";
//static NSString *const st_browserItem_ImageName			= @"OrderFrontBrowser";

// アクション
/*static NSString *const st_actionButtonItemIdentifier    = @"ActionButton";
static NSString *const st_actionButtonItemLabelKey      = @"ActionButton Label";
static NSString *const st_actionButtonItemPaletteLabelKey = @"ActionButton Palette Label";*/


// スレッドタイトル検索
static NSString *const st_ttsItemIdentifier = @"ThreadTitleSearch";
static NSString *const st_ttsItemLabelKey = @"TTS Label";
static NSString *const st_ttsItemToolTipKey = @"TTS ToolTip";

// 共有
static NSString *const st_shareItemIdentifier = @"SharingService";
static NSString *const st_shareItemLabelKey = @"Share Label";
static NSString *const st_shareItemToolTipKey = @"Share ToolTip";

static NSString *const st_toolbar_identifier			= @"Thread Window Toolbar";


@implementation CMRThreadViewerTbDelegate
- (NSString *)identifier
{
	return st_toolbar_identifier;
}
@end



@implementation CMRThreadViewerTbDelegate(Private)
- (NSString *)reloadThreadItemIdentifier
{
	return st_reloadItem_Identifier;
}
- (NSString *)replyItemIdentifier
{
	return st_ReplyItem_Identifier;
}
- (NSString *)addFavoritesItemIdentifier
{
	return st_favoritesIdentifier;
}
- (NSString *)deleteItemIdentifier
{
	return st_deleteItemItemIdentifier;
}
- (NSString *)toggleOnlineModeIdentifier
{
	return st_onlineModeIdentifier;
}

- (NSString *)stopTaskIdentifier
{
	return st_stopTaskIdentifier;
}
- (NSString *)historySegmentedControlIdentifier
{
	return st_historySegmentedControlIdentifier;
}
- (NSString *)scaleSegmentedControlIdentifier
{
	return st_scaleSegmentedControlIdentifier;
}
- (NSString *)orderFrontBrowserItemIdentifier
{
	return st_browserItemIdentifier;
}
/*
- (NSString *)actionButtonItemIdentifier
{
    return st_actionButtonItemIdentifier;
}
*/
- (NSString *)threadTitleSearchIdentifier
{
    return st_ttsItemIdentifier;
}

- (NSString *)sharingServiceItemIdentifer
{
    return st_shareItemIdentifier;
}

- (NSArray *)unsupportedItemsArray
{
	return [[super unsupportedItemsArray] arrayByAddingObject:st_launchCMLFIdentifier];
}
@end


@implementation CMRThreadViewerTbDelegate(Protected)
/*
- (void)setupActionButtonItem:(NSToolbarItem *)tbItem windowController:(id)wc
{
    NSSize itemSize;
    [m_actionButton retain];
    [m_actionButton removeFromSuperviewWithoutNeedingDisplay];
    [m_actionButton setTarget:nil];
    [m_actionButton setAction:NULL];
    [tbItem setView:m_actionButton];
    [m_actionButton release];
    
    itemSize = [m_actionButton bounds].size;
    [tbItem setMinSize:itemSize];
    [tbItem setMaxSize:itemSize];
    
//    [(BSSegmentedControlTbItem *)tbItem setDelegate:wc];
    [m_actionButton setMenu:[[wc class] loadContextualMenuForTextView]];
}
*/
- (void)initializeToolbarItems:(NSWindow *)aWindow
{
	NSToolbarItem			*item_;
	NSWindowController		*wcontroller_;

    [NSBundle loadNibNamed:@"CMRThreadViewerTbItems" owner:self];
    
	wcontroller_ = [aWindow windowController];
	UTILAssertNotNil(wcontroller_);

    [self appendButton:m_reloadThreadButton
        withIdentifier:[self reloadThreadItemIdentifier]
                 label:st_reloadItem_LabelKey
          paletteLabel:st_reloadItem_PaletteLabelKey
               toolTip:st_reloadItem_ToolTipKey
                action:@selector(reloadThread:)
          customizable:YES];
    
    [self appendButton:m_replyButton
        withIdentifier:[self replyItemIdentifier]
                 label:st_ReplyItem_LabelKey
          paletteLabel:st_ReplyItem_PaletteLabelKey
               toolTip:st_ReplyItem_ToolTipKey
                action:@selector(reply:)
          customizable:YES];
    
    [self appendButton:m_addFavoritesButton
        withIdentifier:st_favoritesIdentifier
                 label:st_favoritesLabelKey
          paletteLabel:st_favoritesPaletteLabelKey
               toolTip:st_favoritesToolTipKey
                action:@selector(addFavorites:)
          customizable:YES];
    
    [self appendButton:m_deleteButton
        withIdentifier:[self deleteItemIdentifier]
                 label:st_deleteItemItemLabelKey
          paletteLabel:st_deleteItemItemPaletteLabelKey
               toolTip:st_deleteItemItemToolTipKey
                action:@selector(deleteThread:)
          customizable:YES];

    [self appendButton:m_stopTaskButton
        withIdentifier:[self stopTaskIdentifier]
                 label:st_stopTaskLabelKey
          paletteLabel:st_stopTaskPaletteLabelKey
               toolTip:st_stopTaskToolTipKey
                action:@selector(cancelCurrentTask:)
          customizable:YES];
     
    [self appendButton:m_orderFrontBrowserButton
        withIdentifier:[self orderFrontBrowserItemIdentifier]
                 label:st_browserItemLabelKey
          paletteLabel:st_browserItemPaletteLabelKey
               toolTip:st_browserItemToolTipKey
                action:@selector(showMainBrowser:)
          customizable:YES];

    [self appendButton:m_threadTitleSearchButton
        withIdentifier:[self threadTitleSearchIdentifier]
                 label:st_ttsItemLabelKey
          paletteLabel:nil
               toolTip:st_ttsItemToolTipKey
                action:@selector(showTGrepClientWindow:)
          customizable:YES];

    [self appendButton:m_sharingServiceButton
        withIdentifier:[self sharingServiceItemIdentifer]
                 label:st_shareItemLabelKey
          paletteLabel:nil
               toolTip:st_shareItemToolTipKey
                action:@selector(shareThreadInfo:)
          customizable:NO];
    [m_sharingServiceButton sendActionOn:NSLeftMouseDownMask];

    item_ = [self appendButton:m_thunderButton
                withIdentifier:[self toggleOnlineModeIdentifier]
                         label:st_onlineModeLabelKey
                  paletteLabel:st_onlineModePaletteLabelKey
                       toolTip:st_onlineModeToolTipKey
                        action:@selector(toggleOnlineMode:)
                  customizable:YES];
    [[item_ menuFormRepresentation] setTitle:[self localizedString:st_onlineModePaletteLabelKey]];
	
	item_ = [self appendToolbarItemWithClass:[BSSegmentedControlTbItem class]
							  itemIdentifier:[self historySegmentedControlIdentifier]
						   localizedLabelKey:st_historySegmentedControlLabelKey
					localizedPaletteLabelKey:st_historySegmentedControlPaletteLabelKey
						 localizedToolTipKey:nil
									  action:NULL
									  target:wcontroller_];
    [self setupControl:m_historyButton onItem:item_ action:@selector(historySegmentedControlPushed:) target:wcontroller_];
	
	item_ = [self appendToolbarItemWithClass:[BSSegmentedControlTbItem class]
							  itemIdentifier:[self scaleSegmentedControlIdentifier]
						   localizedLabelKey:st_scaleSegmentedControlLabelKey
					localizedPaletteLabelKey:st_scaleSegmentedControlPaletteLabelKey
						 localizedToolTipKey:nil
									  action:NULL
									  target:wcontroller_];
    [self customizeSegmentedControlIcons:m_scaleButton];
    [self setupControl:m_scaleButton onItem:item_ action:@selector(scaleSegmentedControlPushed:) target:wcontroller_];
}
@end



@implementation CMRThreadViewerTbDelegate(NSToolbarDelegate)
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    if (floor(NSAppKitVersionNumber) > 1138) { // Mountain Lion
	return [NSArray arrayWithObjects:
				[self reloadThreadItemIdentifier],
                NSToolbarSpaceItemIdentifier,
				[self deleteItemIdentifier],
				[self addFavoritesItemIdentifier],
                [self sharingServiceItemIdentifer],
				NSToolbarFlexibleSpaceItemIdentifier,
				[self orderFrontBrowserItemIdentifier],
				[self replyItemIdentifier],
				nil];
    } else {
        return [NSArray arrayWithObjects:
				[self reloadThreadItemIdentifier],
				NSToolbarSeparatorItemIdentifier,
				[self deleteItemIdentifier],
				[self addFavoritesItemIdentifier],
				NSToolbarFlexibleSpaceItemIdentifier,
				[self orderFrontBrowserItemIdentifier],
				NSToolbarSeparatorItemIdentifier,
				[self replyItemIdentifier],
				nil];
    }
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    if (floor(NSAppKitVersionNumber) > 1138) { // Mountain Lion
        return [NSArray arrayWithObjects:
				[self reloadThreadItemIdentifier],
				[self stopTaskIdentifier],
				[self addFavoritesItemIdentifier],
				[self deleteItemIdentifier],
				[self replyItemIdentifier],
				[self toggleOnlineModeIdentifier],
				[self scaleSegmentedControlIdentifier],
				[self historySegmentedControlIdentifier],
				[self orderFrontBrowserItemIdentifier],
                [self threadTitleSearchIdentifier],
                [self sharingServiceItemIdentifer],
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				nil];
    } else {
        return [NSArray arrayWithObjects:
				[self reloadThreadItemIdentifier],
				[self stopTaskIdentifier],
				[self addFavoritesItemIdentifier],
				[self deleteItemIdentifier],
				[self replyItemIdentifier],
				[self toggleOnlineModeIdentifier],
				[self scaleSegmentedControlIdentifier],
				[self historySegmentedControlIdentifier],
				[self orderFrontBrowserItemIdentifier],
                [self threadTitleSearchIdentifier],
				NSToolbarSeparatorItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				nil];
    }
}
@end
