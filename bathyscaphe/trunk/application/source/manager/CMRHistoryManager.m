//
//  CMRHistoryManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/06/12.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRHistoryManager.h"
#import "CocoMonar_Prefix.h"
#import "AppDefaults.h"
#import "BoardListItem.h"

// assume item is precious if visitedCount >= PreciousItemThreshold
#define PreciousItemThreshold 5

static const NSUInteger kHistoryItemsBacketCount = CMRHistoryCountOfEntriesType;

#pragma mark -

@implementation CMRHistoryManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

+ (NSString *)defaultFilepath
{
    return [[CMRFileManager defaultManager] supportFilepathWithName:CMRHistoryFile resolvingFileRef:NULL];
}

- (id)init
{
    if (self = [super init]) {
        NSString        *filepath_;
        
        filepath_ = [[self class] defaultFilepath];
        UTILAssertNotNil(filepath_);

		NSData			*data;
		NSDictionary	*rep;			
		NSString *errorStr;

		data = [NSData dataWithContentsOfFile:filepath_];
		if (data) {
			rep = [NSPropertyListSerialization propertyListFromData:data
												   mutabilityOption:NSPropertyListImmutable
															 format:NULL
												   errorDescription:&errorStr];
			if (!rep) {
				NSLog(@"CMRHistoryManager failed to read History.plist with NSPropertyListSerialization");
				rep = [NSDictionary dictionaryWithContentsOfFile:filepath_];
			}
		} else {
			rep = [NSDictionary dictionaryWithContentsOfFile:filepath_];
		}
		[self loadDictionaryRepresentation:rep];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:NSApplicationWillTerminateNotification
                                                   object:NSApp];
    }
    return self;
}

- (void)clearHistoryItemsBacket
{
    if (_backets != NULL) {
        NSInteger i;
        NSInteger cnt;

        cnt = kHistoryItemsBacketCount;
        for (i = 0; i < cnt; i++) {
            [_backets[i] release];
        }
        free(_backets);
    }
    _backets = NULL;
}

- (id *)historyItemsBacket
{
    if (NULL == _backets) {
        size_t    size = (kHistoryItemsBacketCount * sizeof(id));

        _backets = malloc(size);
        if (NULL == _backets) {
            [NSException raise:NSGenericException format:@"%@ malloc()", UTIL_HANDLE_FAILURE_IN_METHOD];
        }
        bzero(_backets, size);
    }
    return _backets;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearHistoryItemsBacket];
	[super dealloc];
}

- (NSUInteger)historyItemLimitForType:(CMRHistoryItemType)aType
{
	switch (aType) {
    case CMRHistoryBoardEntryType:
        return [CMRPref maxCountForBoardsHistory];
    case CMRHistoryThreadEntryType:
        return [CMRPref maxCountForThreadsHistory];
    default:
        UTILUnknownSwitchCase(aType);
        return 10;
    }
}

- (NSMutableArray *)mutableHistoryItemArrayForType:(CMRHistoryItemType)aType
{
    id *backets_;

    if (aType >= CMRHistoryCountOfEntriesType || aType < 0) {
// #warning 64BIT:Check formatting arguments
// 2010-06-06 tsawada2 修正済
        [NSException raise:NSRangeException 
                    format:@"%@ Attempt to index(%ld) bounds(%ld)",
                            UTIL_HANDLE_FAILURE_IN_METHOD,
                            (long)aType,
                            (long)CMRHistoryCountOfEntriesType];
    }
    backets_ = [self historyItemsBacket];
    if (NULL == backets_[aType]) {
        backets_[aType] = [[NSMutableArray alloc] init];
    }

    return backets_[aType];
}

- (NSArray *)historyItemArrayForType:(NSInteger)aType
{
    return [self mutableHistoryItemArrayForType:aType];
}

- (void)removeItemForType:(CMRHistoryItemType)aType atIndex:(NSUInteger)anIndex
{
    NSMutableArray *itemArray_;
    CMRHistoryItem *item_;

    itemArray_ = [self mutableHistoryItemArrayForType:aType];
    if (anIndex >= [itemArray_ count]) {
        return;
    }
    item_ = [[itemArray_ objectAtIndex:anIndex] retain];
    [itemArray_ removeObjectAtIndex:anIndex];
	[item_ autorelease];
}

