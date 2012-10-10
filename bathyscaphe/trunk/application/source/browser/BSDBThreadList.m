//
//  BSDBThreadList.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/19.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSDBThreadList.h"

#import "CMRThreadsList_p.h"
#import "missing.h"
#import "BSDateFormatter.h"
#import "CMRThreadSignature.h"
#import "BSThreadListUpdateTask.h"
#import "BSThreadsListOPTask.h"
//#import "BSBoardListItemHEADCheckTask.h"
#import "BSSmartBoardUpdateTask.h"
#import "BoardListItem.h"
#import "DatabaseManager.h"
#import "BSThreadListItem.h"
#import "BSIkioiNumberFormatter.h"
#import "CMRDocumentController.h"
#import "CMRAbstructThreadDocument.h"
#import "BSSExpParser.h"
#import "BSLabelManager.h"
#import "SmartBoardListItem.h"

#import "CMRThreadLayoutTask.h"

NSString *BSDBThreadListDidFinishUpdateNotification = @"BSDBThreadListDidFinishUpdateNotification";
NSString *BSDBThreadListWantsPartialReloadNotification = @"BSDBThreadListWantsPartialReloadNotification";


@interface BSDBThreadList(Private)
- (void)setSortDescriptors:(NSArray *)inDescs;
- (void)addSortDescriptor:(NSSortDescriptor *)inDesc;

- (void)pushIfCanExcute:(id <CMRTask>)task;
@end


@interface BSDBThreadList(ToBeRefactoring)
@end


@implementation BSDBThreadList
@synthesize rebuildError;
// primitive
- (id)initWithBoardListItem:(BoardListItem *)item
{
	if (self = [super init]) {
		[self setBoardListItem:item];

		mCursorLock = [[NSLock alloc] init];
		mTaskLock = [[NSLock alloc] init];
	}
	
	return self;
}

+ (id)threadListWithBoardListItem:(BoardListItem *)item
{
	return [[[self alloc] initWithBoardListItem:item] autorelease];
}

- (void)dealloc
{
	[mCursor release];
	mCursor = nil;
	[mCursorLock release];
	mCursorLock = nil;
	[mBoardListItem release];
	mBoardListItem = nil;
	[mSearchString release];
	mSearchString = nil;

	[mTask cancel:self];
	[mTask autorelease];
	[mUpdateTask cancel:self];
	[mUpdateTask autorelease];
	[mTaskLock release];
	
	[mSortDescriptors release];
	mSortDescriptors = nil;

    self.rebuildError = nil;

	[super dealloc];
}

- (void)registerToNotificationCenter
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	CMRFavoritesManager *fm = [CMRFavoritesManager defaultManager];
	[nc addObserver:self
		   selector:@selector(favoritesManagerDidChange:)
			   name:CMRFavoritesManagerDidLinkFavoritesNotification
			 object:fm];
	[nc addObserver:self
		   selector:@selector(favoritesManagerDidChange:)
			   name:CMRFavoritesManagerDidRemoveFavoritesNotification
			 object:fm];
    [nc addObserver:self
           selector:@selector(threadLabelDidChange:)
               name:DatabaseDidUpdateThreadLabelNotification
             object:[DatabaseManager defaultManager]];

	[super registerToNotificationCenter];
}

- (void)removeFromNotificationCenter
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	CMRFavoritesManager *fm = [CMRFavoritesManager defaultManager];

	[nc removeObserver:self
				  name:CMRFavoritesManagerDidLinkFavoritesNotification
				object:fm];
	[nc removeObserver:self
				  name:CMRFavoritesManagerDidRemoveFavoritesNotification
				object:fm];
	[nc removeObserver:self
				  name:BSThreadListUpdateTaskDidFinishNotification
				object:nil];
    [nc removeObserver:self
                  name:DatabaseDidUpdateThreadLabelNotification
                object:[DatabaseManager defaultManager]];

	[super removeFromNotificationCenter];
}

#pragma mark## Accessor ##
- (void)setBoardListItem:(BoardListItem *)item
{
	id temp = mBoardListItem;
	mBoardListItem = [item retain];
	[temp release];
}

- (BOOL)isFavorites
{
	return [BoardListItem isFavoriteItem:[self boardListItem]];
}

