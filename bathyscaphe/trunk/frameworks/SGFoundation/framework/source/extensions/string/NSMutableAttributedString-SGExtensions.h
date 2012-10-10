//
//  NSMutableAttributedString-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/NSObject.h>
#import <Foundation/NSAttributedString.h>

@class NSString, NSDictionary;

@interface NSMutableAttributedString(SGExtentions)
- (void)addAttribute:(NSString *)name value:(id)value;

- (void)deleteAll;

- (void)appendString:(NSString *)str withAttributes:(NSDictionary *)dict;
- (void)appendString:(NSString *)str withAttribute:(NSString *)attrsName value:(id)value;
@end
