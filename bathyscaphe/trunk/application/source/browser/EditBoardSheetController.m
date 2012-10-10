//
//  EditBoardSheetController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/09/04.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "EditBoardSheetController.h"
#import "CocoMonar_Prefix.h"
#import "BoardManager.h"
#import "BoardListItem.h"

static NSString *const kEditBoardSheetNibName       = @"EditBoardSheet";
static NSString *const kEditBoardSheetStringsName   = @"BoardListEditor";

static NSString *const kEditBoardSheetHelpAnchorEditBoard = @"Edit Board HelpAnchor";
static NSString *const kEditBoardSheetHelpAnchorEditCategory = @"Edit Category HelpAnchor";
static NSString *const kEditBoardSheetHelpAnchorAddCategory = @"Add Category HelpAnchor";

static NSString *const kEditDrawerItemMsgForAdditionKey = @"Add Category Msg";
static NSString *const kEditDrawerItemMsgForBoardKey = @"Edit Board Msg";
static NSString *const kEditDrawerItemMsgForCategoryKey = @"Edit Category Msg";

@implementation EditBoardSheetController
@synthesize enteredText;
@synthesize targetItem;
@synthesize partialStringIsValid;
@synthesize shouldValidatePartialString;
@synthesize delegate;
@synthesize helpAnchor;

- (id)initWithDelegate:(id<EditBoardSheetControllerDelegate>)aDelegate targetItem:(BoardListItem *)anItem
{
    if (self = [super initWithWindowNibName:kEditBoardSheetNibName]) {
        [self window];
        self.shouldValidatePartialString = NO;
        self.partialStringIsValid = YES;
        self.targetItem = anItem;
    }
    return self;
}

- (id)initWithDelegate:(id<EditBoardSheetControllerDelegate>)aDelegate
{
    return [self initWithDelegate:aDelegate targetItem:nil];
}

- (id)init
{
    return [self initWithDelegate:nil targetItem:nil];
}

- (void)dealloc
{
    self.targetItem = nil;
    self.enteredText = nil;
    self.helpAnchor = nil;
    [super dealloc];
}

#pragma mark Accessors
- (NSTextField *)messageField
{
    return m_messageField;
}

- (NSTextField *)warningField
{
    return m_warningField;
}

#pragma mark Actions
- (IBAction)pressOK:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)pressCancel:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)pressHelp:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:self.helpAnchor
                                               inBook:[NSBundle applicationHelpBookName]];
}

- (void)beginEditBoardSheetForWindow:(NSWindow *)targetWindow
{
    NSString *name_ = [[self targetItem] representName];
    NSString *URLStr_ = [[[self targetItem] url] absoluteString];

    NSString *messageTemplate = [self localizedString:kEditDrawerItemMsgForBoardKey];

// #warning 64BIT: Check formatting arguments
// 2010-09-06 tsawada2 検証済
    [[self messageField] setStringValue:[NSString localizedStringWithFormat:messageTemplate, name_]];
    [self setEnteredText:URLStr_];
    [self setShouldValidatePartialString:YES];
    [self setPartialStringIsValid:YES];
    self.helpAnchor = [self localizedString:kEditBoardSheetHelpAnchorEditBoard];

    [NSApp beginSheet:[self window]
       modalForWindow:targetWindow
        modalDelegate:self
       didEndSelector:@selector(editBoardSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)beginEditCategorySheetForWindow:(NSWindow *)targetWindow
{
    NSString *name_ = [[self targetItem] representName];

    NSString *messageTemplate = [self localizedString:kEditDrawerItemMsgForCategoryKey];

// #warning 64BIT: Check formatting arguments
// 2010-09-06 tsawada2 検証済
    [[self messageField] setStringValue:[NSString localizedStringWithFormat:messageTemplate, name_]];
    [self setEnteredText:name_];
    [self setShouldValidatePartialString:NO];
    [self setPartialStringIsValid:YES];
    self.helpAnchor = [self localizedString:kEditBoardSheetHelpAnchorEditCategory];

    [NSApp beginSheet:[self window]
       modalForWindow:targetWindow
        modalDelegate:self
       didEndSelector:@selector(editCategorySheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)beginAddCategorySheetForWindow:(NSWindow *)targetWindow
{
    [[self messageField] setStringValue:[self localizedString:kEditDrawerItemMsgForAdditionKey]];   
    [self setEnteredText:nil];
    [self setShouldValidatePartialString:NO];
    [self setPartialStringIsValid:YES];
    self.helpAnchor = [self localizedString:kEditBoardSheetHelpAnchorAddCategory];

    [NSApp beginSheet:[self window]
       modalForWindow:targetWindow
        modalDelegate:self
       didEndSelector:@selector(addCategorySheetDidEnd:returnCode:delegateInfo:)
          contextInfo:nil];
}

#pragma mark Utilities
+ (NSString *)localizableStringsTableName
{
    return kEditBoardSheetStringsName;
}

- (void)finishSheet:(NSInteger)returnCode
{
    if (self.delegate) {
        [self.delegate controller:self didEndSheetWithReturnCode:returnCode]; 
    }
    self.targetItem = nil;
}

#pragma mark Sheet Delegates
- (void)addCategorySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode delegateInfo:(id)aDelegate
{
    if (NSOKButton == returnCode) {
        [[BoardManager defaultManager] addCategoryOfName:[self enteredText]];
    }

    [sheet close];
    [self finishSheet:returnCode];
}

- (void)editCategorySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(id)contextInfo
{
    if (NSOKButton == returnCode) {
        [[BoardManager defaultManager] editCategoryItem:[self targetItem] newName:[self enteredText]];
    }

    [sheet close];
    [self finishSheet:returnCode];
}

- (void)editBoardSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(id)contextInfo
{
    self.shouldValidatePartialString = NO;
    [[self warningField] setStringValue:@""];

    if (NSOKButton == returnCode) {
        [[BoardManager defaultManager] editBoardItem:[self targetItem] newURLString:[self enteredText]];
    }

    [sheet close];
    [self finishSheet:returnCode];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    if (![self shouldValidatePartialString]) {
        return;
    }
    // 簡単な入力文字列チェックを行う
    NSText *fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
    NSString *partialString = [fieldEditor string];
    NSString *error = @"";

    if (![partialString hasPrefix:@"http://"]) {
        error = [self localizedString:@"Validation Error 1"];
        [self setPartialStringIsValid:NO];
    } else if (![partialString hasSuffix:@"/"]) {
        error = [self localizedString:@"Validation Error 2"];
        [self setPartialStringIsValid:NO];
    } else {
        [self setPartialStringIsValid:YES];
    }
    [[self warningField] setStringValue:error];
}
@end
