//
//  PreferencesController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/05/17.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "AppDefaults.h"

@protocol PreferencesController
@required
- (AppDefaults *)preferences;
@end


@protocol BSCurrentThemeEditing
@required
- (void)editCurrentTheme:(id)sender;
@end


@interface PreferencesController : NSObject<NSWindowDelegate, PreferencesController> {
    IBOutlet NSView *_contentView;
    NSWindow        *_window;
    AppDefaults     *_preferences;
}

- (id)initWithPreferences:(AppDefaults *)pref;

- (NSWindow *)window;
- (void)setWindow:(NSWindow *)aWindow;

- (void)setPreferences:(AppDefaults *)aPreferences;

- (void)setupUIComponents;
- (void)updateUIComponents;

- (void)showSubpaneWithIdentifier:(NSString *)subpaneId;
- (NSString *)currentSubpaneIdentifier;

// same as NSPreferencePane
- (NSView *)loadMainView;
- (NSView *)mainView;
- (NSString *)mainNibName;
- (void)mainViewDidLoad;

// invoked by parent PreferencesPane
- (void)willUnselect;
- (void)didSelect;

- (IBAction)openHelp:(id)sender;
@end


@interface PreferencesController(Toolbar)
- (NSToolbarItem *)makeToolbarItem;
- (NSString *)identifier;
- (NSString *)helpKeyword;
- (NSString *)label;
- (NSString *)paletteLabel;
- (NSString *)toolTip;
- (NSImage *)image;
- (NSString *)imageName;
@end
