//
//  NSEvent-SGExtensions.h
//  SGAppKit
//
//  Created by Tsutomu Sawada on 07/01/21.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSEvent.h>


@interface NSEvent(BSAdditions)
+ (NSTimeInterval)bs_doubleClickInterval; // Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
@end

#define kDoubleClickThresholdKey @"System - DoubleClickThreshold" // Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
