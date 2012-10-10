//
//  SGBaseRangeArray.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/15.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface SGBaseRangeArray : NSObject
{
    @private
    NSMutableArray *bs_imp;
}
+ (id)array;
+ (id)arrayWithRangeArray:(SGBaseRangeArray *)theArray;
- (id)initWithRangeArray:(SGBaseRangeArray *)theArray;

- (NSRange)rangeAtIndex:(NSUInteger)anIndex;

- (NSUInteger)count;
- (BOOL)isEmpty;
- (NSRange)last;
- (NSRange)head;

- (void)append:(NSRange)aRange;
- (void)setRange:(NSRange)aRange atIndex:(NSUInteger)anIndex;

- (void)removeLast;
- (void)removeAll;

- (void)enumerateRangesWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(NSValue *rangeObj, NSUInteger idx, BOOL *stop))block;
@end
