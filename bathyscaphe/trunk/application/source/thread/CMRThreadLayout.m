//
//  CMRThreadLayout.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/08.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadLayout_p.h"
#import "CMRMessageAttributesStyling.h"
#import "CMRMessageAttributesTemplate_p.h"
#import "CMRAttributedMessageComposer.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"



@implementation CMRThreadLayout
- (id)initWithTextView:(NSTextView *)aTextView
{
	UTILAssertKindOfClass(aTextView, CMRThreadView);
	if (self = [self init]) {
		[self setTextView:(CMRThreadView *)aTextView];
	}
	return self;
}

- (id)init
{
	if (self = [super init]) {
//		_worker = [[CMXWorkerContext alloc] initWithUsingDrawingThread:NO];
		_messagesLock = [[NSLock alloc] init];

		// initialize local buffers
		_messageRanges = [[SGBaseRangeArray alloc] init];
		_messageBuffer = [[CMRThreadMessageBuffer alloc] init];

		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(threadMessageDidChangeAttribute:)
                                                     name:CMRThreadMessageDidChangeAttributeNotification
                                                   object:nil];
        m_operationQueue = [[NSOperationQueue alloc] init];
        m_countedSet = [[NSCountedSet alloc] init];
        m_reverseReferencesCountedSet = [[NSCountedSet alloc] init];
	}
	return self;
}

- (void)dealloc
{
    [m_operationQueue cancelAllOperations];
    [m_operationQueue release];
	UTIL_DEBUG_METHOD;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	// ワーカースレッドの終了
//	[_worker shutdown:self];
//	[_worker autorelease];
    
    [m_countedSet release];
    [m_reverseReferencesCountedSet release];

	[_textView release];
	[_messagesLock release];
	[_messageRanges release];
	[_messageBuffer release];

	[super dealloc];
}

- (BOOL)isMessagesEdited
{
    return _isMessagesEdited;
}

- (void)setMessagesEdited:(BOOL)flag
{
    _isMessagesEdited = flag;
}

- (void)run
{
    // ToBeRemoved_CMXWorkerContext
    NSLog(@"DEPRECATED...");
//	[_worker run];
}

- (void)doDeleteAllMessages
{
	NSTextStorage *contents_;
	NSUInteger length_;

	contents_ = [self textStorage];

	// --------- Delete All Contents ---------
	length_ = [contents_ length];
	if (length_ > 0) {
		NSRange			contentRng_;
        contentRng_ = NSMakeRange(0, length_);
		[contents_ beginEditing];
		[contents_ deleteCharactersInRange:contentRng_];
		[contents_ endEditing];
	}

	// --------- Delete Message Ranges ---------
	[_messagesLock lock];
	[[self messageRanges] removeAll];
	[[self messageBuffer] removeAll];
	[_messagesLock unlock];
    
    //
    [[self countedSet] removeAllObjects];
    [[self reverseReferencesCountedSet] removeAllObjects];

	[self setMessagesEdited:NO];
}

- (BOOL)isInProgress
{
    return [m_operationQueue operationCount] > 0;
//	return  [_worker isInProgress];
}

- (void)clear
{
    // ToBeRemoved_CMXWorkerContext
//	[_worker removeAll:self];
    [self doDeleteAllMessages];
}

- (void)clear:(id)object
{
    [self doDeleteAllMessages];
    [object performSelector:@selector(threadClearTaskDidFinish:) withObject:nil];
}

- (void)disposeLayoutContext
{
	UTIL_DEBUG_METHOD;

//	[self clear];
//    [m_operationQueue cancelAllOperations];
//	[_worker shutdown:self];

/*
	in the case of ThreadViewer: this method will be invoked when window closing,
	document removing, threadViewer closing. but that time, TextView may be
	activate, so we remove it's layout manager from contents.
*/	
	[[[self layoutManager] retain] autorelease];
	[[self textStorage] removeLayoutManager:[self layoutManager]];

	[self doDeleteAllMessages];
}

