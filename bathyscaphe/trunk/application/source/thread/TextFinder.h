//
//  TextFinder.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/10/10.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSSearchOptions;

@interface TextFinder : NSWindowController {
    IBOutlet NSTextField    *_findTextField;
    IBOutlet NSTextField    *_notFoundField;
    IBOutlet NSBox          *m_optionsBox;
    IBOutlet NSMatrix       *m_targetMatrix;
    IBOutlet NSView         *m_findButtonsView;
    IBOutlet NSButton       *m_disclosureTriangle;
    IBOutlet NSButton       *m_linkOnlyButton;
    IBOutlet NSProgressIndicator *m_progressSpin;
    NSString                *m_findString;
}

+ (id)standardTextFinder;
- (NSTextField *)findTextField;
- (NSTextField *)notFoundField;
- (NSBox *)optionsBox;
- (NSMatrix *)targetMatrix;
- (NSView *)findButtonsView;
- (NSButton *)linkOnlyButton;

//- (void)setSearchTargets:(NSArray *)array display:(BOOL)needsDisaplay;
- (void)setupUIComponents;

- (BSSearchOptions *)currentOperation;
//- (void)restoreState:(BSSearchOptions *)previousOptions;

- (NSString *)findString;
- (void)setFindString:(NSString *)aString;

// Binding...
- (BOOL)isCaseInsensitive;
- (void)setIsCaseInsensitive:(BOOL)checkBoxState;
- (BOOL)isLinkOnly;
- (void)setIsLinkOnly:(BOOL)checkBoxState;
- (BOOL)usesRegularExpression;
- (void)setUsesRegularExpression:(BOOL)checkBoxState;

- (IBAction)changeTargets:(id)sender;
- (IBAction)togglePanelMode:(id)sender;

- (NSString *)loadFindStringFromPasteboard;
- (void)setFindStringToPasteboard;

- (void)expandOrShrinkPanel:(BOOL)willExpand animate:(BOOL)shouldAnimate;
- (void)updateLinkOnlyBtnEnabled;

- (void)registerToNotificationCenter;
@end
