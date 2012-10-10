//
//  BSThemeEditor.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/04/22.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class AppDefaults;

@interface BSThemeEditor : NSWindowController {
    IBOutlet NSObjectController *m_themeGreenCube;
    IBOutlet NSButton *m_debugInternalThemeSetButton;
    IBOutlet NSTextField *m_debugPopupAlphaField;

    NSString    *m_saveThemeIdentifier;
    id          m_delegate;

    BOOL        m_isNewTheme;
    NSString    *m_fileName;
}

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (NSObjectController *)themeGreenCube;

- (BOOL)isNewTheme;
- (void)setIsNewTheme:(BOOL)flag;
- (NSString *)themeFileName;
- (void)setThemeFileName:(NSString *)filename;

- (IBAction)cancelEditingTheme:(id)sender;
- (IBAction)saveTheme:(id)sender;

// 「このテーマの名前」テキストフィールドと Binding
- (NSString *)saveThemeIdentifier;
- (void)setSaveThemeIdentifier:(NSString *)aString;

- (IBAction)openHelpForEditingCustomTheme:(id)sender;

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate contextInfo:(void *)contextInfo;
@end


@interface NSObject(BSThemeEditorModalDelegate)
- (void)themeEditSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (AppDefaults *)preferences;
@end
