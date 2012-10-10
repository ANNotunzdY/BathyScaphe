//
//  FCController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/05/17.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"

@class BSThemeEditor, BSThemePreView;

@interface FCController : PreferencesController<BSCurrentThemeEditing, NSWindowDelegate, PreferencesController> {	
	IBOutlet NSTableView	*m_themesList;
	IBOutlet BSThemePreView *m_preView;
	BSThemeEditor			*m_themeEditor;

	IBOutlet NSTextField	*m_themeNameField;
	IBOutlet NSTextField	*m_themeStatusField;
    IBOutlet NSTextField    *m_themeDivField;
	IBOutlet NSButton		*m_deleteBtn;
	IBOutlet NSTabView		*m_tabView;
    
    IBOutlet NSImageView *m_aaFontSelectionStatusImageView;
    IBOutlet NSTextField *m_aaFontSelectionStatusDescField;
    IBOutlet NSTextField *m_aaFontSelectionStatusSummaryField;
}

- (NSTableView *)themesList;
- (BSThemeEditor *)themeEditor;
- (BSThemePreView *)preView;
- (NSTextField *)themeNameField;
- (NSTextField *)themeStatusField;
- (NSButton *)deleteButton;
- (NSTabView *)tabView;

- (IBAction)fixRowHeightToFont:(id)sender;

- (IBAction)editCustomTheme:(id)sender;

- (IBAction)newTheme:(id)sender;

- (IBAction)showMoreInfoAboutAA:(id)sender;
- (IBAction)openThemeEditorForIDColorSetting:(id)sender;
// Vita Additions
- (NSInteger)mailFieldOption;
- (void)setMailFieldOption:(NSInteger)selectedTag;

// Private
- (void)updateSelectedThemeInfo:(NSInteger)newSelectedRow;
- (void)updateAAFontStatusReport;
- (void)deleteTheme:(NSString *)fileName;
- (IBAction)tryDeleteTheme:(id)sender;
@end
