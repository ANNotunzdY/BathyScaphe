//
//  NSToolbar-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSToolbar-SGExtensions.h"

@implementation NSToolbarItem(SGExtensions)
- (NSString *)title
{
	return [self label];
}
- (void)setTitle:(NSString *)aTitle
{
	[self setLabel:aTitle];
}
@end
