//
//  NSControl-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSControl-SGExtensions.h"


@implementation NSControl(SGExtensions)
- (NSControlSize)controlSize
{
	return [[self cell] controlSize];
}

- (void)setControlSize:(NSControlSize)controlSize
{
	[[self cell] setControlSize:controlSize];
}
@end
