//
//  CMRThreadLayout-MessageRange.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/08.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadLayout_p.h"
#import "CMRAttributedMessageComposer.h"
#import "AppDefaults.h"


@implementation CMRThreadLayout(MessageRange)
- (NSUInteger)numberOfReadedMessages
{
	return [[self messageBuffer] count];
}

- (NSUInteger)firstUnlaidMessageIndex
{
	return [[self messageRanges] count];
}

- (BOOL)isCompleted
{
	return [self numberOfReadedMessages] == [self firstUnlaidMessageIndex];
}

- (NSRange)rangeAtMessageIndex:(NSUInteger)index
{
	return [[self messageRanges] rangeAtIndex:index];
}

- (NSUInteger)messageIndexForRange:(NSRange)aRange
{
    SGBaseRangeArray *ranges = [self messageRanges];
    NSUInteger count = [ranges count];
    NSUInteger i;
    for (i = 0; i < count; i++) {
        NSRange range = [ranges rangeAtIndex:i];
        NSRange intersection = NSIntersectionRange(range, aRange);
        if (intersection.length != 0) {
            return i;
        }
    }
	return NSNotFound;
}

- (NSUInteger)lastMessageIndexForRangeSilverGull:(NSRange)aRange
{
	NSUInteger				index_;
	
	index_ = [[self messageRanges] count] -1;

		NSRange		mesRng_;
		NSRange		intersection_;
		
		mesRng_ = [[self messageRanges] last];
		intersection_ = NSIntersectionRange(mesRng_, aRange);
		if (NSMaxRange(intersection_) == NSMaxRange(mesRng_)) {
			return index_;
		}

	return [self messageIndexForRange:aRange];
}

- (NSUInteger)lastMessageIndexForRange:(NSRange)aRange
{
    SGBaseRangeArray *ranges = [self messageRanges];
    NSInteger last = [ranges count] - 1;
    if (last < 0) {
        return NSNotFound;
    }
    NSInteger i;

    for (i = last; i >= 0; i--) {
        NSRange range = [ranges rangeAtIndex:i];
        NSRange intersection = NSIntersectionRange(range, aRange);
        if (intersection.length != 0) {
            return i;
        }
    }
	return NSNotFound;
}

- (NSAttributedString *)contentsAtIndex:(NSUInteger)index
{
	return [self contentsForIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (NSAttributedString *)contentsForIndexes:(NSIndexSet *)indexes
                             composingMask:(UInt32)composingMask
                                   compose:(BOOL)doCompose
                            attributesMask:(UInt32)attributesMask
{

//	CMRThreadMessage	*m;

	NSUInteger				size = [indexes lastIndex]+1;
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	
	if (!indexes || [indexes count] == 0) {
        return nil;
    }
	if ([self firstUnlaidMessageIndex] < size) {
        return nil;
    }
//	NSUInteger idx;
//	NSRange e = NSMakeRange(0, size);

	composer_ = [[CMRAttributedMessageComposer alloc] init];
	textBuffer_ = [[NSMutableAttributedString alloc] init];
	
	[composer_ setAttributesMask:attributesMask];
	[composer_ setComposingMask:composingMask compose:doCompose];
	
	[composer_ setContentsStorage:textBuffer_];
/*
	while ([indexes getIndexes:&idx maxCount:1 inIndexRange:&e] > 0) {
		m = [[self messageBuffer] messageAtIndex:idx];
		[composer_ composeThreadMessage:m];
	}*/

    // Concurrent は禁止！
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CMRThreadMessage *message = [[self messageBuffer] messageAtIndex:idx];
        [composer_ composeThreadMessage:message];
    }];

	[composer_ release];
	return [textBuffer_ autorelease];
}

- (NSAttributedString *)contentsForTargetIndex:(NSUInteger)messageIndex
								 composingMask:(UInt32)composingMask
									   compose:(BOOL)doCompose
								attributesMask:(UInt32)attributesMask
{
	CMRThreadMessage	*m;
	NSUInteger	limit = [self firstUnlaidMessageIndex];
	NSUInteger	i;
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	
	if (limit == 0) return nil;

	composer_ = [[CMRAttributedMessageComposer alloc] init];
	textBuffer_ = [[NSMutableAttributedString alloc] init];
	
	[composer_ setAttributesMask:attributesMask];
	[composer_ setComposingMask:composingMask compose:doCompose];
	[composer_ setComposingTargetIndex: messageIndex];
	[composer_ setContentsStorage:textBuffer_];
	
	for (i = 0; i < limit; i++) {
		m = [[self messageBuffer] messageAtIndex:i];
		[composer_ composeThreadMessage:m];
	}
	[composer_ release];
	return [textBuffer_ autorelease];
}

