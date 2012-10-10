//
//  NSDictionary-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/NSDictionary-SGExtensions.h>
#import <SGFoundation/PrivateDefines.h>




@implementation NSDictionary(SGExtensions)
+ (id)empty
{
	static id kSharedInstance;
	if (!kSharedInstance) {
		kSharedInstance = [[NSDictionary alloc] init];
	}
	return kSharedInstance;
}
/*
- (id)deepMutableCopy
{
	return [self deepMutableCopyWithZone:nil];
}

- (id)deepMutableCopyWithZone:(NSZone *)zone
{
	NSMutableDictionary *mdict_;		// 可変辞書
	NSEnumerator        *iter_;			// 順次探索
	id item_;			// 各アイテム
    id copiedItem_; // コピーされたアイテム
	id key;			// 各検索キー

	mdict_ = [self mutableCopyWithZone:zone];
	iter_ = [mdict_ keyEnumerator];
	
	while (key = [iter_ nextObject]) {
		item_ = [mdict_ objectForKey:key];
		if ([item_ respondsToSelector:@selector(deepMutableCopyWithZone:)]) {
			copiedItem_ = [item_ deepMutableCopyWithZone:zone];
		} else if ([item_ respondsToSelector:@selector(mutableCopyWithZone:)]) {
			copiedItem_ = [item_ mutableCopyWithZone:zone];
		} else {
			// 可変オブジェクトのコピーがサポートされていない場合は
			// そのまま加える。
            copiedItem_ = [item_ retain];
		}
		[mdict_ setObject:copiedItem_ forKey:key];
		[copiedItem_ release];
	}
	return mdict_;
}
*/
#define PRIV_OBJECT_CONVERTION(keyArg, classNameArg)	\
	id		object_;\
	\
	object_ = [self objectForKey:key];\
	if (!object_ || ![object_ isKindOfClass:[classNameArg class]]) {\
		return nil;\
	}\
	return object_

- (NSNumber *)numberForKey:(id)key
{
	PRIV_OBJECT_CONVERTION(key, NSNumber);
}
- (NSDictionary *)dictionaryForKey:(id)key;
{
	PRIV_OBJECT_CONVERTION(key, NSDictionary);
}
- (NSString *)stringForKey:(id)key
{
	PRIV_OBJECT_CONVERTION(key, NSString);
}
- (NSArray *)arrayForKey:(id)key
{
	PRIV_OBJECT_CONVERTION(key, NSArray);
}
#undef PRIV_OBJECT_CONVERTION

- (float)floatForKey:(id)key defaultValue:(CGFloat)defaultValue
{
	NSNumber		*num_;
	num_ = [self numberForKey:key];
	return num_ ? [num_ doubleValue] : defaultValue;
}

- (float)floatForKey:(id)key
{
	return [self floatForKey:key defaultValue:0.0f];
}

- (double)doubleForKey:(id)key defaultValue:(double)defaultValue
{
	NSNumber *num_;
	num_ = [self numberForKey:key];
	return num_ ? [num_ doubleValue] : defaultValue;
}

- (double)doubleForKey:(id)key
{
	return [self doubleForKey:key defaultValue:0.0];
}

- (BOOL)boolForKey:(id)key defaultValue:(BOOL)defaultValue
{
	id value_;

	value_ = [self objectForKey:key];
	if (value_) { 
		if ([value_ isKindOfClass:[NSString class]] || [value_ isKindOfClass:[NSNumber class]]) {
			return [value_ boolValue];
		}
	}
	return defaultValue;
}

- (BOOL)boolForKey:(id)key
{
	return [self boolForKey:key defaultValue:NO];
}

- (NSInteger)integerForKey:(id)key defaultValue:(NSInteger)defaultValue
{
	NSNumber *num_;
	num_ = [self numberForKey:key];
	return num_ ? [num_ integerValue] : defaultValue;
}

- (NSInteger)integerForKey:(id)key
{
	return [self integerForKey:key defaultValue:0];
}

- (NSUInteger)unsignedIntegerForKey:(id)key defaultValue:(NSUInteger)defaultValue
{
	NSNumber *num_;
	num_ = [self numberForKey:key];
	return num_ ? [num_ unsignedIntegerValue] : defaultValue;
}

- (NSUInteger)unsignedIntegerForKey:(id)key
{
	return [self unsignedIntegerForKey:key defaultValue:0];
}

- (id)objectForKey:(id)key defaultObject:(id)defaultObject
{
	id obj;

	obj = [self objectForKey:key];
    return obj ?: defaultObject;
}

- (NSPoint)pointForKey:(id)key
{
	id		obj;

	UTILRequireCondition(key, ErrConvert);
	obj = [self objectForKey:key];

	UTILRequireCondition(obj, ErrConvert);
	if ([obj isKindOfClass:[NSString class]]) {
		return NSPointFromString(obj);
    }
	if ([obj respondsToSelector:@selector(pointValue)]) {
		return [obj pointValue];
    }
ErrConvert:
	return NSZeroPoint;
}

- (NSRect)rectForKey:(id)key
{
	id		obj;

	UTILRequireCondition(key, ErrConvert);
	obj = [self objectForKey:key];

	UTILRequireCondition(obj, ErrConvert);
	if ([obj isKindOfClass:[NSString class]]) {
		return NSRectFromString(obj);
    }
	if ([obj respondsToSelector:@selector(rectValue)]) {
		return [obj rectValue];
    }
ErrConvert:
	return NSZeroRect;
}

- (NSSize)sizeForKey:(id)key
{
	id		obj;

	UTILRequireCondition(key, ErrConvert);
	obj = [self objectForKey:key];

	UTILRequireCondition(obj, ErrConvert);
	if ([obj isKindOfClass:[NSString class]]) {
		return NSSizeFromString(obj);
    }
	if ([obj respondsToSelector:@selector(sizeValue)]) {
		return [obj sizeValue];
    }
ErrConvert:
	return NSZeroSize;
}
@end


@implementation NSUserDefaults(SGExtensions030717)
- (NSInteger)integerForKey:(NSString *)key defaultValue:(NSInteger)defaultValue
{
	id obj;
	obj = [self objectForKey:key];
	return (!obj || ![obj respondsToSelector:@selector(integerValue)]) ? defaultValue : [obj integerValue];
}

- (float)floatForKey:(NSString *)key defaultValue:(CGFloat)defaultValue
{
	id obj;
	obj = [self objectForKey:key];
	return (!obj || ![obj respondsToSelector:@selector(doubleValue)]) ? defaultValue : [obj doubleValue];
}

- (BOOL)boolForKey:(NSString *)key defaultValue:(BOOL)defaultValue
{
	id obj;
	obj = [self objectForKey:key];
	return (!obj || ![obj respondsToSelector:@selector(boolValue)]) ? defaultValue : [obj boolValue];
}
@end
