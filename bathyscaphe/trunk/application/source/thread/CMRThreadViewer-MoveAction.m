//
//  CMRThreadViewer-MoveAction.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/16.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"
#import "CMRThreadLayout.h"
#import "BSDateFormatter.h"
#import "BSIndexPanelController.h"


@implementation CMRThreadViewer(MoveActionSupport)
- (void)validateIndexingNavigator
{
    NSNotification *notification = [NSNotification notificationWithName:BSShouldValidateIdxNavNotification object:self];
    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                               postingStyle:NSPostWhenIdle
                                               coalesceMask:(NSNotificationCoalescingOnName|NSNotificationCoalescingOnSender)
                                                   forModes:nil];
}

- (void)validateIdxNavLazily:(NSNotification *)notification
{
	NSInteger index_;
	NSInteger maxValue_;
	NSInteger minValue_;

	if (![self threadLayout]) {
		maxValue_ = 0;
	} else {
		maxValue_ = [[self threadLayout] firstUnlaidMessageIndex];
	}

	if (0 == maxValue_) {
		index_ = 0;
		minValue_ = 0;
	} else {
		index_ = [[self threadLayout] firstMessageIndexForDocumentVisibleRect];
		if (index_ == NSNotFound) {
            index_ = 0;
		}
		index_++;
		minValue_ = 1;
	}

    [[self indexingNavigator] setEnabled:(index_ != minValue_) forSegment:0];
    [[self indexingNavigator] setEnabled:(index_ != maxValue_) forSegment:4];
    [[self indexingNavigator] setEnabled:(index_ != minValue_) forSegment:1];
    [[self indexingNavigator] setEnabled:(index_ != maxValue_) forSegment:3];
    [[self indexingNavigator] setEnabled:[self canScrollToLastUpdatedMessage] forSegment:2];
}

- (void)scrollMessageAtIndex:(NSInteger)index
{
	[[self threadLayout] scrollMessageAtIndex:index];
}

- (void)contentViewBoundsDidChange:(NSNotification *)notification
{
	UTILAssertNotificationName(
		notification,
		NSViewBoundsDidChangeNotification);
	UTILAssertNotificationObject(
		notification,
		[[self scrollView] contentView]);

	[self validateIndexingNavigator];
}
@end



@implementation CMRThreadViewer(MoveAction)
/* 最初／最後のレス */
- (IBAction)scrollFirstMessage:(id)sender
{
	[self scrollMessageAtIndex:0];
}

- (IBAction)scrollLastMessage:(id)sender
{
	[self scrollMessageAtIndex:[[self threadLayout] firstUnlaidMessageIndex] -1];
}

/* 次／前のレス */
- (IBAction)scrollPreviousMessage:(id)sender
{
	[self scrollPrevMessage:sender];
}

- (IBAction)scrollPrevMessage:(id)sender
{
	[self scrollMessageAtIndex:[[self threadLayout] previousVisibleMessageIndex]];
}

- (IBAction)scrollNextMessage:(id)sender
{
	[self scrollMessageAtIndex:[[self threadLayout] nextVisibleMessageIndex]];
}

/* 次／前のブックマーク */
- (IBAction)scrollPreviousBookmark:(id)sender 
{
	[self scrollMessageAtIndex:[[self threadLayout] previousBookmarkIndex]];
}

- (IBAction)scrollNextBookmark:(id)sender
{
	[self scrollMessageAtIndex:[[self threadLayout] nextBookmarkIndex]];
}

/* その他 */
- (IBAction)scrollToLastReadedIndex:(id)sender
{
    [self scrollMessageAtIndex:[[self threadAttributes] lastIndex]];
}

- (IBAction)scrollToLastUpdatedIndex:(id)sender
{
	[[self threadLayout] scrollToLastUpdatedIndex:sender];
}

