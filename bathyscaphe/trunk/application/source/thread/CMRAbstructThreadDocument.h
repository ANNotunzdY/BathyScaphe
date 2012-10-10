//
//  CMRAbstructThreadDocument.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/14.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "BSLabelMenuItemView.h"

@class CMRThreadAttributes;
@class BSMessageSampleRegistrant;

@interface CMRAbstructThreadDocument : NSDocument<BSLabelMenuItemViewValidation> {
    CMRThreadAttributes         *_threadAttributes;
    NSTextStorage               *_textStorage;
    NSString *m_candidateHost;
    BSMessageSampleRegistrant *m_registrant;
}

- (CMRThreadAttributes *)threadAttributes;
- (void)setThreadAttributes:(CMRThreadAttributes *)attributes;
- (BOOL)isAAThread;
- (void)setIsAAThread:(BOOL)flag;
- (BOOL)isDatOchiThread;
- (void)setIsDatOchiThread:(BOOL)flag;
- (NSUInteger)labelOfThread;
- (void)setLabelOfThread:(NSUInteger)label toggle:(BOOL)shouldToggle;

- (NSString *)candidateHost;
- (void)setCandidateHost:(NSString *)host;

- (NSTextStorage *)textStorage;
- (void)setTextStorage:(NSTextStorage *)aTextStorage;

- (BSMessageSampleRegistrant *)registrant;

// IBActions
// Available in Starlight Breaker.
- (IBAction)showDocumentInfo:(id)sender;
- (IBAction)showMainBrowser:(id)sender;
- (IBAction)toggleAAThread:(id)sender;
- (IBAction)toggleDatOchiThread:(id)sender;
//- (IBAction)toggleMarkedThread:(id)sender;
- (IBAction)toggleLabeledThread:(id)sender; // [sender tag] == 1 thru 7

- (IBAction)toggleAAThreadFromInfoPanel:(id)sender;
- (IBAction)toggleDatOchiThreadFromInfoPanel:(id)sender;
- (IBAction)toggleLabeledThreadFromInfoPanel:(id)sender;

- (IBAction)revealInFinder:(id)sender; // Available in Twincam Angel and later.
- (IBAction)openInBrowser:(id)sender; // Available in SilverGull and later.
@end

/* for AppleScript */
@interface CMRAbstructThreadDocument(ScriptingSupport)
- (NSTextStorage *)selectedText;

- (NSDictionary *)threadAttrDict;
- (NSString *)threadTitleAsString;
- (NSString *)threadURLAsString;
- (NSString *)boardNameAsString;
- (NSString *)boardURLAsString;

- (BOOL)showsThreadDocument; // Dummy

- (void)handleReloadThreadCommand:(NSScriptCommand*)command;
@end


@interface NSWindowController(CMRAbstructThreadDocumentDelegate)
- (void)document:(NSDocument *)aDocument willRemoveController:(NSWindowController *)aController;
@end


extern NSString *const CMRAbstractThreadDocumentDidToggleDatOchiNotification;
extern NSString *const CMRAbstractThreadDocumentDidToggleLabelNotification;
