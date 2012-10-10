//
//  BSSmartBoardUpdateTask.h
//  BathyScaphe
//
//  Created by 堀 昌樹 on 12/07/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "BSThreadListTask.h"
#import "BSDBThreadList.h"
#import "BoardListItem.h"

@interface BSSmartBoardUpdateTask : BSThreadListTask
{
	BSDBThreadList *_targetList;
	BoardListItem *_item;
	BOOL forceDL;
	
	id <SQLiteCursor> _targetThreads;
	
	NSMutableSet *_boards;
	NSMutableDictionary *_updateData;
	
	NSMutableArray *networkErrors;
}

// rebuild flag is never use.
+ (id)taskWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)forceDL rebuild:(BOOL)flag;
- (id)initWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)forceDL rebuild:(BOOL)flag;

@end