- (NSInteger)indexOfOldestItemForType:(NSInteger)aType
{
    NSArray *itemArray = [self mutableHistoryItemArrayForType:aType];
    NSInteger i;
    NSInteger cnt = [itemArray count];
    CMRHistoryItem *oldest = nil;
    NSInteger oldestIndex = -1;

    for (i = 0; i < cnt; i++) {
        CMRHistoryItem *item = [itemArray objectAtIndex:i];
        
        if (!oldest || NSOrderedDescending == [oldest.historyDate compare:item.historyDate]) {
            oldest = item;
            oldestIndex = i;
        }
    }
    return oldestIndex;
}

- (void)addItem:(CMRHistoryItem *)anItem
{
    CMRHistoryItem *item_ = anItem;
    NSMutableArray *itemArray_;
	NSMutableArray *newArray_;
    NSUInteger index_;
    NSUInteger limit_;

    UTILAssertNotNilArgument(anItem, @"Item");

    limit_ = [self historyItemLimitForType:anItem.historyType];
    itemArray_ = [self mutableHistoryItemArrayForType:anItem.historyType];
    if ((index_ = [itemArray_ indexOfObject:anItem]) != NSNotFound) {
        // Update
        item_ = [itemArray_ objectAtIndex:index_];
        item_.historyTitle = anItem.historyTitle;
        [item_ setRepresentedObject:[anItem representedObject]];
        item_.historyDate = [NSDate date];
        [item_ incrementVisitedCount];		
		[itemArray_ exchangeObjectAtIndex:index_ withObjectAtIndex:0];		
    } else {
        if (limit_ == [itemArray_ count]) { // Check limit
            NSInteger idx;
            idx = [self indexOfOldestItemForType:anItem.historyType];
            UTILDebugWrite1(@"Oldest Item is %@.", [itemArray_ objectAtIndex:idx]);
            [self removeItemForType:anItem.historyType atIndex:idx];
        }
        // New Entry
        [itemArray_ insertObject:anItem atIndex:0];
    }

	// sort by date
	newArray_ = [[itemArray_ sortedArrayUsingSelector:@selector(_compareByDate:)] mutableCopy];
    [itemArray_ removeAllObjects];
	[itemArray_ addObjectsFromArray:newArray_];	
	[newArray_ release];
}

- (CMRHistoryItem *)addItemWithTitle:(NSString *)aTitle
                                type:(CMRHistoryItemType)aType
                              object:(id)aRepresentedObject
{
    CMRHistoryItem    *item_;

    item_ = [[CMRHistoryItem alloc] initWithTitle:aTitle type:aType];
    [item_ setRepresentedObject:aRepresentedObject];

    [self addItem:item_];
    return [item_ autorelease];
}

#pragma mark -

#define kHistoryItemEntriesKey        @"HistoryDates"
#define kHistoryFileVersionKey        @"HistoryFileVersion"
#define kHistoryFileVersionAllowed    1
#define kHistoryFileVersionNew		  2

static NSString *const stHistoryPropertyKey[] = 
{
    @"Board",
    @"Thread",
};

- (void)removeAllItems
{
    [self clearHistoryItemsBacket];
}

