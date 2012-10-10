//
//  BoardManager-SettingTxt.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/04/03.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BoardManager.h"
#import "BSSettingTxtDetector.h"
#import "AppDefaults.h"
#import "SmartBoardList.h"
#import "BSBoardInfoInspector.h"
#import "DatabaseManager.h"
#import "BSLocalRulesCollector.h"
#import "BSLocalRulesPanelController.h"

NSString *const BoardManagerDidFinishDetectingSettingTxtNotification = @"BoardManagerDidFinishDetectingSettingTxtNotification";

@implementation BoardManager(SettingTxtDetector)
- (BOOL)doDownloadSettingTxtForBoard:(NSString *)boardName
{
    NSURL *boardURL = [self URLForBoardName:boardName];
    NSString *URLStr_ = [boardURL absoluteString];
    NSURL *settingTxtURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", URLStr_, @"SETTING.TXT"]];

    BSSettingTxtDetector *detector_ = [[BSSettingTxtDetector alloc] initWithBoardName:boardName settingTxtURL:settingTxtURL];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self
           selector:@selector(detectorDidFinish:)
               name:BSSettingTxtDetectorDidFinishNotification
             object:detector_];
    [nc addObserver:self
           selector:@selector(detectorDidFail:)
               name:BSSettingTxtDetectorDidFailNotification
             object:detector_];

    [detector_ startDownloadingSettingTxt];

    return YES;
}

- (BOOL)askDownloadAndDetectNowForBoard:(NSString *)boardName allowToInputManually:(BOOL)manualFlag
{
    NSInteger ret;

    NSAlert *alert_ = [[NSAlert alloc] init];
    [alert_ setAlertStyle:NSInformationalAlertStyle];
// #warning 64BIT: Check formatting arguments
// 2011-04-03 tsawada2 確認済
    [alert_ setMessageText:[NSString stringWithFormat:(manualFlag ? NSLocalizedString(@"DetectorTitle", nil) : NSLocalizedString(@"DetectorTitle2", nil)), boardName]];
    [alert_ setInformativeText:(manualFlag ? NSLocalizedString(@"DetectorMessage", nil) : NSLocalizedString(@"DetectorMessage2", nil))];
    [alert_ addButtonWithTitle:NSLocalizedString(@"DetectOK", nil)];
    [alert_ addButtonWithTitle:NSLocalizedString(@"DetectCancel", nil)];
    if (manualFlag) {
        [alert_ addButtonWithTitle:NSLocalizedString(@"DetectManually", nil)];
    }
    [alert_ setHelpAnchor:NSLocalizedString(@"DetectNoNameHelpAnchor", nil)];
    [alert_ setDelegate:[NSApp delegate]];
    [alert_ setShowsHelp:YES];

    ret = [alert_ runModal];
    [alert_ release];

    if (ret == NSAlertFirstButtonReturn) {
        return [self doDownloadSettingTxtForBoard:boardName];
    } else if (ret == NSAlertSecondButtonReturn) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)startDownloadSettingTxtForBoard:(NSString *)boardName askIfOffline:(BOOL)flag allowToInputManually:(BOOL)manualFlag
{
    const char *hs;
    NSURL *boardURL = [self URLForBoardName:boardName];
    
    hs = [[boardURL host] UTF8String];
    
    if (NULL == hs) return NO;
    if (!is_2channel(hs)) return NO;    

    if (![CMRPref isOnlineMode] && flag) {
        return [self askDownloadAndDetectNowForBoard:boardName allowToInputManually:manualFlag];
    }
    return [self doDownloadSettingTxtForBoard:boardName];
}

#pragma mark BSSettingTxtDetector Notifications
- (void)detectorDidFail:(NSNotification *)aNotification
{
    id detector_ = [aNotification object];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BSSettingTxtDetectorDidFailNotification
                                                  object:detector_];

    [detector_ release];
    UTILNotifyName(BoardManagerDidFinishDetectingSettingTxtNotification);
}

- (void)detectorDidFinish:(NSNotification *)aNotification
{
    NSDictionary *infoDict_ = [aNotification userInfo];
    id detector_ = [aNotification object];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:BSSettingTxtDetectorDidFinishNotification
                                                  object:detector_];

    NSString *board = [infoDict_ objectForKey:kBSSTDBoardNameKey];

    [self addNoName: [infoDict_ objectForKey:kBSSTDNoNameValueKey] forBoard:board];
    [self setTypeOfBeLoginPolicy:[infoDict_ unsignedIntegerForKey:kBSSTDBeLoginPolicyTypeValueKey] forBoard:board];
    [self setAllowsNanashi:[infoDict_ boolForKey:kBSSTDAllowsNanashiBoolValueKey] atBoard:board];
    [self setAllowsCharRef:[infoDict_ boolForKey:kBSSTDAllowsCharRefBoolValueKey] atBoard:board];
    [self setRegistrantShouldConsiderName:![infoDict_ boolForKey:kBSSTDShowsPrefectureBoolValueKey] atBoard:board];
    [self setLastDetectedDate:[infoDict_ objectForKey:kBSSTDDetectedDateKey] forBoard:board];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
        NSLog(@"** USER DEBUG ** BoardManager has successfully set properties for %@ detected by BSSettingTextDetector.", board);
    }
    [detector_ release];
    UTILNotifyName(BoardManagerDidFinishDetectingSettingTxtNotification);
}
@end


