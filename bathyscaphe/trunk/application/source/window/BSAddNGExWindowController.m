//
//  BSAddNGExWindowController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/07.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSAddNGExWindowController.h"
#import "CocoMonar_Prefix.h"
#import "CMRThreadSignature.h"
#import "BSNGExpression.h"
#import "AppDefaults.h"
#import "CMRSpamFilter.h"
#import "BoardManager.h"
#import "CMRThreadViewer.h"

static NSString *const kTableName = @"AddNgExWindow";
@implementation BSAddNGExWindowController

@synthesize ngExpression = m_NGExpression;

- (id)init
{
    if (self = [super initWithWindowNibName:@"BSAddNGExpressionWindow"]) {
        ;
    }
    return self;
}

- (void)dealloc
{
    [m_NGExpressionController setContent:nil];

    [m_signature release];
    self.ngExpression = nil;

    [super dealloc];
}


- (NSObjectController *)ngExpressionController
{
    return m_NGExpressionController;
}

- (NSMatrix *)scopeSelector
{
    return m_scopeSelector;
}

- (NSButton *)runSpamFilterImmediatelyButton
{
    return m_runSpamFilterImmediatelyButton;
}

- (void)updateUIComponents
{
    NSString *label = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ only", kTableName, nil), [m_signature boardName]];
    [(NSButtonCell *)[[self scopeSelector] cellWithTag:BSAddNGExBoardScopeType] setTitle:label];
    [[self scopeSelector] selectCellWithTag:[CMRPref ngExpressionAddingScope]];
    [[self runSpamFilterImmediatelyButton] setState:([CMRPref runSpamFilterAfterAddingNGExpression] ? NSOnState : NSOffState)];
}

- (void)showAddNGExpressionSheetForWindow:(NSWindow *)window
                          threadSignature:(CMRThreadSignature *)signature
                               expression:(NSString *)expression
{
    BSNGExpression *ex = [[BSNGExpression alloc] initWithExpression:expression targetMask:BSNGExpressionAtAll regularExpression:NO];
    self.ngExpression = ex;
    [ex release];
    m_signature = [signature retain];

    [self window]; // load window if needed

    [[self ngExpressionController] setContent:self.ngExpression];
    [self updateUIComponents];

    [NSApp beginSheet:[self window]
       modalForWindow:window
        modalDelegate:self
       didEndSelector:@selector(addNGExSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (void)addNGExSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)code contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    [[self ngExpressionController] setContent:nil];
    if ((code == NSOKButton) && ([[self runSpamFilterImmediatelyButton] state] == NSOnState)) {
        NSNotification *notification;
        NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
        
        notification = [NSNotification notificationWithName:CMRThreadViewerRunSpamFilterNotification object:self];
        [queue enqueueNotification:notification postingStyle:NSPostWhenIdle];
    }
}

- (IBAction)cancelAddingNGEx:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)addNGExAndClose:(id)sender
{
    [[self ngExpressionController] commitEditing];
    NSInteger scope = [[self scopeSelector] selectedTag];
    switch (scope) {
        case BSAddNGExBoardScopeType:
            [[BoardManager defaultManager] addNGExpression:self.ngExpression forBoard:[m_signature boardName]];
            break;
        default:
            [[CMRSpamFilter sharedInstance] addNGExpression:self.ngExpression];
            break;
    }

    [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)addNGExHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:NSLocalizedStringFromTable(@"AddNgExWindow Help Anchor", kTableName, nil)
                                               inBook:[NSBundle applicationHelpBookName]];
}

- (IBAction)toggleRunImmediately:(id)sender
{
    [CMRPref setRunSpamFilterAfterAddingNGExpression:([[self runSpamFilterImmediatelyButton] state] == NSOnState)];
}

- (IBAction)selectScope:(id)sender
{
    [CMRPref setNgExpressionAddingScope:[(NSMatrix *)sender selectedTag]];
}
@end
