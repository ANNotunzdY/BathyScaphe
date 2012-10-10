//
//  CMRAbstructThreadDocument.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/09/02.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAbstructThreadDocument_p.h"
#import "BSThreadInfoPanelController.h"
#import "BoardManager.h"
#import <SGAppKit/NSWorkspace-SGExtensions.h>
#import "AppDefaults.h"
#import "BSMessageSampleRegistrant.h"
#import "missing.h"

NSString *const CMRAbstractThreadDocumentDidToggleDatOchiNotification = @"CMRAbstractThreadDocumentDidToggleDatOchiNotification";
NSString *const CMRAbstractThreadDocumentDidToggleLabelNotification = @"CMRAbstractThreadDocumentDidToggleLabelNotification";

@implementation CMRAbstructThreadDocument
#pragma mark Accessors
- (NSTextStorage *)textStorage
{
    if (!_textStorage) {
        _textStorage = [[NSTextStorage alloc] init];
    }
    return _textStorage;
}

- (void)setTextStorage:(NSTextStorage *)aTextStorage
{
    [aTextStorage retain];
    [_textStorage release];
    _textStorage = aTextStorage;
}

- (CMRThreadAttributes *)threadAttributes
{
    return _threadAttributes;
}

- (void)setThreadAttributes:(CMRThreadAttributes *)newAttributes
{
    CMRThreadAttributes     *oldAttributes_;

    oldAttributes_ = _threadAttributes;
    _threadAttributes = [newAttributes retain];

    [oldAttributes_ release];
    if (m_registrant) {
        m_registrant.threadIdentifier = [newAttributes threadSignature];
    }
}
/*
- (NSArray *)cachedKeywords
{
    return m_keywords;
}

- (void)setCachedKeywords:(NSArray *)array
{
    [array retain];
    [m_keywords release];
    m_keywords = array;
}

- (BSRelatedKeywordsCollector *)keywordsCollector
{
    if (!m_collector) {
        m_collector = [[BSRelatedKeywordsCollector alloc] init];
    }
    return m_collector;
}
*/
- (BOOL)isAAThread
{
    return [[self threadAttributes] isAAThread];
}

- (void)setIsAAThread:(BOOL)flag
{
    if ([self isAAThread] == flag) return;

    NSArray *winControllers;
    [[self threadAttributes] setIsAAThread:flag];
    winControllers = [self windowControllers];
    if ([winControllers count] > 0) {
        [winControllers makeObjectsPerformSelector:@selector(changeAllMessageAttributesWithAAFlag:) withObject:[NSNumber numberWithBool:flag]];
    }
}

- (BOOL)isDatOchiThread
{
    return [[self threadAttributes] isDatOchiThread];
}

- (void)setIsDatOchiThread:(BOOL)flag
{
    if ([self isDatOchiThread] == flag) return;
    
    [[self threadAttributes] setIsDatOchiThread:flag];
    NSDictionary *foo = [NSDictionary dictionaryWithObject:[[self threadAttributes] path] forKey:@"path"];
    UTILNotifyInfo(CMRAbstractThreadDocumentDidToggleDatOchiNotification, foo);
}

- (NSUInteger)labelOfThread
{
    if (![self showsThreadDocument] || ![self threadAttributes]) {
        // AppleScript でエラーを発生させるために…
        [NSException raise:NSGenericException format:@"No target threads found"];
    }
    return [[self threadAttributes] label];
}

- (void)setLabelOfThread:(NSUInteger)label
{
    if (![self showsThreadDocument] || ![self threadAttributes]) {
        // AppleScript でエラーを発生させるために…
        [NSException raise:NSGenericException format:@"No target threads found"];
    }
    [self setLabelOfThread:label toggle:NO];
}

- (void)setLabelOfThread:(NSUInteger)label toggle:(BOOL)shouldToggle
{
    BOOL    isAssign = YES;
    NSUInteger currentLabel = [[self threadAttributes] label];
    if (currentLabel == label) {
        if (!shouldToggle) {
            return;
        }
        [[self threadAttributes] setLabel:0];
        isAssign = NO;
    } else {
        [[self threadAttributes] setLabel:label];
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[[self threadAttributes] path], @"path",
        [NSNumber numberWithUnsignedInteger:(isAssign ? label : 0)], @"code", NULL];
    UTILNotifyInfo(CMRAbstractThreadDocumentDidToggleLabelNotification, userInfo);
}

