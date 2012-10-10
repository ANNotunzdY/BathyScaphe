//
//  NSTextView-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface NSTextView(SGExtensions)
- (id)attribute:(NSString *)aName atPoint:(NSPoint)aPoint effectiveRange:(NSRangePointer)aRangePtr;

- (NSRect)boundingRectForCharacterInRange:(NSRange)aRange;
- (NSRange)characterRangeForDocumentVisibleRect;

// Carbon's HIDictionaryWindowShow() wrapper. Available in BathyScaphe 2.0 and later.
- (void)bs_lookupInDictionaryWithRange:(NSRange)selectedRange;
@end
