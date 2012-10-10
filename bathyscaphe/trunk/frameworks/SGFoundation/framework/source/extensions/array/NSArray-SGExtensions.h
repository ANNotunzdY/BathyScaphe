//
//  NSArray-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface NSArray(SGExtensions)
+ (id)empty;
- (BOOL)isEmpty;
// firstObject used by HTMLView
- (id)head;
@end
