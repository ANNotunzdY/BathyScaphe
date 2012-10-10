//
//  BSImagePreviewInspector-Tb.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/08/03.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSImagePreviewInspector.h"
#import "BSIPIDefaults.h"
#import <SGAppKit/BSSegmentedControlTbItem.h>
#import <SGAppKit/BSNSControlToolbarItem.h>
#import <SGAppKit/NSWorkspace-SGExtensions.h>

static NSString *const kIPITbActionBtnId		= @"Actions";
static NSString *const kIPITbSettingsBtnId		= @"Settings"; // Deprecated
static NSString *const kIPITbCancelBtnId		= @"CancelAndSave";
static NSString *const kIPITbPreviewBtnId		= @"OpenWithPreview";
static NSString *const kIPITbFullscreenBtnId	= @"StartFullscreen";
static NSString *const kIPITbBrowserBtnId		= @"OpenWithBrowser";
static NSString *const kIPITbNaviBtnId			= @"History";
static NSString *const kIPITbPaneBtnId			= @"Panes";
static NSString *const kIPITbDeleteBtnId		= @"Delete";
static NSString *const kIPITbSaveBtnId			= @"Save";

static NSString *const kIPIToobarId				= @"jp.tsawada2.BathyScaphe.ImagePreviewer:Toolbar";

@implementation BSImagePreviewInspector(ToolbarAndUtils)
#pragma mark Utilities
- (NSString *)localizedStrForKey:(NSString *)key
{
	NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
	return [selfBundle localizedStringForKey:key value:key table:nil];
}

- (NSImage *)imageResourceWithName:(NSString *)name
{
	NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
	NSString *path;
	path = [selfBundle pathForImageResource:name];
	
	if (!path) {
        return nil;
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
    [image setTemplate:YES];
	
	return [image autorelease];
}

- (NSToolbarItem *)tbItemForId:(NSString *)identifier
						 label:(NSString *)label
				  paletteLabel:(NSString *)pLabel
					   toolTip:(NSString *)toolTip
                        button:(NSButton *)button
{
    Class tbItemClass = button ? [BSNSControlToolbarItem class] : [NSToolbarItem class];
	NSToolbarItem *item = [[[tbItemClass alloc] initWithItemIdentifier:identifier] autorelease];
	[item setLabel:[self localizedStrForKey:label]];
	[item setPaletteLabel:[self localizedStrForKey:pLabel]];
	[item setToolTip:[self localizedStrForKey:toolTip]];

    [button retain];
    [item setView:button];
    // 10.5 以降、-setMinSize:, -setMaxSize を呼ばなければ元々の -view のサイズが使われる
    [button release];
    
    // -action, -target は既に button にセットされているものとする
    
    // view item では「テキストのみ表示」のときのための -menuFormRepresentation が必須
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[self localizedStrForKey:label] action:[button action] keyEquivalent:@""];
    [menuItem setTarget:[button target]];
    [item setMenuFormRepresentation:menuItem];
    [menuItem release];

	return item;
}

- (NSIndexSet *)validIndexesForAction:(id)actionSender
{
    NSTableView *tableView = [[self nameColumn] tableView];
    NSInteger clickedRow = [tableView clickedRow];
    if (clickedRow != -1) {
        // テーブルビューのコンテクストメニューからのアクション
        // If we clicked on a selected row, then we want to consider all rows in the selection. 
        // Otherwise, we only consider the clicked on row.
        if ([tableView isRowSelected:clickedRow]) {
            return [tableView selectedRowIndexes];
        } else {
            return [NSIndexSet indexSetWithIndex:clickedRow];
        }
    }
    // それ以外（ツールバーボタン、アクションメニュー、イメージビューのコンテクストメニュー）からのアクション
    return [[self tripleGreenCubes] selectionIndexes];
}