- (BOOL)isSmartItem
{
	return [BoardListItem isSmartItem:[self boardListItem]];
}

- (BOOL)isBoard
{
	return [BoardListItem isBoardItem:[self boardListItem]];
}

- (id)boardListItem
{
	return mBoardListItem;
}

- (id)searchString
{
	return mSearchString;
}

- (NSString *)boardName
{
	return [mBoardListItem name];
}

- (NSUInteger)numberOfThreads
{
	NSUInteger count;
	
	@synchronized(mCursorLock) {
		count = [mCursor count];
	}
	
	return count;
}

- (NSUInteger)numberOfFilteredThreads
{
	return [[self filteredThreads] count];
}

- (BSThreadsListViewModeType)viewMode
{
    if ([self isFavorites]) {
        return BSThreadsListShowsFavorites;
    } else if ([self isSmartItem]) {
        return BSThreadsListShowsSmartList;
    }
    return [CMRPref threadsListViewMode];
}

- (void)setViewMode:(BSThreadsListViewModeType)mode
{
    if (mode != BSThreadsListShowsLiveThreads && mode != BSThreadsListShowsStoredLogFiles) {
        return;
    }
    [CMRPref setThreadsListViewMode:mode];
}

#pragma mark## Sorting ##
- (NSArray *)adjustedSortDescriptors
{
	static NSArray *cachedDescArray = nil;

	if (![CMRPref collectByNew]) {
		return [self sortDescriptors];
	} else {
		if (!cachedDescArray) {
			NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"isnew" ascending:NO selector:@selector(numericCompare:)];
			cachedDescArray = [[NSArray alloc] initWithObjects:desc, nil];
			[desc release];
		}
		
		return [cachedDescArray arrayByAddingObjectsFromArray:[self sortDescriptors]];
	}
}

- (void)sortByDescriptors
{
	// お気に入りとスマートボードではindexは飾り
	// TODO 要変更
	if ([self isFavorites] || [self isSmartItem]) {
		if ([[(NSSortDescriptor *)[[self sortDescriptors] objectAtIndex:0] key] isEqualToString:CMRThreadSubjectIndexKey]) {
			return;
		}
	}

	
	@synchronized(mCursorLock) {
		[mCursor autorelease];
        NSArray *foo = [self adjustedSortDescriptors];
        id hoge = [mCursor sortedArrayUsingDescriptors:foo];
		mCursor = [hoge retain];
		[self updateFilteredThreadsIfNeeded];
	}
}

- (NSArray *)sortDescriptors
{
	return mSortDescriptors;
}

- (void)setSortDescriptors:(NSArray *)inDescs
{
	UTILAssertKindOfClass(inDescs, NSArray);
	
	id temp = mSortDescriptors;
	mSortDescriptors = [inDescs retain];
	[temp release];
}

#pragma mark## Thread item operations ##
- (void)updateCursor
{
	@synchronized(self) {
		if (mUpdateTask) {
			if ([mUpdateTask isInProgress]) {
				[mUpdateTask cancel:self];
			}
			[[NSNotificationCenter defaultCenter]
				removeObserver:self
						  name:BSThreadListUpdateTaskDidFinishNotification
						object:mUpdateTask];
			[mUpdateTask release];
			mUpdateTask = nil;
		} 
		{
			mUpdateTask = [[BSThreadListUpdateTask alloc] initWithBSDBThreadList:self];
			
			[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(didFinishCreateCursor:)
				   name:BSThreadListUpdateTaskDidFinishNotification
				 object:mUpdateTask];
		}
		[self pushIfCanExcute:mUpdateTask];
	}
}

- (void)setCursorOnMainThread:(id)cursor
{
	if (cursor) {
		@synchronized(mCursorLock) {
			NSArray *array = [BSThreadListItem threadItemArrayFromCursor:cursor];
			[mCursor autorelease];
			mCursor = [[array sortedArrayUsingDescriptors:[self adjustedSortDescriptors]] retain];
			UTILDebugWrite1(@"cursor count -> %ld", [mCursor count]);
			[self updateFilteredThreadsIfNeeded];
		}
	}
	UTILNotifyName(CMRThreadsListDidChangeNotification);
//	UTILNotifyName(BSDBThreadListDidFinishUpdateNotification);
}

