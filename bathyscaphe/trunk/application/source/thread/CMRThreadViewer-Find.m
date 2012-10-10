//
//  CMRThreadViewer-Find.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/02/16.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"

#import "BSSearchOptions.h"
#import "TextFinder.h"
#import "CMRThreadLayout.h"
#import "CMRThreadView.h"
#import "CMXPopUpWindowManager.h"
#import "CMRAttributedMessageComposer.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "CMRMessageAttributesStyling.h"
// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"

#pragma mark -

@interface NSString(BSOgreAddition)
- (NSRange) rangeOfString: (NSString*) expressionString 
			   searchMask: (CMRSearchMask) options
					range: (NSRange) searchRange;
@end

@implementation NSString(BSOgreAddition)
- (NSRange)rangeOfString:(NSString*)expressionString searchMask:(CMRSearchMask)options range:(NSRange)searchRange
{
    if (options & CMRSearchOptionUseRegularExpression) {
        OnigRegexp *regex;

        if (options & CMRSearchOptionCaseInsensitive) {
            regex = [OnigRegexp compileIgnorecase:expressionString];
        } else {
            regex = [OnigRegexp compile:expressionString];
        }

        OnigResult *match;
        NSRange foundRange = NSMakeRange(NSNotFound, 0);
        if (options & CMRSearchOptionBackwards) {
            match = [regex search:self start:NSMaxRange(searchRange) end:searchRange.location];
        } else {
            match = [regex search:self start:searchRange.location end:NSMaxRange(searchRange)];
        }
        if (match) {
            foundRange = [match bodyRange];
        }
        return foundRange;
    } else {
        NSUInteger mask = NSLiteralSearch;
        if (options & CMRSearchOptionCaseInsensitive) {
            mask |= NSCaseInsensitiveSearch;
        }
        if (options & CMRSearchOptionBackwards) {
            mask |= NSBackwardsSearch;
        }
        return [self rangeOfString:expressionString options:mask range:searchRange];
    }
    return kNFRange;
}
@end

@interface NSLayoutManager(CMRThreadExtensions)
- (BOOL) setTemporaryAttributes : (NSDictionary *) attrs
					  forString : (NSString     *) aString
					  keysArray : (NSArray *) keysArray
					 searchMask : (CMRSearchMask ) searchOption;
@end

@implementation NSLayoutManager(CMRThreadExtensions)
- (BOOL) setTemporaryAttributes : (NSDictionary *) attrs
					  forString : (NSString     *) aString
					  keysArray : (NSArray *) keysArray
					 searchMask : (CMRSearchMask ) searchOption
{
	NSTextStorage	*textStorage_;
	NSRange			searchRange_;
	NSRange			found;
	id				attributesAtPoint;
	NSString		*source_;
	NSUInteger		targetLength;
	BOOL			ret = NO;

	textStorage_ = [self textStorage];
	searchRange_ = [textStorage_ range];
	targetLength = [textStorage_ length];
	source_ = [textStorage_ string];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while(1) {		
		found = [source_ rangeOfString: aString searchMask: searchOption range: searchRange_];

		if (0 == found.length) break;

		attributesAtPoint = [textStorage_ attribute: BSMessageKeyAttributeName atIndex: found.location effectiveRange: NULL];
		if (attributesAtPoint && [keysArray containsObject: attributesAtPoint]) {
//			NSLog(@"Range %@ is OK. Hiliting...", NSStringFromRange(found));
			[self setTemporaryAttributes : attrs forCharacterRange : found];
			ret = YES;
		}
//		NSLog(@"Range %@ is Damepo. Continue.", NSStringFromRange(found));

		searchRange_.location = NSMaxRange(found);
		searchRange_.length = targetLength - searchRange_.location;
		if (0 == searchRange_.length) break;
	}
	[pool release];
	return ret;
}
@end

#pragma mark -

