//
//  CMRSingletonObject.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/22.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#define APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(methodName) \
static id st_instance = nil;\
\
+ (id)methodName\
{\
    if (st_instance == nil) {\
        st_instance = [[super allocWithZone:NULL] init];\
    }\
    return st_instance;\
}\
+ (id)allocWithZone:(NSZone *)zone\
{\
    return [[self methodName] retain];\
}\
- (id)copyWithZone:(NSZone *)zone{return self;}\
- (id)retain{return self;}\
- (NSUInteger)retainCount{return NSUIntegerMax;}\
- (oneway void)release{}\
- (id)autorelease{return self;}