- (void)didFinishCreateCursor:(id)notification
{
	id obj = [notification object];
	
	if (![obj isKindOfClass:[BSThreadListUpdateTask class]]) {
		return;
	}
	
	id temp = [[[obj cursor] retain] autorelease];	
	
	[self performSelectorOnMainThread:@selector(setCursorOnMainThread:)
						   withObject:temp
						waitUntilDone:NO];
}

- (void)updateThreadItem:(NSDictionary *)userInfo
{
    NSUInteger index;
	@synchronized(mCursorLock) {
        index = indexOfIdentifier(mCursor, [userInfo objectForKey:UserInfoThreadIDKey]);
    }
    if (index == NSNotFound) {
        // 現在の一覧に当該スレッドは存在しない
        if (([self viewMode] % 2) == 1) { // ログ一覧モード：ログ未取得から取得に変わった可能性がある。
            // isInserted ではなかったのは、DB上はスレッドのデータが存在するから。
            [self updateCursor];
        }
        return;
    }

	@synchronized(mCursorLock) {
        BSThreadListItem *item = [mCursor objectAtIndex:index];
//        NSLog(@"Check\n%@", item);
        // 板違いのスレッドかもしれない。
		NSArray *boardIDs = [[DatabaseManager defaultManager] boardIDsForName:[userInfo objectForKey:UserInfoBoardNameKey]];
		NSString *boardID = [NSString stringWithFormat:@"%ld", [item boardID]];
		if(![boardIDs containsObject:boardID]) {
			return;
		}

        id resCount = [userInfo objectForKey:UserInfoThreadCountKey];
        if (resCount) {
            NSString *tmp = [resCount stringValue];
            [item setValue:tmp forKey:NumberOfAllColumn];
            [item setValue:tmp forKey:NumberOfReadColumn];
        }
        id modDate = [userInfo objectForKey:UserInfoThreadModDateKey];
        if (modDate) {
            [item setValue:modDate forKey:ModifiedDateColumn];
        }
        id statusObj = [userInfo objectForKey:UserInfoThreadStatusKey];
        long status;
        if (statusObj) {
            status = (long)[statusObj integerValue];
        } else {
            status = (long)ThreadLogCachedStatus;
        }
        [item setValue:[NSString stringWithFormat:@"%ld", status] forKey:ThreadStatusColumn];

        [self updateFilteredThreadsIfNeeded];
    }

    index = indexOfIdentifier([self filteredThreads], [userInfo objectForKey:UserInfoThreadIDKey]);
    if (index != NSNotFound) {
        // テーブルビューに表示されているはず。
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:index];
        NSDictionary *userInfo2 = [NSDictionary dictionaryWithObject:indexes forKey:@"Indexes"];
        UTILNotifyInfo(BSDBThreadListWantsPartialReloadNotification, userInfo2);
    }
}

- (void)cleanUpThreadItem:(NSArray *)threadFilePaths
{
    NSString *identifier;
    NSString *boardName;
    CMRThreadSignature *signature;

    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    BOOL isLogMode = (([self viewMode] % 2) == 1);

    for ( NSString *path in threadFilePaths) {
        signature = [CMRThreadSignature threadSignatureFromFilepath:path];
        identifier = [signature identifier];
        boardName = [signature boardName];

        NSUInteger index = indexOfIdentifier(mCursor, identifier);
        if (index == NSNotFound) {
            continue;
        }

        BSThreadListItem *item = [mCursor objectAtIndex:index];
        // 板違いの同一 dat 番号スレッドかもしれない（めったにないだろうが…）。
        if (![[item boardName] isEqualToString:boardName]) {
            continue;
        }

        [indexes addIndex:index];

        if (!isLogMode) {
            [item setValue:[NSNull null] forKey:NumberOfReadColumn];
            [item setValue:[NSNull null] forKey:ModifiedDateColumn];
            [item setValue:[NSString stringWithFormat:@"%lu", (long)ThreadNoCacheStatus] forKey:ThreadStatusColumn];
            [item setValue:@"0" forKey:IsDatOchiColumn];
        }
    }

    if ([indexes count] == 0) {
        return;
    }

    if (isLogMode) {
        @synchronized(mCursorLock) {
            NSMutableArray *tmp = [mCursor mutableCopy];
            [tmp removeObjectsAtIndexes:indexes];
            [mCursor autorelease];
            mCursor = tmp;
        }
    }

    [self updateFilteredThreadsIfNeeded];

    NSDictionary *userInfo2 = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"Indexes"];
    UTILNotifyInfo(BSDBThreadListWantsPartialReloadNotification, userInfo2);
}