@implementation CMRThreadViewer(TextViewSupport)
- (BOOL)validateAsRegularExpression:(NSString *)aString
{
//    BOOL isValid = [OGRegularExpression isValidExpressionString: aString];
    if (!aString) {
        return NO;
    }
    BOOL isValid = ([OnigRegexp compile:aString] != nil);
    if (isValid) {
        return YES;
    }
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 検証済
	[alert setMessageText:[NSString stringWithFormat:[self localizedString:@"InvalidRegularExpressionMsg"], aString]];
	[alert setInformativeText:[self localizedString:@"InvalidRegularExpressionInfo"]];
	[alert addButtonWithTitle:[self localizedString:@"InvalidRegularExpressionOK"]];

	NSBeep();
	[alert runModal];
	return NO;
}

#pragma mark Find Prev, Next, AtFirst
- (NSRange) rangeOfStorageLinkOnly: (NSString *) subString 
						searchMask: (CMRSearchMask) mask
							 range: (NSRange) aRange
{
	NSAttributedString	*attrs_;
	NSRange				linkRange_;
	id					link_;
	NSUInteger			charIndex_;
	NSUInteger			toIndex_;
	NSArray				*filter_;
	BOOL				backwards_;
	
	attrs_ = [[self textView] textStorage];
	UTILAssertRespondsTo(self, @selector(HTMLViewFilteringLinkSchemes:));
	filter_ = [self HTMLViewFilteringLinkSchemes : (CMRThreadView *)[self textView]];
	backwards_ = (mask & CMRSearchOptionBackwards);
	
	if (backwards_) {
		charIndex_ = NSMaxRange(aRange);
		if (charIndex_ == 0) return kNFRange;
		charIndex_--;
		toIndex_ = 0;
	} else {
		charIndex_ = aRange.location;
		toIndex_ = NSMaxRange(aRange);
	}
	while (1) {
		if (backwards_) {
			if (charIndex_ < toIndex_) break;
		} else {
			if (charIndex_ >= toIndex_) break;
		}
		
		link_ = [attrs_ attribute : NSLinkAttributeName
						  atIndex : charIndex_
			longestEffectiveRange : &linkRange_
						  inRange : aRange];
		
		if (link_ != nil) {
			NSString		*linkstr_;
			NSRange			found_;
			NSURL			*url_;
			
			
			url_ = [NSURL URLWithLink : link_];
			if ([url_ scheme] != nil && NO == [filter_ containsObject : [url_ scheme]]) {
				// メール欄は[url_ scheme]がnil
				linkstr_ = [url_ absoluteString]; 
				
				if (0 == [subString length]) return linkRange_;
				
				found_ = [linkstr_ rangeOfString : subString 
									  searchMask : mask
										   range : NSMakeRange(0, [linkstr_ length])];

				if (found_.location != NSNotFound && found_.length != 0) {
					return linkRange_;
				}
			}
		}
		if (backwards_) {
			if (0 == linkRange_.location) return kNFRange;
			charIndex_ = linkRange_.location -1;
		} else {
			charIndex_ = NSMaxRange(linkRange_);
		}
	}

	return kNFRange;
}

- (void)findText:(NSString *)aString keysArray:(NSArray *)keysArray searchMask:(CMRSearchMask)searchOption range:(NSRange)aRange
{
	NSTextView	*textView_ = [self textView];
	NSString	*text_ = [textView_ string];
	NSRange		result_;

	UTILNotifyName(BSThreadViewerWillStartFindingNotification);

	UTILRequireCondition((text_ && [text_ length]), ErrNotFound);
	UTILRequireCondition((aString && [aString length]), ErrNotFound);
	
	if (CMRSearchOptionLinkOnly & searchOption) {
		result_ = [self rangeOfStorageLinkOnly:aString searchMask:searchOption range:aRange];
	} else {
//		unsigned int strLength = [aString length];
        while (1) {
			NSAttributedString *attrText_ = [textView_ textStorage];
			id check;

			result_ = [text_ rangeOfString:aString searchMask:searchOption range:aRange];

			if (result_.location == NSNotFound) {
				break;
			}

			check = [attrText_ attribute:BSMessageKeyAttributeName atIndex:result_.location effectiveRange:NULL];
			if (check && [keysArray containsObject:check]) {
				break;
			}
			if (searchOption & CMRSearchOptionBackwards) {
				aRange.length = result_.location;
                aRange.location = 0;
			} else {
				aRange.length = [text_ length] - NSMaxRange(result_);
				aRange.location = NSMaxRange(result_);
			}
            if (aRange.length < 1) {
                break;
            }
		}
	}

	UTILRequireCondition(
		result_.location != NSNotFound && result_.length != 0,
		ErrNotFound);

	[textView_ setSelectedRange:result_];
	[textView_ scrollRangeToVisible:result_];

	// Leopard
//	if ([textView_ respondsToSelector:@selector(showFindIndicatorForRange:)]) {
		[textView_ showFindIndicatorForRange:result_];
//	}

	UTILNotifyInfo3(
		BSThreadViewerDidEndFindingNotification,
		[NSNumber numberWithUnsignedInteger:1],
		kAppThreadViewerFindInfoKey);

	return;

ErrNotFound:
	NSBeep();
	UTILNotifyInfo3(
		BSThreadViewerDidEndFindingNotification,
		[NSNumber numberWithUnsignedInteger:0],
		kAppThreadViewerFindInfoKey);
	return;
}

