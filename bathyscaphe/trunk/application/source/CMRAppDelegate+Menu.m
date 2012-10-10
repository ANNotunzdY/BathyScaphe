//
//  CMRAppDelegate+Menu.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/07/04.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAppDelegate_p.h"
#import "BSScriptsMenuManager.h"
#import "BSReplyTextTemplateManager.h"
#import "BSModalStatusWindowController.h"
#import "BoardManager.h"

// ----------------------------------------
// D e f i n e d
// ----------------------------------------
// Bookmark file
#define kURLBookmarksPlist @"URLBookmarks.plist"

#define kBrowserListColumnsPlist        @"browserListColumns.plist"

// Elements name
#define kCMRAppDelegateNameKey      @"Name"
#define kCMRAppDelegateURLKey       @"URL"
#define kCMRAppDelegateBookmarksKey @"Bookmarks"



@implementation CMRAppDelegate(MenuSetup)
+ (NSString *)pathForURLBookmarkResource
{
    NSString    *path;
    NSBundle    *bundle;
    
    bundle = [NSBundle applicationSpecificBundle];
    path = [bundle pathForResourceWithName:kURLBookmarksPlist];
    if (path) {
        return path;
    }
    bundle = [NSBundle mainBundle];
    path = [bundle pathForResourceWithName:kURLBookmarksPlist];
    
    return path;
}

+ (NSArray *)URLBookmarkArray
{
    return [NSArray arrayWithContentsOfFile:[self pathForURLBookmarkResource]];
}

+ (BOOL)isCategoryWithDictionary:(NSDictionary *)item
{
    return ([item objectForKey:kCMRAppDelegateBookmarksKey] != nil);
}