- (NSString *)candidateHost
{
    return m_candidateHost;
}

- (void)setCandidateHost:(NSString *)host
{
    [host retain];
    [m_candidateHost release];
    m_candidateHost = host;
}

- (BSMessageSampleRegistrant *)registrant
{
    if (!m_registrant) {
        m_registrant = [[BSMessageSampleRegistrant alloc] initWithThreadSignature:[[self threadAttributes] threadSignature]];
    }
    return m_registrant;
}

#pragma mark Override
- (void)dealloc
{
    [m_registrant release];
    m_registrant = nil;
    [m_candidateHost release];
//    [m_collector release];
//    [m_keywords release];
    [_threadAttributes release];
    [_textStorage release];
    [super dealloc];
}

- (void)removeWindowController:(NSWindowController *)windowController
{
    NSEnumerator        *iter_;
    NSWindowController  *controller_;
    SEL                 selector_;
    
    selector_ = @selector(document:willRemoveController:);
    iter_ = [[self windowControllers] objectEnumerator];

    while (controller_ = [iter_ nextObject]) {
        if (![controller_ respondsToSelector:selector_]) {
            continue;
        }
        [controller_ document:self willRemoveController:windowController];
    }

//    if ([[self keywordsCollector] delegate] == windowController) {
//        [[self keywordsCollector] setDelegate:nil];
//    }

    [super removeWindowController:windowController];
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
    if ([[self windowControllers] count] == 0) {
        [self makeWindowControllers];
    }

    NSPrintOperation *op = [NSPrintOperation printOperationWithView:[[[self windowControllers] objectAtIndex:0] textView] printInfo:[self printInfo]];
    [op setShowsPrintPanel:YES];
    [op setShowsProgressPanel:YES];

    NSPrintPanel *printPanel = [op printPanel];
    [printPanel setOptions:([printPanel options]|NSPrintPanelShowsPageSetupAccessory)];

    return op;
}

#pragma mark Validation
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)theItem
{
    SEL action_;

    action_ = [theItem action];
    
    if (action_ == @selector(showDocumentInfo:) || action_ == @selector(showMainBrowser:)) {
        return ([self showsThreadDocument] && ([self threadAttributes] != nil));
    }

    if (action_ == @selector(saveDocumentAs:)) {
        setUserInterfaceItemTitle(theItem, NSLocalizedString(@"Save Menu Item Default", @"Save as..."));
        return ([self showsThreadDocument] && ([self threadAttributes] != nil));
    } else if (action_ == @selector(toggleAAThread:)) {
        if (![self showsThreadDocument] || ![self threadAttributes]) {
            return NO;
        }
        setUserInterfaceItemState(theItem, [self isAAThread]);
    } else if (action_ == @selector(toggleLabeledThread:)) {
        if (![self showsThreadDocument] || ![self threadAttributes]) {
            setUserInterfaceItemState(theItem, NO);
            return NO;
        }
        NSInteger labelCode = [theItem tag];
        setUserInterfaceItemState(theItem, (labelCode == [[self threadAttributes] label]));
    } else if (action_ == @selector(toggleDatOchiThread:)) {
        if (![self showsThreadDocument] || ![self threadAttributes]) {
            return NO;
        }
        setUserInterfaceItemState(theItem, [self isDatOchiThread]);
    } else if (action_ == @selector(openInBrowser:)) {
        return ([self showsThreadDocument] && ([[self threadAttributes] threadURL] != nil));
    }
    return [super validateUserInterfaceItem:theItem];
}

- (BOOL)validateLabelMenuItem:(BSLabelMenuItemView *)item
{
    if (![self showsThreadDocument] || ![self threadAttributes]) {
        return NO;
    }
    [item setSelected:YES forLabel:[[self threadAttributes] label] clearOthers:YES];
    return YES;
}

#pragma mark IBActions
- (IBAction)showDocumentInfo:(id)sender
{
    [[BSThreadInfoPanelController sharedInstance] showWindow:sender];
}

