/**
  * $Id: CMRFavoritesManager.m,v 1.10 2006-01-05 14:16:44 tsawada2 Exp $
  *
  * Copyright (c) 2005 BathyScaphe Project. All rights reserved.
  */

#import "CMRFavoritesManager.h"
#import "CocoMonar_Prefix.h"

#import "CMRThreadAttributes.h"
#import "CMRThreadsList_p.h"
#import <AppKit/NSDocumentController.h>

NSString *const CMRFavoritesManagerDidLinkFavoritesNotification = @"CMRFavoritesManagerDidLinkFavoritesNotification";
NSString *const CMRFavoritesManagerDidRemoveFavoritesNotification = @"CMRFavoritesManagerDidRemoveFavoritesNotification";

@implementation CMRFavoritesManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

+ (NSString *) defaultFilepath
{
	return [[CMRFileManager defaultManager]
				 supportFilepathWithName : CMRFavoritesFile
						resolvingFileRef : NULL];
}

// 暫定
+ (NSString *) subFilepath
{
	return [[CMRFileManager defaultManager]
				 supportFilepathWithName : CMRFavMemoFile
						resolvingFileRef : NULL];
}

- (id) init
{
	if (self = [super init]) {
		[[NSNotificationCenter defaultCenter]
				 addObserver : self
					selector : @selector(applicationWillTerminate:)
					    name : NSApplicationWillTerminateNotification
					  object : NSApp];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver : self];
	[_favoritesItemsArray release];
	[_favoritesItemsIndex release];
	[_changedFavItemsPool release];
	[super dealloc];
}

- (void) applicationWillTerminate : (NSNotification *) notification
{	
	UTILAssertNotificationName(
		notification,
		NSApplicationWillTerminateNotification);
	UTILAssertNotificationObject(
		notification,
		NSApp);	
	
	[[self favoritesItemsArray] writeToFile : [[self class] defaultFilepath]
								 atomically : YES];
	[[self changedFavItemsPool] writeToFile : [[self class] subFilepath]
								 atomically : YES];

}

#pragma mark -

- (NSMutableArray *) favoritesItemsArray
{
	if (nil == _favoritesItemsArray) {
		_favoritesItemsArray = [[NSMutableArray alloc] initWithContentsOfFile : 
														[[self class] defaultFilepath]];
	}
	if (nil == _favoritesItemsArray) {
		_favoritesItemsArray = [[NSMutableArray alloc] init];
	}
	
	return _favoritesItemsArray;
}

- (void) setFavoritesItemsArray : (NSMutableArray *) anArray
{
	id		tmp;
	
	tmp = _favoritesItemsArray;
	_favoritesItemsArray = [anArray retain];
	[tmp release];
}

- (NSMutableArray *) favoritesItemsIndex
{
	if (nil == _favoritesItemsIndex) {
		NSMutableArray	*favItems_ = [self favoritesItemsArray];

		if ([favItems_ count] == 0) {
			_favoritesItemsIndex = [[NSMutableArray alloc] init];
		} else {
			NSEnumerator	*iter_;
			NSDictionary	*anItem_;	// each favorite item
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // 2005-12-04 どうだろう？

			_favoritesItemsIndex = [[NSMutableArray alloc] initWithCapacity : [favItems_ count]];

			iter_ = [favItems_ objectEnumerator];

			while ((anItem_ = [iter_ nextObject]) != nil) {
				id	itemPath_;
				itemPath_ = [CMRThreadAttributes pathFromDictionary : anItem_];
				UTILAssertNotNil(itemPath_);

				[_favoritesItemsIndex addObject : itemPath_];
			}
			
			[pool release];
		}
	}
	
	return _favoritesItemsIndex;
}

- (void) setFavoritesItemsIndex : (NSMutableArray *) anArray
{
	id		tmp;
	
	tmp = _favoritesItemsIndex;
	_favoritesItemsIndex = [anArray retain];
	[tmp release];
}

// このへん、暫定的な実装
- (NSMutableArray *) changedFavItemsPool
{
	if (nil == _changedFavItemsPool) {
		_changedFavItemsPool = [[NSMutableArray alloc] initWithContentsOfFile : 
														[[self class] subFilepath]];
	}
	if (nil == _changedFavItemsPool) {
		_changedFavItemsPool = [[NSMutableArray alloc] initWithCapacity : 50];
	}
	
	return _changedFavItemsPool;
}

