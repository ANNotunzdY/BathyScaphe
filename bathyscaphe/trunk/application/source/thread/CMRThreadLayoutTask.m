//
//  CMRThreadLayoutTask.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/11.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadLayoutTask.h"
#import "CocoMonar_Prefix.h"
#import "CMRTaskManager.h"

@implementation CMRThreadLayoutConcreateTask
+ (id)task
{
    return [[[self alloc] init] autorelease];
}

+ (id)taskWithIndentifier:(id)anIdentifier
{
    id  obj;

    obj = [self task];
    [obj setIdentifier:anIdentifier];
    return obj;
}

- (id)init
{
    if (self = [super init]) {
        [self setIsInProgress:NO];
        [self setAmount:-1];
    }
    return self;
}

- (void)dealloc
{
//  NSLog(@"-dealloc Called (%@)", NSStringFromClass([self class]));
    [self setMessage:nil];
    [self setIdentifier:nil];
    [self setLayout:nil];
    [super dealloc];
}

- (CMRThreadLayout *)layout
{
    return _layout;
}

- (void)setLayout:(CMRThreadLayout *)aLayout
{
    [aLayout retain];
    [_layout release];
    _layout = aLayout;
}

- (id)identifier
{
    return _identifier;
}

- (void)setIdentifier:(id)anIdentifier
{
    [anIdentifier retain];
    [_identifier release];
    _identifier = anIdentifier; 
}

- (void)postInterruptedNotification
{
    // ToBeRemoved_CMXWorkerContext
    [[NSNotificationCenter defaultCenter] postNotificationName:CMRThreadTaskInterruptedNotification object:self];
}

- (void)executeWithLayout:(CMRThreadLayout *)layout
{
    [[CMRTaskManager defaultManager] performSelectorOnMainThread:@selector(addTask:) withObject:self waitUntilDone:YES];
    [[CMRTaskManager defaultManager] performSelectorOnMainThread:@selector(taskWillStart:) withObject:self waitUntilDone:YES];
    [self setIsInProgress:YES];

    @try{
        [self setLayout:layout];
        [self doExecuteWithLayout:layout];
    }
    @catch(NSException *localException) {
        NSString        *name_ = [localException name];
        // ToBeRemoved_CMXWorkerContext
        if ([CMRThreadTaskInterruptedException isEqualToString:name_]) {
            [self finalizeWhenInterrupted];
            [self postInterruptedNotification];
        } else {
            NSLog(@"%@ - %@", name_, localException);
        }
        // 例外が発生した場合はもう一度投げる。
        @throw;
    }
    @finally {
        [self setIsInProgress:NO];
        [self setMessage:[self localizedString:@"Did Finish"]];
        [[CMRTaskManager defaultManager] performSelectorOnMainThread:@selector(taskDidFinish:) withObject:self waitUntilDone:YES];
    }
}

- (void)doExecuteWithLayout:(CMRThreadLayout *)layout
{
    // subclass should override this method
}

- (void)finalizeWhenInterrupted
{
    // subclass should call super
    [self setMessage:NSLocalizedString(@"Cancel", @"Cancel")];
}

- (BOOL)isInterrupted
{
    return _isInterrupted;
}

- (void)setIsInterrupted:(BOOL)anIsInterrupted
{
    _isInterrupted = anIsInterrupted;
}
/**
  * @exception CMRThreadTaskInterruptedException
  *            [self isInterrupted] == YESなら例外を発生
  */
- (void)checkIsInterrupted
{
    if ([self isInterrupted]) {
        // ToBeRemoved_CMXWorkerContext
        [NSException raise:CMRThreadTaskInterruptedException format:@"Thread task %@ is interrupted...", [self identifier]];
    }
}

- (void)run
{
    [self executeWithLayout:[self layout]];
}

#pragma mark CMRTask
- (NSString *)title
{
    return @"";
}

- (NSString *)message
{
    NSString *result;
  @synchronized(self) {
    result = [[m_statusMsg retain] autorelease];
  }
    return result;
}

- (void)setMessage:(NSString *)msg
{
  @synchronized(self) {
    [msg retain];
    [m_statusMsg release];
    m_statusMsg = msg;
  }
}

- (BOOL)isInProgress
{
    return _isInProgress;
}

- (void)setIsInProgress:(BOOL)isInProgress
{
    _isInProgress = isInProgress;
}

- (double)amount
{
    return m_amount;
}

- (void)setAmount:(double)doubleValue
{
    m_amount = doubleValue;
}

- (IBAction)cancel:(id)sender
{
    [self setIsInterrupted:YES];
}

#pragma mark Localized Strings
+ (NSString *)localizableStringsTableName
{
    return @"CMRTaskDescription";
}
@end