- (void)toggleDatOchiThreadItemWithPath:(NSString *)path
{
    CMRThreadSignature *signature = [CMRThreadSignature threadSignatureFromFilepath:path];
    NSString *identifier = [signature identifier];
    NSString *boardName = [signature boardName];
    NSUInteger index = indexOfIdentifier(mCursor, identifier);
    if (index == NSNotFound) {
        return;
    }

    BSThreadListItem *item = [mCursor objectAtIndex:index];
    // 板違いの同一 dat 番号スレッドかもしれない（めったにないだろうが…）。
    if (![[item boardName] isEqualToString:boardName]) {
        return;
    }

    NSString *newFlag = [item isDatOchi] ? @"0" : @"1";
    [item setValue:newFlag forKey:IsDatOchiColumn];
    [self updateFilteredThreadsIfNeeded];

    index = indexOfIdentifier([self filteredThreads], identifier);
    if (index != NSNotFound) {
        // テーブルビューに表示されているはず。
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:index];
        NSDictionary *userInfo2 = [NSDictionary dictionaryWithObject:indexes forKey:@"Indexes"];
        UTILNotifyInfo(BSDBThreadListWantsPartialReloadNotification, userInfo2);
    }

}

- (void)setLabel:(NSUInteger)label forThreadItemWithPath:(NSString *)path
{
    CMRThreadSignature *signature = [CMRThreadSignature threadSignatureFromFilepath:path];
    NSString *identifier = [signature identifier];
    NSString *boardName = [signature boardName];
    NSUInteger index = indexOfIdentifier(mCursor, identifier);
    if (index == NSNotFound) {
        return;
    }

    BSThreadListItem *item = [mCursor objectAtIndex:index];
    // 板違いの同一 dat 番号スレッドかもしれない（めったにないだろうが…）。
    if (![[item boardName] isEqualToString:boardName]) {
        return;
    }

    [item setValue:[NSString stringWithFormat:@"%lu", (unsigned long)label] forKey:ThreadLabelColumn];
    [self updateFilteredThreadsIfNeeded];

    // スレッド一覧に有るか？
    index = indexOfIdentifier([self filteredThreads], identifier);
    if (index != NSNotFound) {
        NSDictionary *userInfo2 = [NSDictionary dictionaryWithObject:[NSIndexSet indexSetWithIndex:index] forKey:@"Indexes"];
        UTILNotifyInfo(BSDBThreadListWantsPartialReloadNotification, userInfo2);
    }
}

#pragma mark## Filter ##
- (void)updateFilteredThreadsIfNeeded
{
	NSPredicate *predicate = nil;
	if (mSearchString && [mSearchString length] > 0) {
        predicate = [BSSExpParser predicateForString:mSearchString forKey:ThreadNameColumn];
	}
	if (predicate) {
		[self setFilteredThreads:[mCursor filteredArrayUsingPredicate:predicate]];
	} else {
		UTILDebugWrite(@"Predicate is null");
		[self setFilteredThreads:mCursor];
	}
	
	UTILDebugWrite1(@"filteredThreads count -> %ld", [[self filteredThreads] count]);
}

- (BOOL)filterByString:(NSString *)string
{
	id tmp = mSearchString;
	mSearchString = [string retain];
	[tmp release];
	
	[self updateFilteredThreadsIfNeeded];
	return YES;
}

static inline NSUInteger maskForNextUpdatedThread() {
    if ([CMRPref nextUpdatedThreadContainsNewThread]) {
        return (ThreadUpdatedStatus|ThreadNewCreatedStatus|ThreadHeadModifiedStatus)^(ThreadNoCacheStatus|ThreadLogCachedStatus);
    } else {
        return (ThreadUpdatedStatus|ThreadHeadModifiedStatus)^ThreadLogCachedStatus;
    }
}