- (void)push:(id<CMRThreadLayoutTask>)aTask
{
/*	UTILAssertNotNilArgument(aTask, @"task");
	[(id)aTask setLayout:self];
	[_worker push:aTask];*/
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:aTask selector:@selector(executeWithLayout:) object:self];
    [m_operationQueue addOperation:op];
    [op release];
}
@end


@implementation CMRThreadLayout(Accessor)
- (CMRThreadView *)textView
{
	return _textView;
}

- (void)setTextView:(CMRThreadView *)aTextView
{
    [aTextView retain];
    [_textView release];
    _textView = aTextView;
}

- (NSLayoutManager *)layoutManager
{
	return [[self textView] layoutManager];
}

- (NSTextContainer *)textContainer
{
	return [[self textView] textContainer];
}

- (NSTextStorage *)textStorage
{
	return [[self textView] textStorage];
}

- (NSScrollView *)scrollView
{
	return [[self textView] enclosingScrollView];
}

- (CMRThreadMessage *)messageAtIndex:(NSUInteger)anIndex
{
	return [[self messageBuffer] messageAtIndex:anIndex];
}

- (NSArray *)messagesAtIndexes:(NSIndexSet *)indexes
{
    return [[self messageBuffer] messagesAtIndexes:indexes];
}

- (BOOL)onlySingleMessageInRange:(NSRange)range
{
	NSUInteger index1, index2;

	index1 = [self messageIndexForRange:range];
	index2 = [self lastMessageIndexForRange:range];
	return (index1 == index2);
}

- (void)threadMessageDidChangeAttribute:(NSNotification *)theNotification
{
	CMRThreadMessage	*message;
	NSUInteger			mIndex;
	
	UTILAssertNotificationName(
		theNotification,
		CMRThreadMessageDidChangeAttributeNotification);
	
	message = [theNotification object];
	if ((mIndex = [[self messageBuffer] indexOfMessage:message]) != NSNotFound) {
		[self updateMessageAtIndex:mIndex];
	}
}

- (void)updateMessageAtIndex:(NSUInteger)anIndex
{
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	CMRThreadMessage				*m;
	NSRange							mesRange_;
	NSInteger						changeInLength_ = 0;
	
	if (NSNotFound == anIndex || [self firstUnlaidMessageIndex] <= anIndex) {
		return;
    }

	[_messagesLock lock];

	do {
		m = [[self messageBuffer] messageAtIndex:anIndex];
		mesRange_ = [[self messageRanges] rangeAtIndex:anIndex];
		// 非表示のレスは生成しない
		if (![m isVisible]) {
			if (mesRange_.length != 0) {
				changeInLength_ = -(mesRange_.length);
				[[self textStorage] deleteCharactersInRange:mesRange_];
			}
			break;
		}

		composer_ = [[CMRAttributedMessageComposer alloc] init];
		textBuffer_ = [[NSMutableAttributedString alloc] init];
		
		[composer_ setComposingMask:CMRInvisibleMask compose:NO];
		[composer_ setContentsStorage:textBuffer_];

		[composer_ composeThreadMessage:m];
		changeInLength_ = [textBuffer_ length] - mesRange_.length;

		[[self textStorage] replaceCharactersInRange:mesRange_ withAttributedString:textBuffer_];
		
		[textBuffer_ release];
		[composer_ release];
		textBuffer_ = nil;
		composer_ = nil;
	} while (0);
	[_messagesLock unlock];

	if (changeInLength_ != 0) {
		mesRange_.length += changeInLength_;
		[self slideMessageRanges:changeInLength_ fromLocation:mesRange_.location +1];
		[[self messageRanges] setRange:mesRange_ atIndex:anIndex];
	}

    [[self layoutManager] invalidateDisplayForCharacterRange:mesRange_];
    [[self layoutManager] ensureLayoutForCharacterRange:mesRange_];
	[self setMessagesEdited:YES];
}

- (void)changeAllMessageAttributes:(BOOL)onOffFlag flags:(UInt32)mask
{
	[[self messageBuffer] changeAllMessageAttributes:onOffFlag flags:mask];
}

