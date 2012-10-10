//
//  CMRHistoryManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/06/12.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CocoMonar_Prefix.h"
#import "CMRHistoryObject.h"


enum {
    CMRHistoryNoTypeAssignedType = -1,
    CMRHistoryBoardEntryType,
    CMRHistoryThreadEntryType,
    CMRHistoryCountOfEntriesType,
};
typedef NSInteger CMRHistoryItemType;

//
// ツールバーに使用するためにNSCodingが必要
//
@interface CMRHistoryItem : NSObject<CMRPropertyListCoding, NSCoding>
{
    @private
    CMRHistoryItemType _type;
    NSUInteger _visitedCount;
    NSString *_title;
    NSDate *_date;
    id<CMRHistoryObject> _representedObject;
}
- (id)initWithTitle:(NSString *)aTitle type:(CMRHistoryItemType)aType;

@property(readwrite, assign) CMRHistoryItemType historyType;
@property(readwrite, retain) NSString *historyTitle;
@property(readwrite, retain) NSDate *historyDate;
@property(readwrite, assign) NSUInteger visitedCount;

- (id<CMRHistoryObject>)representedObject;
- (BOOL)hasRepresentedObject:(id)anObject;
- (void)setRepresentedObject:(id<CMRHistoryObject>)aRepresentedObject;

- (void)incrementVisitedCount;

- (NSComparisonResult)_compareByDate:(CMRHistoryItem *)anObject;
@end


@interface CMRHistoryManager : NSObject<NSMenuDelegate>
{
    @private
    id *_backets;
}
+ (CMRHistoryManager *) defaultManager;

- (void)loadDictionaryRepresentation:(NSDictionary *)aDictionary;
- (NSDictionary *)dictionaryRepresentation;
- (void)removeAllItems;

- (NSArray *)historyItemArrayForType:(CMRHistoryItemType) aType;

- (void)addItem:(CMRHistoryItem *) anItem;
- (CMRHistoryItem *)addItemWithTitle:(NSString *)aTitle
                                type:(CMRHistoryItemType)aType
                              object:(id)aRepresentedObject;

- (void)removeItemForType:(CMRHistoryItemType)aType atIndex:(NSUInteger)anIndex;
@end
