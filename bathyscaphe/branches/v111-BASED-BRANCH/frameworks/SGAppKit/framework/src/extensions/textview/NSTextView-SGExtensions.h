//: NSTextView-SGExtensions.h
/**
  * $Id: NSTextView-SGExtensions.h,v 1.1.1.1.4.2 2006-01-29 12:58:10 masakih Exp $
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.
  * See the file LICENSE for copying permission.
  */

#import <Cocoa/Cocoa.h>


@interface NSTextView(SGExtensions)
- (id) attribute : (NSString	 *) aName
		 atPoint : (NSPoint		  ) aPoint 
  effectiveRange : (NSRangePointer) aRangePtr;
  
// Available in BathyScaphe 1.1.3 and later.
- (id)			attribute : (NSString	 *) aName
				  atPoint : (NSPoint		  ) aPoint 
	longestEffectiveRange : (NSRangePointer) aRangePtr
				  inRange : (NSRange) rangeLimit;

// Merge from NSTextView+CMXAdditions.m
- (NSRect) boundingRectForCharacterInRange : (NSRange) aRange;
- (NSRange) characterRangeForDocumentVisibleRect;
@end
