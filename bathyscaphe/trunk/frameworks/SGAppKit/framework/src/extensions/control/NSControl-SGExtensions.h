//
//  NSControl-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSControl.h>



@interface NSControl(SGExtensions)
// for fix NSToolbar sizeMode
- (NSControlSize)controlSize;
- (void)setControlSize:(NSControlSize)controlSize;
@end