- (NSUInteger)numberOfMessageAttributes:(UInt32)mask
{
	NSEnumerator		*iter_;
	CMRThreadMessage	*m;
	NSUInteger			count_ = 0;

	iter_ = [self messageEnumerator];
	while (m = [iter_ nextObject]) {
		if (mask & [m flags]) {
			count_++;
        }
	}
	return count_;
}

- (SGBaseRangeArray *)messageRanges
{
	return _messageRanges;
}

- (void)addMessageRange:(NSRange)range
{
	[_messagesLock lock];
	[[self messageRanges] append:range];
	[_messagesLock unlock];
}

- (void)slideMessageRanges:(NSInteger)changeInLength fromLocation:(NSUInteger)fromLocation
{
    SGBaseRangeArray *ranges = [self messageRanges];
    NSUInteger count = [ranges count];
    NSUInteger i;
    NSRange range;
    for (i = 0; i < count; i++) {
        range = [ranges rangeAtIndex:i];
        if (range.location >= fromLocation) {
            range.location += changeInLength;
            [ranges setRange:range atIndex:i];
        }
    }
}

- (void)extendMessageRange:(NSInteger)extensionLength forMessageIndex:(NSUInteger)baseIndex
{
    SGBaseRangeArray *ranges = [self messageRanges];
    SGBaseRangeArray *newRanges = [SGBaseRangeArray array];
    [ranges enumerateRangesWithOptions:0 usingBlock:^(NSValue *rangeObj, NSUInteger idx, BOOL *stop) {
        NSRange range = [rangeObj rangeValue];
        if (idx == baseIndex) {
            range.length += extensionLength;
            [newRanges append:range];
        } else if (idx > baseIndex) {
            range.location += extensionLength;
            [newRanges append:range];
        } else {
            [newRanges append:range];
        }
    }];
    
    [newRanges retain];
    [_messageRanges release];
    _messageRanges = newRanges;
}

- (CMRThreadMessageBuffer *)messageBuffer
{
	return _messageBuffer;
}

- (NSEnumerator *)messageEnumerator
{
	return [[[self messageBuffer] messages] objectEnumerator];
}

- (NSArray *)allMessages
{
    return [[self messageBuffer] messages];
}

- (void)addMessagesFromBuffer:(CMRThreadMessageBuffer *)otherBuffer
{
	NSEnumerator		*iter_;
	CMRThreadMessage	*m;
	
	if (!otherBuffer) {
		return;
	}
	[_messagesLock lock];
	[[self messageBuffer] addMessagesFromBuffer:otherBuffer];

	iter_ = [[otherBuffer messages] objectEnumerator];
	while (m = [iter_ nextObject]) {
		[m setPostsAttributeChangedNotifications:YES];
	}

	[_messagesLock unlock];
}

- (NSCountedSet *)countedSet
{
    return m_countedSet;
}

- (NSCountedSet *)reverseReferencesCountedSet
{
    return m_reverseReferencesCountedSet;
}
@end


@implementation CMRThreadLayout(DocuemntVisibleRect)
- (NSUInteger)firstMessageIndexForDocumentVisibleRect
{
	NSRange visibleRange_;
	
	visibleRange_ = [[self textView] characterRangeForDocumentVisibleRect];
	
	// 各レスの最後には空行が含まれるため、表示されている範囲を
	// そのまま渡すと見た目との齟齬が気になる。
	// よって、位置を改行ひとつ分ずらす。
	if (visibleRange_.length > 1) {
	  visibleRange_.location += 1;
	  visibleRange_.length -= 1;	//範囲チェックを省く簡便のため
	}

	return [self messageIndexForRange:visibleRange_];
}

- (NSUInteger)lastMessageIndexForDocumentVisibleRect
{
	NSRange visibleRange_;
	
	visibleRange_ = [[self textView] characterRangeForDocumentVisibleRect];
	
	if (visibleRange_.length > 1) {
	  visibleRange_.location += 1;
	  visibleRange_.length -= 1;
	}

    // とりあえずの修正、1.6.2 以降でもっときちんと
	return [self lastMessageIndexForRangeSilverGull:visibleRange_];
}

