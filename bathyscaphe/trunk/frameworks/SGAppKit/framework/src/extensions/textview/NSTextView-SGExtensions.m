//
//  NSTextView-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSTextView-SGExtensions.h"
#import <SGFoundation/SGFoundation.h>
#import <Carbon/Carbon.h>
#import "UTILKit.h"


@implementation NSTextView(TextStorageAttributes)
- (id)attribute:(NSString *)aName atPoint:(NSPoint)aPoint effectiveRange:(NSRangePointer)aRangePtr
{
    NSTextStorage   *content_ = [self textStorage];
    NSLayoutManager *lmanager_ = [self layoutManager];
    NSTextContainer *tcontainer_ = [self textContainer];
    NSUInteger      glyphIndex_;
    NSUInteger      charIndex_;

    UTILRequireCondition([self mouse:aPoint inRect:[self bounds]], no_attribute);

    glyphIndex_ = [lmanager_ glyphIndexForPoint:aPoint inTextContainer:tcontainer_ fractionOfDistanceThroughGlyph:NULL];
    UTILRequireCondition(glyphIndex_ < [lmanager_ numberOfGlyphs], no_attribute);
    
    charIndex_ = [lmanager_ characterIndexForGlyphAtIndex:glyphIndex_];
    
    return [content_ attribute:aName atIndex:charIndex_ effectiveRange:aRangePtr];
    
no_attribute:
    if (aRangePtr != NULL) {
        *aRangePtr = kNFRange;
    }
    return nil;
}

- (NSRect)boundingRectForCharacterInRange:(NSRange)aRange
{
    NSLayoutManager *lm  = [self layoutManager];
    NSTextContainer *container_ = [self textContainer];
    NSUInteger      count_;
    NSRange         glyphRange_;
    
    count_ = [[self string] length];
    if (NSNotFound == aRange.location || NSMaxRange(aRange) > count_) {
        return NSZeroRect;
    }
    glyphRange_ = [lm glyphRangeForCharacterRange:aRange actualCharacterRange:NULL];
    return [lm boundingRectForGlyphRange:glyphRange_ inTextContainer:container_];
}

- (NSRange)characterRangeForDocumentVisibleRect
{
    NSRect              visibleRect_;
    NSRange             glyphRange_;
    NSRange             charRange_;
    NSLayoutManager     *lm;
    NSTextContainer     *container_;
    
    visibleRect_ = [[self enclosingScrollView] documentVisibleRect];
    lm = [self layoutManager];
    container_ = [self textContainer];

    // Glyphを生成しないメソッド
    glyphRange_ = [lm glyphRangeForBoundingRectWithoutAdditionalLayout:visibleRect_ inTextContainer:container_];
    charRange_ = [lm characterRangeForGlyphRange:glyphRange_ actualGlyphRange:NULL];

    return charRange_;
}

#pragma mark HIDictionaryWindowShow() Wrapper
- (void)bs_lookupInDictionaryWithRange:(NSRange)selectedRange
{
    NSAttributedString *text = [[self textStorage] attributedSubstringFromRange:selectedRange];
    NSFont *attr = [text attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    CGFloat adjust = [attr ascender];
//    CFRange range = CFRangeMake(0, selectedRange.length);

    NSLayoutManager *lm = [self layoutManager];
    NSRange glyphRange;
    NSRect  rect;

    glyphRange = [lm glyphRangeForCharacterRange:selectedRange actualCharacterRange:NULL];
    rect = [lm boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
//    NSPoint windowPoint = [self convertPoint:NSMakePoint(rect.origin.x, rect.origin.y + adjust) toView:nil];
//    NSPoint screenPoint = [[self window] convertBaseToScreen:windowPoint];
//    CGPoint point = CGPointMake(screenPoint.x, NSMaxY([[[NSScreen screens] objectAtIndex:0] frame]) - screenPoint.y);

//    HIDictionaryWindowShow(NULL, (CFAttributedStringRef)text, range, NULL, point, false, NULL);
    [self showDefinitionForAttributedString:text atPoint:NSMakePoint(rect.origin.x, rect.origin.y + adjust)];
}
@end
