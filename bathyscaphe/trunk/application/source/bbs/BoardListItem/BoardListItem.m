//
//  BoardListItem.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/16.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//

#import "BoardListItem.h"
#import "ConcreteBoardListItem.h"

#import "DatabaseManager.h"

NSString *BoardListItemUpdateChildrenNotification = @"BoardListItemUpdateChildrenNotification";
NSString *BoardListItemUpdateThreadsNotification = @"BoardListItemUpdateThreadsNotification";

NSString *BSPasteboardTypeBoardListItem = @"jp.tsawada2.BathyScaphe.pasteboard.boardlistitem";

@implementation BoardListItem

+ (id) allocWithZone : (NSZone *) zone
{
	if ([self class] == [BoardListItem class]) {
		return [[ConcreteBoardListItem sharedInstance] retain];
	}
	
	return [super allocWithZone : zone];
}

- (NSUInteger)hash
{
	return _name ? [_name hash] : [super hash];
}

- (NSImage *) icon
{	
	return _icon;
}

- (NSString *)iconBaseName
{
    return @"BoardItem";
}

- (void) setIcon : (NSImage *) icon
{
	id temp = _icon;
	_icon = [icon retain];
	[temp release];
}
- (NSString *) name
{
	return _name;
}
- (void) setName : (NSString *) newName
{
	id temp = _name;
	_name = [newName retain];
	[temp release];
}

- (BOOL) hasURL
{
	return NO;
}
- (NSURL *) url
{
	[self doesNotRecognizeSelector : _cmd];
	
	return nil;
}
- (void) setURLString : (NSString *) urlString
{
	[self doesNotRecognizeSelector : _cmd];
}

- (BOOL) hasChildren
{
	return NO;
}
- (BoardListItem *) parentForItem : (BoardListItem *) item
{
	return nil;
}
- (NSUInteger) numberOfItem
{	
	return 0;
}
- (NSUInteger) indexOfItem : (id) item
{
	return NSNotFound;
}
- (id) itemAtIndex : (NSUInteger) index
{
	[NSException raise:NSRangeException
				format:@"***%s:index (%ld) beyond bounds (0)",sel_getName(_cmd), (long)index];
	return nil;
}
- (NSArray *) items
{
	return [NSArray array];
}
- (id) itemForName : (NSString *) name
{
	return [self itemForName : name deepSearch : NO];
}
- (id) itemForName : (NSString *) name deepSearch : (BOOL) isDeep
{
	return [self itemForName : name ofType : BoardListAnyTypeItem deepSearch : isDeep];
}
- (id) itemForRepresentName : (NSString *) name
{
	return [self itemForRepresentName : name deepSearch : NO];
}
- (id) itemForRepresentName : (NSString *) name deepSearch : (BOOL) isDeep
{
	return [self itemForName : name deepSearch : isDeep];
}
- (id) itemForName : (NSString *)name ofType: (BoardListItemType)type
{
	return [self itemForName : name ofType : type deepSearch : NO];
}

// primitive
- (id) itemForName : (NSString *)name ofType: (BoardListItemType)type deepSearch : (BOOL) isDeep
{
	return nil;
}
- (id) itemForRepresentName : (NSString *)name ofType: (BoardListItemType)type
{
	return [self itemForRepresentName : name ofType : type deepSearch : NO];
}
- (id) itemForRepresentName : (NSString *)name ofType: (BoardListItemType)type deepSearch : (BOOL) isDeep
{
	return [self itemForName : name ofType : type deepSearch : isDeep];
}

// tsawada2 added 2007-02-10
- (id) itemWithRepresentNameHavingPrefix: (NSString *) prefix deepSearch: (BOOL) isDeep // For Type-To-Select search.
{
	return nil;
}

- (NSString *) representName
{
	return [self name];
}
- (void) setRepresentName : (NSString *) newRepresentName
{
	[self setName : newRepresentName];
}

- (id) description
{
	return [super description];
}
- (id)plist
{
	return [NSString stringWithFormat: @"%@ (%p)", NSStringFromClass([self class]), self];
}

#pragma mark## NSCoding protocol ##
- (void) encodeWithCoder : (NSCoder *) aCoder
{
	//
}
- (id) initWithCoder : (NSCoder *) aDecoder
{
	return [self init];
}

#pragma mark## CMRPropertyListCoding protocol ##
+ (id) objectWithPropertyListRepresentation : (id) rep
{
	return [[[self alloc] initWithPropertyListRepresentation : rep] autorelease];
}
- (id) propertyListRepresentation
{
	NSLog(@"Enter <%@ : %p> <%@>", NSStringFromClass ([self class]) , self, NSStringFromSelector (_cmd) );
	[self doesNotRecognizeSelector : _cmd];
	return nil;
}
- (id) initWithPropertyListRepresentation : (id) rep
{
	[self doesNotRecognizeSelector : _cmd];
	
	return nil;
}
- (BOOL) isHistoryEqual : (id) anObject
{
	if ([anObject isEqual : self]) return YES;
	
	if ([anObject isKindOfClass : [self class]]) return YES;
	
	return NO;
}

#ifdef DEBUG
- (id) objectForKey : (id) key
{
	NSLog(@"Enter <%@ : %p> <%@>", NSStringFromClass ([self class]) , self, NSStringFromSelector (_cmd) );
	return nil;
}
#endif

