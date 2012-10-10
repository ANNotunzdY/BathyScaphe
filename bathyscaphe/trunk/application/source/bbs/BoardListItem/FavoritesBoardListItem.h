//
//  FavoritesBoardListItem.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AbstractDBBoardListItem.h"

@interface FavoritesBoardListItem : AbstractDBBoardListItem
{
	id <SQLiteCursor> items;
}

+ (id) sharedInstance;

@end
