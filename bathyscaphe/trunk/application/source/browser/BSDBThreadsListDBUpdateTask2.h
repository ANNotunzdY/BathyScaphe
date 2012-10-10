//
//  BSDBThreadsListDBUpdateTask2.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/06.
//  Copyright 2006-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSDBThreadsListDBUpdateTask2 : NSObject
{
	NSString *bbsName;
	NSData *subjectData;
	NSNumber *boardID;

	BOOL isInterrupted;
	BOOL isRebuilding;
    BOOL isLivedoor;

    NSError *lastError;
}

+ (id)taskWithBBSName:(NSString *)name data:(NSData *)data livedoor:(BOOL)isLivedoorFlag rebuilding:(BOOL)isRebuildingFlag;
- (id)initWithBBSName:(NSString *)name data:(NSData *)data livedoor:(BOOL)isLivedoorFlag rebuilding:(BOOL)isRebuildingFlag;

- (void)run;

- (void)setBBSName:(NSString *)name;

- (BOOL)isRebuilding;
- (BOOL)isLivedoor;

- (NSError *)lastErrorWhileRebuilding;
@end

/*
@interface BSDBThreadsListDBUpdateTask2(TaskNotification)
- (void)postNotificationWithName:(NSString *)name;
@end

extern NSString *const BSDBThreadsListDBUpdateTask2DidFinishNotification;
*/