- (NSAttributedString *)contentsForIndexes:(NSIndexSet *)indexes
{
	if (kSpamFilterInvisibleAbonedBehavior == [CMRPref spamFilterBehavior]) {
		return [self contentsForIndexes:indexes
                          composingMask:CMRInvisibleAbonedMask
                                compose:NO
                         attributesMask:CMRLocalAbonedMask];
	} else {
		return [self contentsForIndexes:indexes
                          composingMask:CMRInvisibleAbonedMask
                                compose:NO
                         attributesMask:(CMRLocalAbonedMask|CMRSpamMask)];
	}
}

#pragma mark On-the-fly loading
/*- (NSUInteger)numberOfMessagesPerOnTheFly
{
	id		v;
	
	v = SGTemplateResource(ENSURE_LENGTH_KEY);
	if (!v || ![v respondsToSelector:@selector(unsignedIntegerValue)]) {
		return 10;
    }

	return [v unsignedIntegerValue];
}*/

- (void)ensureMessageToBeVisibleAtIndex:(NSUInteger)anIndex
{
//	[self ensureMessageToBeVisibleAtIndex:anIndex effectsLongest:NO];
    NSRange range = [self rangeAtMessageIndex:anIndex];

    [[self layoutManager] ensureLayoutForCharacterRange:range];
}

/*- (void)ensureMessageToBeVisibleAtIndex:(NSUInteger)anIndex effectsLongest:(BOOL)longestFlag
{
	CMRThreadMessage	*m;
	NSUInteger			i, st, lst, cnt, max;
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	NSUInteger			textLength_ = 0;
	NSRange				mesRange_;
	
	max = [self numberOfMessagesPerOnTheFly];
	cnt = [self firstUnlaidMessageIndex];
	if (NSNotFound == anIndex || cnt <= anIndex)
		return;
	
	m = [[self messageBuffer] messageAtIndex:anIndex];
	if (NO == [m isTemporaryInvisible]) return;
	
	// 範囲を求める（上方向）
	for (i = 0, st = anIndex; st >= 0; i++, st--) {
		m = [[self messageBuffer] messageAtIndex:st];
		if (NO == [m isTemporaryInvisible] || (NO == longestFlag && i >= max)) {
			st++;
			break;
		}
		
		if (0 == st) break;
	}
	// 範囲を求める（下方向）
	for (i = 0, lst = anIndex; lst < cnt; i++, lst++) {
		m = [[self messageBuffer] messageAtIndex:lst];
		if (NO == [m isTemporaryInvisible] || (NO == longestFlag && i >= max)) {
			lst--;
			break;
		}
		if (cnt-1 == lst) break;
	}
	
	composer_ = [[CMRAttributedMessageComposer alloc] init];
	textBuffer_ = [[NSMutableAttributedString alloc] init];
	[composer_ setContentsStorage:textBuffer_];
	
	[[self messageBuffer] setTemporaryInvisible:NO
							inRange:NSMakeRange(st, (lst - st +1))];
	
	mesRange_ = [[self messageRanges] rangeAtIndex:st];
	textLength_ = mesRange_.location;
	[_messagesLock lock];
	for (i = st; i <= lst; i++) {
		m = [[self messageBuffer] messageAtIndex:i];
		
		mesRange_ = NSMakeRange([textBuffer_ length], 0);
		[composer_ composeThreadMessage:m];
		mesRange_.length = [textBuffer_ length] - mesRange_.location;
		mesRange_.location += textLength_;
		
		[[self messageRanges] setRange:mesRange_ atIndex:i];
	}
	
	// オリジナルの範囲を補正
	textLength_ = [textBuffer_ length];
	for (i = lst +1; i < cnt; i++) {
		mesRange_ = [[self messageRanges] rangeAtIndex:i];
		mesRange_.location += textLength_;
		[[self messageRanges] setRange:mesRange_ atIndex:i];
	}
	[_messagesLock unlock];
	
	mesRange_ = [[self messageRanges] rangeAtIndex:st];
	[[self textStorage] beginEditing];
	[[self textStorage] insertAttributedString:textBuffer_
							atIndex:mesRange_.location];
	[self fixEllipsisProxyAttachment];
	[[self textStorage] endEditing];

	// 2005-09-09 tsawada2 <ben-sawa@td5.so-net.ne.jp>
	// Tiger で、オンザフライでレス展開したとき描画がしばしば乱れる問題を
	// これで回避…できるだろうか？しばらく様子見。
	[[self scrollView] setNeedsDisplay:YES];

	[textBuffer_ release];
	[composer_ release];
}*/

