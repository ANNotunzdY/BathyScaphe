//
//  FavoritesBoardListItem.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/17.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//

#import "FavoritesBoardListItem.h"

#import "BoardBoardListItem.h"

#import "DatabaseManager.h"
#import "CMRBBSListTemplateKeys.h"
#import <SGAppKit/NSImage-SGExtensions.h>


@implementation FavoritesBoardListItem
//APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance) ;
+ (id)sharedInstance
{
	static id _sharedInstance = nil;
	
	if (!_sharedInstance) {
		_sharedInstance = [[self alloc] init];
	}
	
	return _sharedInstance;
}

- (id)init
{
	if (self = [super init]) {
		NSString *query;
	   	query = [NSString stringWithFormat:@"SELECT * FROM %@ INNER JOIN %@ USING(%@, %@)",
			BoardThreadInfoViewName, FavoritesTableName, BoardIDColumn, ThreadIDColumn];
		[self setQuery:query];
	}

	return self;
}

- (id)retain { return self; }
- (oneway void)release {}
- (NSUInteger)retainCount { return NSUIntegerMax; }

- (BOOL)isEqual:(id)other
{
	return (self == other);
}

- (NSImage *)icon
{
	return [NSImage imageAppNamed:[self iconBaseName]];
}

- (NSString *)iconBaseName
{
    return @"FavoritesItem";
}

- (NSString *)name
{
	return CMXFavoritesDirectoryName;
}
- (void)setName:(NSString *)newName
{
	//
}

#pragma mark## CMRPropertyListCoding protocol ##
//+ (id)objectWithPropertyListRepresentation:(id)rep
//{
//	return [[[self alloc] initWithPropertyListRepresentation:rep] autorelease];
//}
- (id)propertyListRepresentation
{
	return [self name];
}
- (id)initWithPropertyListRepresentation:(id)rep
{
	[self release];
	
	return [[[self class] sharedInstance] retain];
}
@end
