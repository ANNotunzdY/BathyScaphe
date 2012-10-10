//
//  NSDictionary-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class NSFont, NSColor;


@interface NSDictionary(SGExtensions)
+ (id)empty;
/*
- (id)deepMutableCopy;
- (id)deepMutableCopyWithZone:(NSZone *)zone;
*/
- (NSString *)stringForKey:(id)key;
- (NSNumber *)numberForKey:(id)key;
- (NSDictionary *)dictionaryForKey:(id)key;
- (NSArray *)arrayForKey:(id)key;

- (float)floatForKey:(id)key defaultValue:(CGFloat)defaultValue;
- (float)floatForKey:(id)key;
- (double)doubleForKey:(id)key defaultValue:(double)defaultValue;
- (double)doubleForKey:(id)key;
- (BOOL)boolForKey:(id)key defaultValue:(BOOL)defaultValue;
- (BOOL)boolForKey:(id)key;
- (NSInteger)integerForKey:(id)key defaultValue:(NSInteger)defaultValue;
- (NSInteger)integerForKey:(id)key;
- (NSUInteger)unsignedIntegerForKey:(id)key defaultValue:(NSUInteger)defaultValue;
- (NSUInteger)unsignedIntegerForKey:(id)key;
- (id)objectForKey:(id)key defaultObject:(id)defaultObject;

- (NSPoint)pointForKey:(id)key;
- (NSRect)rectForKey:(id)key;
- (NSSize)sizeForKey:(id)key;
@end


@interface NSUserDefaults(SGExtensions030717)
- (NSInteger)integerForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (float)floatForKey:(NSString *)key defaultValue:(CGFloat)defaultValue;
- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
@end
