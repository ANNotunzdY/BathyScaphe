//
//  CMRThreadVisibleRange.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/09/23.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/SGFoundation.h>
#import <CocoMonar/CocoMonar.h>

/*!
 * @class       CMRThreadVisibleRange
 * @abstract    表示レス数
 * @discussion  表示レス数を指定するオブジェクト
 */
@interface CMRThreadVisibleRange : NSObject<NSCopying, CMRPropertyListCoding> {
	NSUInteger		_firstVisibleLength;
	NSUInteger		_lastVisibleLength;
}

+ (id)visibleRangeWithFirstVisibleLength:(NSUInteger)aFirstVisibleLength
					   lastVisibleLength:(NSUInteger)aLastVisibleLength;
- (id)initWithFirstVisibleLength:(NSUInteger)aFirstVisibleLength
			   lastVisibleLength:(NSUInteger)aLastVisibleLength;

- (NSDictionary *)dictionaryRepresentation;
- (BOOL)initializeFromDictionaryRepresentation:(NSDictionary *)rep;

- (BOOL)isShownAll;
- (BOOL)isEmpty;

- (NSUInteger)firstVisibleLength;
- (void)setFirstVisibleLength:(NSUInteger)aFirstVisibleLength;
- (NSUInteger)lastVisibleLength;
- (void)setLastVisibleLength:(NSUInteger)aLastVisibleLength;
- (NSUInteger)visibleLength;
@end


/*!
 * @enum       表示レス数
 * @discussion 表示レス数のうち、何らかのフラグ
 * @constant   CMRThreadShowAll, すべてを表示
 */
enum {
	CMRThreadShowAll = NSNotFound,
};
