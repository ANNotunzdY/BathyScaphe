//
//  NSEvent-SGExtensions.m
//  SGAppKit
//
//  Created by Tsutomu Sawada on 07/01/21.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSEvent-SGExtensions.h"
#import <SGFoundation/SGTemplatesManager.h>

@implementation NSEvent(BSAdditions)
+ (NSTimeInterval)bs_doubleClickInterval
{
    static double cachedKVT = -2.0;
    if (cachedKVT == -2.0) {
        id obj2 = SGTemplateResource(kDoubleClickThresholdKey);
        if (obj2) {
            cachedKVT = [obj2 doubleValue];
        }
    }

    if (cachedKVT == -1.0) { // Use System Value
        return [self doubleClickInterval];
    } else if (cachedKVT >= 0) { // Use KeyValueTemplates.plist's value.
        return cachedKVT;
    }

    return 1.0;
}
@end
