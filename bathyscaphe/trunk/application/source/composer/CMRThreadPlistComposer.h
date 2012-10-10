//
//  CMRThreadPlistComposer.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/02/26.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRMessageComposer.h"


@interface CMRThreadPlistComposer : CMRMessageComposer {
    @private
    NSMutableDictionary *m_thread;
    NSMutableArray      *m_threadsArray;
}

+ (id)composerWithThreadsArray:(NSMutableArray *)threads;
- (id)initWithThreadsArray:(NSMutableArray *)threads;
@end
