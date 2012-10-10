//
//  BSBoardInfoInspector.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/10/08.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSBoardInfoInspector.h"

#import <SGFoundation/SGFoundation.h>
#import <CocoMonar/CocoMonar.h>

#import "BoardManager.h"
#import "CMRThreadViewer.h"
#import "CMRBrowser.h"
#import "BoardListItem.h"
#import "BSNGExpressionsEditorController.h"
#import "AppDefaults.h"

#define BrdMgr  [BoardManager defaultManager]

static NSString *const BIINibFileNameKey        = @"BSBoardInfoPanel";
static NSString *const BIIFrameAutoSaveNameKey  = @"BathyScaphe:BoardInfoInspector Panel Autosave";
static NSString *const BIIHelpKeywordKey        = @"BoardInspector Help Keyword";

@implementation BSBoardInfoInspector
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance);

- (id)init
{
    if (self = [super initWithWindowNibName:BIINibFileNameKey]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(browserBoardChanged:)
                   name:CMRBrowserDidChangeBoardNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(mainWindowChanged:)
                   name:NSWindowDidBecomeMainNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(viewerThreadChanged:)
                   name:CMRThreadViewerDidChangeThreadNotification
                 object:nil];
        [nc addObserver:self
               selector:@selector(boardManagerDidDetectSettingTxt:)
                   name:BoardManagerDidFinishDetectingSettingTxtNotification
                 object:BrdMgr];
        [self setIsDetecting:NO];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [m_currentTargetBoardName release];
    [m_editor release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [[self window] setFrameAutosaveName:BIIFrameAutoSaveNameKey];
    [self synchronizeSelectedToolbarItem];
    [self updateHostSymbolsMatrix];
}

- (void)showInspectorForTargetBoard:(NSString *)boardName
{
    [self setCurrentTargetBoardName:boardName];
    [self showWindow:self];
}

- (IBAction)showBoardInspectorPanel:(id)sender
{
    [[self window] performClose:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([item action] == @selector(showBoardInspectorPanel:)) {
        [item setTitle:NSLocalizedStringFromTable(@"Hide Board Inspector", @"ThreadViewer", @"")];
    }
    return YES;
}

- (void)updateHostSymbolsMatrix
{
    if (![self currentTargetBoardName]) {
        return;
    }
    NSSet *symbols = [BrdMgr spamHostSymbolsForBoard:[self currentTargetBoardName]];
    NSArray *cells = [m_hostSymbolsMatrix cells];
    for (NSActionCell *cell in cells) {
        BOOL isSpamSymbol = [symbols containsObject:[cell title]];
        [cell setState:(isSpamSymbol ? NSOnState : NSOffState)];
    }
}

- (void)autoHideNGExpressionsEditorIfNeeded
{
    if (!m_editor) {
        return;
    }
    if (![self shouldEnableUI] && [[[self editor] window] isVisible]) {
        [[self editor] closeEditorSheet:self];
    }
    [[self editor] setTargetBoardName:[self currentTargetBoardName]];
}

- (void)synchronizeSelectedToolbarItem
{
    NSString *lastId = [CMRPref lastShownBoardInfoInspectorPaneIdentifier];
    [m_panes selectTabViewItemWithIdentifier:lastId];
    [m_toolbar setSelectedItemIdentifier:lastId];
}

#pragma mark Accessors
- (NSString *)currentTargetBoardName
{
    return m_currentTargetBoardName;
}

- (void)setCurrentTargetBoardName:(NSString *)newTarget
{
    [self willChangeValueForKey:@"noNamesArray"];
    [self willChangeValueForKey:@"boardURLAsString"];
    [self willChangeValueForKey:@"shouldEnableUI"];
    [self willChangeValueForKey:@"defaultKotehan"];
    [self willChangeValueForKey:@"defaultMail"];
    [self willChangeValueForKey:@"shouldAlwaysBeLogin"];
    [self willChangeValueForKey:@"treatsAsciiArtAsSpamAtTargetBoard"];
    [self willChangeValueForKey:@"boardListItem"];
    [self willChangeValueForKey:@"shouldEnableBeBtn"];
    [self willChangeValueForKey:@"shouldEnableURLEditing"];
    [self willChangeValueForKey:@"nanashiAllowed"];
    [self willChangeValueForKey:@"treatsNoSageAsSpamAtTargetBoard"];
    [self willChangeValueForKey:@"spamCorpusForTargetBoard"];
    [self willChangeValueForKey:@"charRefInfoString"];
    [self willChangeValueForKey:@"registrantShouldConsiderNameAtTargetBoard"];
    [self willChangeValueForKey:@"lastDetectedDateForTargetBoard"];

    [newTarget retain];
    [m_currentTargetBoardName release];
    m_currentTargetBoardName = newTarget;

    [self didChangeValueForKey:@"lastDetectedDateForTargetBoard"];
    [self didChangeValueForKey:@"registrantShouldConsiderNameAtTargetBoard"];
    [self didChangeValueForKey:@"charRefInfoString"];
    [self didChangeValueForKey:@"spamCorpusForTargetBoard"];
    [self didChangeValueForKey:@"treatsNoSageAsSpamAtTargetBoard"];
    [self didChangeValueForKey:@"nanashiAllowed"];
    [self didChangeValueForKey:@"shouldEnableURLEditing"];
    [self didChangeValueForKey:@"shouldEnableBeBtn"];
    [self didChangeValueForKey:@"boardListItem"];
    [self didChangeValueForKey:@"treatsAsciiArtAsSpamAtTargetBoard"];
    [self didChangeValueForKey:@"shouldAlwaysBeLogin"];
    [self didChangeValueForKey:@"defaultMail"];
    [self didChangeValueForKey:@"defaultKotehan"];
    [self didChangeValueForKey:@"shouldEnableUI"];
    [self didChangeValueForKey:@"boardURLAsString"];
    [self didChangeValueForKey:@"noNamesArray"];

    [self updateHostSymbolsMatrix];
    [self autoHideNGExpressionsEditorIfNeeded];
}

- (BOOL)isDetecting
{
    return m_isDetecting;
}

- (void)setIsDetecting:(BOOL)flag
{
    m_isDetecting = flag;
}

- (NSButton *)addNoNameBtn
{
    return m_addNoNameBtn;
}

- (NSButton *)removeNoNameBtn
{
    return m_removeNoNameBtn;
}

- (NSButton *)editBoardURLButton
{
    return m_editBoardURLButton;
}

- (BSNGExpressionsEditorController *)editor
{
    if (!m_editor) {
        m_editor = [[BSNGExpressionsEditorController alloc] initWithDelegate:self boardName:nil];
    }
    return m_editor;
}

#pragma mark IBActions
- (IBAction)showWindow:(id)sender
{
    // toggle-Action : すでにパネルが表示されているときは、パネルを閉じる
    if ([[self window] isVisible]) {
        [[self window] performClose:sender];
    } else {
        [super showWindow:sender];
    }
}

- (IBAction)addNoName:(id)sender
{
    // Lion でなぜか currentTargetBoardName をそのまま -askUserAboutDefaultNoNameForBoard:presetValue: の引数に使うと
    // BoardManager の中で値が不正になってしまってクラッシュする問題が発生したため、とりあえず改めて NSString インスタンスを作って
    // 渡してみる（落ちなくはなったようだ）。
    NSString *lionString = [[NSString alloc] initWithString:[self currentTargetBoardName]];
    [BrdMgr askUserAboutDefaultNoNameForBoard:lionString presetValue:nil];
    [lionString release];
}

- (IBAction)startDetect:(id)sender
{
    if ([BrdMgr startDownloadSettingTxtForBoard:[self currentTargetBoardName] askIfOffline:NO allowToInputManually:NO]) {
        [self setIsDetecting:YES];
    } else {
        NSBeep();
    }
}

- (IBAction)editBoardURL:(id)sender
{
    EditBoardSheetController *controller = [[EditBoardSheetController alloc] initWithDelegate:self targetItem:[self boardListItem]];
    [controller beginEditBoardSheetForWindow:[self window]];
}

- (IBAction)openHelpForMe:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:NSLocalizedString(BIIHelpKeywordKey, @"Board options")
                                               inBook:[NSBundle applicationHelpBookName]];
}