- (void)loadDictionaryRepresentation:(NSDictionary *)aDictionary
{
    NSDictionary *dict_;
    NSInteger   fileVersion_;
    NSUInteger  i;
    NSUInteger  j;
	NSUInteger  max;
    
    if (!aDictionary) {
        return;
    }
    fileVersion_ = [aDictionary integerForKey:kHistoryFileVersionKey];
	if (fileVersion_ == kHistoryFileVersionAllowed) {
		NSLog(@"Ignore Old Board History.");
		j = 1;
	} else if (fileVersion_ == kHistoryFileVersionNew) {
//		NSLog(@"No Problem");
		j = 0;
	} else {
// #warning 64BIT:Check formatting arguments
// 2010-06-12 tsawada2 修正済
        NSLog(@"History FileVersion(%ld) was not supported!", (long)fileVersion_);
        return;
    }
    [self clearHistoryItemsBacket];
    
    dict_ = [aDictionary dictionaryForKey:kHistoryItemEntriesKey];
    if (!dict_ || [dict_ count] == 0) {
        return;
    }
    @try {
        for (i = j; i < kHistoryItemsBacketCount; i++) {
            NSString *key_;
            NSArray *itemArray_;
            id entry_;

            key_ = stHistoryPropertyKey[i];
            itemArray_ = [dict_ arrayForKey:key_];
            if (!itemArray_ || [itemArray_ count] == 0) {
                continue;
            }

            for (id entry_ in itemArray_) {
                CMRHistoryItem *historyItem_;

                historyItem_ = [CMRHistoryItem objectWithPropertyListRepresentation:entry_];
                if (!historyItem_) {
                    continue;
                }
                [self addItem:historyItem_];
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"An error has occurred while loading %@. <Reason - %@>", CMRHistoryFile, exception);
        [[NSFileManager defaultManager] copyItemAtPath:[[self class] defaultFilepath]
                                                toPath:[[CMRFileManager defaultManager] supportFilepathWithName:@"History_loadFailed.plist"
                                                                                               resolvingFileRef:NULL]
                                                 error:NULL];
    }
}

- (id)genHistoriesPropertyListRepresentation:(NSArray *)aHistories
{
    NSMutableArray    *historyArray_;
    NSEnumerator    *iter_;
    CMRHistoryItem    *item_;
    
    historyArray_ = [NSMutableArray array];
    iter_ = [aHistories objectEnumerator];
    while (item_ = [iter_ nextObject]) {
        id        obj_;
        
        obj_ = [item_ propertyListRepresentation];
        [historyArray_ addObject:obj_];
    }
    
    return historyArray_;
}

- (NSDictionary *)historiesPropertyListRepresentation
{
    NSMutableDictionary        *dict_;
    
    dict_ = [NSMutableDictionary dictionary];
    if (_backets != NULL) {
        NSUInteger    i, cnt;
        
        cnt = kHistoryItemsBacketCount;
        for (i = 0; i < cnt; i++) {
            id        obj_;
            
            obj_ = [self genHistoriesPropertyListRepresentation:_backets[i]];
            [dict_ setObject:obj_ forKey:stHistoryPropertyKey[i]];
        }
    }
    return dict_;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary        *dict_;
    
    dict_ = [NSMutableDictionary dictionary];
    [dict_ setInteger:kHistoryFileVersionNew
               forKey:kHistoryFileVersionKey];
    [dict_ setObject:[self historiesPropertyListRepresentation]
              forKey:kHistoryItemEntriesKey];
    
    return dict_;
}

- (NSData *)binaryRepresentation
{
	NSString *errorStr;
	return [NSPropertyListSerialization dataFromPropertyList:[self dictionaryRepresentation]
													  format:NSPropertyListBinaryFormat_v1_0
											errorDescription:&errorStr];
}

- (void)applicationWillTerminate:(NSNotification *)theNotification
{    
    UTILAssertNotificationName(
        theNotification,
        NSApplicationWillTerminateNotification);

	[[self binaryRepresentation] writeToFile:[[self class] defaultFilepath] atomically:YES];
}
@end


@implementation CMRHistoryManager(NSMenuDelegate)
- (void)boardHistoryMenuNeedsUpdate:(NSMenu *)menu
{
	NSUInteger n = [menu numberOfItems];
	if (n > 0) {
		NSInteger i;
		for (i=n-1;i>=0;i--) {
			[menu removeItemAtIndex:i];
		}
	}

	NSArray	*historyItemsArray = [self historyItemArrayForType:CMRHistoryBoardEntryType];
	if (!historyItemsArray || [historyItemsArray count] == 0) {
		[menu addItemWithTitle:NSLocalizedString(@"No Board History", @"") action:NULL keyEquivalent:@""];
		return;
	} else {
		NSEnumerator *iter = [historyItemsArray reverseObjectEnumerator];
		CMRHistoryItem *eachItem;
		NSMenuItem *menuItem;
		NSString *title_;
		BoardListItem *item_;

		while (eachItem = [iter nextObject]) {
			title_ = eachItem.historyTitle;
			if (!title_) {
                continue;
            }
			menuItem = [[NSMenuItem alloc] initWithTitle:title_ action:@selector(showBoardFromHistoryMenu:) keyEquivalent:@""];
			item_ = (BoardListItem *)[eachItem representedObject];

			[menuItem setTarget:[NSApp delegate]];
//			[menuItem setImage:[item_ icon]];
			[menuItem setRepresentedObject:item_];

			[menu insertItem:menuItem atIndex:0];
			[menuItem release];
		}
	}
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if ([menu delegate] != self) {
        return;
    }
    if ([menu supermenu] != [NSApp mainMenu]) {
        [self boardHistoryMenuNeedsUpdate:menu];
        return;
    }

    if ([menu numberOfItems] > 6) {
        NSInteger i;
        for (i = [menu numberOfItems] - 2; i > 4; i--) {
            [menu removeItemAtIndex:i];
        }
    }

    NSArray *historyItemsArray = [self historyItemArrayForType:CMRHistoryThreadEntryType];
    if (!historyItemsArray || [historyItemsArray count] == 0) {
        return;
    } else {
        NSEnumerator *iter = [historyItemsArray reverseObjectEnumerator];
        CMRHistoryItem *eachItem;
        NSMenuItem *menuItem;
        NSString *title;
        SEL action = @selector(showThreadFromHistoryMenu:);

        [menu insertItem:[NSMenuItem separatorItem] atIndex:5];

        while (eachItem = [iter nextObject]) {
            title = eachItem.historyTitle;
            if (!title) {
                title = @"(N/A)";
            }

            menuItem = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
            [menuItem setTarget:nil];
            [menuItem setRepresentedObject:[eachItem representedObject]];
            [menu insertItem:menuItem atIndex:5];
            [menuItem release];
        }
    }
}
@end

#pragma mark -

@implementation CMRHistoryItem

@synthesize historyType = _type;
@synthesize historyTitle = _title;
@synthesize historyDate = _date;
@synthesize visitedCount = _visitedCount;

- (id)init
{
    if (self = [super init]) {
//        [self setHistoryDate:[NSDate date]];
//        [self setType:-1];
//        [self setVisitedCount:1];
        self.historyDate = [NSDate date];
        self.historyType = CMRHistoryNoTypeAssignedType;
        self.visitedCount = 1;
    }
    return self;
}

- (id)initWithTitle:(NSString *)aTitle type:(CMRHistoryItemType)aType
{
    if (self = [self init]) {
//        [self setTitle:aTitle];
//        [self setType:aType];
        self.historyTitle = aTitle;
        self.historyType = aType;
    }
    return self;
}

- (void) dealloc
{
    [_date release];
    [_title release];
    [_representedObject release];
    [super dealloc];
}
/*
- (NSInteger) type
{
    return _type;
}

- (void) setType:(NSInteger) aType
{
    _type = aType;
}

- (NSString *) title
{
    return _title;
}

- (NSDate *) historyDate
{
    return _date;
}
*/
- (id<CMRHistoryObject>)representedObject
{
    return _representedObject;
}
/*
- (NSUInteger) visitedCount
{
    return _visitedCount;
}

- (void) setTitle:(NSString *) aTitle
{
    id        tmp;
    
    tmp = _title;
    _title = [aTitle retain];
    [tmp release];
}

- (void) setHistoryDate:(NSDate *) aDate
{
    id        tmp;
    
    tmp = _date;
    _date = [aDate retain];
    [tmp release];
}
*/
- (void)setRepresentedObject:(id<CMRHistoryObject>)aRepresentedObject
{
    id tmp;
    
    UTILAssertConformsTo(aRepresentedObject, @protocol(CMRPropertyListCoding));
        
    tmp = _representedObject;
    _representedObject = [aRepresentedObject retain];
    [tmp release];
}
/*
- (void) setVisitedCount:(NSUInteger) aVisitedCount
{
    _visitedCount = aVisitedCount;
}
*/
- (void)incrementVisitedCount
{
    _visitedCount++;
}

- (BOOL)hasRepresentedObject:(id)anObject
{
    id obj;
    
    if (![anObject conformsToProtocol:@protocol(CMRHistoryObject)]) {
        return NO;
    }
    obj = [self representedObject];
    return (obj == anObject) ? YES : [obj isHistoryEqual:anObject];
}

- (NSComparisonResult)_compareByDate:(CMRHistoryItem *)anObject
{
	NSDate *date1;
    NSDate *date2;

	date1 = [self historyDate];
	date2 = [anObject historyDate];

	return [date2 compare:date1];
}

#pragma mark CMRPropertyListCoding

#define kRepresentationTitleKey				@"Title"
#define kRepresentationDateKey				@"HistoryDate"
#define kRepresentationObjectKey			@"RepresentedObject"
#define kRepresentationClassKey				@"RepresentedClass"
#define kRepresentationTypeKey				@"HistoryType"
#define kRepresentationVisitedCountKey		@"VisitedCount"

+ (id)objectWithPropertyListRepresentation:(id)rep
{
    id title_;
    NSDate *date_;
    id object_;
    CMRHistoryItemType type_;
    NSUInteger count_;
    
    NSString *className_;
    Class class_;
    
    CMRHistoryItem *instance_;
    
    if (!rep || ![rep isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    title_ = [rep objectForKey:kRepresentationTitleKey];
    date_ = [rep objectForKey:kRepresentationDateKey];
    UTILAssertKindOfClass(date_, NSDate);
    
    className_ = [rep stringForKey:kRepresentationClassKey];
    UTILAssertNotNil(className_);
    class_ = NSClassFromString(className_);
    UTILAssertNotNil(class_);
    object_ = [rep objectForKey:kRepresentationObjectKey];
    UTILAssertNotNil(object_);
    object_ = [class_ objectWithPropertyListRepresentation:object_];
    UTILAssertNotNil(object_);
    
    type_ = [rep integerForKey:kRepresentationTypeKey];
    count_ = [rep unsignedIntegerForKey:kRepresentationVisitedCountKey];
    
    instance_ = [[self alloc] initWithTitle:title_ type:type_];
    [instance_ setRepresentedObject:object_];
    instance_.historyDate = date_;
    instance_.visitedCount = count_;

    return [instance_ autorelease];
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *dict;

    dict = [NSMutableDictionary dictionary];

    [dict setNoneNil:self.historyTitle forKey:kRepresentationTitleKey];
    [dict setNoneNil:self.historyDate forKey:kRepresentationDateKey];
    [dict setNoneNil:NSStringFromClass([[self representedObject] class]) forKey:kRepresentationClassKey];
    [dict setNoneNil:[[self representedObject] propertyListRepresentation] forKey:kRepresentationObjectKey];
    [dict setNoneNil:[NSNumber numberWithInteger:self.historyType] forKey:kRepresentationTypeKey];
    [dict setNoneNil:[NSNumber numberWithUnsignedInteger:self.visitedCount] forKey:kRepresentationVisitedCountKey];

    return dict;
}

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)coder
{
    NSAssert([coder allowsKeyedCoding], @"Coder does not support keyed coding!!");

    self.historyTitle = [coder decodeObjectForKey:kRepresentationTitleKey];
    self.historyDate = [coder decodeObjectForKey:kRepresentationDateKey];
    [self setRepresentedObject:[coder decodeObjectForKey:kRepresentationObjectKey]];
    self.historyType = [coder decodeIntegerForKey:kRepresentationTypeKey];
    self.visitedCount = [coder decodeIntegerForKey:kRepresentationVisitedCountKey];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    id tmp;
    NSAssert([encoder allowsKeyedCoding], @"Coder does not support keyed coding!!");

    tmp = self.historyTitle;
    if (tmp) {
        [encoder encodeObject:tmp forKey:kRepresentationTitleKey];
    }
    tmp = self.historyDate;
    if (tmp) {
        [encoder encodeObject:tmp forKey:kRepresentationDateKey];
    }
    tmp = [self representedObject];
    if (tmp) {
        [encoder encodeObject:tmp forKey:kRepresentationObjectKey];
    }
    [encoder encodeInteger:self.historyType forKey:kRepresentationTypeKey];
    [encoder encodeInteger:self.visitedCount forKey:kRepresentationVisitedCountKey];
}

#pragma mark NSObject
- (NSString *)description
{
// #warning 64BIT:Check formatting arguments
// 2010-06-06 tsawada2 修正済
    return [NSString stringWithFormat:
                @"<%@ %p> title=%@ type=%ld visited=%lu date=%@ object=%@",
                [self className],
                self,
                self.historyTitle,
                (long)(self.historyType),
                (unsigned long)(self.visitedCount),
                self.historyDate,
                [self representedObject]];
}

- (BOOL)isEqual:(id)other
{
    id obj1;
    id obj2;
    BOOL result = NO;
    CMRHistoryItem *item_ = other;

    if (item_ == self) {
        return YES;
    }
    if (!item_) {
        return NO;
    }
    if (![item_ isKindOfClass:[self class]]) {
        return [super isEqual:item_];
    }
    result = (self.historyType == item_.historyType);
    if (!result) {
        return NO;
    }
    obj1 = [self representedObject];
    obj2 = [item_ representedObject];
    result = (obj1 == obj2) ? YES : [obj1 isHistoryEqual:obj2];

    return result;
}
@end
