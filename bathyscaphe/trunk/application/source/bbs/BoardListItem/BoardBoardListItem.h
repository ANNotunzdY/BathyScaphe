//
//  BoardBoardListItem.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AbstractDBBoardListItem.h"

@interface BoardBoardListItem : AbstractDBBoardListItem
{
	NSUInteger boardID;
	NSString *representName;
}

- (id) initWithBoardID : (NSUInteger) boardID;
- (id) initWithURLString : (NSString *) urlString;

- (NSUInteger) boardID;
- (void) setBoardID : (NSUInteger) boardID;

@end