- (IBAction)changePane:(id)sender
{
    NSString *identifier = [(NSToolbarItem *)sender itemIdentifier];
    [m_panes selectTabViewItemWithIdentifier:identifier];
    [CMRPref setLastShownBoardInfoInspectorPaneIdentifier:identifier];
}

- (IBAction)hostSymbolChanged:(id)sender
{
    NSMutableSet *symbols = [[NSMutableSet alloc] initWithCapacity:7];
    NSArray *cells = [m_hostSymbolsMatrix cells];
    for (NSActionCell *cell in cells) {
        if ([cell state] == NSOnState) {
            [symbols addObject:[cell title]];
        }
    }
    NSSet *immutableSymbols = [[NSSet alloc] initWithSet:symbols];
    [BrdMgr setSpamHostSymbols:immutableSymbols forBoard:[self currentTargetBoardName]];
    [immutableSymbols release];
    [symbols release];
}

- (IBAction)openNGExpressionsEditorSheet:(id)sender
{
    [[self editor] bindNGExpressionsArrayTo:self withKeyPath:@"spamCorpusForTargetBoard"];
    [[self editor] setTargetBoardName:[self currentTargetBoardName]];
    [[self editor] openEditorSheet:self];
}

#pragma mark Accesors For Binding
- (NSMutableArray *)noNamesArray
{
    return [[[BrdMgr defaultNoNameArrayForBoard:[self currentTargetBoardName]] mutableCopy] autorelease];
}