- (IBAction)scrollToFirstTodayMessage:(id)sender
{
	NSDate *aDate = [[BSDateFormatter sharedDateFormatter] baseDateOfToday];
	NSUInteger index_ = [[self threadLayout] messageIndexOfLaterDate:aDate];
	if (index_ != NSNotFound) {
		[[self threadLayout] scrollMessageAtIndex:index_];
	} else {
		NSBeep();
	}
}

- (IBAction)scrollToLatest50FirstIndex:(id)sender
{
    NSUInteger index;
    NSUInteger lastIndex = [[self threadLayout] firstUnlaidMessageIndex];
    if (lastIndex < 50) {
        index = 0;
    } else {
        index = lastIndex - 50;
    }
    [self scrollMessageAtIndex:index];
}

- (IBAction)scrollPrevBookmarkOrFirst:(id)sender
{
    NSUInteger index = [[self threadLayout] previousBookmarkIndex];
    if (index != NSNotFound) {
        [self scrollPreviousBookmark:sender];
    } else {
        [self scrollFirstMessage:sender];
    }
}

- (IBAction)scrollNextBookmarkOrLast:(id)sender
{
    NSUInteger index = [[self threadLayout] nextBookmarkIndex];
    if (index != NSNotFound) {
        [self scrollNextBookmark:sender];
    } else {
        [self scrollLastMessage:sender];
    }
}

- (IBAction)showIndexPanel:(id)sender
{
    BSIndexPanelController *wc = [[BSIndexPanelController alloc] init];
    [wc beginSheetModalForThreadViewer:self];
}

- (IBAction)scrollFromNavigator:(id)sender
{
    if (sender != [self indexingNavigator]) {
        return;
    }

    switch ([sender selectedSegment]) {
        case 0:
            [self scrollPrevBookmarkOrFirst:sender];
            break;
        case 1:
            [self scrollPrevMessage:sender];
            break;
        case 2:
            [self scrollToLastUpdatedIndex:sender];
            break;
        case 3:
            [self scrollNextMessage:sender];
            break;
        case 4:
            [self scrollNextBookmarkOrLast:sender];
            break;
        default:
            break;
    }
}
@end


@implementation CMRThreadViewer(MoveActionValidation)
- (BOOL)canScrollToMessage
{
	return ([self threadLayout] && ([[self threadLayout] firstUnlaidMessageIndex] != 0));
}

- (BOOL)canScrollFirstMessage
{
	if (![self canScrollToMessage]) {
        return NO;
    }
    NSInteger index_;
    NSInteger min_;
    index_ = [[self threadLayout] firstMessageIndexForDocumentVisibleRect];
    if (index_ == NSNotFound) {
        index_ = 0;
    }
    index_++;
    min_ = (index_ == 0) ? 0 : 1;
	return (index_ != min_);
}

- (BOOL)canScrollLastMessage
{
	if (![self canScrollToMessage]) {
        return NO;
    }
    NSInteger index_;
    index_ = [[self threadLayout] firstMessageIndexForDocumentVisibleRect];
    if (index_ == NSNotFound) {
        index_ = 0;
    }
    index_++;
	return (index_ != [[self threadLayout] firstUnlaidMessageIndex]);
}

- (BOOL)canScrollPrevMessage
{
	return [self canScrollFirstMessage];
}

- (BOOL)canScrollNextMessage
{
	return [self canScrollLastMessage];
}

- (BOOL)canScrollToLastReadedMessage
{
	if (![self canScrollToMessage]) {
		return NO;
	}
	if (NSNotFound == [[self threadAttributes] lastIndex]) {
		return NO;
	}
	return YES;
}

- (BOOL)canScrollToLastUpdatedMessage
{
	NSRange range_;
	
	if (![self canScrollToMessage]) {
        return NO;
	}
	range_ = [[self threadLayout] firstLastUpdatedHeaderAttachmentRange];
	if (NSNotFound == range_.location) {
        return NO;
	}
	return YES;
}
@end
