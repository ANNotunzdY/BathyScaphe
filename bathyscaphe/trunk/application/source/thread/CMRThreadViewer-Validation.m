//
//  CMRThreadViewer-Validation.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/02/16.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"

#import "CMRThreadsList.h"
#import "CMRThreadView.h"
//#import "CMRThreadVisibleRange.h"
#import "CMRThreadLayout.h"
#import "CMXPopUpWindowManager.h"
#import "BSBoardInfoInspector.h"

//////////////////////////////////////////////////////////////////////
#pragma mark Define and Constants
//////////////////////////////////////////////////////////////////////
#define kReplyItemKey				@"Reply..."
#define kReplyToItemKey				@"Reply 2..."

#define kAddFavaritesItemKey			@"Add Favorites"
#define kRemoveFavaritesItemKey			@"Remove Favorites"
#define kAddFavaritesItemImageName		@"AddFavoritesTemplate"
#define kRemoveFavaritesItemImageName	@"RemoveFavoritesTemplate"

#define kShowBoardInspectorKey			@"Show Board Inspector"
#define kHideBoardInspectorKey			@"Hide Board Inspector"

#define kDeleteWithoutAlertKey			@"Delete Log"
#define kDeleteWithAlertKey				@"Delete Log..."

/*** アクション・メニュー ***/
#define kActionMenuItemTag				(100)	/* 「アクション」 */

#define kActionSpamHeader				(111)	/* 「迷惑レス」ヘッダ */
#define kActionAAHeader					(222)	/* 「AA」ヘッダ */
#define kActionBookmarkHeader			(333)	/* 「ブックマーク」ヘッダ */
#define kActionLocalAbonedHeader		(444)	/* 「ローカルあぼーん」ヘッダ */
#define kActionInvisibleAbonedHeader	(555)	/* 「透明あぼーん」ヘッダ */

#pragma mark -

@implementation CMRThreadViewer(Validation)

#pragma mark Action Menu


/*** レス属性 ***/
static NSInteger messageMaskForTag(NSInteger tag)
{
	if (kActionInvisibleAbonedHeader <= tag) {
		return CMRInvisibleAbonedMask;
	} else if (kActionLocalAbonedHeader <= tag) {
		return CMRLocalAbonedMask;
	} else if (kActionBookmarkHeader <= tag) {
		return CMRBookmarkMask;
	} else if (kActionAAHeader <= tag) {
		return CMRAsciiArtMask;
	} else if (kActionSpamHeader <= tag) {
		return CMRSpamMask;
	} 
	return 0;
}
/*- (IBAction) clearMessageAttributes : (id) sender
{
	[[self threadLayout]
		changeAllMessageAttributes : NO
							 flags : messageMaskForTag([sender tag])];
}
- (IBAction) setOnMessageAttributes : (id) sender
{
	[[self threadLayout]
		changeAllMessageAttributes : YES
							 flags : messageMaskForTag([sender tag])];
}*/
- (IBAction) showMessageMatchesAttributes : (id) sender
{
	NSRange				indexRange_;
	CMRThreadLayout		*layout = [self threadLayout];
	NSAttributedString	*contents_;
	NSPoint				location_;
	NSUInteger			composingMask_;
	NSUInteger			attributeMask_ = CMRAnyAttributesMask;
	
	composingMask_ = messageMaskForTag([sender tag]);
	// ブックマーク、ＡＡ以外の属性は無視する
	attributeMask_ &= ~CMRBookmarkMask;
	attributeMask_ &= ~CMRAsciiArtMask;
	
	indexRange_ = NSMakeRange(0, [layout firstUnlaidMessageIndex]);
	if (0 == indexRange_.length)
		return;
	
	contents_ = [layout contentsForIndexes:[NSIndexSet indexSetWithIndexesInRange:indexRange_]
	 					 composingMask : composingMask_
							   compose : YES
						attributesMask : attributeMask_];
	
	if (!contents_ || ![contents_ length]) {
		NSBeep();
		return;
	}
	location_ = [self locationForInformationPopUp];
	[CMRPopUpMgr showPopUpWindowWithContext : contents_
								  forObject : [self threadIdentifier]
									  owner : self
							   locationHint : location_];
}

#pragma mark Validation Helpers