- (void)setNoNamesArray:(NSMutableArray *)anArray
{
    [BrdMgr setDefaultNoNameArray:[NSArray arrayWithArray:anArray] forBoard:[self currentTargetBoardName]];
}

- (NSString *)boardURLAsString
{
    BoardListItem *tmp = [self boardListItem];
    if ([tmp type] != BoardListBoardItem) {
        return nil;
    }
    return [[tmp url] absoluteString];
}

- (BOOL)shouldEnableUI
{
    BoardListItem *tmp_ = [self boardListItem];
    if ([[self boardListItem] type] != BoardListBoardItem) {
        return NO;
    }
    if ([[tmp_ representName] hasSuffix:@"headline"]) {
        return NO;
    }
    return YES;
}

- (BOOL)shouldEnableBeBtn
{
    return (BSBeLoginDecidedByUser == [BrdMgr typeOfBeLoginPolicyForBoard:[self currentTargetBoardName]]);
}

- (BOOL)shouldEnableURLEditing
{
    return ([[self boardListItem] type] == BoardListBoardItem);
}

- (NSString *)defaultKotehan
{
    return [BrdMgr defaultKotehanForBoard:[self currentTargetBoardName]];
}

- (void)setDefaultKotehan:(NSString *)fieldValue
{
    [BrdMgr setDefaultKotehan:((fieldValue != nil) ? fieldValue : @"") forBoard:[self currentTargetBoardName]];
}

- (NSString *)defaultMail
{
    return [BrdMgr defaultMailForBoard:[self currentTargetBoardName]];
}

- (void)setDefaultMail:(NSString *)fieldValue
{
    [BrdMgr setDefaultMail:((fieldValue != nil) ? fieldValue : @"") forBoard:[self currentTargetBoardName]];
}

- (NSDate *)lastDetectedDateForTargetBoard
{
    return [BrdMgr lastDetectedDateForBoard:[self currentTargetBoardName]];
}

- (BOOL)shouldAlwaysBeLogin
{
    return [BrdMgr alwaysBeLoginAtBoard:[self currentTargetBoardName]];
}

- (void)setShouldAlwaysBeLogin:(BOOL)checkboxState
{
    [BrdMgr setAlwaysBeLogin:checkboxState atBoard:[self currentTargetBoardName]];
}

- (BOOL)treatsAsciiArtAsSpamAtTargetBoard
{
    return [BrdMgr treatsAsciiArtAsSpamAtBoard:[self currentTargetBoardName]];
}

- (void)setTreatsAsciiArtAsSpamAtTargetBoard:(BOOL)checkboxState
{
    [BrdMgr setTreatsAsciiArtAsSpam:checkboxState atBoard:[self currentTargetBoardName]];
}

- (BoardListItem *)boardListItem
{
    return [BrdMgr itemForName:[self currentTargetBoardName]];
}

