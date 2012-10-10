//
//  SGBaseRangeArray.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/15.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGBaseRangeArray.h"


@interface SGBaseRangeArray(PrivateAccessor)
- (NSMutableArray *)internalArray;
@end


@implementation SGBaseRangeArray(PrivateAccessor)
- (NSMutableArray *)internalArray
{
    return bs_imp;
}
@end


@implementation SGBaseRangeArray
+ (id)array
{
    return [[[self alloc] init] autorelease];
}

+ (id)arrayWithRangeArray:(SGBaseRangeArray *)theArray
{
    return [[[self alloc] initWithRangeArray:theArray] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        bs_imp = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithRangeArray:(SGBaseRangeArray *)theArray
{
    if (self = [super init]) {
        bs_imp = [[NSMutableArray alloc] initWithArray:[theArray internalArray]];
    }
    return self;
}

- (void)dealloc
{
    [bs_imp release];
    bs_imp = nil;
    [super dealloc];
}

// NSObject
- (NSString *)description
{
    NSMutableString *description_ = [NSMutableString string];
    NSUInteger i;
    NSUInteger count = [self count];
    NSRange range;

    [description_ appendFormat:@"<%@ %p> count=%lu\n", [self className], self, (unsigned long)count];

    for (i = 0; i < count; i++) {
        range = [self rangeAtIndex:i];
        [description_ appendFormat:@"  %lu: %@\n", (unsigned long)i, NSStringFromRange(range)];
    }
    return description_;
}

- (NSRange)rangeAtIndex:(NSUInteger)anIndex
{
    return [(NSValue *)[bs_imp objectAtIndex:anIndex] rangeValue];
}

- (BOOL)isEmpty
{
    return (0 == [self count]);
}

- (NSRange)last
{
    NSUInteger count_ = [self count];
    
    if (0 == count_) {
        return NSMakeRange(NSNotFound, 0);
    }
    return [self rangeAtIndex:(count_ - 1)];
}

- (NSRange)head
{
    return ([self isEmpty]) ? NSMakeRange(NSNotFound, 0) : [self rangeAtIndex:0];
}

- (NSUInteger)count
{
    return [bs_imp count];
}

- (void)append:(NSRange)aRange
{
    [bs_imp addObject:[NSValue valueWithRange:aRange]];
}

- (void)setRange:(NSRange)aRange atIndex:(NSUInteger)anIndex
{
    [bs_imp replaceObjectAtIndex:anIndex withObject:[NSValue valueWithRange:aRange]];
}

- (void)removeLast
{
    [bs_imp removeLastObject];
}

- (void)removeAll
{
    [bs_imp removeAllObjects];
}

- (void)enumerateRangesWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(NSValue *rangeObj, NSUInteger idx, BOOL *stop))block
{
    [bs_imp enumerateObjectsWithOptions:opts usingBlock:block];
}
@end