- (BOOL)validateActionMenuItem:(NSMenuItem *)theItem
{
	NSInteger			tag = [theItem tag];
//	SEL			action = [theItem action];
	NSUInteger	mask;
	
	mask = messageMaskForTag(tag);
	if (mask != 0) {
		NSUInteger	nMatches;		

		nMatches = [[self threadLayout] numberOfMessageAttributes:mask];

		{
			NSString	*title_ = @"";
			NSString	*key_   = nil;
			
			if (kActionSpamHeader == tag) {
				key_ = @"ActionSpamHeaderFormat";
			} else if (kActionAAHeader == tag) {
				key_ = @"ActionAAHeaderFormat";
			} else if (kActionBookmarkHeader == tag) {
				key_ = @"ActionBookmarkHeaderFormat";
			} else if (kActionLocalAbonedHeader == tag) {
				key_ = @"ActionLocalAbonedHeaderFormat";
			} else if (kActionInvisibleAbonedHeader == tag) {
				key_ = @"ActionInvisibleAbonedHeaderFormat";
			}
			if (key_) {
				// ヘッダ
				title_ = [self localizedString:key_];
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 修正済
				title_ = [NSString stringWithFormat:title_, (unsigned long)nMatches];
				[theItem setTitle:title_];
			}
		}
		
//		if ( @selector(clearMessageAttributes:) == action || 
//			 @selector(showMessageMatchesAttributes:) == action )
//		{
			return (nMatches != 0);
//		}
		
		// すべてのレスを変更
/*		if (@selector(setOnMessageAttributes:) == action) {
			unsigned nReaded = [[self threadLayout] numberOfReadedMessages];
			
			if (0 == nReaded) return NO;
			
			return (nReaded > nMatches);
		}*/
	}
	return NO;
}

- (void)validateDeleteThreadItemTitle:(id)theItem
{
	if ([theItem isKindOfClass:[NSMenuItem class]]) {
        NSString *key = [CMRPref quietDeletion] ? kDeleteWithoutAlertKey : kDeleteWithAlertKey;
		[theItem setTitle:[self localizedString:key]];
	}
}

- (BOOL)validateDeleteThreadItemEnabling:(NSString *)threadPath
{
	if (threadPath && [[NSFileManager defaultManager] fileExistsAtPath:threadPath]) {
		return YES;
	} else {
		return NO;
	}
}

- (CMRFavoritesOperation)favoritesOperationForThreads:(NSArray *)threadsArray
{
    if (!threadsArray) {
        return CMRFavoritesOperationNone;
    }
    NSUInteger noneCount = 0;
    NSUInteger removeCount = 0;
    CMRFavoritesManager *fm = [CMRFavoritesManager defaultManager];
    for (NSDictionary *thread in threadsArray) {
        CMRFavoritesOperation op = [fm availableOperationWithPath:[CMRThreadAttributes pathFromDictionary:thread]];
        if (op == CMRFavoritesOperationRemove) {
            removeCount++;
        } else if (op == CMRFavoritesOperationNone) {
            noneCount++;
        }
    }
    NSUInteger threadsCount = [threadsArray count];
    if (threadsCount == noneCount) {
        return CMRFavoritesOperationNone;
    }
    if ((threadsCount - noneCount) == removeCount) {
        return CMRFavoritesOperationRemove;
    }
    return CMRFavoritesOperationLink;
}

- (BOOL)validateAddFavoritesItem:(id)theItem forOperation:(CMRFavoritesOperation)operation
{
    NSString *titleKey;

	if (CMRFavoritesOperationNone == operation) {
		return NO;
	}

    titleKey = (CMRFavoritesOperationLink == operation) ? kAddFavaritesItemKey : kRemoveFavaritesItemKey;
	[theItem setTitle:[self localizedString:titleKey]];
	
	if ([theItem image]) {
        NSString *imageName;
        imageName = (CMRFavoritesOperationLink == operation) ? kAddFavaritesItemImageName : kRemoveFavaritesItemImageName;
        NSImage *image_ =[NSImage imageAppNamed:imageName];
        [theItem setImage:image_];
	}
	return YES;
}

- (BOOL)validateReplyItem:(id)theItem
{
	NSString		*title_;
	
	title_ = (0 == ([[self textView] selectedRange]).length)
				? [self localizedString:kReplyItemKey]
				: [self localizedString:kReplyToItemKey];
	
	[theItem setTitle:title_];		

	return ([self threadAttributes] && [self shouldShowContents]);
}

- (void)validateShowBoardInspectorPanelItemTitle:(id)item
{
	NSWindowController *wc_ = [BSBoardInfoInspector sharedInstance];
	if (![wc_ isWindowLoaded]) {
		[item setTitle:[self localizedString:kShowBoardInspectorKey]];
	} else {
		BOOL tmpBool = [[wc_ window] isVisible];
		[item setTitle:[self localizedString:(tmpBool ? kHideBoardInspectorKey : kShowBoardInspectorKey)]];
	}
}

- (BOOL)validateBBSActionItems
{
    return YES; // subclass should override this method
}

