//
//  SGFunctor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/16.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGFunctor.h"

@implementation SGFunctor
+ (id)functorWithObject:(id)obj
{
    return [[[self alloc] initWithObject:obj] autorelease];
}

- (id)initWithObject:(id)obj
{
    if (self = [self init]) {
        [self setObjectValue:obj];
    }
    return self;
}

- (void)dealloc
{
    [m_objectValue release];
    [super dealloc];
}

- (void)execute:(id)sender
{
    // Subclass should override this method
}

- (id)objectValue
{
    return m_objectValue;
}

- (void)setObjectValue:(id)anObjectValue
{
    id tmp;

    tmp = m_objectValue;
    m_objectValue = [anObjectValue copy];
    [tmp release];
}
@end
