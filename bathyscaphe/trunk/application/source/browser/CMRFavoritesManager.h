//
//  CMRFavoritesManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/09.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class CMRThreadSignature;

enum {
	CMRFavoritesOperationNone,
	CMRFavoritesOperationLink,
	CMRFavoritesOperationRemove
};
typedef NSUInteger CMRFavoritesOperation;


@interface CMRFavoritesManager : NSObject
{
//    @private
//    NSUInteger availableHEADCheckCount;
//    NSDate *firstHEADCheckedDate;
}
+ (id)defaultManager;

- (CMRFavoritesOperation)availableOperationWithPath:(NSString *)filepath;
- (CMRFavoritesOperation)availableOperationWithSignature:(CMRThreadSignature *)signature;

- (BOOL)canCreateFavoriteLinkFromPath:(NSString *)filepath;
- (BOOL)favoriteItemExistsOfThreadPath:(NSString *)filepath;
- (BOOL)favoriteItemExistsOfThreadSignature:(CMRThreadSignature *)signature;

- (BOOL)addFavoriteWithSignature:(CMRThreadSignature *)signature;
- (BOOL)removeFromFavoritesWithSignature:(CMRThreadSignature *)signature;
@end


/*@interface CMRFavoritesManager(HEADCheckLimit)
- (void)decrementHEADCheckCount;
- (BOOL)canHEADCheck:(NSError **)errorPtr;
@end*/


extern NSString *const CMRFavoritesManagerDidLinkFavoritesNotification;
extern NSString *const CMRFavoritesManagerDidRemoveFavoritesNotification;
