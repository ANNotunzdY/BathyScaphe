//
//  SmartBoardListItem.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AbstractDBBoardListItem.h"

@interface SmartBoardListItem : AbstractDBBoardListItem
{
	id mConditions;
}

- (id) initWithName : (NSString *) name condition : (id) condition;

- (id) condition;
- (void) setCondition:(id)condition;

@end
