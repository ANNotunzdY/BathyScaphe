//:BoardManager_p.h
// encoding="UTF-8"

#import "BoardManager.h"
#import "AppDefaults.h"
#import "CocoMonar_Prefix.h"
#import "SmartBoardList.h"

#import <AppKit/NSApplication.h>



@interface BoardManager(Notification)
- (void)boardListDidChange:(NSNotification *)notification;
- (BOOL)saveListsIfNeeded;
@end


@interface BoardManager(PrivateUtilities)
- (id)entryForBoardName:(NSString *)aBoardName;
- (id)valueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(id)value;
- (void)setValue:(id)value forKey:(NSString *)key atBoard:(NSString *)boardName;
- (void)removeValueForKey:(NSString *)key atBoard:(NSString *)boardName;
- (NSString *)stringValueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(NSString *)value;
- (void)setStringValue:(NSString *)value forKey:(NSString *)key atBoard:(NSString *)boardName;
- (BOOL)boolValueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(BOOL)value;
- (void)setBoolValue:(BOOL)value forKey:(NSString *)key atBoard:(NSString *)boardName;
- (NSDate *)dateValueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(NSDate *)value;
- (void)setDateValue:(NSDate *)value forKey:(NSString *)key atBoard:(NSString *)boardName;
@end


extern NSString *const NNDTenoriTigerSortDescsKey;
