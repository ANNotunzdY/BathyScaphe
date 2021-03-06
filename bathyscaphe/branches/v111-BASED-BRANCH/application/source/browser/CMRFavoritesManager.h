/**
  * $Id: CMRFavoritesManager.h,v 1.3.2.2 2006-09-01 13:46:54 masakih Exp $
  *
  * Copyright (c) 2005 BathyScaphe Project. All rights reserved.
  */

#import <Foundation/Foundation.h>


typedef enum {
	CMRFavoritesOperationNone,
	CMRFavoritesOperationLink,
	CMRFavoritesOperationRemove
} CMRFavoritesOperation;


@interface CMRFavoritesManager : NSObject
{
	NSMutableArray	*_favoritesItemsArray;
	NSMutableArray	*_favoritesItemsIndex;
	NSMutableArray	*_changedFavItemsPool;
}

+ (id) defaultManager;
/*
- (NSMutableArray *) favoritesItemsArray;
- (void) setFavoritesItemsArray : (NSMutableArray *) anArray;
- (NSMutableArray *) favoritesItemsIndex;
- (void) setFavoritesItemsIndex : (NSMutableArray *) anArray;

- (NSMutableArray *) changedFavItemsPool;
- (void) setChangedFavItemsPool : (NSMutableArray *) anArray;

- (NSMutableArray *) itemsForRemoving;
- (NSMutableArray *) itemsForChange;
*/
//@end



//@interface CMRFavoritesManager(Management)
- (CMRFavoritesOperation) availableOperationWithThread: (id) threadIdentifier ofBoard: (NSString *) boardName;
//- (CMRFavoritesOperation) availableOperationWithPath : (NSString *) filepath;
//- (BOOL) canCreateFavoriteLinkFromPath : (NSString *) filepath;
//- (BOOL) favoriteItemExistsOfThreadPath : (NSString *) filepath;
/*
- (BOOL) addFavoriteWithThread : (NSDictionary *) thread;
- (BOOL) addFavoriteWithFilePath : (NSString *) filepath;
- (BOOL) removeFromFavoritesWithThread : (NSDictionary *) thread;
- (BOOL) removeFromFavoritesWithFilePath : (NSString *) filepath;
*/
- (BOOL) addFavoriteWithThread: (id) threadIdentifier ofBoard: (NSString *) boardName;
- (BOOL) removeFavoriteWithThread: (id) threadIdentifier ofBoard: (NSString *) boardName;

//- (void) removeFromFavoritesWithPathArray : (NSArray *) pathArray_;
/*
- (int) insertFavItemsTo : (int) index withIndexArray : (NSArray *) indexArray_ isAscending : (BOOL) isAscending_;

- (void) addItemToPoolWithFilePath : (NSString *) filepath;
- (void) removeFromPoolWithFilePath : (NSString *) filepath;
*/
@end



/**
  * userInfo:
  * 	@"File"	-- filepath to be performed (NSString)
  *
  */
#define kAppFavoritesManagerInfoFilesKey	@"File"

extern NSString *const CMRFavoritesManagerDidLinkFavoritesNotification;
extern NSString *const CMRFavoritesManagerDidRemoveFavoritesNotification;