- (NSUInteger)indexOfNextUpdatedThread:(NSUInteger)currentIndex
{
    BSThreadListItem *item;
    NSUInteger count = [self numberOfFilteredThreads];
    NSUInteger start = 0;
    if (currentIndex != NSNotFound) {
        start = currentIndex + 1;
    }
    NSUInteger i;
    NSString *path = nil;
    NSUInteger mask = maskForNextUpdatedThread();
    for (i = start; i < count; i++) {
        item = [[self filteredThreads] objectAtIndex:i];
        ThreadStatus status = [item status];
        if (status & mask) {
            path = [[item threadFilePath] copy];
            break;
        }
    }
    if (!path && (start != 0)) {
        for (i = 0; i < start; i++) {
            item = [[self filteredThreads] objectAtIndex:i];
            ThreadStatus status = [item status];
            if (status & mask) {
                path = [[item threadFilePath] copy];
                break;
            }
        }
    }
    if (!path) {
        return NSNotFound;
    }
    NSUInteger returnValue = [self indexOfThreadWithPath:path ignoreFilter:NO];
    [path release];
    return returnValue;
}

#pragma mark## DataSource ##
- (NSDictionary *)paragraphStyleAttrForIdentifier:(NSString *)identifier
{
	static NSMutableParagraphStyle *style_ = nil;
	
	NSDictionary *result = nil;
	
	if (!style_) {
		// 長過ぎる内容を「...」で省略
		style_ = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
		[style_ setLineBreakMode:NSLineBreakByTruncatingTail];
	}

	if ([identifier isEqualToString:ThreadPlistIdentifierKey]) {
		result = [[self class] threadCreatedDateAttrTemplate];
	} else if ([identifier isEqualToString:LastWrittenDateColumn]) {
		result = [[self class] threadLastWrittenDateAttrTemplate];
	} else if ([identifier isEqualToString:CMRThreadModifiedDateKey]) {
		result = [[self class] threadModifiedDateAttrTemplate];
	} else {
		result = [NSDictionary dictionaryWithObjectsAndKeys:style_, NSParagraphStyleAttributeName, nil];
	}

	return result;
}

- (NSDictionary *)threadAttributesAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView
{
	BSThreadListItem *row;
	
	@synchronized(mCursorLock) {
		row = [[[[self filteredThreads] objectAtIndex:rowIndex] retain] autorelease];
	}
	
	return [row attribute];
}

- (NSUInteger)threadLabelAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView
{
	BSThreadListItem *item;
	@synchronized(mCursorLock) {
		item = [[self filteredThreads] objectAtIndex:rowIndex];
	}
	return [item label];
}

- (BOOL)isThreadLogCachedAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView label:(NSUInteger *)label
{
    BSThreadListItem *item = [[self filteredThreads] objectAtIndex:rowIndex];
    if (label != NULL) {
        *label = [item label];
    }
    return (([item status] & ThreadLogCachedStatus) > 0);
}

- (BOOL)isThreadLogCachedAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView isDatOchi:(BOOL *)datOchiFlag
{
    BSThreadListItem *item = [[self filteredThreads] objectAtIndex:rowIndex];
    if (datOchiFlag != NULL) {
        *datOchiFlag = [item isDatOchi];
    }
    return (([item status] & ThreadLogCachedStatus) > 0);
}

- (NSIndexSet *)indexesOfFilePathsArray:(NSArray *)filepaths ignoreFilter:(BOOL)flag
{
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];

    NSUInteger result;
    CMRDocumentFileManager *dfm = [CMRDocumentFileManager defaultManager];
    NSArray *threads = flag ? mCursor : [self filteredThreads];

    NSString *identifier;

    @synchronized(mCursorLock) {
        for (NSString *path in filepaths) {
            identifier = [dfm datIdentifierWithLogPath:path];
            result = indexOfIdentifier(threads, identifier);
            if (result != NSNotFound) {
                [set addIndex:result];
            }
        }
    }

    return set;
}

- (NSUInteger)indexOfThreadWithPath:(NSString *)filepath ignoreFilter:(BOOL)ignores
{
	NSUInteger result;
	CMRDocumentFileManager *dfm = [CMRDocumentFileManager defaultManager];
	NSString *identifier = [dfm datIdentifierWithLogPath:filepath];
	
	@synchronized(mCursorLock) {
		if (ignores) {
			result = indexOfIdentifier(mCursor, identifier);
		} else {
			result = indexOfIdentifier([self filteredThreads], identifier);
		}
	}
	
	return result;
}

