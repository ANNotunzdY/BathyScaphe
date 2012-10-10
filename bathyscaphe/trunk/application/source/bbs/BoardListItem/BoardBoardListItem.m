//
//  BoardBoardListItem.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//

#import "BoardBoardListItem.h"

#import "DatabaseManager.h"
#import "CMRBBSListTemplateKeys.h"

#import <SGAppKit/NSImage-SGExtensions.h>

static NSMutableDictionary *_commonInstances = nil;
static NSLock *_commonInstancesLock = nil;

@interface BoardBoardListItem(Private)
- (id) _privateInitWithBoardID : (NSUInteger) boardID;
@end

@implementation BoardBoardListItem

+ (void)initialize
{
	static BOOL isFirst = YES;
	
	if (isFirst) {
		isFirst = NO;
		
		_commonInstances = [[NSMutableDictionary dictionary] retain];
		_commonInstancesLock = [[NSLock alloc] init];
	}
}

+ (id) boardBoardListWithBoardID : (NSUInteger) inBoardID
{
	return [[[self alloc] initWithBoardID : inBoardID] autorelease];
}

- (id) initWithBoardID : (NSUInteger) inBoardID
{	
	id result = nil;
	id key = [NSNumber numberWithUnsignedInteger:inBoardID];
	
	[_commonInstancesLock lock];
	result = [[_commonInstances objectForKey : key] retain];
	if (!result) {
		result = [super init];
		if (result) {
			[result setBoardID : inBoardID];
			[_commonInstances setObject : result forKey : key];
		}
	} else {
		[super init];
		[self release];
	}
	[_commonInstancesLock unlock];
	
	return result;
}
- (id) initWithURLString : (NSString *) urlString
{
	NSUInteger inBoardID;
	
	inBoardID = [[DatabaseManager defaultManager] boardIDForURLString : urlString];
	if (inBoardID == NSNotFound) {
		[super init];
		[self release];
		return nil;
	}
	
	return [self initWithBoardID : inBoardID];
}

- (void) dealloc
{
	[representName release];
	
	[super dealloc];
}

- (id) description
{
	return [[self plist] description];
}
- (id) plist
{
	id dict;
	id url;
	id repName;
	
	dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys : [self name], BoardPlistNameKey, nil];
	
	url = [[DatabaseManager defaultManager] urlStringForBoardID : [self boardID]];
	UTILAssertNotNil(url);
	[dict setObject : url forKey : BoardPlistURLKey];
	
	if((repName = [self representName])) {
		[dict setObject : repName forKey : @"RepresentName"];
	}
	
	return [dict autorelease];
}

#pragma mark## CMRPropertyListCoding protocol ##
- (id) propertyListRepresentation
{
	id result;
	
	result = [NSMutableDictionary dictionaryWithObject : [NSNumber numberWithUnsignedInteger:[self boardID]]
												forKey : @"BoardID"];
	if (representName) {
		[result setObject : representName
				   forKey : @"RepresentName"];
	}
	
	return result;
}
- (id) initWithPropertyListRepresentation : (id) rep
{
	id result;
	id repname;
	
	if ([rep isKindOfClass : [NSNumber class]]) {
		return [self initWithBoardID : [rep unsignedIntegerValue]];
	}
	
	result = [self initWithBoardID : [[rep objectForKey : @"BoardID"] unsignedIntegerValue]];
	
	repname = [rep objectForKey : @"RepresentName"];
	if (repname) {
		[result setRepresentName : repname];
	}
	
	return result;
}
- (BOOL) isHistoryEqual : (id) anObject
{
	if (![super isHistoryEqual : anObject]) return NO;

	if ([anObject boardID] == [self boardID]) return YES;
	
	return NO;
}

- (NSImage *)icon
{
	return [NSImage imageAppNamed:[self iconBaseName]];
}

- (NSString *) name
{
	if(![super name]) {
		id name = [[DatabaseManager defaultManager] nameForBoardID : [self boardID]];
		[super setName:name];
	}
	
	return [super name];
}
- (void) setName : (NSString *) name
{
	NSString *currentName;
	DatabaseManager *dbm = [DatabaseManager defaultManager];
	
	currentName = [dbm nameForBoardID : [self boardID]];
	if ([currentName isEqualTo : name]) return;
	
	[dbm renameBoardID : [self boardID] toName : name];
}

- (NSString *) representName
{
	if (representName) {
		return representName;
	}
	
	return [self name];
}
- (void) setRepresentName : (NSString *) name
{
	id temp = representName;
	
	representName = [name copy];
	[temp release];
}

- (BOOL) hasURL
{
	return YES;
}
- (NSURL *) url
{
	id urlString = [[DatabaseManager defaultManager] urlStringForBoardID : [self boardID]];
	
	return [NSURL URLWithString : urlString];
}
- (void) setURLString : (NSString *) urlString
{
	[[DatabaseManager defaultManager] moveBoardID : boardID toURLString : urlString];
}

- (NSUInteger) boardID
{
	return boardID;
}
- (void) setBoardID : (NSUInteger) newBoardID
{
	NSMutableString *query;
	
	boardID = newBoardID;
	
	query = [NSMutableString stringWithFormat: @"SELECT * FROM %@ INNER JOIN %@ \n",
		TempThreadNumberTableName, BoardThreadInfoViewName];
	[query appendFormat: @"\t\tUSING (%@, %@) ", BoardIDColumn, ThreadIDColumn];
	[query appendFormat: @"WHERE %@ = %ld", BoardIDColumn, (long)boardID];
	
	[self setQuery : query];
}

#pragma mark NSPasteboardWriting
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    static NSArray *cachedTypes = nil;
    if (!cachedTypes) {
        cachedTypes = [[NSArray alloc] initWithObjects:BSPasteboardTypeBoardListItem, (NSString *)kUTTypeURL, NSPasteboardTypeString, nil];
    }
    return cachedTypes;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    if ([type isEqualToString:BSPasteboardTypeBoardListItem]) {
        return [self plist];
    } else if ([type isEqualToString:(NSString *)kUTTypeURL]) {
        return [[self url] pasteboardPropertyListForType:(NSString *)kUTTypeURL];
    } else if ([type isEqualToString:NSPasteboardTypeString]) {
        return [NSString stringWithFormat:@"%@\n%@", [self representName], [[self url] absoluteString]];
    }
    return nil;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    return 0;
}
@end
