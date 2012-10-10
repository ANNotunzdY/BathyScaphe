//
//  NSMutableDictionary-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface NSMutableDictionary(SGExtensions)
- (void)setNoneNil:(id)obj forKey:(id)key;
- (void)moveEntryWithKey:(id)key to:(id)other;
- (void)setFloat:(float)aValue forKey:(id)aKey;
- (void)setDouble:(double)aValue forKey:(id)aKey;
- (void)setInteger:(NSInteger)aValue forKey:(id)aKey;
- (void)setUnsignedInteger:(NSUInteger)aValue forKey:(id)aKey;
- (void)setBool:(BOOL)aValue forKey:(id)aKey;

- (void)setRect:(NSRect)aValue forKey:(id)aKey;
- (void)setSize:(NSSize)aValue forKey:(id)aKey;
- (void)setPoint:(NSPoint)aValue forKey:(id)aKey;
@end
