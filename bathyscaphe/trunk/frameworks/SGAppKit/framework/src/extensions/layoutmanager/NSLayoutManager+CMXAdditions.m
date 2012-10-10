//
//  NSLayoutManager+CMXAdditions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSLayoutManager+CMXAdditions.h"
#import <AppKit/AppKit.h>
#import <SGFoundation/String+Utils.h>

@implementation NSLayoutManager(CMXAdditions)
- (NSUInteger) performsGlyphGenerationIfNeeded
{
	NSUInteger		numberOfGlyphs_;
	
	numberOfGlyphs_ = [self numberOfGlyphs];
	if(0 == numberOfGlyphs_)
		return numberOfGlyphs_;
	
// #warning 64BIT: Check formatting arguments
// 2010-03-07 tsawada2 修正済
	NSAssert2(
		[self isValidGlyphIndex : (numberOfGlyphs_ -1)],
		@"***ERROR*** numberOfGlyphs(%lu), but index(%lu) was invalid index!?",
		numberOfGlyphs_,
		(numberOfGlyphs_ -1));
	
	return numberOfGlyphs_;
}
- (NSRect) boundingRectForTextContainer : (NSTextContainer *) aContainer
{
	return [self boundingRectForGlyphRange:[self glyphRangeForTextContainer:aContainer] inTextContainer:aContainer];
}

- (BOOL) isValidGlyphRange : (NSRange) glyphRange
{
	if(NO == [self isValidGlyphIndex : glyphRange.location])
		return NO;
	
	if(NO == [self isValidGlyphIndex : NSMaxRange(glyphRange) -1])
		return NO;
	
	return YES;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
- (NSUInteger) glyphIndexForCharacterAtIndex : (NSUInteger) anIndex
{
	NSRange			glyphRange_;
	
	glyphRange_ = [self glyphRangeForCharacterRange:NSMakeRange(anIndex, 1) actualCharacterRange:NULL];
	return glyphRange_.location;
}
#endif
@end



@implementation NSLayoutManager(ChangingTextStorage)
- (void) changeTextStorage : (NSTextStorage *) newTextStorage
{
	NSTextStorage		*textStorage_;
	
	textStorage_ = [self textStorage];
	
	[self retain];
	[textStorage_ removeLayoutManager : self];
	[newTextStorage addLayoutManager : self];
	[self autorelease];
	
	if(nil == textStorage_ || nil == newTextStorage)
		return;
	
	if(LAYOUTMANAGER_SHOULD_FIX_BAD_BEHAVIOR){
		NSUInteger	mask_;
		NSRange		invalidatedRange_;
		
		mask_ = (NSTextStorageEditedCharacters | NSTextStorageEditedAttributes);
		invalidatedRange_ = [newTextStorage range];
		[self textStorage : newTextStorage
				   edited : mask_
					range : invalidatedRange_
		   changeInLength : ([textStorage_ length] * -1)
		 invalidatedRange : invalidatedRange_];
	}
}
@end
