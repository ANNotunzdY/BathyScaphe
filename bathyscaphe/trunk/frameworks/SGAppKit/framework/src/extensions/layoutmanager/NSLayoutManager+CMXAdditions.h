//
//  NSLayoutManager+CMXAdditions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSLayoutManager.h>

@class NSTextContainer, NSTextStorage;

#define LAYOUTMANAGER_SHOULD_FIX_BAD_BEHAVIOR		YES


@interface NSLayoutManager(CMXAdditions)
/*!
 * @method      performsGlyphGenerationIfNeeded
 * @abstract    必要な場合はGlyphを生成する
 *
 * @discussion  生成されていないGlyphがあれば生成します。
 * @result      Glyphの数
 */
- (NSUInteger) performsGlyphGenerationIfNeeded;
- (NSRect) boundingRectForTextContainer : (NSTextContainer *) aContainer;

/*!
 * @method            isValidGlyphRange:
 * @abstract          指定した範囲が正当かどうかの判定
 *
 * @discussion        指定したグリフの範囲が正当ならYESを返す
 * @param glyphRange  参照するグリフの範囲
 * @result            指定したグリフの範囲が正当ならYESを返す
 */
- (BOOL) isValidGlyphRange : (NSRange) glyphRange;

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
- (NSUInteger) glyphIndexForCharacterAtIndex : (NSUInteger) anIndex;
#endif
@end



@interface NSLayoutManager(FIX_BAD_BEHAVIOR)
- (void) changeTextStorage : (NSTextStorage *) newTextStorage;
@end
