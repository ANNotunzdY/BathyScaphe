//
//  BSThreadListUpdateTask.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/03/29.
//  Copyright 2006,2012 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BSThreadListTask.h"

@class BSDBThreadList;

@interface BSThreadListUpdateTask : BSThreadListTask
{
	BSDBThreadList *target;
	BOOL userCanceled;
	
	NSString *bbsName;
	
	id cursor;
}

+ (id)taskWithBSDBThreadList:(BSDBThreadList *)threadList;
- (id)initWithBSDBThreadList:(BSDBThreadList *)threadList;

- (id)cursor;

@end

@interface BSThreadListUpdateTask(Notification)
- (void) postTaskDidFinishNotification;
@end

extern NSString *BSThreadListUpdateTaskDidFinishNotification;
