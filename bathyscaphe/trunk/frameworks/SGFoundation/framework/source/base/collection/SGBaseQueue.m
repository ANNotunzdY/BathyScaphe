//
//  SGBaseQueue.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/07.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGBaseQueue.h"


@implementation SGBaseQueue
- (id)init
{
	if (self = [super init]) {
		_mutableArray = [[NSMutableArray alloc] init];
	}

	return self;
}

+ (id)queue
{
	return [[[self alloc] init] autorelease];
}

- (void)dealloc
{
	[_mutableArray release];
	_mutableArray = nil;
	[super dealloc];
}

#pragma mark SGBaseQueue Protocol
- (void)put:(id)item
{
	if (!item) {
		[NSException raise:NSInvalidArgumentException
					format:@"*** -[%@ %@]: attempt to put nil",
							NSStringFromClass([self class]),
							NSStringFromSelector(_cmd)];
	}
	[_mutableArray addObject:item];
}

- (id)take
{
	id		item_;
	
	if ([self isEmpty]) {
		return nil;
	}
	item_ = [[_mutableArray objectAtIndex:0] retain];
	[_mutableArray removeObjectAtIndex:0];
	
	return [item_ autorelease];
}

- (BOOL)isEmpty
{
	return (0 == [_mutableArray count]);
}
@end

#pragma mark -
@implementation SGBaseThreadSafeQueue
- (id)init
{
	if (self = [super init]) {
		_lock = [[NSLock alloc] init];
	}

	return self;
}

- (void)dealloc
{
	[_lock release];
	_lock = nil;
	[super dealloc];
}

#pragma mark SGBaseQueue Protocol
- (void)put:(id)item
{
	[_lock lock];
	[super put:item];
	[_lock unlock];
}

- (id)take
{
	id		item_;
	[_lock lock];
	item_ = [super take];
	[_lock unlock];
	return item_;
}
@end