- (void) setChangedFavItemsPool : (NSMutableArray *) anArray
{
	id		tmp;
	
	tmp = _changedFavItemsPool;
	_changedFavItemsPool = [anArray retain];
	[tmp release];
}

- (NSMutableArray *) itemsForRemoving
{
	NSEnumerator	*iter_;
	NSString		*anItem_;	// each pool item
	
	NSArray			*tmp_ = [self favoritesItemsIndex];
	NSFileManager	*dFM_ = [NSFileManager defaultManager];
	
	NSMutableArray	*array_ = [NSMutableArray array];

	iter_ = [[self changedFavItemsPool] objectEnumerator];
	
	while ((anItem_ = [iter_ nextObject]) != nil) {
		if ((![tmp_ containsObject : anItem_]) || (![dFM_ fileExistsAtPath : anItem_]))
			[array_ addObject : anItem_];
	}

	return array_;
}

- (NSMutableArray *) itemsForChange
{
	NSEnumerator	*iter_;
	NSString		*anItem_;	// each pool item
	
	NSArray			*tmp_ = [self favoritesItemsIndex];
	
	NSMutableArray	*array_ = [NSMutableArray array];

	iter_ = [[self changedFavItemsPool] objectEnumerator];
	
	while ((anItem_ = [iter_ nextObject]) != nil) {
		if ([tmp_ containsObject : anItem_])
			[array_ addObject : anItem_];
	}

	return array_;
}
@end

#pragma mark -

@implementation CMRFavoritesManager(Management)
- (CMRFavoritesOperation) availableOperationWithPath : (NSString *) filepath
{
	NSString	*fileType_;
	
	if(nil == filepath) return NO;
	
	if([[self favoritesItemsIndex] containsObject : filepath])
		return CMRFavoritesOperationRemove;

	if(NO == [[NSFileManager defaultManager] fileExistsAtPath : filepath]) {
		//if([[self favoritesItemsIndex] containsObject : filepath])
		//	return CMRFavoritesOperationRemove;
		//else
			return CMRFavoritesOperationNone;
	}
	
	fileType_ = [[NSDocumentController sharedDocumentController] typeFromFileExtension : [filepath pathExtension]];
	
	return [fileType_ isEqualToString : CMRThreadDocumentType]
				? CMRFavoritesOperationLink
				: CMRFavoritesOperationNone;
}

- (BOOL) canCreateFavoriteLinkFromPath : (NSString *) filepath
{
	return (CMRFavoritesOperationLink == [self availableOperationWithPath : filepath]);
}

- (BOOL) favoriteItemExistsOfThreadPath : (NSString *) filepath
{
	UTILAssertNotNil(filepath);
	return [[self favoritesItemsIndex] containsObject : filepath];
}
	
- (BOOL) addFavoriteWithThread : (NSDictionary *) thread
{
	NSString	*path_;
	if(nil == thread) return NO;

	path_ = [CMRThreadAttributes pathFromDictionary : thread];
	if(path_ == nil || NO == [self canCreateFavoriteLinkFromPath : path_]) return NO;
	
	[[self favoritesItemsArray] addObject : thread];
	[[self favoritesItemsIndex] addObject : path_];
	
	// write Now
	[[self favoritesItemsArray] writeToFile : [[self class] defaultFilepath]
								 atomically : YES];

	UTILNotifyInfo3(
		CMRFavoritesManagerDidLinkFavoritesNotification,
		path_,
		kAppFavoritesManagerInfoFilesKey);
			
	return YES;
}

- (BOOL) addFavoriteWithFilePath : (NSString *) filepath
{
	NSDictionary	*attr_;
	
	if(filepath == nil || NO == [self canCreateFavoriteLinkFromPath : filepath]) return NO;
	
	attr_ = [CMRThreadsList attributesForThreadsListWithContentsOfFile : filepath];
	if (attr_ == nil) return NO;
	
	return [self addFavoriteWithThread : attr_];
}

- (BOOL) removeFromFavoritesWithThread : (NSDictionary *) thread
{
	NSString *path_;
	if (nil == thread) return NO;
	
	path_ = [CMRThreadAttributes pathFromDictionary : thread];
	return [self removeFromFavoritesWithFilePath : path_];
}

