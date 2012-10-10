//
//  BSTGrepClientWindowController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/09/20.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "BSTGrepClientTableView.h"

@class BSURLDownload, BSTGrepSoulGem;

@interface BSTGrepClientWindowController : NSWindowController<NSTableViewDelegate, BSTGrepClientTableViewDelegate, NSApplicationDelegate> {
    IBOutlet NSArrayController *m_searchResultsController;
    IBOutlet NSSearchField *m_searchField;
    IBOutlet NSPopUpButton *m_searchOptionButton;
    IBOutlet NSProgressIndicator *m_progressIndicator;
    IBOutlet NSTableView *m_tableView;
    IBOutlet NSTextField *m_infoField;

    BSURLDownload *m_download;
    NSURL *m_lastQuery;

    NSMutableArray *m_cacheIndex;

    BSTGrepSoulGem *m_soulGem;
}

@property(readwrite, retain) NSURL *lastQuery;

+ (id)sharedInstance;

- (NSArrayController *)searchResultsController;
- (NSSearchField *)searchField;
- (NSPopUpButton *)searchOptionButton;
- (NSProgressIndicator *)progressIndicator;

- (NSMutableArray *)cacheIndex;

- (BSTGrepSoulGem *)soulGem;

- (IBAction)startTGrep:(id)sender;
- (IBAction)chooseSearchOption:(id)sender;

- (IBAction)cancelCurrentTask:(id)sender;
- (IBAction)openSelectedThreads:(id)sender;
- (IBAction)openInBrowser:(id)sender;
- (IBAction)quickLook:(id)sender;
- (IBAction)showMainBrowser:(id)sender;
- (IBAction)openBBSInBrowser:(id)sender; // 検索結果を Web ブラウザで開く
@end