#pragma mark Toolbars
- (void)setupToolbar
{
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:kIPIToobarId] autorelease];

    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
	[toolbar setSizeMode:NSToolbarSizeModeSmall];
    
    [toolbar setDelegate:self];
    
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
    if (!m_toolbarItems) {
        m_toolbarItems = [[NSMutableDictionary alloc] init];
    }
    
    NSToolbarItem *item = nil;

    if ([itemIdent isEqual:kIPITbSettingsBtnId]) {
        return nil;
	}
    
    if (![m_toolbarItems objectForKey:itemIdent]) {
        if ([itemIdent isEqual:kIPITbCancelBtnId]) {
            item = [self tbItemForId:itemIdent label:@"Stop" paletteLabel:@"Stop/Save" toolTip:@"StopTip" button:m_tbStopOrReloadBtn];
            [item setTag:574];

        } else if ([itemIdent isEqual:kIPITbSaveBtnId]) {
            BOOL autoCollect = [[BSIPIDefaults sharedIPIDefaults] autoCollectImages];
            if (autoCollect) {
                item = [self tbItemForId:itemIdent label:@"Reveal" paletteLabel:@"RevealInFinder" toolTip:@"RevealTip" button:m_tbSaveOrRevealBtn];
                [(NSButton *)[item view] setImage:[NSImage imageNamed:NSImageNameRevealFreestandingTemplate]];
            } else {
                item = [self tbItemForId:itemIdent label:@"Save" paletteLabel:@"Save" toolTip:@"SaveTip" button:m_tbSaveOrRevealBtn];
            }
            [item setTag:575];

        } else if ([itemIdent isEqual:kIPITbPreviewBtnId]) {
            item = [self tbItemForId:itemIdent label:@"Preview" paletteLabel:@"OpenWithPreview" toolTip:@"PreviewTip" button:m_tbOpenWithPreviewBtn];
            [item setTag:575];
        
        } else if ([itemIdent isEqual:kIPITbFullscreenBtnId]) {
            item = [self tbItemForId:itemIdent label:@"FullScreen" paletteLabel:@"StartFullScreen" toolTip:@"FullScreenTip" button:m_tbFullScreenBtn];
            [item setTag:573];
        
        } else if ([itemIdent isEqual:kIPITbBrowserBtnId]) {
            item = [self tbItemForId:itemIdent label:@"Browser" paletteLabel:@"OpenWithBrowser" toolTip:@"BrowserTip" button:m_tbOpenWithBrowserBtn];
            [item setTag:573];
        
        } else if ([itemIdent isEqual:kIPITbDeleteBtnId]) {
            item = [self tbItemForId:itemIdent label:@"Delete" paletteLabel:@"Delete" toolTip:@"DeleteTip" button:m_tbDeleteBtn];
            [item setTag:573];

        } else if([itemIdent isEqual:kIPITbActionBtnId]) {
            item = [self tbItemForId:itemIdent label:@"Actions" paletteLabel:@"Actions" toolTip:@"ActionsTip" button:nil];

            NSSize		size;
            NSView		*actionBtn;
            NSMenuItem	*menuFormRep;
            NSMenu		*menuFormRepSubmenu;

            actionBtn = [[self actionBtn] retain];
            
            menuFormRep = [[[NSMenuItem alloc] initWithTitle:[self localizedStrForKey:@"Actions"] action:NULL keyEquivalent:@""] autorelease];
            [menuFormRep setImage:[NSImage imageNamed:NSImageNameActionTemplate]];

            menuFormRepSubmenu = [[[self actionBtn] menu] copy];
            [menuFormRepSubmenu removeItemAtIndex:0];
            [menuFormRep setSubmenu:[menuFormRepSubmenu autorelease]];

            [item setView:actionBtn];
            [item setMenuFormRepresentation:menuFormRep];
            size = [actionBtn bounds].size;
            [item setMinSize:size];
            [item setMaxSize:size];
            [actionBtn release];
        } else if ([itemIdent isEqual:kIPITbNaviBtnId]) {
            NSSize	size_;
            NSView	*tmp_;
            NSMenuItem	*attachMenuItem_;
            item = [[[BSSegmentedControlTbItem alloc] initWithItemIdentifier:itemIdent] autorelease];
            
            [item setLabel:[self localizedStrForKey:@"History"]];
            [item setPaletteLabel:[self localizedStrForKey:@"History"]];
            [item setToolTip:[self localizedStrForKey:@"HistoryTip"]];
            
            tmp_ = [[self cacheNavigationControl] retain];
            
            attachMenuItem_ = [[[NSMenuItem alloc] initWithTitle:[self localizedStrForKey:@"HistoryTextOnly"]
                                                          action:NULL
                                                   keyEquivalent:@""] autorelease];
//            [attachMenuItem_ setImage:[self imageResourceWithName:@"HistoryFolder"]];
            [attachMenuItem_ setSubmenu:[self cacheNaviMenuFormRep]];
            
            [item setView:tmp_];
            [item setMenuFormRepresentation:attachMenuItem_];
            size_ = [tmp_ bounds].size;
            [item setMinSize:size_];
            [item setMaxSize:size_];
            [(BSSegmentedControlTbItem *)item setDelegate:self];
            [tmp_ release];
        } else if ([itemIdent isEqual:kIPITbPaneBtnId]) {
            NSSize	size_;
            NSView	*tmp_;
            NSMenuItem	*attachMenuItem_;
            item = [[[BSSegmentedControlTbItem alloc] initWithItemIdentifier:itemIdent] autorelease];
            
            [item setLabel:[self localizedStrForKey:@"Panes"]];
            [item setPaletteLabel:[self localizedStrForKey:@"Panes"]];
            [item setToolTip:[self localizedStrForKey:@"PanesTip"]];
            
            tmp_ = [[self paneChangeBtn] retain];
            attachMenuItem_ = [[[NSMenuItem alloc] initWithTitle:[self localizedStrForKey:@"PanesTextOnly"]
                                                          action:@selector(changePane:)
                                                   keyEquivalent:@""] autorelease];
            [attachMenuItem_ setTarget:self];
            [attachMenuItem_ setImage:[self imageResourceWithName:@"imageView"]];
                                                   
            [item setView:tmp_];
            [item setMenuFormRepresentation:attachMenuItem_];
            size_ = [tmp_ bounds].size;
            [item setMinSize:size_];
            [item setMaxSize:size_];
            [(BSSegmentedControlTbItem *)item setDelegate:self];
            [tmp_ release];
        }
        [m_toolbarItems setObject:item forKey:itemIdent];
    }

    return [m_toolbarItems objectForKey:itemIdent];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:kIPITbNaviBtnId, kIPITbPaneBtnId, kIPITbActionBtnId, NSToolbarFlexibleSpaceItemIdentifier,
									 kIPITbCancelBtnId, kIPITbSaveBtnId, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:kIPITbNaviBtnId, kIPITbPaneBtnId, kIPITbActionBtnId, kIPITbCancelBtnId, kIPITbDeleteBtnId,
									 kIPITbSaveBtnId, kIPITbBrowserBtnId, kIPITbPreviewBtnId, kIPITbFullscreenBtnId,
									 NSToolbarFlexibleSpaceItemIdentifier,
									 NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

