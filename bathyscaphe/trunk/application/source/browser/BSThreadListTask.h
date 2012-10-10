//
//  BSThreadListTask.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 12/04/29.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

#import "CMRTask.h"
//#import "CMXWorkerContext.h"

@interface BSThreadListTask : NSObject <CMRTask>
{
	// CMRThreadLayoutTask
	BOOL _isInProgress;
	BOOL _isInterrupted;
	NSString *_message;
	CGFloat	_amount;
}
@property (readonly) id identifier;
@property BOOL isInProgress;
@property BOOL isInterrupted;
@property (readonly) NSString *title;
@property (readonly, copy) NSString *message;
@property CGFloat amount;

- (void)excute;

// register to CMRTaskManager and excute. 
- (void)run;
@end