#pragma mark NSPasteboardReading
+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    static NSArray *cachedTypes = nil;
    if (!cachedTypes) {
        cachedTypes = [[NSArray alloc] initWithObjects:BSPasteboardTypeBoardListItem, nil];
    }
    return cachedTypes;
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    if ([type isEqualToString:BSPasteboardTypeBoardListItem]) {
        return NSPasteboardReadingAsPropertyList;
    }
    return NSPasteboardReadingAsData;
}

- (id)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type
{
    if ([type isEqualToString:BSPasteboardTypeBoardListItem]) {
        return [[[self class] baordListItemFromPlist:propertyList] retain];
    }
    return nil;
}

#pragma mark NSPasteboardWriting
// BoardBoardListItem はオーバーライドしているので注意
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    static NSArray *cachedTypes = nil;
    if (!cachedTypes) {
        cachedTypes = [[NSArray alloc] initWithObjects:BSPasteboardTypeBoardListItem, nil];
    }
    return cachedTypes;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    if ([type isEqualToString:BSPasteboardTypeBoardListItem]) {
        return [self plist];
    }
    return nil;
}
@end


@implementation BoardListItem (ThreadsList)

- (id <SQLiteCursor>) cursorForThreadList
{
	return nil;
}
- (NSString *) query
{
	return nil;
}

- (void) postUpdateThreadsNotification
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	[center postNotificationName : BoardListItemUpdateThreadsNotification
						  object : self];
}
	
@end


@implementation BoardListItem (Creation)
+ (id) favoritesItem
{
	return [ConcreteBoardListItem favoritesItem];
}
+ (id) boardListItemWithFolderName : (NSString *) name
{
	return [ConcreteBoardListItem boardListItemWithFolderName : name];
}
+ (id) baordListItemWithBoradID : (NSUInteger) boardID
{
	return [ConcreteBoardListItem baordListItemWithBoradID : boardID];
}
+ (id) boardListItemWithURLString : (NSString *) urlString
{
	return [ConcreteBoardListItem boardListItemWithURLString : urlString];
}
+ (id) baordListItemWithName : (NSString *) name condition : (id) condition
{
	return [ConcreteBoardListItem baordListItemWithName : name condition : condition];
}
+ (id) baordListItemFromPlist : (id) plist
{
	return [ConcreteBoardListItem baordListItemFromPlist : plist];
}
- (id) initForFavorites
{
	NSLog(@"Oh! what do you do?") ;
	
	return nil;
}
- (id) initWithFolderName : (NSString *) name
{
	NSLog(@"Oh! what do you do?") ;
	
	return nil;
}
- (id) initWithBoardID : (NSUInteger) boardID
{
	NSLog(@"Oh! what do you do?") ;
	
	return nil;
}
- (id) initWithURLString : (NSString *) urlString
{
	NSLog(@"Oh! what do you do?") ;
	
	return nil;
}
- (id) initWithName : (NSString *) name condition : (id) condition;
{
	NSLog(@"Oh! what do you do?") ;
	
	return nil;
}
- (id) initWithContentsOfFile : (NSString *) path;
{
	NSLog(@"Oh! what do you do?") ;
	
	return nil;
}

@end

@implementation BoardListItem (TypeCheck)

+ (BOOL) isBoardItem : (BoardListItem *) item
{
	return [ConcreteBoardListItem isBoardItem : item];
}
+ (BOOL) isFavoriteItem : (BoardListItem *) item
{
	return [ConcreteBoardListItem isFavoriteItem : item];
}
+ (BOOL) isFolderItem : (BoardListItem *) item
{
	return [ConcreteBoardListItem isFolderItem : item];
}
+ (BOOL) isSmartItem : (BoardListItem *) item
{
	return [ConcreteBoardListItem isSmartItem : item];
}
+ (BOOL) isCategory : (BoardListItem *) item
{
	return [ConcreteBoardListItem isFolderItem : item];
}

+ (BoardListItemType) typeForItem : (BoardListItem *) item
{
	return [ConcreteBoardListItem typeForItem : item];
}
- (BoardListItemType) type
{
	return [BoardListItem typeForItem : self];
}
@end

@implementation BoardListItem (Mutable)

- (BOOL) isMutable
{
	return NO;
}
- (void) addItem : (BoardListItem *) item
{
	[self doesNotRecognizeSelector : _cmd];
}
- (void) insertItem : (BoardListItem *) item atIndex : (NSUInteger) index
{
	[self doesNotRecognizeSelector : _cmd];
}
- (void) insertItem : (BoardListItem *) item afterItem : (BoardListItem *) object
{
	[self insertItem : item afterItem : object deepSearch : NO];
}
- (void) insertItem : (BoardListItem *) item afterItem : (BoardListItem *) object deepSearch : (BOOL) isDeep
{
	[self doesNotRecognizeSelector : _cmd];
}
- (void) removeItem : (BoardListItem *) item
{
	[self removeItem : item deepSearch : NO];
}
- (void) removeItem : (BoardListItem *) item deepSearch : (BOOL) isDeep
{
	[self doesNotRecognizeSelector : _cmd];
}
- (void) removeItemAtIndex : (NSUInteger) index
{
	[self doesNotRecognizeSelector : _cmd];
}

- (void) postUpdateChildrenNotification
{
	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	[center postNotificationName : BoardListItemUpdateChildrenNotification
						  object : self];
}

@end
