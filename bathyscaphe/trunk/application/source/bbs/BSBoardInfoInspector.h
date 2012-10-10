//
//  BSBoardInfoInspector.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/10/08.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "EditBoardSheetController.h"

/*!
    @class       BSBoardInfoInspector
    @abstract    manage the "Board Info" inspector panel
    @discussion  BSBoardInfoInspector は、「掲示板オプション」（仮称）インスペクタ・パネルのコントローラです。
*/
@class BoardListItem;
@class BSNGExpressionsEditorController;

@interface BSBoardInfoInspector : NSWindowController<EditBoardSheetControllerDelegate> {
    NSString *m_currentTargetBoardName;
    BSNGExpressionsEditorController *m_editor;
    BOOL m_isDetecting;

    IBOutlet NSButton *m_addNoNameBtn;
    IBOutlet NSButton *m_removeNoNameBtn;
    IBOutlet NSButton *m_editBoardURLButton;
    IBOutlet NSTabView *m_panes;
    IBOutlet NSToolbar *m_toolbar;
    IBOutlet NSMatrix *m_hostSymbolsMatrix;
}

+ (id)sharedInstance;

- (void)showInspectorForTargetBoard:(NSString *)boardName;

- (BSNGExpressionsEditorController *)editor;
- (void)updateHostSymbolsMatrix;
- (void)synchronizeSelectedToolbarItem;

// Accessor
- (NSString *)currentTargetBoardName;
- (void)setCurrentTargetBoardName:(NSString *)newTarget;

- (NSButton *)addNoNameBtn;
- (NSButton *)removeNoNameBtn;
- (NSButton *)editBoardURLButton;

// IBAction
- (IBAction)addNoName:(id)sender;
- (IBAction)startDetect:(id)sender;
- (IBAction)editBoardURL:(id)sender;
- (IBAction)openHelpForMe:(id)sender;

- (IBAction)changePane:(id)sender;
- (IBAction)hostSymbolChanged:(id)sender;

- (IBAction)openNGExpressionsEditorSheet:(id)sender;

// Binding
- (NSMutableArray *)noNamesArray;
- (void)setNoNamesArray:(NSMutableArray *)anArray;

- (NSString *)boardURLAsString;
- (BOOL)shouldEnableUI;
- (BOOL)shouldEnableBeBtn;
- (BOOL)shouldEnableURLEditing;

- (NSString *)defaultKotehan;
- (void)setDefaultKotehan:(NSString *)fieldValue;

- (NSString *)defaultMail;
- (void)setDefaultMail:(NSString *)fieldValue;

- (NSDate *)lastDetectedDateForTargetBoard;

- (BOOL)shouldAlwaysBeLogin;
- (void)setShouldAlwaysBeLogin:(BOOL)checkboxState;

- (BOOL)treatsAsciiArtAsSpamAtTargetBoard;
- (void)setTreatsAsciiArtAsSpamAtTargetBoard:(BOOL)checkboxState;

- (BOOL)treatsNoSageAsSpamAtTargetBoard;
- (void)setTreatsNoSageAsSpamAtTargetBoard:(BOOL)checkboxState;

- (BOOL)registrantShouldConsiderNameAtTargetBoard;
- (void)setRegistrantShouldConsiderNameAtTargetBoard:(BOOL)checkboxState;

- (NSMutableArray *)spamCorpusForTargetBoard;
- (void)setSpamCorpusForTargetBoard:(NSMutableArray *)anArray;

- (BoardListItem *)boardListItem;

- (NSInteger)nanashiAllowed;

- (NSString *)charRefInfoString;

- (BOOL)isDetecting;
- (void)setIsDetecting:(BOOL)flag;
@end
