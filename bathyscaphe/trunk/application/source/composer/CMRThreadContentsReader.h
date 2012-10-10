//
//  CMRThreadContentsReader.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/29. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <CocoMonar/CocoMonar.h>

@protocol CMRMessageComposer;

@interface CMRThreadContentsReader : CMRResourceFileReader
{
    @private
    NSUInteger bs_nextMessageIndex;
}
/* subclass should do overriding */
- (NSUInteger)numberOfMessages;
- (BOOL)composeNextMessageWithComposer:(id<CMRMessageComposer>)composer;

- (NSDictionary *)threadAttributes;

/* index is 0-based */
- (NSUInteger)nextMessageIndex;
- (void)setNextMessageIndex:(NSInteger)aNextMessageIndex;
- (void)incrementNextMessageIndex;
- (void)composeWithComposer:(id<CMRMessageComposer>)composer;
@end
