//
//  Browser.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/02/17.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CocoMonar_Prefix.h"
#import "CMRAbstructThreadDocument.h"

@class CMRThreadsList, BSDBThreadList;

@interface Browser : CMRAbstructThreadDocument {
	@private
	BSDBThreadList *m_currentThreadsList;
	NSString *m_searchString;
    BOOL m_showsThreadDocument;
    
    // For Window Restoration (Test...)
    id m_signatureForWindowRestoration;
}

- (NSURL *)boardURL;

- (BSDBThreadList *)currentThreadsList;
- (void)setCurrentThreadsList:(BSDBThreadList *)newList;

- (void)reloadThreadsList;

- (NSString *)searchString;
- (void)setSearchString:(NSString *)text;

- (BOOL)searchThreadsInListWithCurrentSearchString;

// 端的に言うと Window Controller (CMRBrowser) が3ペイン状態か2ペイン状態かを表す。
// YES - 3 pane, NO - 2 pane
- (BOOL)showsThreadDocument;
- (void)setShowsThreadDocument:(BOOL)flag;

- (id)signatureForWindowRestoration;

- (IBAction)toggleThreadsListViewMode:(id)sender;
- (IBAction)cleanupDatochiFiles:(id)sender;
- (IBAction)rebuildThreadsList:(id)sender; // Available in Tenori Tiger.
- (IBAction)newThread:(id)sender; // Available in SilverGull.
@end

/* for AppleScript */
@interface Browser(ScriptingSupport)
- (NSString *)tListBoardURL;

- (NSString *)tListBoardName;
- (void)setTListBoardName:(NSString *)boardNameStr;

- (void)handleReloadListCommand:(NSScriptCommand*)command;
- (void)handleReloadThreadCommand:(NSScriptCommand*)command;
@end


@interface NSObject(BrowserDelegate)
- (void)document:(NSDocument *)document willChangeThreadsListViewMode:(NSUInteger)newMode;
@end
