//
//  NSPasteboard-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/05/31.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface NSAttributedString(CMXAdditions)
- (void)writeToPasteboard:(NSPasteboard *)pboard;
@end