- (NSUInteger)indexOfThreadWithPath:(NSString *)filepath
{
	return [self indexOfThreadWithPath:filepath ignoreFilter:NO];
}

- (CMRThreadSignature *)threadSignatureWithTitle:(NSString *)title
{
	BSThreadListItem *row;

	@synchronized(mCursorLock) {
		row = itemOfTitle(mCursor, title);
	}
	
	if (!row) {
		return nil;
	}
	return [CMRThreadSignature threadSignatureWithIdentifier:[row identifier] boardName:[self boardName]];		
}
- (void)tableView:(NSTableView *)aTableView removeFromDBAtRowIndexes:(NSIndexSet *)rowIndexes
{
    NSUInteger index = [rowIndexes firstIndex];
	BSThreadListItem *row;
	
	@synchronized(mCursorLock) {
		row = [[[[self filteredThreads] objectAtIndex:index] retain] autorelease];
	}
    NSString *identifier = [row identifier];
    NSUInteger boardID = [row boardID];
    
    [[DatabaseManager defaultManager] removeThreadOfIdentifier:identifier atBoard:boardID];
}

- (void)tableView:(NSTableView *)aTableView setLabel:(NSUInteger)label atRowIndexes:(NSIndexSet *)rowIndexes
{
    // データベースおよびログファイルの更新
    NSArray *foo = [self tableView:aTableView threadFilePathsArrayAtRowIndexes:rowIndexes];
    for (NSString *path in foo) {
        NSURL *bar = [NSURL fileURLWithPath:path];
        id doc = [[CMRDocumentController sharedDocumentController] documentAlreadyOpenForURL:bar];
        if (doc) {
            [doc setLabelOfThread:label toggle:NO];
        } else {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfURL:bar];
            if (!dict) {
                NSLog(@"no dict %@", path);
                continue;
            }
            CMRThreadAttributes *attr = [[CMRThreadAttributes alloc] initWithDictionary:dict];
            [attr setLabel:label];
            [attr writeAttributes:dict];
            [attr release];
            [dict writeToURL:bar atomically:YES];
        }
    }
    // 表示上の更新
    NSArray *threadsListItems = [[self filteredThreads] objectsAtIndexes:rowIndexes];
    for (BSThreadListItem *item in threadsListItems) {
        if (([item status] & ThreadNoCacheStatus) > 0) {
            NSLog(@"throughing %@", [item threadName]);
            continue;
        }
        [item setValue:[NSString stringWithFormat:@"%lu", (unsigned long)label] forKey:ThreadLabelColumn];
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:rowIndexes forKey:@"Indexes"];
    UTILNotifyInfo(BSDBThreadListWantsPartialReloadNotification, userInfo);
}

- (void)tableView:(NSTableView *)aTableView setIsDatOchi:(BOOL)flag atRowIndexes:(NSIndexSet *)rowIndexes
{
    // データベースおよびログファイルの更新
    NSArray *foo = [self tableView:aTableView threadFilePathsArrayAtRowIndexes:rowIndexes];
    for (NSString *path in foo) {
        NSURL *bar = [NSURL fileURLWithPath:path];
        id doc = [[CMRDocumentController sharedDocumentController] documentAlreadyOpenForURL:bar];
        if (doc) {
            [doc setIsDatOchiThread:flag];
        } else {
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfURL:bar];
            if (!dict) {
                NSLog(@"no dict %@", path);
                continue;
            }
            CMRThreadAttributes *attr = [[CMRThreadAttributes alloc] initWithDictionary:dict];
            [attr setIsDatOchiThread:flag];
            [attr writeAttributes:dict];
            [attr release];
            [dict writeToURL:bar atomically:YES];
        }
    }
    // 表示上の更新
    NSArray *threadsListItems = [[self filteredThreads] objectsAtIndexes:rowIndexes];
    for (BSThreadListItem *item in threadsListItems) {
        if (([item status] & ThreadNoCacheStatus) > 0) {
            NSLog(@"throughing %@", [item threadName]);
            continue;
        }
        [item setValue:flag ? @"1" : @"0" forKey:IsDatOchiColumn];
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:rowIndexes forKey:@"Indexes"];
    UTILNotifyInfo(BSDBThreadListWantsPartialReloadNotification, userInfo);    
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	UTILDebugWrite1(@"numberOfRowsInTableView -> %ld", [self numberOfFilteredThreads]);
	
	return [self numberOfFilteredThreads];
}

