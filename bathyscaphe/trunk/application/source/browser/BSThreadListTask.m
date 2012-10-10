//
//  BSThreadListTask.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 12/04/29.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadListTask.h"

#import "CMRTaskManager.h"

@interface BSThreadListTask()
@property (readwrite, copy) NSString *message;
@end


@implementation BSThreadListTask
@synthesize isInProgress = _isInProgress;
@synthesize isInterrupted = _isInterrupted;
@synthesize message = _message;
@synthesize amount = _amount;

@dynamic identifier, title;


#pragma mark Localized Strings
+ (NSString *)localizableStringsTableName
{
    return @"CMRTaskDescription";
}

- (id)init
{
	self = [super init];
	if(self) {
		self.amount = -1;
	}
	return self;
}
- (void)dealloc
{
	[_message release];
	
	[super dealloc];
}

- (id)identifier
{
	return [NSString stringWithFormat:@"%@-%p", self, self];
}

- (void)run
{
    [[CMRTaskManager defaultManager] performSelectorOnMainThread:@selector(addTask:) withObject:self waitUntilDone:YES];
    [[CMRTaskManager defaultManager] performSelectorOnMainThread:@selector(taskWillStart:) withObject:self waitUntilDone:YES];
    self.isInProgress = YES;
    @try {
        [self excute];
    }
    @catch(NSException *localException) {
        NSString        *name_ = [localException name];
        // ToBeRemoved_CMXWorkerContext
        if ([CMRThreadTaskInterruptedException isEqualToString:name_]) {
            [self finalizeWhenInterrupted];
            [self postInterruptedNotification];
			return;
        } else {
            NSLog(@"%@ - %@", name_, localException);
        }
        // 例外が発生した場合はもう一度投げる。
        @throw;
    }
	@finally {
        self.isInProgress = NO;
        self.message = [self localizedString:@"Did Finish"];
		self.amount = -1;
        [[CMRTaskManager defaultManager] performSelectorOnMainThread:@selector(taskDidFinish:) withObject:self waitUntilDone:YES];
    }
}

- (void)excute {}
- (void)cancel:(id)sender
{
	self.isInterrupted = YES;
}

- (void)finalizeWhenInterrupted
{
    // subclass should call super
    self.message = NSLocalizedString(@"Cancel", @"Cancel");
}
- (void)postInterruptedNotification
{
    // ToBeRemoved_CMXWorkerContext
    [[NSNotificationCenter defaultCenter] postNotificationName:CMRThreadTaskInterruptedNotification object:self];
}

@end

@implementation BSThreadListTask(CMRThreadLayoutTaskDummy)

- (void)executeWithLayout:(id)layout
{
	[self run];
}

@end