- (void)setupURLBookmarksMenuWithMenu:(NSMenu *)menu bookmarks:(NSArray *)bookmarks
{
    NSEnumerator    *iter_;
    NSDictionary    *item_;
    
    if (!menu) {
        return;
    }
    if (!bookmarks) {
        return;
    }
    iter_ = [bookmarks objectEnumerator];
    while (item_ = [iter_ nextObject]) {
        NSString        *title_;
        NSMenuItem        *menuItem_;
        
        if (![item_ isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        title_ = [item_ objectForKey:kCMRAppDelegateNameKey];
        if (!title_) {
            continue;
        }
        if (0 == [title_ length]) {
            [menu addItem:[NSMenuItem separatorItem]];
            continue;
        }

        menuItem_ = [[NSMenuItem alloc] initWithTitle:title_ action:NULL keyEquivalent:@""];
        if ([[self class] isCategoryWithDictionary:item_]) {
            NSMenu *submenu_;
            NSArray *bookmarks_;
            
            bookmarks_ = [item_ objectForKey:kCMRAppDelegateBookmarksKey];
            UTILAssertNotNil(bookmarks_);
            
            submenu_ = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:title_];
            [self setupURLBookmarksMenuWithMenu:submenu_ bookmarks:bookmarks_];
            [menuItem_ setSubmenu:submenu_];
            [submenu_ release];
        } else {
            NSString *URLString_;
            NSURL *URLToOpen_;
            
            URLString_ = [item_ objectForKey:kCMRAppDelegateURLKey];
            if (!URLString_) {
                [menuItem_ release];
                continue;
            }
            URLToOpen_ = [NSURL URLWithString:URLString_];
                            
            [menuItem_ setTarget:self];
            [menuItem_ setAction:@selector(openURL:)];
            [menuItem_ setRepresentedObject:URLToOpen_];
        }
        [menu addItem:menuItem_];
        [menuItem_ release];
    }
}

- (void)setupURLBookmarksMenuWithMenu:(NSMenu *)menu
{
    NSArray            *URLBookmarkArray_;
    
    UTILAssertNotNilArgument(menu, @"Menu");
    URLBookmarkArray_ = [[self class] URLBookmarkArray];
    if (!URLBookmarkArray_) {
        return;
    }
    [menu addItem:[NSMenuItem separatorItem]];
    [self setupURLBookmarksMenuWithMenu:menu bookmarks:URLBookmarkArray_];
}

- (void)setupBrowserListColumnsMenuWithMenu:(NSMenu *)menu
{
    NSArray         *defaultColumnsArray_;
    NSEnumerator    *iter_;
    NSDictionary    *item_;
    
    UTILAssertNotNilArgument(menu, @"Menu");
    defaultColumnsArray_ = [[self class] defaultColumnsArray];
    if (!defaultColumnsArray_) {
        return;
    }
	iter_ = [defaultColumnsArray_ objectEnumerator];
    while (item_ = [iter_ nextObject]) {
        NSString		*title_;
		NSString		*identifier_;
        NSMenuItem		*menuItem_;
        
        if (![item_ isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        title_ = [item_ objectForKey:@"Title"];
        identifier_ = [item_ objectForKey:@"Identifier"];
        
        menuItem_ = [[NSMenuItem alloc] initWithTitle:title_ action:NULL keyEquivalent:@""];

		[menuItem_ setRepresentedObject:identifier_];
        [menu addItem:menuItem_];
        [menuItem_ release];
    }
}

- (void)setupMenu
{
    NSMenuItem    *menuItem_;
	CMRMainMenuManager	*dm_ = [CMRMainMenuManager defaultManager];
	CMRHistoryManager	*hm_ = [CMRHistoryManager defaultManager];

    menuItem_ = [dm_ helpMenuItem];
    NSAssert([menuItem_ hasSubmenu], @"menuItem must have submenu");
    [self setupURLBookmarksMenuWithMenu:[menuItem_ submenu]];

    [dm_ setupLabelMenuItems:nil];

	[[dm_ browserListColumnsMenuItem] setSubmenu:[self browserListColumnsMenuTemplate]];

	[[dm_ historyMenu] setDelegate:hm_];
	[[dm_ boardHistoryMenu] setDelegate:hm_];
	[[dm_ templatesMenu] setDelegate:[BSReplyTextTemplateManager defaultManager]];
	[BSScriptsMenuManager setupScriptsMenu];
}
@end


@implementation CMRAppDelegate(Util)
+ (NSArray *)defaultColumnsArray
{
    NSBundle    *bundles[] = {
                [NSBundle applicationSpecificBundle], 
                [NSBundle mainBundle],
                nil};
    NSBundle    **p = bundles;
    NSString    *path = nil;
    
    for (; *p != nil; p++)
        if ((path = [*p pathForResourceWithName:kBrowserListColumnsPlist])) {
            break;
        }
    return (nil == path) ? nil : [NSArray arrayWithContentsOfFile:path];
}

- (NSMenu *)browserListColumnsMenuTemplate
{
    NSArray         *defaultColumnsArray_;
	NSMenu			*menu;
    NSEnumerator    *iter_;
    NSDictionary    *item_;
	Class			expectedClass = [NSDictionary class];
    
    defaultColumnsArray_ = [[self class] defaultColumnsArray];
    if (!defaultColumnsArray_) {
        return nil;
    }
	menu = [[NSMenu alloc] initWithTitle:@"Columns"];

	iter_ = [defaultColumnsArray_ objectEnumerator];
    while (item_ = [iter_ nextObject]) {
        NSString		*title_;
		NSString		*identifier_;
        NSMenuItem		*menuItem_;
        
        if (![item_ isKindOfClass:expectedClass]) {
            continue;
        }
        title_ = [item_ objectForKey:@"Long Title"];
        identifier_ = [item_ objectForKey:@"Identifier"];
        
        menuItem_ = [[NSMenuItem alloc] initWithTitle:title_ action:@selector(chooseColumn:) keyEquivalent:@""];
		[menuItem_ setRepresentedObject:identifier_];
        [menu addItem:menuItem_];
        [menuItem_ release];
	}

	return [menu autorelease];
}
@end


@implementation CMRAppDelegate(Hinagiku)
- (void)fixInvalidSortDescriptors
{
    NSArray *boardNames = [[[BoardManager defaultManager] noNameDict] allKeys];
    NSUInteger count = [boardNames count];
    if (!boardNames || count == 0) {
        return;
    }

    BSModalStatusWindowController *winController;
    winController = [[BSModalStatusWindowController alloc] init];

    [[winController progressIndicator] setIndeterminate:NO];
    [[winController progressIndicator] setMaxValue:count];
    [[winController progressIndicator] setDoubleValue:0];
    [[winController messageTextField] setStringValue:NSLocalizedString(@"Fix Invalid Sort Descs Msg", nil)];

    NSModalSession session = [NSApp beginModalSessionForWindow:[winController window]];

    NSUInteger i;
    NSString *boardName;
    for (i = 0; i < count; i++) {
        [NSApp runModalSession:session];
        boardName = [boardNames objectAtIndex:i];
        [[winController infoTextField] setStringValue:boardName];
        [[winController progressIndicator] incrementBy:i];
        [[BoardManager defaultManager] repairInvalidDescriptorForBoard:boardName];
    }

    [[BoardManager defaultManager] saveNoNameDict];
    [CMRPref setInvalidSortDescriptorFixed:YES];

	[NSApp endModalSession:session];
    [winController close];
    [winController release];
}
@end


@implementation CMRAppDelegate(Homuhomu)
- (void)removeInfoServerData
{
    if (![[BoardManager defaultManager] shouldRepairInvalidBoardData]) {
        return;
    }

    BSModalStatusWindowController *winController;
    winController = [[BSModalStatusWindowController alloc] init];
    
    [[winController progressIndicator] setIndeterminate:YES];
    [[winController messageTextField] setStringValue:NSLocalizedString(@"Remove Info Server Data Msg", nil)];
    [[winController infoTextField] setStringValue:@""];
    
    NSModalSession session = [NSApp beginModalSessionForWindow:[winController window]];
    [[winController progressIndicator] startAnimation:nil];
    
    [[BoardManager defaultManager] repairInvalidBoardData];

    [CMRPref setInvalidBoardDataRemoved:YES];
    
	[NSApp endModalSession:session];
    [[winController progressIndicator] stopAnimation:nil];
    [winController close];
    [winController release];
}
@end


@implementation CMRAppDelegate(DotInvader)
- (void)fixUnconvertedNoNameEntityReference
{
    NSArray *boardNames = [[[BoardManager defaultManager] noNameDict] allKeys];
    NSUInteger count = [boardNames count];
    if (!boardNames || count == 0) {
        return;
    }
    
    BSModalStatusWindowController *winController;
    winController = [[BSModalStatusWindowController alloc] init];
    
    [[winController progressIndicator] setIndeterminate:NO];
    [[winController progressIndicator] setMaxValue:count];
    [[winController progressIndicator] setDoubleValue:0];
    [[winController infoTextField] setStringValue:@""];
    [[winController messageTextField] setStringValue:NSLocalizedString(@"Fix Unconverted NoName EntityRef", nil)];
    
    NSModalSession session = [NSApp beginModalSessionForWindow:[winController window]];
    
    NSUInteger i;
    NSString *boardName;
    for (i = 0; i < count; i++) {
        [NSApp runModalSession:session];
        boardName = [boardNames objectAtIndex:i];
        [[winController infoTextField] setStringValue:boardName];
        [[winController progressIndicator] incrementBy:i];
        [[BoardManager defaultManager] fixUnconvertedNoNameEntityReferenceForBoard:boardName];
    }
    
    [[BoardManager defaultManager] saveNoNameDict];
    [CMRPref setNoNameEntityReferenceConverted:YES];
    
	[NSApp endModalSession:session];
    [winController close];
    [winController release];
}
@end