#pragma mark NSUserInterfaceValidations Protocol
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)theItem
{
	SEL	action_ = [theItem action];

//		if (action_ == @selector(clearMessageAttributes:) || action_ == @selector(showMessageMatchesAttributes:) ||
//			action_ == @selector(setOnMessageAttributes:)) {
    if (action_ == @selector(showMessageMatchesAttributes:)) {
        return [self validateActionMenuItem:(NSMenuItem *)theItem];
    }

	// レス
	if (action_ == @selector(reply:)) {
		return [self validateReplyItem:theItem];
	}

	// お気に入りに追加
	if (action_ == @selector(addFavorites:)) {
        CMRFavoritesOperation operation = [[CMRFavoritesManager defaultManager] availableOperationWithSignature:[self threadIdentifier]];
		return [self validateAddFavoritesItem:theItem forOperation:operation];
	}

	// ログを削除(...)
	if (action_ == @selector(deleteThread:)) {
		[self validateDeleteThreadItemTitle:theItem];
		return [self validateDeleteThreadItemEnabling:[self path]];
	}

	// 移動
	if (action_ == @selector(scrollFirstMessage:))
		return [self canScrollFirstMessage];
	if (action_ == @selector(scrollLastMessage:))
		return [self canScrollLastMessage];
	if (action_ == @selector(scrollPrevMessage:))
		return [self canScrollPrevMessage];
	if (action_ == @selector(scrollNextMessage:))
		return [self canScrollNextMessage];
	if (action_ == @selector(scrollToLastReadedIndex:)) 
		return [self canScrollToLastReadedMessage];
	if (action_ == @selector(scrollToLastUpdatedIndex:)) 
		return [self canScrollToLastUpdatedMessage];
	// ブックマークに移動
	if (action_ == @selector(scrollPreviousBookmark:)) 
		return ([[self threadLayout] previousBookmarkIndex] != NSNotFound);
	if (action_ == @selector(scrollNextBookmark:)) 
		return ([[self threadLayout] nextBookmarkIndex] != NSNotFound);
	if (action_ == @selector(scrollToFirstTodayMessage:))
		return [self canScrollToMessage]; // とりあえず
	if (action_ == @selector(scrollToLatest50FirstIndex:))
		return [self canScrollToMessage]; // とりあえず
	if (action_ == @selector(showIndexPanel:))
		return [self canScrollToMessage]; // とりあえず
	
	// 検索と文字の拡大／縮小
	if (action_ == @selector(showStandardFindPanel:) ||
        action_ == @selector(findNextText:) ||
	    action_ == @selector(findPreviousText:) ||
	    action_ == @selector(findFirstText:) ||
	    action_ == @selector(findAll:) ||
	    action_ == @selector(findAllByFilter:) ||
	    action_ == @selector(biggerText:) ||
	    action_ == @selector(smallerText:) ||
	    action_ == @selector(runSpamFilter:) ||
	    action_ == @selector(runAsciiArtDetector:) ||
	    action_ == @selector(scaleSegmentedControlPushed:)) { // For Segmented Control
        return [self shouldShowContents] && [[[self textView] textStorage] length];
    }

    if (action_ == @selector(actualSizeText:)) {
        if ([self shouldShowContents] && [[[self textView] textStorage] length]) {
            return (m_scaleCount != 0);
        }
        return NO;
    }
	
	// 履歴：戻る／進む
	if (action_ == @selector(historyMenuPerformForward:)) {
		if ([self shouldShowContents]) {
			return ([self threadIdentifierFromHistoryWithRelativeIndex:1] != nil);
		} else {
			return NO;
		}
	}

	if (action_ == @selector(historyMenuPerformBack:)) {
		if ([self shouldShowContents]) {
			return ([self threadIdentifierFromHistoryWithRelativeIndex:-1] != nil);
		} else {
			return NO;
		}
	}

	// 選択テキストのコビー、抽出
	if (action_ == @selector(copySelectedResURL:) || action_ == @selector(extractUsingSelectedText:)) {
        return ([[self textView] selectedRange].length != 0);
    }
	if (action_ == @selector(copyURL:) || action_ == @selector(copyThreadAttributes:) || action_ == @selector(shareThreadInfo:)) {
        return ([self selectedThreads] && [self numberOfSelectedThreads]);
    }

	if (action_ == @selector(reloadThread:)) {
		return ([self threadAttributes] && ![(CMRThreadDocument *)[self document] isDatOchiThread]);
    }

    if (action_ == @selector(retrieveThread:)) {
        if (![self threadAttributes]) {
            return NO;
        } else {
            if (![(CMRThreadDocument *)[self document] isDatOchiThread]) {
                return YES;
            } else {
                return [CMRPref shouldLoginIfNeeded];
            }
        }
    }

    // 掲示板関連アクション
    if (action_ == @selector(showLocalRules:)) {
        [(NSMenuItem *)theItem setTitle:NSLocalizedString(@"Show Local Rules", @"")];
        return [self validateBBSActionItems];
    }
    if (action_ == @selector(showBoardInspectorPanel:)) {
        [self validateShowBoardInspectorPanelItemTitle:theItem]; // メニュータイトルの変更のために
        return [self validateBBSActionItems];
    }
    if (action_ == @selector(openBBSInBrowser:)) {
        [(NSMenuItem *)theItem setTitle:NSLocalizedString(@"Open BBS in Browser", @"")];
        return [self validateBBSActionItems];
    }

	return [super validateUserInterfaceItem:theItem];
}
@end