// 次／前のレス
- (NSUInteger)nextMessageIndexOfIndex:(NSUInteger)index attribute:(UInt32)flags value:(BOOL)attributeIsSet
{
	NSUInteger i;
    NSUInteger cnt;
	CMRThreadMessage *m;
	
	if (NSNotFound == index) {
		return NSNotFound;
    }
	cnt = [self firstUnlaidMessageIndex];
	if (cnt <= index) {
		return NSNotFound;
    }
	for (i = index +1; i < cnt; i++) {
		m = [self messageAtIndex:i];
		if (attributeIsSet == (([m flags] & flags) != 0)) {
			return i;
        }
	}
	
	return NSNotFound;
}

- (NSUInteger)previousMessageIndexOfIndex:(NSUInteger)index attribute:(UInt32)flags value:(BOOL)attributeIsSet
{
    NSInteger i;
	CMRThreadMessage *m;
	
	if (NSNotFound == index) {
		return NSNotFound;
	}
	if (0 == index) {
		return NSNotFound;
	}
	for (i = (index - 1); i >= 0; i--) {
		m = [self messageAtIndex:i];
		if (attributeIsSet == (([m flags] & flags) != 0)) {
			return i;
        }
	}

	return NSNotFound;
}

- (NSUInteger)messageIndexOfLaterDate:(NSDate *)baseDate attribute:(UInt32)flags value:(BOOL)attributeIsSet
{
	NSUInteger i;
    NSUInteger cnt;
	CMRThreadMessage *m;
	id msgDate;
	
	if (!baseDate) {
		return NSNotFound;
    }

	cnt = [self numberOfReadedMessages];

	for (i = 0; i < cnt; i++) {
		m = [self messageAtIndex:i];
		msgDate = [m date];
		if (!msgDate || ![msgDate isKindOfClass:[NSDate class]]) {
            continue;
        }
		if (([(NSDate *)msgDate compare: baseDate] != NSOrderedAscending) && (attributeIsSet == (([m flags] & flags) != 0))) {
			return i;
		}
	}

	return NSNotFound;
}

#pragma mark Jumpable index
- (NSUInteger)nextVisibleMessageIndex
{
	return [self nextVisibleMessageIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

- (NSUInteger)previousVisibleMessageIndex
{
	return [self previousVisibleMessageIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

static UInt32 attributeMaskForVisibleMessageIndexDetection()
{
	if (kSpamFilterInvisibleAbonedBehavior == [CMRPref spamFilterBehavior]) {
		return (CMRInvisibleAbonedMask|CMRSpamMask);
	} else {
		return CMRInvisibleAbonedMask;
	}
}

- (NSUInteger) nextVisibleMessageIndexOfIndex:(NSUInteger) anIndex
{
	return [self nextMessageIndexOfIndex:anIndex 
							   attribute:attributeMaskForVisibleMessageIndexDetection()
								   value:NO];
}

- (NSUInteger)previousVisibleMessageIndexOfIndex:(NSUInteger)anIndex
{
	return [self previousMessageIndexOfIndex:anIndex 
								   attribute:attributeMaskForVisibleMessageIndexDetection()
									   value:NO];
}

#pragma mark Jumping to bookmarks
- (NSUInteger)nextBookmarkIndex
{
	return [self nextBookmarkIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

- (NSUInteger)previousBookmarkIndex
{
	return [self previousBookmarkIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

- (NSUInteger)nextBookmarkIndexOfIndex:(NSUInteger)anIndex
{
	return [self nextMessageIndexOfIndex:anIndex attribute:CMRBookmarkMask value:YES];
}

- (NSUInteger)previousBookmarkIndexOfIndex:(NSUInteger) anIndex
{
	return [self previousMessageIndexOfIndex:anIndex attribute:CMRBookmarkMask value:YES];
}

#pragma mark Jumping to Specific date's Message
- (NSUInteger)messageIndexOfLaterDate:(NSDate *)baseDate
{
	return [self messageIndexOfLaterDate:baseDate attribute:attributeMaskForVisibleMessageIndexDetection() value:NO];
}
@end
