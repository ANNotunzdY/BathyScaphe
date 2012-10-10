//
//  CMRMainMenuManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/18.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRMainMenuManager.h"
#import "CocoMonar_Prefix.h"
#import "missing.h"
#import "BSLabelManager.h"
#import "BSLabelMenuItemView.h"
#import "CMXMenuHolder.h"


#define     APPLICATION_MENU_TAG    0
#define     FILE_MENU_TAG           1
#define     EDIT_MENU_TAG           2
#define     BROWSER_MENU_TAG        3
#define     BBS_MENU_TAG            4
#define     THREAD_MENU_TAG         5
#define     WINDOW_MENU_TAG         6
#define     HELP_MENU_TAG           7
#define     SCRIPTS_MENU_TAG        8
#define     HISTORY_MENU_TAG        9

#define     BROWSER_COLUMNS_TAG     2
#define     BROWSER_LAYOUT_TAG      3
#define     THREAD_MARKS_LABELS_TAG 2
#define     HISTORY_INSERT_MARKER   1001
#define     HISTORY_SUB_MARKER      1002
#define     TEMPLATES_SUB_MARKER    2001

#define     REMOVE_FROM_DB_MENUITEM_TAG 4001
#define     THREAD_CONTEXTUAL_MASK  5000

@implementation CMRMainMenuManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager)

- (id)init
{
    if (self = [super init]) {
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(setupLabelMenuItems:)
//                                                     name:BSLabelManagerDidUpdateDisplayNamesNotification
//                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#define MENU_ACCESSER(aMethodName, aTag)        \
- (NSMenuItem *)aMethodName { return (NSMenuItem*)[[NSApp mainMenu] itemWithTag:(aTag)]; }

MENU_ACCESSER(applicationMenuItem, APPLICATION_MENU_TAG)
MENU_ACCESSER(fileMenuItem, FILE_MENU_TAG)
MENU_ACCESSER(editMenuItem, EDIT_MENU_TAG)
MENU_ACCESSER(browserMenuItem, BROWSER_MENU_TAG)
MENU_ACCESSER(historyMenuItem, HISTORY_MENU_TAG)
MENU_ACCESSER(BBSMenuItem, BBS_MENU_TAG)
MENU_ACCESSER(threadMenuItem, THREAD_MENU_TAG)
MENU_ACCESSER(windowMenuItem, WINDOW_MENU_TAG)
MENU_ACCESSER(helpMenuItem, HELP_MENU_TAG)
MENU_ACCESSER(scriptsMenuItem, SCRIPTS_MENU_TAG)

#undef MENU_ACCESSER

- (NSInteger)historyItemInsertionIndex
{
    return ([[[self historyMenuItem] submenu] indexOfItemWithTag:HISTORY_INSERT_MARKER]+1);
}

- (NSMenu *)historyMenu
{
    return [[self historyMenuItem] submenu];
}

- (NSMenu *)boardHistoryMenu
{
    return [[[[self historyMenuItem] submenu] itemWithTag:HISTORY_SUB_MARKER] submenu];
}

- (NSMenu *)fileMenu
{
    return [[self fileMenuItem] submenu];
}

- (NSMenu *)templatesMenu
{
    return [[[[self editMenuItem] submenu] itemWithTag:TEMPLATES_SUB_MARKER] submenu];
}

- (NSMenu *)threadContexualMenuTemplate
{
    NSMenu *menuTemplate = [[NSMenu alloc] initWithTitle:@""];

    NSMenu *menuBase = [[self threadMenuItem] submenu];
    NSEnumerator *iter = [[menuBase itemArray] objectEnumerator];
    NSMenuItem  *eachItem;
    NSMenuItem  *addingItem;

    while (eachItem = [iter nextObject]) {
        if ([eachItem tag] > THREAD_CONTEXTUAL_MASK) {
            addingItem = [eachItem copy];
            [addingItem setKeyEquivalent:@""];
            [menuTemplate addItem:addingItem];
            [addingItem release];
        }
    }
    
    return [menuTemplate autorelease];
}
@end


@implementation CMRMainMenuManager(CMRApp)
- (NSMenuItem *)browserListColumnsMenuItem
{
    return (NSMenuItem *)[[[self browserMenuItem] submenu] itemWithTag:BROWSER_COLUMNS_TAG];
}

- (NSMenuItem *)browserLayoutMenuItem
{
    return (NSMenuItem *)[[[self browserMenuItem] submenu] itemWithTag:BROWSER_LAYOUT_TAG];
}

- (NSMenuItem *)threadLabelsMenuItem
{
    return (NSMenuItem *)[[[self threadMenuItem] submenu] itemWithTag:THREAD_MARKS_LABELS_TAG];
}

- (void)removeItemWithTag:(NSInteger)tag fromMenu:(NSMenu *)menu
{
    NSMenuItem *menuItem = [menu itemWithTag:tag];
    if (menuItem) {
        [menu removeItem:menuItem];
    }
}

- (void)removeDebugMenuItemIfNeeded
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
        NSMenu *menu = [[self threadMenuItem] submenu];
        [self removeItemWithTag:REMOVE_FROM_DB_MENUITEM_TAG fromMenu:menu];
        [self removeItemWithTag:4002 fromMenu:menu]; // TODO あとで
    }
}

- (void)removeFullScreenMenuItemIfNeeded
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
        NSMenu *menu = [[self browserMenuItem] submenu];
        [self removeItemWithTag:1070 fromMenu:menu];
        [self removeItemWithTag:1071 fromMenu:menu];
    }
}


- (void)setupLabelMenuItems:(NSNotification *)aNotification
{
    NSMenu *menu = [[self threadLabelsMenuItem] submenu];
/*    NSArray *labelNames = [[BSLabelManager defaultManager] displayNames];
    NSArray *items = [menu itemArray];
    for (NSMenuItem *item in items) {
        NSInteger tag = [item tag];
        if (tag < 1 || tag > 7) {
            continue;
        }
        [item setTitle:[labelNames objectAtIndex:(tag - 1)]];
    }*/
    NSMenuItem *tmp = [menu itemWithTag:901];
    if (!m_labelMenuItemView) {
        m_labelMenuItemView = [[BSLabelMenuItemHolder labelMenuItemView] retain];
    }
    [tmp setView:m_labelMenuItemView];
    [m_labelMenuItemView release];
}
@end