#pragma mark Validation
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item
{
	NSArrayController	*cube_ = [self tripleGreenCubes];
	NSInteger tag_ = [item tag];

//	NSIndexSet	*indexes = [cube_ selectionIndexes];
    NSIndexSet *indexes = [self validIndexesForAction:item];
	BOOL		selected = ([indexes count] > 0);

	if (tag_ == 573) {
		return selected;
	} else if (tag_ == 575) {
        if ([(id)item isKindOfClass:[NSMenuItem class]] && ([item action] == @selector(saveImage:))) {
            if ([[BSIPIDefaults sharedIPIDefaults] autoCollectImages]) {
                [(id)item setTitle:[self localizedStrForKey:@"RevealMenu"]];
            } else {
                [(id)item setTitle:[self localizedStrForKey:@"SaveMenu"]];
            }
        }
		return (selected && [[BSIPIHistoryManager sharedManager] cachedTokensArrayContainsNotNullObjectAtIndexes:indexes]);
	} else if (tag_ == 576) { // Menu Item Only
//		return (selected && ([indexes count] == 1) && [[[cube_ selectedObjects] objectAtIndex:0] valueForKey:@"downloadedFilePath"]);
		return (selected && ([indexes count] == 1) && [[[cube_ arrangedObjects] objectAtIndex:[indexes firstIndex]] valueForKey:@"downloadedFilePath"]);
	} else if (tag_ == 574) {
		if (!selected) {
            return NO;
        }
		BSIPIHistoryManager *manager = [BSIPIHistoryManager sharedManager];
		if ([manager cachedTokensArrayContainsDownloadingTokenAtIndexes:indexes]) {
            if ([(id)item isKindOfClass:[NSMenuItem class]]) {
                [(NSMenuItem *)item setTitle:[self localizedStrForKey:@"StopMenu"]];               
            } else if ([(id)item isKindOfClass:[BSNSControlToolbarItem class]]) {
                [(BSNSControlToolbarItem *)item setLabel:[self localizedStrForKey:@"Stop"]];
                [(BSNSControlToolbarItem *)item setToolTip:[self localizedStrForKey:@"StopTip"]];
                [(NSButton *)[(BSNSControlToolbarItem *)item view] setImage:[NSImage imageNamed:NSImageNameStopProgressTemplate]];
            }
			[(id)item setAction:@selector(cancelDownload:)];
		} else {
            if ([(id)item isKindOfClass:[NSMenuItem class]]) {
                [(NSMenuItem *)item setTitle:[self localizedStrForKey:@"RetryMenu"]];
            } else if ([(id)item isKindOfClass:[BSNSControlToolbarItem class]]) {
                [(BSNSControlToolbarItem *)item setLabel:[self localizedStrForKey:@"Retry"]];
                [(BSNSControlToolbarItem *)item setToolTip:[self localizedStrForKey:@"RetryTip"]];
                [(NSButton *)[(BSNSControlToolbarItem *)item view] setImage:[NSImage imageNamed:NSImageNameRefreshTemplate]];
            }
			[(id)item setAction:@selector(retryDownload:)];
		}
		return YES;
	}

    return YES;
}