- (void)scrollMessageWithRange:(NSRange)aRange
{
	CMRThreadView	*textView = [self textView];
    BOOL needsAdjust = ![CMRPref oldMessageScrollingBehavior];

    if (needsAdjust) {
        // 2010-08-15 tsawada2
        // non-contiguous layout でこのおまじないが効く
        [textView scrollRangeToVisible:aRange];
    }
	NSRect			characterBoundingRect;
	NSRect			newVisibleRect;
    NSRect          currentVisibleRect;
	NSPoint			newOrigin;
	NSClipView		*clipView;
	
	if (NSNotFound == aRange.location || 0 == aRange.length) {
		NSBeep();
		return;
	}
	
	characterBoundingRect = [textView boundingRectForCharacterInRange:aRange];
	if (NSEqualRects(NSZeroRect, characterBoundingRect)) {
        return;
	}

	clipView = [[self scrollView] contentView];
	currentVisibleRect = [clipView documentVisibleRect];

	newOrigin = [textView bounds].origin;
	newOrigin.y = characterBoundingRect.origin.y;	

    newVisibleRect = currentVisibleRect;
	newVisibleRect.origin = newOrigin;

	if (!NSEqualRects(newVisibleRect, currentVisibleRect)) {
		// 表示予定領域(newVisibleRect)のGlyphがレイアウトされていることを保証する
        [[self layoutManager] ensureLayoutForBoundingRect:newVisibleRect inTextContainer:[self textContainer]];
		// ----------------------------------------
		// Simulate user scroll
		// ----------------------------------------
        if (needsAdjust) {
            newVisibleRect.origin = [clipView constrainScrollPoint:newOrigin];
        }
		newVisibleRect = [[clipView documentView] adjustScroll:newVisibleRect];
		[clipView scrollToPoint:newVisibleRect.origin];
		[[self scrollView] reflectScrolledClipView:clipView];
	}
}

- (IBAction)scrollToLastUpdatedIndex:(id)sender
{
	[self scrollMessageWithRange:[self firstLastUpdatedHeaderAttachmentRange]];
}

- (void)scrollMessageAtIndex:(NSUInteger)anIndex
{
	if (NSNotFound == anIndex || [self firstUnlaidMessageIndex] <= anIndex) {
		return;
    }

	[self scrollMessageWithRange:[self rangeAtMessageIndex:anIndex]];
}
@end


@implementation CMRThreadLayout(Attachment)
- (NSDate *)lastUpdatedDateFromHeaderAttachment
{
	return [self lastUpdatedDateFromFirstHeaderAttachmentEffectiveRange:NULL];
}

- (NSRange)firstLastUpdatedHeaderAttachmentRange
{
	NSRange effectiveRange_;

	[self lastUpdatedDateFromFirstHeaderAttachmentEffectiveRange:&effectiveRange_];
	return effectiveRange_;
}

- (NSDate *)lastUpdatedDateFromFirstHeaderAttachmentEffectiveRange:(NSRangePointer)effectiveRange
{
	NSTextStorage	*content_ = [self textStorage];
	NSUInteger		charIndex_;
	NSUInteger		toIndex_;
	NSRange			charRng_;
	NSRange			range_;
	id				value_ = nil;

	charRng_ = NSMakeRange(0, [content_ length]);
	charIndex_ = charRng_.location;
	toIndex_   = NSMaxRange(charRng_);

	while (charIndex_ < toIndex_) {
		value_ = [content_ attribute:CMRMessageLastUpdatedHeaderAttributeName
							 atIndex:charIndex_
			   longestEffectiveRange:&range_
							 inRange:charRng_];
		if (value_) {
			if (effectiveRange != NULL) {
                *effectiveRange = range_;
			}
			if (![value_ isKindOfClass:[NSDate class]]) {
                return nil;
            }
			return (NSDate *)value_;
		}
		charIndex_ = NSMaxRange(range_);
	}
	if (effectiveRange != NULL) {
        *effectiveRange = NSMakeRange(NSNotFound, 0);
    }
	return nil;
}