static NSString *labelNameForCode(NSUInteger num)
{
    if (num < 1 || num > 7) {
        return @"--";
    }
    return [[[BSLabelManager defaultManager] displayNames] objectAtIndex:(num - 1)];
}

- (id)objectValueForIdentifier:(NSString *)identifier atIndex:(NSInteger)index
{
	BSThreadListItem *row;
	id result = nil;
	ThreadStatus s;
	
	@synchronized(mCursorLock) {
		row = [[[[self filteredThreads] objectAtIndex:index] retain] autorelease];
	}
	
	s = [row status];
	
	if ([identifier isEqualTo:CMRThreadSubjectIndexKey]) {
		result = [row threadNumber];
		if(!result || result == [NSNull null]) {
			result = [NSNumber numberWithInteger:index + 1];
		}
	} else if ([identifier isEqualTo:BSThreadEnergyKey]) {
		result = [row valueForKey:identifier];
        if (!result) {
            if ([CMRPref energyUsesLevelIndicator]) {
                return [NSNumber numberWithDouble:0];
            }
        }
		UTILAssertKindOfClass(result, NSNumber);

		if ([CMRPref energyUsesLevelIndicator]) {
			double ikioi = [result doubleValue];
			ikioi = log(ikioi); // 対数を取る事で、勢いのむらを少なくする
			if (ikioi < 0) ikioi = 0;
			return [NSNumber numberWithDouble:ikioi];
		}
    } else if ([identifier isEqualTo:BSThreadLabelKey]) {
        result = labelNameForCode([row label]);
    } else if ([identifier isEqualTo:CMRThreadStatusKey]) {
        return [row statusImage];
	} else {
		result = [row valueForKey:identifier];
	}

	// パラグラフスタイルを設定。
	if (result && ![result isKindOfClass:[NSImage class]]) {
		id attr = [self paragraphStyleAttrForIdentifier:identifier];
		if ([result isKindOfClass:[NSDate class]]) {
			result = [[BSDateFormatter sharedDateFormatter] attributedStringForObjectValue:result withDefaultAttributes:attr];
		} else if ([result isKindOfClass:[NSNumber class]]) {
			result = [[BSIkioiNumberFormatter sharedIkioiNumberFormatter] attributedStringForObjectValue:result withDefaultAttributes:attr];
		} else {
			result = [[[NSMutableAttributedString alloc] initWithString:[result stringValue] attributes:attr] autorelease];
		}
	}
	
	// Font and Color を設定。
	NSInteger type = (s == ThreadNewCreatedStatus) 
		? kValueTemplateNewArrivalType
		: kValueTemplateDefaultType;
	if ([row isDatOchi]) {
		type = kValueTemplateDatOchiType;
	}
	result = [[self class] objectValueTemplate:result forType:type];

	return result;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString		*identifier_ = [aTableColumn identifier];
	
    if ([identifier_ isEqualToString:ThreadPlistIdentifierKey] ||
        [identifier_ isEqualToString:CMRThreadModifiedDateKey] || [identifier_ isEqualToString:LastWrittenDateColumn])
    {
        CGFloat location_ = [aTableColumn width];
        location_ -= [aTableView intercellSpacing].width * 2;
        [[self class] resetDataSourceTemplateForColumnIdentifier:identifier_ width:location_];
    }

	return [self objectValueForIdentifier:identifier_ atIndex:rowIndex];
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	UTILDebugWrite(@"Received tableView:sortDescriptorsDidChange: message");
    NSIndexSet *indexes = [aTableView selectedRowIndexes];
    NSIndexSet *newIndexes = nil;
    NSArray *tmpPaths = [self tableView:aTableView threadFilePathsArrayAtRowIndexes:indexes];

	[self setSortDescriptors:[aTableView sortDescriptors]];
	[self sortByDescriptors];
	[aTableView reloadData];

    if ([tmpPaths count] > 0) {
        newIndexes = [self indexesOfFilePathsArray:tmpPaths ignoreFilter:NO];
    }

    if ([newIndexes count] > 0) {
        [aTableView selectRowIndexes:newIndexes byExtendingSelection:NO];
    }
}

