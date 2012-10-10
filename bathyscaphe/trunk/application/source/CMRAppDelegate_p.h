//
//  CMRAppDelegate_p.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/07/26.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAppDelegate.h"

#import "CocoMonar_Prefix.h"
#import "AppDefaults.h"
#import "CMRTaskManager.h"
#import "CMRMainMenuManager.h"
#import "CMROpenURLManager.h"
#import "CMRHistoryManager.h"

// CMRLocalizableStringsOwner
#define APP_MAINMENU_LOCALIZABLE_FILE_NAME	@"Localizable"


//:CMRAppDelegate+Menu.m
@interface CMRAppDelegate(MenuSetup)
- (void)setupMenu;
@end


@interface CMRAppDelegate(Hinagiku)
- (void)fixInvalidSortDescriptors;
@end


@interface CMRAppDelegate(Homuhomu)
- (void)removeInfoServerData;
@end


@interface CMRAppDelegate(DotInvader)
- (void)fixUnconvertedNoNameEntityReference;
@end
