//
//  CMRTaskManager-Management.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/18.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRTaskManager_p.h"

@implementation CMRTaskManager(TaskInProgress)
- (void)addTaskInProgress:(id<CMRTask>)aTask
{
    CMRTaskItemController       *controller_;
    
    controller_ = [self controllerForTask:aTask];
    if (!controller_) return;
    [[self tasksInProgress] addObject:aTask];   
    [self setCurrentTask:aTask];
}

- (void)removeTask:(id<CMRTask>)aTask
{
    CMRTaskItemController       *controller_;

    controller_ = [self controllerForTask:aTask];
    if (!controller_) return;

    [[self tasksInProgress] removeObject:aTask];
// Restored 2009-09-21
//    if ([[self tasksInProgress] count] > 0) {
//        [self setCurrentTask:[[self tasksInProgress] lastObject]];
//    } else {
//        [self setCurrentTask:nil];
//    }
    
    // 対応表から削除
    [[self controllerMapping] removeObjectForKey:[aTask identifier]];

    [[self taskItemControllers] removeObject:controller_];
    [[self taskContainerView] performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
}

- (BOOL)shouldRegisterTask:(id<CMRTask>)aTask
{
    return ([aTask identifier] != nil);
}
@end


@implementation CMRTaskManager(TaskItemManagement)
- (CMRTaskItemController *)controllerForTask:(id<CMRTask>)aTask
{
    if (![aTask identifier]) return nil;
    
    return [[self controllerMapping] objectForKey:[aTask identifier]];
}

- (NSMutableArray *)taskItemControllers
{
    if (!_taskItemControllers) {
        _taskItemControllers = [[NSMutableArray alloc] init];
    }
    return _taskItemControllers;
}

- (NSMutableDictionary *)controllerMapping
{
    if (!_controllerMapping) {
        _controllerMapping = [[NSMutableDictionary alloc] init];
    }
    return _controllerMapping;
}

- (NSMutableArray *)tasksInProgress
{
    if (!_tasksInProgress) {
        _tasksInProgress = [[NSMutableArray alloc] init];
    }
    return _tasksInProgress;
}

- (void)addTaskItemController:(CMRTaskItemController *)newController
{
    id<CMRTask>     task_;
    
    UTILAssertNotNilArgument(newController, @"Controller");
    
    task_ = [newController task];
    UTILAssertNotNilArgument(task_, @"Task");
    UTILAssertNotNilArgument([task_ identifier], @"identifier");
    
    [[self taskItemControllers] addObject:newController];
    // 
    // タスクとコントローラの対応をここで記録し、
    // タスクが終わり次第削除する。
    // 
    [[self controllerMapping] setObject:newController forKey:[task_ identifier]];
    [[self taskContainerView] performSelector:@selector(reloadData) withObject:nil afterDelay:0.05];
}
@end
