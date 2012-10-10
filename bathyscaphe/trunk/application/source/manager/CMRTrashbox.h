//
//  CMRTrashbox.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/21.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface CMRTrashbox : NSObject
+ (id)trash;

- (BOOL)performWithFiles:(NSArray *)filenames;
@end

//extern NSString *const CMRTrashboxWillPerformNotification;
extern NSString *const CMRTrashboxDidPerformNotification;

extern NSString *const kAppTrashUserInfoFilesKey;
extern NSString *const kAppTrashUserInfoStatusKey;
