//
//  BSSearchOptions.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/17.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSSearchOptions.h"


@implementation BSSearchOptions
#pragma mark Designated Initializers
+ (id) operationWithFindObject: (NSString *) searchString
					   options: (CMRSearchMask) options
						target: (NSArray *) keysArray
{
	return [[[self alloc] initWithFindObject: searchString
									 options: options
									  target: keysArray] autorelease];
}

- (id) initWithFindObject: (NSString *) searchString
				  options: (CMRSearchMask) options
				   target: (NSArray *) keysArray;
{
	if (self = [super init]) {
		m_searchString = [searchString retain];
		m_targetKeysArray = [keysArray retain];
		m_searchMask = options;
	}
	return self;
}

#pragma mark Overrides
- (void) dealloc
{
	[m_searchString release];
	[m_targetKeysArray release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat : 
				@"<%@ %p> findObject=%@ targetKeysArray=[%@] option=%lu",
				[self className],
				self,
				[self findObject],
				[[self targetKeysArray] componentsJoinedByString: @", "],
				(unsigned long)[self optionMasks]];
}

- (BOOL) isEqual : (id) other
{
	BSSearchOptions	*other_ = other;
	id					obj1, obj2;
	BOOL				result = NO;
	
	if(nil == other) return NO;
	if(nil == self) return YES;
	
	obj1 = [self findObject];
	obj2 = [other_ findObject];
	result = (obj1 == obj2) ? YES : [obj1 isEqual : obj2];
	if(NO == result)
		return NO;
	
	obj1 = [self targetKeysArray];
	obj2 = [other_ targetKeysArray];
	result = (obj1 == obj2) ? YES : [obj1 isEqual : obj2];
	if(NO == result)
		return NO;
	
	return ([self optionMasks] == [other_ optionMasks]);
}

- (NSUInteger) hash
{
	return [[self findObject] hash];
}

#pragma mark NSCopying
- (id) copyWithZone : (NSZone *) zone
{
	return [self retain];
}

#pragma mark CMRPropertyListCoding
/*#define kRepresentationFindObjectKey		@"Find"
#define kRepresentationReplaceObjectKey		@"Replace"
#define kRepresentationUserInfoObjectKey	@"UserInfo"
#define kRepresentationOptionKey			@"Option"
+ (id) objectWithPropertyListRepresentation : (id) rep
{
	id			findObject_;
	id			replaceObject_;
	id			userInfo_;
	unsigned	findOption_;
	
	if(nil == rep || NO == [rep isKindOfClass : [NSDictionary class]])
		return nil;
	
	findObject_ = [rep objectForKey : kRepresentationFindObjectKey];
	replaceObject_ = [rep objectForKey : kRepresentationReplaceObjectKey];
	userInfo_ = [rep objectForKey : kRepresentationUserInfoObjectKey];
	findOption_ = [rep unsignedIntegerForKey : kRepresentationOptionKey];
	
	return [self operationWithFindObject : findObject_
								 replace : replaceObject_
								userInfo : userInfo_
								  option : findOption_];
}

- (id) propertyListRepresentation
{
	NSMutableDictionary		*dict;
	
	dict = [NSMutableDictionary dictionary];
	
	[dict setNoneNil:[self findObject] forKey:kRepresentationFindObjectKey];
	[dict setNoneNil:[self replaceObject] forKey:kRepresentationReplaceObjectKey];
	[dict setNoneNil:[self userInfo] forKey:kRepresentationUserInfoObjectKey];
	[dict setUnsignedInteger:[self findOption] forKey:kRepresentationOptionKey];

	return dict;
}
*/
#pragma mark Accessors
- (NSString *) findObject
{
	return m_searchString;
}

- (NSArray *) targetKeysArray
{
	return m_targetKeysArray;
}

- (CMRSearchMask) optionMasks
{
	return m_searchMask;
}

- (BOOL) optionStateForOption: (CMRSearchMask) opt
{
	return (m_searchMask & opt);
}

- (void) setOptionState: (BOOL) flag
			  forOption: (CMRSearchMask) opt;
{
	m_searchMask = flag ? (m_searchMask | opt) : (m_searchMask & (~opt));
}

+ (NSArray *)keysArrayFromStatesArray:(NSArray *)statesArray
{
    static NSArray *allKeys = nil;
    if (!allKeys) {
        allKeys = [[NSArray alloc] initWithObjects:@"name", @"mail", @"IDString", @"host", @"cachedMessage", nil];
    }
    NSMutableArray  *tmpArray = [NSMutableArray array];
    NSInteger   i;
    
    for (i = 0; i < 5; i++) {
        if ([[statesArray objectAtIndex:i] integerValue] == NSOnState) {
            [tmpArray addObject:[allKeys objectAtIndex:i]];
        }
    }
    return tmpArray;
}

/*
- (BOOL)isCaseInsensitive;
- (void)setIsCaseInsensitive:(BOOL)checkBoxState;
- (BOOL)isLinkOnly;
- (void)setIsLinkOnly:(BOOL)checkBoxState;
- (BOOL)usesRegularExpression;
- (void)setUsesRegularExpression:(BOOL)flag;

- (unsigned int)searchTargets
{
	return m_targetsMask;
}

- (void)setSearchTargets:(unsigned int)targetsMask
{
	m_targetsMask = targetsMask;
}
*/
@end
