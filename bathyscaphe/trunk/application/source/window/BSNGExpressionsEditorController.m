//
//  BSNGExpressionsEditorController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/01.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSNGExpressionsEditorController.h"
#import "CocoMonar_Prefix.h"

static NSString *const kNibName = @"BSNGExpressionsEditor";
static NSString *const kTableName = @"NGExpressionsEditor";

@interface BSNGExpressionsEditorController(Private)
- (void)updateMessageText;
@end


@implementation BSNGExpressionsEditorController

@synthesize delegate = m_delegate;

- (id)initWithDelegate:(id)obj boardName:(NSString *)boardName
{
    if (self = [super initWithWindowNibName:kNibName]) {
        self.delegate = obj;
        [self setTargetBoardName:boardName];
    }
    return self;
}

- (void)windowDidLoad
{
    [self updateMessageText];
}

- (void)dealloc
{
    self.delegate = nil;
    [self setTargetBoardName:nil];

    [self unbindNGExpressionsArray];

    // nib top-level object
    [m_controller release];
    m_controller = nil;

    [super dealloc];
}

- (void)bindNGExpressionsArrayTo:(id)observableController withKeyPath:(NSString *)keyPath
{
    if (![self isWindowLoaded]) {
        [self window];
    }
    [m_controller bind:@"contentArray" toObject:observableController withKeyPath:keyPath options:nil];
}

- (void)unbindNGExpressionsArray
{
    [m_controller unbind:@"contentArray"];
    [m_controller setContent:nil]; // 念のため
}

- (NSString *)targetBoardName
{
    return m_targetBoardName;
}

- (void)setTargetBoardName:(NSString *)boardName
{
    [boardName retain];
    [m_targetBoardName release];
    m_targetBoardName = boardName;
    [self updateMessageText];
}

- (IBAction)openEditorSheet:(id)sender
{
    NSWindow *window = nil;
    id delegate = self.delegate;
    if (delegate && [delegate respondsToSelector:@selector(windowForNGExpressionsEditor:)]) {
        window = [delegate windowForNGExpressionsEditor:self];
    }

    if (!window) {
        return;
    }

    [NSApp beginSheet:[self window]
       modalForWindow:window
        modalDelegate:self
       didEndSelector:@selector(NGExpressionsEditorSheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];        
}

- (IBAction)closeEditorSheet:(id)sender
{
    [m_controller commitEditing];

    [NSApp endSheet:[self window]];
}

- (IBAction)showEditorHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:NSLocalizedStringFromTable(@"Editor Help Anchor", kTableName, nil)
                                               inBook:[NSBundle applicationHelpBookName]];
}
@end


@implementation BSNGExpressionsEditorController(Private)
- (void)updateMessageText
{
    if (![self isWindowLoaded]) {
        [self window];
    }
    NSString *messageText;
    if ([self targetBoardName]) {
        messageText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Message Text Board %@ Scope", kTableName, nil), [self targetBoardName]];
    } else {
        messageText = NSLocalizedStringFromTable(@"Message Text App Scope", kTableName, nil);
    }
    [m_messageTextField setStringValue:messageText];
}

- (void)NGExpressionsEditorSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    id delegate = self.delegate;
    [[self window] orderOut:self];
    if (delegate && [delegate respondsToSelector:@selector(NGExpressionsEditorDidClose:)]) {
        [delegate NGExpressionsEditorDidClose:self];
    }
}
@end