- (void) findWithOperation: (BSSearchOptions *) searchOptions
					 range: (NSRange) aRange
{
	UTILRequireCondition(searchOptions, ErrNotFound);

	BOOL useRegExp = (CMRSearchOptionUseRegularExpression & [searchOptions optionMasks]);
	if (useRegExp && NO == [self validateAsRegularExpression: [searchOptions findObject]]) goto ErrNotFound;

	[self findText: [searchOptions findObject]
		 keysArray: [searchOptions targetKeysArray]
		searchMask: [searchOptions optionMasks]
			 range: aRange];

ErrNotFound:
	return;
}

- (IBAction) findNextText : (id) sender
{
	BSSearchOptions	*findOperation_;
	NSTextView		*textView_ = [self textView];
	NSRange			searchRange_;

	findOperation_ = [[TextFinder standardTextFinder] currentOperation];
	UTILRequireCondition(findOperation_, ErrNotFound);

	searchRange_ = [textView_ selectedRange];

	if (searchRange_.length == 0) {
		// テキストが選択されていない場合は、ウインドウで「見えている」テキストの先頭から検索を開始する。
		searchRange_ = [textView_ characterRangeForDocumentVisibleRect];
		searchRange_.length = [[textView_ string] length] - searchRange_.location;
	} else {
		searchRange_.location = NSMaxRange(searchRange_);
		searchRange_.length = [[textView_ string] length] - searchRange_.location;
	}
	[self findWithOperation : findOperation_ range : searchRange_];
	
ErrNotFound:
	return;
}

- (IBAction) findPreviousText : (id) sender
{
	BSSearchOptions	*findOperation_;
	NSTextView		*textView_ = [self textView];
	NSRange			searchRange_;
	
	findOperation_ = [[TextFinder standardTextFinder] currentOperation];
	UTILRequireCondition(findOperation_, ErrNotFound);
	
	[findOperation_ setOptionState: YES forOption: CMRSearchOptionBackwards];
	
	searchRange_ = [textView_ selectedRange];
	if (searchRange_.length == 0) {
		searchRange_ = [textView_ characterRangeForDocumentVisibleRect];
		searchRange_.length = NSMaxRange(searchRange_);
		searchRange_.location = 0;
	} else {
		searchRange_.length = searchRange_.location;
		searchRange_.location = 0;
	}
	[self findWithOperation : findOperation_ range : searchRange_];
	
ErrNotFound:
	return;
}

- (IBAction) findFirstText : (id) sender
{
	BSSearchOptions	*findOperation_;
	NSRange			searchRange_;
	
	findOperation_ = [[TextFinder standardTextFinder] currentOperation];
	UTILRequireCondition(findOperation_, ErrNotFound);
	searchRange_ = NSMakeRange(0, [[[self textView] string] length]);
	
	[self findWithOperation : findOperation_ range : searchRange_];

ErrNotFound:
	return;
}

- (IBAction) showStandardFindPanel:(id)sender
{
    [[TextFinder standardTextFinder] showWindow:sender];
}

