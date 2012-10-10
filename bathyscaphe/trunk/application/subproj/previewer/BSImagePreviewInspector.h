//
//  BSImagePreviewInspector.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/10/10.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "BSPreviewPluginInterface.h"
#import "BSIPIHistoryManager.h"
#import "BSIPIArrayController.h"
#import "BSIPITableView.h"

@class BSIPIToken;

@interface BSImagePreviewInspector : NSWindowController<BSLinkPreviewing, BSIPITableViewDelegate, NSToolbarDelegate, NSWindowDelegate> {
	IBOutlet NSTextField			*m_infoField;
	IBOutlet NSPopUpButton			*m_actionBtn;
	IBOutlet NSImageView			*m_imageView;
	IBOutlet NSProgressIndicator	*m_progIndicator;
	IBOutlet NSSegmentedControl		*m_cacheNaviBtn;
	IBOutlet NSTabView				*m_tabView;
	IBOutlet NSSegmentedControl		*m_paneChangeBtn;
	IBOutlet NSTableColumn			*m_nameColumn;
	IBOutlet NSMenu					*m_cacheNaviMenuFormRep;
	IBOutlet BSIPIArrayController	*m_tripleGreenCubes;
    
    IBOutlet NSButton *m_tbOpenWithPreviewBtn;
    IBOutlet NSButton *m_tbOpenWithBrowserBtn;
    IBOutlet NSButton *m_tbFullScreenBtn;
    IBOutlet NSButton *m_tbSaveOrRevealBtn;
    IBOutlet NSButton *m_tbStopOrReloadBtn;
    IBOutlet NSButton *m_tbDeleteBtn;

	@private
	BOOL			m_shouldRestoreKeyWindow;
    NSMutableDictionary *m_toolbarItems;
    NSTimer *m_fadeOutTimer;
}

// Content object for BSIPIArrayController.
- (id)historyManager;

- (NSTimer *)fadeOutTimer;
- (void)setFadeOutTimer:(NSTimer *)aTimer;

// Actions
- (IBAction)openImage:(id)sender;
- (IBAction)openImageWithPreviewApp:(id)sender;
- (IBAction)saveImage:(id)sender;
- (IBAction)saveImageAs:(id)sender;
- (IBAction)removeImage:(id)sender;
- (IBAction)copyURL:(id)sender;
- (IBAction)startFullscreen:(id)sender;
- (IBAction)cancelDownload:(id)sender;
- (IBAction)retryDownload:(id)sender;

- (IBAction)historyNavigationPushed:(id)sender;
- (IBAction)changePane:(id)sender;

- (IBAction)forceRunTbCustomizationPalette:(id)sender;
@end


@interface BSImagePreviewInspector(ToolbarAndUtils)
- (NSString *)localizedStrForKey:(NSString *)key;
- (NSImage *)imageResourceWithName:(NSString *)name;
- (void)setupToolbar;

- (NSIndexSet *)validIndexesForAction:(id)actionSender;
@end


@interface BSImagePreviewInspector(ViewAccessor)
- (NSTextField *)infoField;
- (NSPopUpButton *)actionBtn;
- (NSImageView *)imageView;
- (NSProgressIndicator *)progIndicator;
- (NSSegmentedControl *)cacheNavigationControl;
- (NSTabView *)tabView;
- (NSSegmentedControl *)paneChangeBtn;
- (NSTableColumn *)nameColumn;
- (NSMenu *)cacheNaviMenuFormRep;
- (BSIPIArrayController *)tripleGreenCubes;

- (NSTimer *)timerForFadeOut;

- (void)makeWindowOpaqueWithFade:(NSNotification *)notification;
@end
