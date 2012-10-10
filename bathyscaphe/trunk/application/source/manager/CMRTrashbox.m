//
//  CMRTrashbox.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/21.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRTrashbox.h"
#import "CocoMonar_Prefix.h"
#import <SGAppKit/SGAppKit.h>
#import "DatabaseManager.h"

NSString *const CMRTrashboxDidPerformNotification	= @"CMRTrashboxDidPerformNotification";

NSString *const kAppTrashUserInfoFilesKey		= @"Files";
NSString *const kAppTrashUserInfoStatusKey		= @"Status";

@interface NSObject(BSFileManagerHelperStub)
+ (BOOL)moveFilesToTrashSync:(NSArray *)files;
@end

@implementation CMRTrashbox
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(trash);

- (BOOL)performWithFiles:(NSArray *)filenames
{
	BOOL				isSucceeded;
	NSMutableDictionary	*info;
	OSErr				err;
	
	if (!filenames || [filenames count] == 0) return NO;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"BSMoveToTrashWithFinder"]) {
        isSucceeded = [[NSWorkspace sharedWorkspace] moveFilesToTrashSync:filenames];
    } else {
        isSucceeded = [[NSWorkspace sharedWorkspace] moveFilesToTrash:filenames];
    }

	err = isSucceeded ? noErr : -1;

	info = [NSDictionary dictionaryWithObjectsAndKeys:filenames, kAppTrashUserInfoFilesKey,
		[NSNumber numberWithInt:err], kAppTrashUserInfoStatusKey, NULL];

	if (isSucceeded) {
        [[DatabaseManager defaultManager] cleanUpItemsWhichHasBeenRemoved:filenames];
    }

	UTILNotifyInfo(
		CMRTrashboxDidPerformNotification,
		info);
	
	return isSucceeded;
}
@end