#pragma mark Extract, Hilite
- (BOOL) hiliteForMatchingString: (NSString *) aString
					   keysArray: (NSArray *) keysArray
					searchOption: (CMRSearchMask) searchOption
inLayoutManager: (NSLayoutManager *) layoutManager onPopup:(BOOL)popupWindowFlag
{
	NSDictionary		*dict;
	
#if UTIL_DEBUGGING
	UTILDescBoolean(searchOption & CMRSearchOptionCaseInsensitive);
	UTILDescBoolean(searchOption & CMRSearchOptionUseRegularExpression);
	UTILDescBoolean(searchOption & CMRSearchOptionLinkOnly);
#endif
    
    BSThreadViewTheme *theme = [CMRPref threadViewTheme];
    NSColor *hiliteColor;
    if (popupWindowFlag && [theme popupUsesAlternateHiliteColor]) {
        hiliteColor = [theme popupAlternateHiliteColor];
    } else {
        hiliteColor = [theme hiliteColor];
    }
	
	dict = [NSDictionary dictionaryWithObject:hiliteColor forKey:NSBackgroundColorAttributeName];
	return [layoutManager setTemporaryAttributes: dict
									   forString: aString
									   keysArray: keysArray
									  searchMask: searchOption];
}

- (NSRange) threadMessage: (CMRThreadMessage *) aMessage
					 keys: (NSArray *) keysArray
			rangeOfString: (NSString *) aString
			   searchMask: (CMRSearchMask) options
{
	NSRange		found;
	NSString	*target;
	NSEnumerator *iter_ = [keysArray objectEnumerator];
	NSString *eachKey;

	if (nil == aMessage || 0 == [aString length])
		return kNFRange;

	while (eachKey = [iter_ nextObject]) {
		target = [aMessage valueForKey : eachKey];
		if (nil == target || 0 == [target length])
			continue;

		found = [target rangeOfString: aString
						   searchMask: options
								range: [target range]];

		if (found.length != 0) 
			return found;
	}
	
	return kNFRange;
}

- (void)findTextByFilter:(NSString *)aString searchMask:(CMRSearchMask)searchOption targetKeys:(NSArray *)keysArray locationHint:(NSPoint)location
{
	CMRThreadLayout	*layout = [self threadLayout];
	CMXPopUpWindowController *popUp_;
    NSUInteger nCount;

	if ([aString length] == 0) {
        return;
    }

	BOOL useRegExp = (searchOption & CMRSearchOptionUseRegularExpression);
	if (useRegExp && ![self validateAsRegularExpression: aString]) {
        return;
    }

	UTILNotifyName(BSThreadViewerWillStartFindingNotification);

    NSArray *allMessages = [layout allMessages];
    NSIndexSet *indexes = [allMessages indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        NSRange found = [self threadMessage:obj keys:keysArray rangeOfString:aString searchMask:searchOption];
        if (found.length > 0) {
            return YES;
        }
        return NO;
    }];

    nCount = [indexes count];
    if (nCount == 0) {
        // 見つからなかった
        NSBeep();
        goto CleanUp;
    }
    
    NSAttributedString *textBuffer_ = [layout contentsForIndexes:indexes composingMask:(CMRLocalAbonedMask|CMRInvisibleAbonedMask) compose:NO attributesMask:0];

	popUp_ = [CMRPopUpMgr showPopUpWindowWithContext:textBuffer_
										   forObject:[self threadIdentifier]
											   owner:self
										locationHint:location];

	[self hiliteForMatchingString:aString keysArray:keysArray searchOption:searchOption inLayoutManager:[[popUp_ textView] layoutManager] onPopup:YES];

CleanUp:
	UTILNotifyInfo3(BSThreadViewerDidEndFindingNotification, [NSNumber numberWithUnsignedInteger:nCount], kAppThreadViewerFindInfoKey);
}

- (IBAction) findAllByFilter : (id) sender
{
	BSSearchOptions		*findOperation_;
	
	findOperation_ = [[TextFinder standardTextFinder] currentOperation];
	if (nil == findOperation_)
		return;
	
	[self findTextByFilter: [findOperation_ findObject]
				searchMask: [findOperation_ optionMasks]
				targetKeys: [findOperation_ targetKeysArray]
			  locationHint: [self locationForInformationPopUp]];
}