- (IBAction)showMainBrowser:(id)sender
{
    CMRThreadAttributes *attr_ = [self threadAttributes];
    NSString *boardName_ = [attr_ boardName];
    if(!boardName_) return; 

    [[NSApp delegate] showThreadsListForBoard:boardName_ selectThread:[attr_ path] addToListIfNeeded:YES];
}

- (IBAction)revealInFinder:(id)sender
{
    NSString *path = [[self threadAttributes] path];
    if (!path) {
        NSBeep();
        return;
    }
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
}

- (IBAction)toggleAAThread:(id)sender
{
    [self setIsAAThread:![self isAAThread]];
}

- (IBAction)toggleDatOchiThread:(id)sender
{
    [self setIsDatOchiThread:![self isDatOchiThread]];
}

- (IBAction)toggleLabeledThread:(id)sender
{
    if ([sender isKindOfClass:[BSLabelMenuItemView class]]) {
        [self setLabelOfThread:[sender clickedLabel] toggle:NO];
    } else {
        [self setLabelOfThread:[sender tag] toggle:YES];
    }
}

- (IBAction)toggleAAThreadFromInfoPanel:(id)sender
{
    NSArray *winControllers;
    BOOL    flag = [self isAAThread];
    winControllers = [self windowControllers];
    if ([winControllers count] > 0) {
        [winControllers makeObjectsPerformSelector:@selector(changeAllMessageAttributesWithAAFlag:) withObject:[NSNumber numberWithBool:flag]];
    }
}

- (IBAction)toggleDatOchiThreadFromInfoPanel:(id)sender
{
    NSDictionary *foo = [NSDictionary dictionaryWithObject:[[self threadAttributes] path] forKey:@"path"];
    UTILNotifyInfo(CMRAbstractThreadDocumentDidToggleDatOchiNotification, foo);
}

- (IBAction)toggleLabeledThreadFromInfoPanel:(id)sender
{
    NSDictionary *foo = [NSDictionary dictionaryWithObjectsAndKeys:[[self threadAttributes] path], @"path",
        [NSNumber numberWithInteger:[sender selectedSegment]], @"code", NULL];
    UTILNotifyInfo(CMRAbstractThreadDocumentDidToggleLabelNotification, foo);
}

- (IBAction)openInBrowser:(id)sender
{
    NSURL *url = [CMRThreadAttributes threadURLWithDefaultParameterFromDictionary:[[self threadAttributes] dictionaryRepresentation]];
    [[NSWorkspace sharedWorkspace] openURL:url inBackground:[CMRPref openInBg]];
}
@end


@implementation CMRAbstructThreadDocument(ScriptingSupport)
- (NSTextStorage *)selectedText
{
    NSAttributedString *attrString;
    attrString = [[self textStorage] attributedSubstringFromRange:[[[[self windowControllers] lastObject] textView] selectedRange]];
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:attrString];
    return [storage autorelease];
}

- (NSDictionary *)threadAttrDict
{
    NSDictionary *tmp = [[self threadAttributes] dictionaryRepresentation];
    return tmp ?: [NSDictionary dictionary];
}

- (NSString *)threadTitleAsString
{
    NSString *tmp = [[self threadAttributes] threadTitle];
    return tmp ?: @"";
}

- (NSString *)threadURLAsString
{
    NSString *tmp = [[[self threadAttributes] threadURL] stringValue];
    return tmp ?: @"";
}

- (NSString *)boardNameAsString
{
    NSString *tmp = [[self threadAttributes] boardName];
    return tmp ?: @"";
}

- (NSString *)boardURLAsString
{
    NSString *tmp = [[[self threadAttributes] boardURL] stringValue];
    return tmp ?: @"";
}

- (NSString *)tListBoardURL
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (NSString *)tListBoardName
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (void)setTListBoardName:(NSString *)boardNameStr
{
    UTILAbstractMethodInvoked;
}

- (NSString *)name
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (void)setName:(NSString *)aName
{
    UTILAbstractMethodInvoked;
}

- (NSString *)mail
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (void)setMail:(NSString *)aMail
{
    UTILAbstractMethodInvoked;
}

- (void)handleReloadThreadCommand:(NSScriptCommand*)command
{
    UTILAbstractMethodInvoked;
}

- (BOOL)showsThreadDocument // Dummy
{
    return YES;
}
@end
