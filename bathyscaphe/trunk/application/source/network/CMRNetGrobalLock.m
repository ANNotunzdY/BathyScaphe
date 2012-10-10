//
//  CMRNetGrobalLock.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/23.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRNetGrobalLock.h"
#import "UTILKit.h"

// for debugging only
#define UTIL_DEBUGGING    1
#import "UTILDebugging.h"

@implementation CMRNetGrobalLock
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance)

- (id)init
{
    if (self = [super init]) {
        m_lock = [[NSLock alloc] init];
        m_requests = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [m_lock release];
    [m_requests release];
    [super dealloc];
}

- (void)add:(id<NSCopying>)aRequest
{
    UTILAssertNotNil(aRequest);
//    UTILAssertConformsTo(aRequest, @protocol(NSCopying));

    UTIL_DEBUG_WRITE1(@"  Lock::add %@", aRequest);
    [m_lock lock];
    [m_requests addObject:aRequest];
    [m_lock unlock];
}

- (void)remove:(id<NSCopying>)aRequest
{
    UTIL_DEBUG_WRITE1(@"  Lock::remove %@", aRequest);
    [m_lock lock];
    [m_requests removeObject:aRequest];
    [m_lock unlock];
}

- (BOOL)has:(id<NSCopying>)aRequest
{
    BOOL ret;
    
    [m_lock lock];
    ret = ([m_requests member:aRequest] != nil);
    [m_lock unlock];

    return ret;
}
@end