- (IBAction) findAll : (id) sender
{
	BSSearchOptions	*findOperation_;
	NSLayoutManager	*lM_ = [[self textView] layoutManager];
	BOOL			found;
	TextFinder		*finder_ = [TextFinder standardTextFinder];
	NSUInteger		k = 1;
	
	findOperation_ = [finder_ currentOperation];
	if (nil == findOperation_)
		return;

	BOOL useRegExp = (CMRSearchOptionUseRegularExpression & [findOperation_ optionMasks]);
	if (useRegExp && NO == [self validateAsRegularExpression: [findOperation_ findObject]]) return;

	UTILNotifyName(BSThreadViewerWillStartFindingNotification);

	[lM_ removeTemporaryAttribute : NSBackgroundColorAttributeName
				forCharacterRange : [[[self textView] textStorage] range]];
	
	found = [self hiliteForMatchingString: [findOperation_ findObject]
								keysArray: [findOperation_ targetKeysArray]
							 searchOption: [findOperation_ optionMasks]
						  inLayoutManager: lM_ onPopup:NO];

	if (NO == found) {
		NSBeep();
		k = 0;
	}

	UTILNotifyInfo3(
		BSThreadViewerDidEndFindingNotification,
		[NSNumber numberWithUnsignedInteger:k],
		kAppThreadViewerFindInfoKey);
}

#pragma mark ID Popup Support
- (void)extractMessagesWithIDString:(NSString *)IDString popUpLocation:(NSPoint)location
{
	CMRThreadLayout *layout = [self threadLayout];
	CMRThreadMessage *message;
	NSEnumerator *iter;
	
	NSMutableAttributedString *textBuffer_;
	CMRAttributedMessageComposer *composer_;
	NSUInteger nFound = 0;

	if (!IDString || [IDString length] == 0) {
        return;
    }
	composer_ = [[CMRAttributedMessageComposer alloc] init];
	textBuffer_ = [[NSMutableAttributedString alloc] init];

	// 「迷惑レス」で「表示しない」の場合は CMRAttributedMessageComposer 側が判断して生成しないのでこれで良い
	[composer_ setComposingMask:(CMRLocalAbonedMask|CMRInvisibleAbonedMask) compose:NO];	
	[composer_ setContentsStorage:textBuffer_];

	iter = [layout messageEnumerator];
	while (message = [iter nextObject]) {
		NSString *IDValue = [message valueForKey:@"IDString"];
		if (!IDValue || [IDValue length] == 0) {
            continue;
        }
		if ([IDValue isEqualToString:IDString]) {
			nFound++;
			[composer_ composeThreadMessage:message];
		}
	}

	if (0 == nFound) {
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 検証済
		NSString *notFoundString = [NSString stringWithFormat:[self localizedString:@"Such ID Not Found"], IDString];
		NSAttributedString *notFoundAttrStr = [[NSAttributedString alloc] initWithString:notFoundString];
		[textBuffer_ appendAttributedString:notFoundAttrStr];
		[notFoundAttrStr release];
	}

	[CMRPopUpMgr showPopUpWindowWithContext:textBuffer_
                                  forObject:[self threadIdentifier]
                                      owner:self
                               locationHint:location];
	[composer_ release];
	[textBuffer_ release];
}

// 2009-04-20 CMRThreadView に実装を移動
/*#pragma mark Use Selection to Find
- (IBAction)findTextInSelection:(id)sender
{
	NSRange		selectedTextRange;
	NSString	*selection;
	TextFinder	*finder_ = [TextFinder standardTextFinder];
	
	selectedTextRange = [[self textView] selectedRange];
	UTILRequireCondition(selectedTextRange.length != 0, ErrNoSelection);

	selection = [[[self textView] string] substringWithRange:selectedTextRange];

	[finder_ showWindow:sender];
	[finder_ setFindString:selection];

ErrNoSelection:
	return;
}*/
@end