- (void)appendLastUpdatedHeader:(BOOL)flag
{
	NSAttributedString	*header_;
	NSRange				range_;
	id					templateMgr = [CMRMessageAttributesTemplate sharedTemplate];
	NSTextStorage		*tS_ = [self textStorage];

	header_ = [templateMgr lastUpdatedHeaderAttachment];
	if (!header_) { 
		return;
    }

    if (flag) {
        [tS_ beginEditing];
    }

	range_.location = [tS_ length];
	[tS_ appendAttributedString:header_];
	range_.length = [tS_ length] - range_.location;
	// 現在の日付を属性として追加
	[tS_ addAttribute:CMRMessageLastUpdatedHeaderAttributeName value:[NSDate date] range:range_];

    if (flag) {
        [tS_ endEditing];
    }
}

- (void)appendLastUpdatedHeader
{
    [self appendLastUpdatedHeader:YES];
}

- (void)clearLastUpdatedHeader:(BOOL)flag
{
	NSRange headerRange_;
	NSTextStorage *tS_ = [self textStorage];

	headerRange_ = [self firstLastUpdatedHeaderAttachmentRange];
	if (NSNotFound == headerRange_.location) {
        return;
    }
	[self slideMessageRanges:-(headerRange_.length) fromLocation:NSMaxRange(headerRange_)];

	if (flag) [tS_ beginEditing];
	[tS_ deleteCharactersInRange:headerRange_];
	if (flag) [tS_ endEditing];
}

- (void)clearLastUpdatedHeader
{
    [self clearLastUpdatedHeader:YES];
}

- (void)insertLastUpdatedHeader
{
    [[self textStorage] beginEditing];
    [self clearLastUpdatedHeader:NO];
    [self appendLastUpdatedHeader:NO];
    [[self textStorage] endEditing];
}

- (void)clearReferencedCountStrings:(NSMutableAttributedString *)attrs
{
    NSRange allRange = NSMakeRange(0, [attrs length]);
    
    [attrs enumerateAttribute:BSMessageReferencedCountAttributeName inRange:allRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [attrs deleteCharactersInRange:range];
            [self extendMessageRange:-(range.length) forMessageIndex:[(NSNumber *)value unsignedIntegerValue]];
        }
    }];
}

- (void)insertReferencedCountStrings:(NSMutableAttributedString *)attrs
{
    NSRange allRange = NSMakeRange(0, [attrs length]);
    NSUInteger charIndex_ = 0;
    id indexNumber;
    NSRange insertionRange;
    
    while (1) {
        if (charIndex_ >= NSMaxRange(allRange)) {
            break;
        }
        
        NSUInteger adjustLength = 0;
        indexNumber = [attrs attribute:CMRMessageIndexAttributeName atIndex:charIndex_ longestEffectiveRange:&insertionRange inRange:allRange];
        
        if (indexNumber) {
            NSUInteger referencedCount = [[self reverseReferencesCountedSet] countForObject:indexNumber];
            if (referencedCount > 0) {
                NSAttributedString *markerString = [[CMRMessageAttributesTemplate sharedTemplate] referencedMarkerStringForMessageIndex:indexNumber referencedCount:referencedCount];
                adjustLength = [markerString length];
                [attrs insertAttributedString:markerString atIndex:NSMaxRange(insertionRange)+1];
                [self extendMessageRange:adjustLength forMessageIndex:[indexNumber unsignedIntegerValue]];
            }
        }
        charIndex_ = NSMaxRange(insertionRange) + adjustLength;
        allRange.length += adjustLength;
    }
}

- (void)updateReferencedCountMarkers
{
    [[self textStorage] beginEditing];
    [self clearReferencedCountStrings:[self textStorage]];
    [self insertReferencedCountStrings:[self textStorage]];
    [[self textStorage] endEditing];
}
@end
