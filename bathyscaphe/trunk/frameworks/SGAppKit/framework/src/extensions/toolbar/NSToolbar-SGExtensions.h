//
//  NSToolbar-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSToolbarItem.h>

@interface NSToolbarItem(SGExtensions)
- (NSString *)title;
- (void)setTitle:(NSString *)aTitle;
@end
