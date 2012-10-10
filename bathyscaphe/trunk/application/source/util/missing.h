//
//  missing.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/06/04.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
@class NSMenu;

@interface NSObject(NotificationExtensions)
- (void)registerToNotificationCenter;
- (void)removeFromNotificationCenter;
- (void)exchangeNotificationObserver:(NSString *)notificationName
                            selector:(SEL)notifiedSelector
                         oldDelegate:(id)oldDelegate
                         newDelegate:(id)newDelegate;
@end


@interface NSObject(CMRAppDelegate)
- (void)showThreadsListForBoard:(NSString *)boardName selectThread:(NSString *)path addToListIfNeeded:(BOOL)addToList;
- (NSMenu *)browserListColumnsMenuTemplate;
@end


extern void setUserInterfaceItemTitle(id item, NSString *title);
extern void setUserInterfaceItemState(id item, BOOL condition);
extern void setUserInterfaceItemStateDirectly(id item, NSCellStateValue state);

/*
 NSError has a new method and key to enable displaying a help button to accompany the error when it's displayed to the user:
 NSString *const NSHelpAnchorErrorKey;
 - (NSString *)helpAnchor;
 （中略）
 Although this functionality is publicized in 10.6, it is available back to 10.4.
*/
//extern NSString *const NSHelpAnchorErrorKey; // Mac OS X 10.6 SDK では NSError.h に定義済み