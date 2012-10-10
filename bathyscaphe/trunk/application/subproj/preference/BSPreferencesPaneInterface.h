//
//  BSPreferencesPaneInterface.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/25.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

@class AppDefaults;

@protocol BSPreferencesPaneProtocol
- (id)initWithPreferences:(AppDefaults *)prefs;

- (NSString *)currentIdentifier;
- (void)setCurrentIdentifier:(NSString *)identifier;

- (id)showPreferencesPaneWithIdentifier:(NSString *)identifier; // Returns the shown pane's window controller.

// Available in BathyScaphe 1.6.3 "Hinagiku" and later.
- (id)showSubpaneWithIdentifier:(NSString *)subpaneId atPaneIdentifier:(NSString *)paneId; // Returns the shown pane's window controller.

// Available in BathyScaphe 2.2 "Baby Universe Day" and later.
- (void)editCurrentThemeInPreferencesPane;
@end

// Pane identifier constants.
#define PPGeneralPreferencesIdentifier	@"General"
#define PPFontsAndColorsIdentifier		@"FontsAndColors"
#define PPAccountSettingsIdentifier		@"AccountSettings"
#define PPFilterPreferencesIdentifier	@"Filter"
#define PPReplyDefaultIdentifier		@"ReplyDefaults"
#define PPAdvancedPreferencesIdentifier	@"Advanced"
#define PPSoundsPreferencesIdentifier	@"Sounds"	// Available in BathyScaphe 1.2 and later.
// #define PPSyncPreferencesIdentifier		@"Sync"		// Available in BathyScaphe 1.3 and later. Removed in BathyScaphe 2.0 and later.
#define PPLinkPreferencesIdentifier		@"Link"		// Available in BathyScaphe 1.6 and later.
#define PPLabelsPreferencesIdentifier   @"Labels"   // Available in BathyScaphe 2.0 and later.

// "Reply" pane's subpane identifier constants. Available in BathyScaphe 1.6.3 "Hinagiku" and later.
#define PPReplyMailAndNameSubpaneIdentifier	@"NameAndMail"
#define PPReplyTemplatesSubpaneIdentifier	@"Templates"

// "View" pane's subpane identifier constants. Available in BathyScaphe 1.6.3 "Hinagiku" and later.
#define PPViewBrowserSubpaneIdentifier	@"Browser"
#define PPViewThemesSubpaneIdentifier	@"Themes"
#define PPViewDetailsSubpaneIdentifier	@"Details"