// action button's menu
/*- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	NSArrayController	*cube_ = [self tripleGreenCubes];
	NSInteger tag_ = [menuItem tag];
	NSIndexSet	*indexes = [cube_ selectionIndexes];
	BOOL		selected = ([indexes count] > 0);

	if (tag_ == 573) {
		return selected;
	} else if (tag_ == 575) {
        if ([menuItem action] == @selector(saveImage:)) {
            if ([[BSIPIDefaults sharedIPIDefaults] autoCollectImages]) {
                [menuItem setTitle:[self localizedStrForKey:@"RevealMenu"]];
            } else {
                [menuItem setTitle:[self localizedStrForKey:@"SaveMenu"]];
            }
        }
		return (selected && [[BSIPIHistoryManager sharedManager] cachedTokensArrayContainsNotNullObjectAtIndexes:indexes]);
	} else if (tag_ == 576) {
		return (selected && ([indexes count] == 1) && [[[cube_ selectedObjects] objectAtIndex:0] valueForKey:@"downloadedFilePath"]);
	} else if (tag_ == 574) {
		if (!selected) return NO;
		BSIPIHistoryManager *manager = [BSIPIHistoryManager sharedManager];
		if ([manager cachedTokensArrayContainsDownloadingTokenAtIndexes:indexes]) {
			[menuItem setTitle:[self localizedStrForKey:@"StopMenu"]];
			[menuItem setAction:@selector(cancelDownload:)];
		} else {
			[menuItem setTitle:[self localizedStrForKey:@"RetryMenu"]];
			[menuItem setAction:@selector(retryDownload:)];
		}
		return YES;
	}

	return YES;
}*/

- (BOOL)segCtrlTbItem:(BSSegmentedControlTbItem *)item validateSegment:(NSInteger)segment
{
	if ([item view] == [self paneChangeBtn]) return YES;

	NSArrayController *cube_ = [self tripleGreenCubes];

	if (segment == 0) {
		return [cube_ canSelectPrevious];
	} else if (segment == 1) {
		return [cube_ canSelectNext];
	}
	return NO;
}
@end