@implementation BoardManager(UserListEditorCore)
- (NSInteger)showSameNameExistsAlert:(NSString *)messageString
{
    NSInteger returnValue;
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setInformativeText:messageString];
    [alert setMessageText:NSLocalizedStringFromTable(@"Same Name Exists", @"BoardListEditor", @"Same Name Exists")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];

    NSBeep();
    returnValue = [alert runModal];
    [alert release];

    return returnValue;
}

- (BOOL)addCategoryOfName:(NSString *)name
{
    BoardListItem *newItem_;

    if (!name) {
        NSBeep();
        return NO;
    }

    if ([[self userList] containsItemWithName:name ofType:(BoardListFavoritesItem|BoardListCategoryItem)]) {
        [self showSameNameExistsAlert:NSLocalizedStringFromTable(@"So cannot add category.", @"BoardListEditor", @"So cannot add category.")];
        return NO;
    }

    newItem_ = [BoardListItem boardListItemWithFolderName:name];

    [[self userList] addItem:newItem_ afterObject:nil];
    return YES;
}

- (BOOL)editBoardItem:(id)item newURLString:(NSString *)newURLString
{
    if (!newURLString || !item) {
        NSBeep();
        return NO;
    }

    if ([[self invalidBoardURLsToBeRemoved] containsObject:newURLString]) {
        NSBeep();
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:NSLocalizedStringFromTable(@"Edit Board Error Msg info2chnet", @"BoardListEditor", nil)];
// #warning 64BIT: Check formatting arguments
// 2011-08-27 tsawada2 確認済
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Edit Board Error Info info2chnet", @"BoardListEditor", nil), newURLString]];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
        [alert runModal];
        return NO;
    }

    [[BSBoardInfoInspector sharedInstance] willChangeValueForKey:@"boardURLAsString"];
    [[self defaultList] setURL:newURLString toItem:item];
    [[self userList] setURL:newURLString toItem:item];
    [[BSBoardInfoInspector sharedInstance] didChangeValueForKey:@"boardURLAsString"];
    return YES;
}

- (BOOL)editCategoryItem:(id)item newName:(NSString *)newName
{
    UTILAssertNotNil(item);
    UTILAssertNotNil(newName);

    UTILAssertKindOfClass(item, BoardListItem);

    if ([[item representName] isEqualToString:newName]) {
        // Nothing to do.
        return YES;
    }

    if ([[self userList] containsItemWithName:newName ofType:(BoardListFavoritesItem | BoardListCategoryItem)]) {
        [self showSameNameExistsAlert:NSLocalizedStringFromTable(@"So cannot change name.", @"BoardListEditor", @"So cannot change name.")];
        return NO;
    }

    [[self userList] item:item setName:newName setURL:nil];
    return YES;
}

- (BOOL)removeBoardItems:(NSArray *)boardItemsForRemoval
{       
    if (!boardItemsForRemoval || [boardItemsForRemoval count] == 0) {
        return NO;
    }

    NSEnumerator *iter_ = [boardItemsForRemoval objectEnumerator];
    id eachItem;

    while (eachItem = [iter_ nextObject]) {
        if (![BoardListItem isFavoriteItem:eachItem]) {
            [[self userList] removeItem:eachItem];
        }
    }

    return YES;
}
@end


@implementation BoardManager(LocalRules)
- (NSMutableArray *)localRulesPanelControllers
{
    if (!m_localRulesPanelControllers) {
        CFArrayCallBacks arrayCallBacks = kCFTypeArrayCallBacks;
        arrayCallBacks.retain = NULL;
        arrayCallBacks.release = NULL;
        m_localRulesPanelControllers = (NSMutableArray *)CFArrayCreateMutable(NULL, 0, &arrayCallBacks);
    }
    return m_localRulesPanelControllers;
}

- (BSLocalRulesPanelController *)makeLocalRulesPanelControllerForBoardName:(NSString *)boardName
{
    BSLocalRulesPanelController *controller;
    controller = [[BSLocalRulesPanelController alloc] init]; // Do not release!

    if (controller) {
        BSLocalRulesCollector *collector;

        [[controller window] setDelegate:self];

        collector = [[BSLocalRulesCollector alloc] initWithBoardName:boardName];
        [controller setObjectControllerContent:collector bindToTextView:YES];
        [collector release];

        [[self localRulesPanelControllers] addObject:controller];
    }

    return controller;
}

- (BSLocalRulesPanelController *)localRulesPanelControllerForBoardName:(NSString *)boardName
{
    NSEnumerator *iter;
    BSLocalRulesPanelController *controller;

    iter = [[self localRulesPanelControllers] objectEnumerator];
    while (controller = [iter nextObject]) {
        id collector = [[controller objectController] content];
        if ([[collector boardName] isEqualToString:boardName]) {
            return controller;
        }
    }

    return [self makeLocalRulesPanelControllerForBoardName:boardName];
}

- (BOOL)isKeyWindowForBoardName:(NSString *)boardName
{
    NSEnumerator *iter;
    BSLocalRulesPanelController *controller;

    iter = [[self localRulesPanelControllers] objectEnumerator];
    while (controller = [iter nextObject]) {
        id collector = [[controller objectController] content];
        if ([[collector boardName] isEqualToString:boardName]) {
            return [[controller window] isKeyWindow];
        }
    }
    return NO;
}
@end
