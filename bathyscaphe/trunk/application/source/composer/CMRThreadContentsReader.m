//
//  CMRThreadContentsReader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/29. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadContentsReader.h"
#import "CocoMonar_Prefix.h"
#import "CMRMessageComposer.h"


@implementation CMRThreadContentsReader
- (id)init
{
    if (self = [super init]) {
        [self setNextMessageIndex:NSNotFound];
    }
    return self;
}

- (NSUInteger)nextMessageIndex
{
    return bs_nextMessageIndex;
}

- (void)setNextMessageIndex:(NSInteger)aNextMessageIndex
{
    bs_nextMessageIndex = aNextMessageIndex;
}

- (void)incrementNextMessageIndex
{
    ++bs_nextMessageIndex;
}

- (void)composeWithComposer:(id<CMRMessageComposer>)composer
{
    while ([self composeNextMessageWithComposer:composer]) {
        ;
    }
}

- (NSUInteger)numberOfMessages
{
    return 0;
}

- (BOOL)composeNextMessageWithComposer:(id<CMRMessageComposer>)composer
{
    UTILAbstractMethodInvoked;
    return NO;
}

- (NSDictionary *)threadAttributes
{
    return [NSDictionary empty];
}
@end