- (NSInteger)nanashiAllowed
{
    return [BrdMgr allowsNanashiAtBoard:[self currentTargetBoardName]] ? 0 : 1;
}

- (NSString *)charRefInfoString
{
    BOOL status = [BrdMgr hasAllowsCharRefEntryAtBoard:[self currentTargetBoardName]];
    if (!status) {
        return NSLocalizedString(@"charRefInfo N/A", nil);
    }
    return [BrdMgr allowsCharRefAtBoard:[self currentTargetBoardName]] ? NSLocalizedString(@"charRefInfo Yes", nil)
                                                                       : NSLocalizedString(@"charRefInfo No", nil);
}

- (BOOL)treatsNoSageAsSpamAtTargetBoard
{
    return [BrdMgr treatsNoSageAsSpamAtBoard:[self currentTargetBoardName]];
}

- (void)setTreatsNoSageAsSpamAtTargetBoard:(BOOL)checkboxState
{
    [BrdMgr setTreatsNoSageAsSpam:checkboxState atBoard:[self currentTargetBoardName]];
}

- (BOOL)registrantShouldConsiderNameAtTargetBoard
{
    return [BrdMgr registrantShouldConsiderNameAtBoard:[self currentTargetBoardName]];
}

- (void)setRegistrantShouldConsiderNameAtTargetBoard:(BOOL)checkboxState
{
    [BrdMgr setRegistrantShouldConsiderName:checkboxState atBoard:[self currentTargetBoardName]];
}

- (NSMutableArray *)spamCorpusForTargetBoard
{
    return [BrdMgr spamMessageCorpusForBoard:[self currentTargetBoardName]];
}

- (void)setSpamCorpusForTargetBoard:(NSMutableArray *)anArray
{
    [BrdMgr setSpamMessageCorpus:[NSMutableArray arrayWithArray:anArray] forBoard:[self currentTargetBoardName]];
}

#pragma mark Notification
- (BOOL)shouldIgnoreNotification
{
    return (![self isWindowLoaded] || ![[self window] isVisible]);
}

- (void)mainWindowChanged:(NSNotification *)theNotification
{
    if ([self shouldIgnoreNotification]) {
        return;
    }
    id winController_ = [[theNotification object] windowController];

    if ([winController_ respondsToSelector: @selector(boardName)]) {
        NSString *tmp_ = [winController_ boardName];

        if (!tmp_) {
            return;
        }
        [self setCurrentTargetBoardName:tmp_];
        [[self window] update];
    }
}

- (void)browserBoardChanged:(NSNotification *)theNotification
{
    if ([self shouldIgnoreNotification]) {
        return;
    }
    id winController_ = [theNotification object];

    if (![(NSWindow *)[winController_ window] isMainWindow]) {
        return;
    }
    if ([winController_ respondsToSelector:@selector(currentThreadsList)]) {
        NSString *tmp_;
        tmp_ = [[winController_ currentThreadsList] boardName];
        if (!tmp_) {
            return;
        }
        [self setCurrentTargetBoardName:tmp_];
        [[self window] update];
    }
}

- (void)viewerThreadChanged:(NSNotification *)theNotification
{
    if ([self shouldIgnoreNotification]) {
        return;
    }
    id winController_ = [theNotification object];

    if ([winController_ isMemberOfClass:[CMRThreadViewer class]]) {
        NSString *tmp_;
        tmp_ = [(CMRThreadViewer *)winController_ boardName];

        if (!tmp_) {
            return;
        }
        if ([[self currentTargetBoardName] isEqualToString:tmp_]) {
            return;
        }
        [self setCurrentTargetBoardName:tmp_];
        [[self window] update];
    }
}

- (void)boardManagerDidDetectSettingTxt:(NSNotification *)aNotification
{
    [self setIsDetecting:NO];
    if ([self isWindowLoaded] && [[self window] isVisible]) {
        [self setCurrentTargetBoardName:m_currentTargetBoardName];
        [[self window] update];
    }
}

- (void)controller:(EditBoardSheetController *)controller didEndSheetWithReturnCode:(NSInteger)code
{
    [controller autorelease];
}

- (NSWindow *)windowForNGExpressionsEditor:(BSNGExpressionsEditorController *)controller
{
    return [self window];
}
@end
