//
//  BSBoardListItemHEADCheckTask.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/13.
//  Copyright 2006,2012 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BSThreadListTask.h"
#import "BSDBThreadList.h"
#import "BoardListItem.h"

@interface BSBoardListItemHEADCheckTask : BSThreadListTask
{
	BSDBThreadList *targetList;
	BoardListItem *item;
	
	NSString *amountString;
	NSString *descString;
}

+ (id)taskWithThreadList:(BSDBThreadList *)list;
- (id)initWithThreadList:(BSDBThreadList *)list;

@end
