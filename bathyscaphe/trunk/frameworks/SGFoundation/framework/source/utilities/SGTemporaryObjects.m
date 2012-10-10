//
//  SGTemporaryObjects.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGTemporaryObjects.h"
#import <SGFoundation/SGFoundationAdditions.h>



static NSString *const SGTemporaryArrayKey      = @"ArraySGTemporaryKey";
static NSString *const SGTemporaryDictionaryKey = @"DictionarySGTemporaryKey";
static NSString *const SGTemporaryAttrStringKey = @"AStringSGTemporaryKey";
static NSString *const SGTemporaryStringKey     = @"StringSGTemporaryKey";
static NSString *const SGTemporarySetKey        = @"SetSGTemporaryKey";
static NSString *const SGTemporaryDataKey       = @"DataSGTemporaryKey";
static NSString *const SGTemporaryRangeArrayKey = @"RArraySGTemporaryKey";



static id SGTemporaryObjectForKey(NSString *aKey, Class aClass)
{
	NSThread			*currentThread_;
	NSMutableDictionary	*threadDictionary_;
	id					instance_;
	
	currentThread_ = [NSThread currentThread];
	threadDictionary_ = [currentThread_ threadDictionary];
	instance_ = [threadDictionary_ objectForKey:aKey];
	if (!instance_) {
		instance_ = [[aClass alloc] init];
		[threadDictionary_ setObject:instance_ forKey:aKey];
		[instance_ release];
		/*
		NSLog(	@">>>[Create Temporary Object]\n\t"
				@"class<%@> for thread<%p>",
				NSStringFromClass(aClass),
				currentThread_);
		*/
	}
	return instance_;
}

NSMutableArray *SGTemporaryArray()
{
	id		instance_;
	
	instance_ = SGTemporaryObjectForKey(
					SGTemporaryArrayKey,
					[NSMutableArray class]);
	[instance_ removeAllObjects];
	
	return instance_;
}

NSMutableDictionary *SGTemporaryDictionary()
{
	id		instance_;
	
	instance_ = SGTemporaryObjectForKey(
					SGTemporaryDictionaryKey,
					[NSMutableDictionary class]);
	[instance_ removeAllObjects];
	
	return instance_;
}

NSMutableAttributedString *SGTemporaryAttributedString()
{
	id		instance_;
	
	instance_ = SGTemporaryObjectForKey(
					SGTemporaryAttrStringKey,
					[NSMutableAttributedString class]);
	[instance_ deleteCharactersInRange:[instance_ range]];
	
	return instance_;
}

NSMutableString *SGTemporaryString()
{
	id		instance_;
	
	instance_ = SGTemporaryObjectForKey(
					SGTemporaryStringKey,
					[NSMutableString class]);
	[instance_ deleteCharactersInRange:[instance_ range]];
	
	return instance_;
}

NSMutableSet *SGTemporarySet()
{
	id		instance_;
	
	instance_ = SGTemporaryObjectForKey(
					SGTemporarySetKey,
					[NSMutableSet class]);
	[instance_ removeAllObjects];
	
	return instance_;
}

NSMutableData *SGTemporaryData()
{
	NSMutableData		*instance_;
	
	instance_ = SGTemporaryObjectForKey(
					SGTemporaryDataKey,
					[NSMutableData class]);
	[instance_ resetBytesInRange:NSMakeRange(0, [instance_ length])];
	
	return instance_;
}

SGBaseRangeArray *SGTemporaryRangeArray()
{
	id		instance_;
	
	instance_ = SGTemporaryObjectForKey(
					SGTemporaryRangeArrayKey,
					[SGBaseRangeArray class]);
	[instance_ removeAll];
	
	return instance_;
}
