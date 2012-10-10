//
//  BSThreadLinkerCorePasser.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 12/08/19.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadLinkerCorePasser.h"
#import "CMRThreadSignature.h"
#import "CMRDocumentFileManager.h"
#import "CMRReplyDocumentFileManager.h"
#import "CMRAbstructThreadDocument.h"
#import "CMRReplyMessenger.h"
#import "BSThreadLinkerCore.h"
#import "CMRThreadAttributes.h"

static NSString *const kTableName = @"PassOnWindow";

@implementation BSThreadLinkerCorePasser
@synthesize fromThreadTitle = m_fromThreadTitle;
@synthesize fromThreadSignature = m_fromThreadSignature;
@synthesize toThreadTitle = m_toThreadTitle;
@synthesize toThreadSignature = m_toThreadSignature;

- (id)init
{
    if (self = [super initWithWindowNibName:@"BSThreadLinkerCorePasser"]) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)dealloc
{
    [[self linkerCoreController] setContent:nil];

    self.fromThreadTitle = nil;
    self.fromThreadSignature = nil;
    self.toThreadTitle = nil;
    self.toThreadSignature = nil;
    [super dealloc];
}

- (NSObjectController *)linkerCoreController
{
    return m_linkerCoreController;
}

- (IBAction)cancelPassingOn:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)passOnAndClose:(id)sender
{
    [self passLinkerCoreOnNextThread:NULL];
    [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)passOnHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:NSLocalizedStringFromTable(@"PassOnWindow Help Anchor", kTableName, nil)
                                               inBook:[NSBundle applicationHelpBookName]];
}

- (BSThreadLinkerCore *)collectLinkerCore
{
    NSURL *logFileURL = [self.fromThreadSignature threadDocumentURL];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[logFileURL path]]) {
        // ログファイルが無い…
    }
    
//    id document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:logFileURL display:NO error:NULL];
    BSThreadLinkerCore *linkerCore = [[BSThreadLinkerCore alloc] init];
/*    linkerCore.threadLabel = [document labelOfThread];
    linkerCore.aaThread = [document isAAThread];
    linkerCore.threadWindowFrame = [[document threadAttributes] windowFrame];
    [document close];*/
    
    NSURL *replyFileURL = [[CMRReplyDocumentFileManager defaultManager] replyDocumentFileURLWithLogURL:logFileURL createIfNeeded:NO];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[replyFileURL path]]) {
        // 下書き書類が無い…
    } else {
        id replyDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:replyFileURL display:NO error:NULL];
        linkerCore.replyName = [replyDocument name];
        linkerCore.replyMail = [replyDocument mail];
        linkerCore.replyDraft = [[replyDocument textStorage] string];
        linkerCore.replyWindowFrame = [replyDocument windowFrame];
        [replyDocument close];
    }
    
    return [linkerCore autorelease];
}

- (void)installLinkerCore:(BSThreadLinkerCore *)linkerCore
{
    NSURL *logFileURL = [self.toThreadSignature threadDocumentURL];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[logFileURL path]]) {
        // ログファイルが無い…
    }
    // TODO このアプローチはダメ
/*    id document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:logFileURL display:NO error:NULL];
    [document setLabelOfThread:linkerCore.threadLabel toggle:NO];
    [document setAAThread:linkerCore.aaThread];
    [[document threadAttributes] setWindowFrame:linkerCore.threadWindowFrame];
    [document close]; // TODO 常に閉じて良いのか？
    */
    NSURL *replyFileURL = [[CMRReplyDocumentFileManager defaultManager] replyDocumentFileURLWithLogURL:logFileURL createIfNeeded:YES];

    BOOL replyFileExists = [[CMRReplyDocumentFileManager defaultManager] replyDocumentFileExistsAtURL:replyFileURL];
    id replyDocument;
    if (replyFileExists && (replyDocument = [[NSDocumentController sharedDocumentController] documentForURL:replyFileURL])) {
        // 引き継ぎ先の書き込みウインドウが既に表示されている場合
        if (linkerCore.replyName) {
            [(CMRReplyMessenger *)replyDocument setName:linkerCore.replyName];
        }
        if (linkerCore.replyMail) {
            [(CMRReplyMessenger *)replyDocument setMail:linkerCore.replyMail];
        }
        if (linkerCore.replyDraft) {
            [(CMRReplyMessenger *)replyDocument setTextStorage:linkerCore.replyDraft];
        }
        if (!NSEqualRects(linkerCore.replyWindowFrame, NSZeroRect)) {
            [[(CMRReplyMessenger *)replyDocument windowForSheet] setFrame:linkerCore.replyWindowFrame display:YES];
        }
    } else {
        // 下書き書類が開いていないか、作成されていない場合。リンカーコアの内容で上書き／新規作成する。
        NSArray *attrs = [NSArray arrayWithObjects:
                          [self.toThreadSignature boardName],
                          self.toThreadTitle,
                          [self.toThreadSignature identifier],
                          (linkerCore.replyName ?: @""),
                          (linkerCore.replyMail ?: @""),
                          (linkerCore.replyDraft ?: @""),
                          NSStringFromRect(linkerCore.replyWindowFrame),
                          @"",
                          nil];
        NSDictionary *attrDict = [NSDictionary dictionaryWithObjects:attrs forKeys:[CMRReplyDocumentFileManager documentAttributeKeys]];
        [[CMRReplyDocumentFileManager defaultManager] createReplyDocumentFileAtURL:replyFileURL documentAttributes:attrDict];
    }
}

- (void)updateUIComponents
{
    [m_fromThreadTitleField setStringValue:(self.fromThreadTitle ?: @"No thread specified")];
    [m_toThreadTitleField setStringValue:(self.toThreadTitle ?: @"No thread specified")];
}

- (void)passingLinkerCoreOnSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)code contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    [[self linkerCoreController] setContent:nil];
}

- (void)beginPassingLinkerCoreOnSheetForWindow:(NSWindow *)window
{
    if (![self isWindowLoaded]) {
        [self window];
    }

    [self updateUIComponents]; // Text Field Setup etc...

    [NSApp beginSheet:[self window] modalForWindow:window modalDelegate:self didEndSelector:@selector(passingLinkerCoreOnSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (BOOL)passLinkerCoreOnNextThread:(NSError **)errorPtr
{
    BSThreadLinkerCore *linkerCore = [self collectLinkerCore];
//    [[self linkerCoreController] setContent:linkerCore];
    [self installLinkerCore:linkerCore];
    return YES;
}
@end
