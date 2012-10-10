/*
 * $Id: CMRThreadViewer-OwnHistory.m,v 1.15 2007-12-11 17:09:37 tsawada2 Exp $
 *
 * それぞれのスレッドビューア内での履歴（グローバルな履歴と一致するとは限らない）の管理と移動アクションのサポート
 * CMRThreadViewer.m から分割
 * encoding="UTF-8"
 */

#import "CMRThreadViewer_p.h"
#import "CMRHistoryManager.h"
#import "DatabaseManager.h"
@class BSSegmentedControlTbItem;

@implementation CMRThreadViewer(History)
- (id)threadIdentifierFromHistoryWithRelativeIndex:(NSInteger)relativeIndex
{
	NSArray *historyItems_ = [self threadHistoryArray];
	NSUInteger historyIndex_ = [self historyIndex];
	NSUInteger historyCount_ = [historyItems_ count];
	NSInteger newIndex_;

	if (NSNotFound == historyIndex_ || 0 == historyCount_) {
		return nil;
	}
	newIndex_ = historyIndex_;
	newIndex_ += relativeIndex;

	if (newIndex_ >= 0 && newIndex_ < historyCount_) {
		return [historyItems_ objectAtIndex:newIndex_];
	}
	return nil;
}

- (BOOL)performHistoryWithRelativeIndex:(NSInteger)relativeIndex
{
	id threadIdentifier_;

	threadIdentifier_ = [self threadIdentifierFromHistoryWithRelativeIndex:relativeIndex];
	if (!threadIdentifier_) {
		return NO;
	}
	// 「戻る／進む」では自身の履歴リストに登録せず、
	// 代わりに履歴を移動
	[self setThreadContentWithThreadIdentifier:threadIdentifier_ noteHistoryList:relativeIndex];
	return YES;
}

// 連続したエントリを削除
- (void)compactThreadHistoryItems
{
	NSMutableArray *items_;
	NSInteger i;
	id prev_ = nil;

	items_ = [self threadHistoryArray];
	for (i = [items_ count] -1; i >= 0; i--) {
		id object_;

		object_ = [items_ objectAtIndex:i];
		// 連続
		if ([object_ isEqual:prev_]) {
			[items_ removeObjectAtIndex:i];
			continue;
		}
		prev_ = object_;
	}
}

- (void)noteHistoryThreadChanged:(NSInteger)relativeIndex
{
	NSMutableArray *items_;
	NSUInteger historyIndex_;
	NSUInteger historyCount_;
	NSInteger newIndex_;

	items_ = [self threadHistoryArray];
	historyIndex_ = [self historyIndex];
	historyCount_ = [items_ count];
	if (0 == relativeIndex) {
		id identifier_;
		// 登録
		identifier_ = [self threadIdentifier];
		if (nil == identifier_) {
			return;
		}
		if (NSNotFound == historyIndex_ || historyIndex_ == (historyCount_ -1)) {
			[items_ addObject:identifier_];
//			historyCount_ = [items_ count];
		} else {
			newIndex_ = historyIndex_ +1;
			[items_ insertObject:identifier_ atIndex:newIndex_];
		}

		// 連続したエントリは削除し、インデックスを修正
		[self compactThreadHistoryItems];
		newIndex_ = [items_ indexOfObject:identifier_];
	} else {
		// 移動
		if (NSNotFound == historyIndex_) {
            return;
		}
		newIndex_ = historyIndex_ + relativeIndex;
		if (newIndex_ < 0) {
            newIndex_ = 0;
        }
		if (newIndex_ >= historyCount_) {
            newIndex_ = historyCount_ -1;
        }
	}

	[self setHistoryIndex:newIndex_];
}

- (void)clearThreadHistories
{
	[self setHistoryIndex:NSNotFound];
	[[self threadHistoryArray] removeAllObjects];
}

#pragma mark Accessors
// No History --> NSNotFound
- (NSUInteger)historyIndex
{
	return _historyIndex;
}

- (void)setHistoryIndex:(NSUInteger)aHistoryIndex
{
	_historyIndex = aHistoryIndex;
}

// History: ThreadSignature...
- (NSMutableArray *)threadHistoryArray
{
	if (!_history) {
		_history = [[NSMutableArray alloc] init];
		[self setHistoryIndex:NSNotFound];
	}

	return _history;
}

#pragma mark IBAction
- (IBAction)historyMenuPerformForward:(id)sender
{
	[self performHistoryWithRelativeIndex:1];
}

- (IBAction)historyMenuPerformBack:(id)sender
{
	[self performHistoryWithRelativeIndex:-1];
}

- (IBAction)historySegmentedControlPushed:(id)sender
{
	NSInteger i = [sender selectedSegment];

	if (i == -1) {
		NSLog(@"No selection?");
	} else if (i == 1) {
		[self historyMenuPerformForward:nil];
	} else {
		[self historyMenuPerformBack:nil];
	}
}

#pragma mark BSSegmentedControlTbItem delegate
- (BOOL)segCtrlTbItem:(BSSegmentedControlTbItem *)item validateSegment:(NSInteger)segment
{
	if ([[item itemIdentifier] isEqualToString:@"scaleSC"]) {
        return [self validateUserInterfaceItem:item];
    }

	if (![self shouldShowContents]) {
		return NO;
    }
	NSInteger relativeIdx;

	if (segment == 0) {
		relativeIdx = -1;
	} else if (segment == 1) {
		relativeIdx = 1;
	} else {
		return NO;
    }
	return ([self threadIdentifierFromHistoryWithRelativeIndex:relativeIdx] != nil);
}
@end