#pragma mark## Notification ##
- (void)favoritesManagerDidChange:(NSNotification *)notification
{
	UTILAssertNotificationObject(
								 notification,
								 [CMRFavoritesManager defaultManager]);
    if ([self isFavorites]) {
        [self updateCursor];
	}
//	UTILNotifyName(CMRThreadsListDidChangeNotification);
}

- (void)threadLabelDidChange:(NSNotification *)notification
{
    if ([self isSmartItem]) {
        id conditions = [(SmartBoardListItem *)[self boardListItem] condition];
        NSString *conditionString = [conditions description];
        if (conditionString && ([conditionString rangeOfString:@"threadLabel" options:NSLiteralSearch].location != NSNotFound)) {
            [self updateCursor];
        }
    }
}
/*
- (id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
	BSThreadListItem *rowItem;	
	@synchronized(mCursorLock) {
		rowItem = [[[[self filteredThreads] objectAtIndex:row] retain] autorelease];
	}
	return rowItem;
}            
*/
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSArray *threadListItems;
    @synchronized(mCursorLock) {
        threadListItems = [[[self filteredThreads] objectsAtIndexes:rowIndexes] copy];
    }
    [pboard clearContents];
    [pboard writeObjects:threadListItems];
    [threadListItems release];
    return YES;
}

#pragma mark## SearchThread ##
+ (NSMutableDictionary *)attributesForThreadsListWithContentsOfFile:(NSString *)filePath
{
	return [[[[BSThreadListItem threadItemWithFilePath:filePath] attribute] mutableCopy] autorelease];
}
@end

@implementation BSDBThreadList(ToBeRefactoring)
#pragma mark## Download ##
- (void)loadAndDownloadThreadsList:(CMRThreadLayout *)worker forceDownload:(BOOL)forceDL rebuild:(BOOL)flag
{
	//　既に起動中の更新タスクを強制終了させる
	[mTaskLock lock];
	if (mTask) {
		if ([mTask isInProgress]) {
			[mTask cancel:self];
		}
		[mTask release];
		mTask = nil;
	}
	[mTaskLock unlock];
	
	Class dlTaskClass = Nil;
	if ([self isFavorites] || [self isSmartItem]) {
		dlTaskClass = [BSSmartBoardUpdateTask class];
	} else {
		dlTaskClass = [BSThreadsListOPTask class];
	}
	[mTaskLock lock];
	mTask = [[dlTaskClass alloc] initWithThreadList:self forceDownload:forceDL rebuild:flag];
	[self pushIfCanExcute:mTask];
	[mTaskLock unlock];
}

- (void)doLoadThreadsList:(CMRThreadLayout *)worker
{
	[self setWorker:worker]; // ????
	[self loadAndDownloadThreadsList:worker forceDownload:NO rebuild:NO];
}

- (void)downloadThreadsList
{
	[self loadAndDownloadThreadsList:[self worker] forceDownload:YES rebuild:NO];
}

- (void)rebuildThreadsList
{
	NSUInteger boardId = [[self boardListItem] boardID];
//	if (![[DatabaseManager defaultManager] deleteAllRecordsOfBoard:boardId]) {
//		return;
//	}
    [[DatabaseManager defaultManager] createRebuildTempTableForBoardID:[NSNumber numberWithUnsignedInteger:boardId]];
    [[DatabaseManager defaultManager] deleteAllRecordsOfBoard:boardId];


	[self loadAndDownloadThreadsList:[self worker] forceDownload:YES rebuild:YES];
}


- (void)pushIfCanExcute:(id <CMRTask>)task
{
	if(![task respondsToSelector:@selector(executeWithLayout:)]) {
		NSLog(@"%s, %@<%p> dose not respond to -executeWithLayout:.",
			  __PRETTY_FUNCTION__,
			  NSStringFromClass([task class]), task);
		return;
	}
	[[self worker] push:(id<CMRThreadLayoutTask>)task];
}
@end


@implementation BSDBThreadList(DataSource)
@end
