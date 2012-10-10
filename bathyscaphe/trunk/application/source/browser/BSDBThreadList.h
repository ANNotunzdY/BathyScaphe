//
//  BSDBThreadList.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/19.
//  Copyright 2005-2008 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CMRThreadsList.h"

#import <SQLiteDB.h>

#import "CMRTask.h"

@class BoardListItem, BSThreadListItem;

@interface BSDBThreadList : CMRThreadsList<BSThreadsListDataSource>
{
	id mCursor;
	NSLock *mCursorLock;
		
	BoardListItem *mBoardListItem;
	NSString *mSearchString;
	
	id<CMRTask> mTask;
	NSLock *mTaskLock;
	
	id<CMRTask> mUpdateTask;
	
	NSArray *mSortDescriptors;

    NSError *rebuildError;
}

- (id)initWithBoardListItem:(BoardListItem *)item;
+ (id)threadListWithBoardListItem:(BoardListItem *)item;

- (void)setBoardListItem:(BoardListItem *)item;
- (id)boardListItem;

- (id)searchString;
- (NSArray *)sortDescriptors;
- (void)setSortDescriptors:(NSArray *)inDescs;

- (BSThreadsListViewModeType)viewMode;
- (void)setViewMode:(BSThreadsListViewModeType)mode;

- (void)updateCursor;
- (void)updateFilteredThreadsIfNeeded;

- (NSUInteger)indexOfNextUpdatedThread:(NSUInteger)currentIndex;

- (void)updateThreadItem:(NSDictionary *)userInfo; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.
- (void)cleanUpThreadItem:(NSArray *)threadFilePaths; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.
- (void)toggleDatOchiThreadItemWithPath:(NSString *)path; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.
// Available in BathyScaphe 2.0 "Final Moratorium" and later.
- (void)setLabel:(NSUInteger)label forThreadItemWithPath:(NSString *)path;

@property(readwrite, retain) NSError *rebuildError;
@end

extern NSString *BSDBThreadListDidFinishUpdateNotification;
extern NSString *BSDBThreadListWantsPartialReloadNotification; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.
