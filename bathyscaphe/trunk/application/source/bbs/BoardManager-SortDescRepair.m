//
//  BoardManager-SortDescRepair.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 09/07/04.
//  Copyright 2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BoardManager_p.h"


@implementation BoardManager(SortDescriptorRepairing)
- (NSArray *)sortDescriptorsForBoard:(NSString *)boardName useDefaultDescs:(BOOL)flag
{
	NSArray *array = nil;

	id obj = [self valueForKey:NNDTenoriTigerSortDescsKey atBoard:boardName defaultValue:nil];
	if (obj && [obj isKindOfClass:[NSData class]]) {
		@try {
			array = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
		}
		@catch (NSException *e) {
			NSLog(@"Warning: -[BoardManager sortDescriptorsForBoard]: (Board:%@) The data is corrupted.", boardName);
		}
	}

	if(!array && flag) {
		return [CMRPref threadsListSortDescriptors];
	}
	
	return array;
}

// 誤った descriptor を基に正しい descriptor を生成して返す。
- (NSSortDescriptor *)repairedDescriptor:(NSSortDescriptor *)invalidDesc
{
    NSString *key = [invalidDesc key];
    BOOL asc = [invalidDesc ascending];
    return [[[NSSortDescriptor alloc] initWithKey:key ascending:asc selector:@selector(numericCompare:)] autorelease];
}

// 修正されていない descriptor があればそのインデックスを。なければ NSNotFound を返す。
- (NSUInteger)indexOfInvalidDescriptor:(NSArray *)descriptors
{
    NSUInteger index = [[descriptors valueForKey:@"key"] indexOfObject:@"threadid"];
    if (index != NSNotFound) {
        SEL selector = [(NSSortDescriptor *)[descriptors objectAtIndex:index] selector];
        if (selector == @selector(numericCompare:)) { // already fixed.
            index = NSNotFound;
        }
    }
    return index;
}

// descriptor の配列を調べ、修正すべき descriptor があれば修正したものと置き換えた新しい descriptor 配列を返す。
- (NSArray *)repairDescsArrayIfNeeded:(NSArray *)descriptors
{
    NSUInteger index = [self indexOfInvalidDescriptor:descriptors];
    if (index != NSNotFound) {
        NSSortDescriptor *invalidDesc = [descriptors objectAtIndex:index];
        NSSortDescriptor *repairedDesc = [self repairedDescriptor:invalidDesc];

        NSMutableArray *tmpArray = [descriptors mutableCopy];
        [tmpArray replaceObjectAtIndex:index withObject:repairedDesc];
        NSArray *newArray = [NSArray arrayWithArray:tmpArray];
        [tmpArray release];
        return newArray;
    }

    return descriptors;
}

- (void)repairInvalidDescriptorForBoard:(NSString *)boardName
{
    NSArray *array = [self sortDescriptorsForBoard:boardName useDefaultDescs:NO];
    if (!array) {
        return;
    }
    NSArray *newArray = [self repairDescsArrayIfNeeded:array];
    [self setSortDescriptors:newArray forBoard:boardName];
}

- (void)fixUnconvertedNoNameEntityReferenceForBoard:(NSString *)boardName
{
    NSArray *array = [self defaultNoNameArrayForBoard:boardName];
    if (!array || ([array count] == 0)) {
        return;
    }
    NSMutableArray *newTmpArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSString *noName in array) {
        NSString *newNoName = [noName stringByReplaceEntityReference];
        [newTmpArray addObject:newNoName];
    }
    NSArray *newArray = [NSArray arrayWithArray:newTmpArray];
    [self setDefaultNoNameArray:newArray forBoard:boardName];
}
@end
