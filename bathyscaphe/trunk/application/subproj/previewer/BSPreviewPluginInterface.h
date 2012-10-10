//
//  BSPreviewPluginInterface.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/03/21.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

@class AppDefaults;

@protocol BSLinkPreviewing
// Designated Initializer
- (id)initWithPreferences:(AppDefaults *)prefs;

// Action
- (BOOL)previewLink:(NSURL *)url;
- (BOOL)validateLink:(NSURL *)url;

@optional
- (BOOL)previewLinks:(NSArray *)urls;
- (IBAction)togglePreviewPanel:(id)sender;
- (IBAction)showPreviewerPreferences:(id)sender;
- (IBAction)resetPreviewer:(id)sender; // Available in BathyScaphe 2.0.5 and later.
@end


@interface NSObject(BSPreviewPluginAdditions)
// Storage for plugin-specific settings
- (NSMutableDictionary *)previewerPrefsDict;

//  Accessor for useful BathyScaphe global settings
- (BOOL)openInBg;
- (BOOL)isOnlineMode;
- (NSString *)linkDownloaderDestination;
@end
