//
//  NSBundle-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSBundle-SGExtensions.h"
// #import "SGFile+AppSupport.h"
#import <SGFoundation/SGFileRef.h>


#define SHOULD_FIX_BAD_SEARCH_RESOURCE_BEHAVIOUR		YES


#define kCFBuncleExecutableKey		@"CFBundleExecutable"
#define kCFBuncleVersionKey		@"CFBundleVersion"
#define kCFBundleHelpBookKey	@"CFBundleHelpBookName"


@implementation NSBundle(SGExtentions)
+ (NSDictionary *)applicationInfoDictionary
{
	return [[self mainBundle] infoDictionary];
}

+ (NSDictionary *)localizedAppInfoDictionary
{
	return [[self mainBundle] localizedInfoDictionary];
}

+ (NSString *)applicationName
{
	return [[self applicationInfoDictionary] objectForKey:kCFBuncleExecutableKey];
}
+ (NSString *)applicationVersion
{
	return [[self applicationInfoDictionary] objectForKey:kCFBuncleVersionKey];
}
+ (NSString *)applicationHelpBookName
{
	return [[self localizedAppInfoDictionary] objectForKey:kCFBundleHelpBookKey];
}

- (NSString *)pathForResourceWithName:(NSString *)fileName
{
	return [self pathForResource:[fileName stringByDeletingPathExtension] ofType:[fileName pathExtension]];
}
- (NSString *)pathForResourceWithName:(NSString *)fileName inDirectory:(NSString *)dirName
{
	return [self pathForResource:[fileName stringByDeletingPathExtension]
						  ofType:[fileName pathExtension]
				     inDirectory:dirName];
}
@end


@implementation NSBundle(SGApplicationSupport)
// ~/Library/Application Support/(ExecutableName)
+ (NSBundle *)applicationSpecificBundle
{
	SGFileRef *reference_;
	
	reference_ = [SGFileRef applicationSpecificFolderRef];
	return [NSBundle bundleWithPath:[reference_ filepath]];
}

+ (NSDictionary *)mergedDictionaryWithName:(NSString *)filename
{
	NSString	*filepath_;
	id			dict_ = nil;
	
	filepath_ = [[NSBundle mainBundle] pathForResourceWithName:filename];
	if (filepath_) {
		dict_ = [NSMutableDictionary dictionaryWithContentsOfFile:filepath_];
	}
	filepath_ = [[NSBundle applicationSpecificBundle] pathForResourceWithName:filename];
	UTILRequireCondition(filepath_, ReturnCopiedDictionary);

	if (!dict_) {
		dict_ = [NSMutableDictionary dictionaryWithContentsOfFile:filepath_];
	} else {
		id tmp;

		tmp = [NSDictionary dictionaryWithContentsOfFile:filepath_];
		UTILRequireCondition(tmp, ReturnCopiedDictionary);
		[dict_ addEntriesFromDictionary:tmp];
	}

ReturnCopiedDictionary:
	return [[dict_ copy] autorelease];
}
@end


@implementation NSBundle(UserAgentString)
+ (NSString *)applicationUserAgent
{
	return [NSString stringWithFormat:@"%@/%@", [NSBundle applicationName], [NSBundle applicationVersion]];
}

+ (NSString *)monazillaUserAgent
{
	return [NSString stringWithFormat:@"Monazilla/1.00 (%@)", [self applicationUserAgent]];
}
@end