- (BOOL) removeFromFavoritesWithFilePath : (NSString *) filepath
{
	int				idx_;

	if (nil == filepath) return NO;
	
	idx_ = [[self favoritesItemsIndex] indexOfObject : filepath];
	if (idx_ == NSNotFound) return NO;

	[[self favoritesItemsArray] removeObjectAtIndex : idx_];
	[[self favoritesItemsIndex] removeObjectAtIndex : idx_];

	UTILNotifyInfo3(
		CMRFavoritesManagerDidRemoveFavoritesNotification,
		filepath,
		kAppFavoritesManagerInfoFilesKey);

	return YES;
}

- (void) removeFromFavoritesWithPathArray : (NSArray *) pathArray_
{
	NSEnumerator	*iter_;
	NSString		*aPath_;

	if (nil == pathArray_ || [pathArray_ count] == 0 ) return;
	iter_ = [pathArray_ objectEnumerator];

	while ((aPath_ = [iter_ nextObject]) != nil) {
		if ([[self favoritesItemsIndex] containsObject : aPath_]) {
			[self removeFromFavoritesWithFilePath : aPath_];
		}
	}
}

#pragma mark -

- (int) insertFavItemsTo : (int) index withIndexArray : (NSArray *) indexArray_ isAscending : (BOOL) isAscending_
{
	NSEnumerator	*iter_;
	NSNumber		*num;
	int				c;
	
	NSMutableArray	*insertArray_;
	NSMutableArray	*aboveArray_;
	NSMutableArray	*belowArray_;

	NSArray			*originalArray_ = [self favoritesItemsArray];

	NSMutableArray	*newFavAry_;
	
	if (indexArray_ == nil || [indexArray_ count] == 0) return index;
	c = [[self favoritesItemsArray] count];
	
	index = isAscending_ ? index : (c - index); 
	
	insertArray_ = [NSMutableArray arrayWithCapacity : c];
	
	aboveArray_ = [NSMutableArray arrayWithArray : 
								[originalArray_ subarrayWithRange : NSMakeRange(0, index)]];
	belowArray_ = [NSMutableArray arrayWithArray :
								[originalArray_ subarrayWithRange : NSMakeRange(index, (c - index))]];
	
	iter_ = isAscending_ ? [indexArray_ objectEnumerator] : [indexArray_ reverseObjectEnumerator];
	
	while ((num = [iter_ nextObject]) != nil) {
		id	favItem;
		int	n = [num intValue];
		favItem = isAscending_ ? [originalArray_ objectAtIndex : n]
							   : [originalArray_ objectAtIndex : ((c - n) - 1)];

		[insertArray_ addObject : favItem];
		[aboveArray_ removeObject : favItem];
		[belowArray_ removeObject : favItem];
	}
	
	newFavAry_ = [[NSMutableArray alloc] initWithCapacity : c];
	[newFavAry_ addObjectsFromArray : aboveArray_];
	[newFavAry_ addObjectsFromArray : insertArray_];
	[newFavAry_ addObjectsFromArray : belowArray_];
	
	[self setFavoritesItemsArray : newFavAry_];
	[newFavAry_ release];

	// 手抜き
	[self setFavoritesItemsIndex : nil];
	[self favoritesItemsIndex];
	
	return isAscending_ ? [aboveArray_ count] : [belowArray_ count];
}

#pragma mark -

//暫定実装
- (void) addItemToPoolWithFilePath : (NSString *) filepath
{
	if (filepath == nil) return;

	// 何らかの理由で既に登録されている場合は、登録しない
	if ([[self changedFavItemsPool] containsObject : filepath]) return;
	
	// 保持数の上限を超えた場合は一番古いものを削除（パフォーマンスとの兼ね合い）
	// SledgeHammer : 上限 50 に固定
    if ([[self changedFavItemsPool] count] > 50) {
		[[self changedFavItemsPool] removeObjectAtIndex : 0];
	}
	
	[[self changedFavItemsPool] addObject : filepath];
}

- (void) removeFromPoolWithFilePath : (NSString *) filepath
{	
	if (filepath == nil) return;
	
	[[self changedFavItemsPool] removeObject : filepath];
}
@end
