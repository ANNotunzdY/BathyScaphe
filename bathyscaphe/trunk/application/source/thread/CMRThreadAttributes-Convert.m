//
//  CMRThreadAttributes-Convert.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/24.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadAttributes.h"
#import "CMRThreadSignature.h"

#import "CMRDocumentFileManager.h"
#import "BoardManager.h"
#import "AppDefaults.h"
#import "CMRHostHandler.h"

#define kCopyThreadBBSNameKey		@"%%%BBSName%%%"
#define kCopyThreadBBSURLKey		@"%%%BBSURL%%%"
#define kCopyThreadTitleKey			@"%%%ThreadTitle%%%"
#define kCopyThreadPathKey			@"%%%ThreadPath%%%"
#define kCopyThreadURLKey			@"%%%ThreadURL%%%"
#define kCopyThreadDATSizeKbKey		@"%%%DATSize-KB%%%"
#define kCopyThreadDATSizeKey		@"%%%DATSize%%%"
#define kCopyThreadCreatedDateKey	@"%%%CreatedDate%%%"
#define kCopyThreadModifiedDateKey	@"%%%ModifiedDate%%%"

#define kCopyThreadFormatKey		@"Thread - CopyThreadFormat"

static NSString *const kCMROldVersionThreadURLKey = @"ThreadURL";

@implementation CMRThreadAttributes(Converter)
+ (BOOL)isNewThreadFromDictionary:(NSDictionary *)dict
{
	NSNumber *s;

	s = [dict objectForKey:CMRThreadStatusKey];
	return s ? (ThreadNewCreatedStatus == [s unsignedIntegerValue]) : NO;
}

+ (NSInteger)numberOfUpdatedFromDictionary:(NSDictionary *)dict
{
	NSNumber *count_;
	NSInteger diffrence_;

	count_ = [dict objectForKey:CMRThreadNumberOfMessagesKey];
	UTILRequireCondition(count_, no_cached);
	diffrence_ = [count_ unsignedIntegerValue];

	count_ = [dict objectForKey:CMRThreadLastLoadedNumberKey];
	UTILRequireCondition(count_, no_cached);
	diffrence_ = diffrence_ - [count_ unsignedIntegerValue];

	UTILRequireCondition(diffrence_ >= 0, no_cached);

	return diffrence_;

no_cached:
    return -1;
}

+ (NSString *)pathFromDictionary:(NSDictionary *)dict
{
	NSString		*boardName_;
	NSString		*datIdentifier_;
	
	if (!dict) {
        return nil;
    }
	boardName_ = [dict objectForKey:ThreadPlistBoardNameKey];
	if (!boardName_) {
		NSString *path_;

		path_ = [dict objectForKey:CMRThreadLogFilepathKey];
		UTILAssertNotNil(path_);
		boardName_ = [[CMRDocumentFileManager defaultManager] boardNameWithLogPath:path_];
	}

	datIdentifier_ = [self identifierFromDictionary:dict];
	return [[CMRDocumentFileManager defaultManager] threadPathWithBoardName:boardName_ datIdentifier:datIdentifier_];
}

+ (NSString *)identifierFromDictionary:(NSDictionary *)dict
{
	NSString		*datIdentifier_;
	
	if (!dict) {
		return nil;
	}
	datIdentifier_ = [dict objectForKey:ThreadPlistIdentifierKey];
	if (!datIdentifier_) {
		NSString *path_;

		path_ = [dict objectForKey:CMRThreadLogFilepathKey];
		UTILRequireCondition(path_ != nil, try_old_format);

		datIdentifier_ = [[CMRDocumentFileManager defaultManager] datIdentifierWithLogPath:path_];
	}
	return datIdentifier_;

try_old_format:
    {
		NSString *threadURLString_;

		threadURLString_ = [dict objectForKey:kCMROldVersionThreadURLKey];
		if (!threadURLString_) {
			return nil;
		}
		return [threadURLString_ lastPathComponent];
	}
}

+ (NSString *)boardNameFromDictionary:(NSDictionary *)dict
{
	return [dict stringForKey:ThreadPlistBoardNameKey];
}

+ (NSString *)threadTitleFromDictionary:(NSDictionary *)dict
{
	return [dict stringForKey:CMRThreadTitleKey];
}

+ (NSDate *)createdDateFromDictionary:(NSDictionary *)dict
{
	return [dict objectForKey:CMRThreadCreatedDateKey];
}

+ (NSDate *)modifiedDateFromDictionary:(NSDictionary *)dict
{
	return [dict objectForKey:CMRThreadModifiedDateKey];
}

+ (NSURL *)boardURLFromDictionary:(NSDictionary *)dict
{
	return [[BoardManager defaultManager] URLForBoardName:[self boardNameFromDictionary:dict]];
}

+ (NSURL *)threadURLWithBoardID:(NSUInteger)boardID datIdentifier:(NSString *)identifier
{
    NSURL *boardURL = [[BoardManager defaultManager] URLForBoardID:boardID];
    CMRHostHandler *handler = [CMRHostHandler hostHandlerForURL:boardURL];
    return [handler readURLWithBoard:boardURL datName:identifier];
}

+ (NSURL *)threadURLFromDictionary:(NSDictionary *)dict
{
	NSURL			*boardURL_;
	NSString		*dat_;
	CMRHostHandler	*handler_;
	
	boardURL_ = [self boardURLFromDictionary:dict];
	dat_ = [self identifierFromDictionary:dict];
	
	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
	
	return [handler_ readURLWithBoard:boardURL_ datName:dat_];
}

+ (NSURL *)threadURLWithLatestParamFromDict:(NSDictionary *)dict resCount:(NSInteger) count
{
	NSURL			*boardURL_;
	NSString		*dat_;
	CMRHostHandler	*handler_;
	
	boardURL_ = [self boardURLFromDictionary:dict];
	dat_ = [self identifierFromDictionary:dict];
	
	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
	
	return [handler_ readURLWithBoard:boardURL_ datName:dat_ latestCount:count];
}

+ (NSURL *)threadURLWithHeaderParamFromDict:(NSDictionary *)dict resCount:(NSInteger) count
{
	NSURL			*boardURL_;
	NSString		*dat_;
	CMRHostHandler	*handler_;
	
	boardURL_ = [self boardURLFromDictionary:dict];
	dat_ = [self identifierFromDictionary:dict];
	
	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
	
	return [handler_ readURLWithBoard:boardURL_ datName:dat_ headCount:count];
}

+ (NSURL *)threadURLWithDefaultParameterFromDictionary:(NSDictionary *)dict
{
	BSOpenInBrowserType aType = [CMRPref openInBrowserType];
		
	if (aType == BSOpenInBrowserLatestFifty) {
		return [self threadURLWithLatestParamFromDict:dict resCount:50];
	} else if (aType == BSOpenInBrowserFirstHundred) {
		return [self threadURLWithHeaderParamFromDict:dict resCount:100];
	}

	return [self threadURLFromDictionary:dict];
}

+ (void)replaceKeywords:(NSMutableString *)theBuffer dictionary:(NSDictionary *)theThread
{
	static NSString *const kNFStringValue = @" - ";
	id          v = nil;
	NSString    *s;
	NSUInteger  bytes;

	SEL messages[] = {
				@selector(boardURLFromDictionary:),
				@selector(threadURLFromDictionary:),
				@selector(boardNameFromDictionary:),
				@selector(threadTitleFromDictionary:),
				@selector(createdDateFromDictionary:),
				@selector(modifiedDateFromDictionary:),
				NULL};
	NSString *keys[] = {
				kCopyThreadBBSURLKey,
				kCopyThreadURLKey,
				kCopyThreadBBSNameKey,
				kCopyThreadTitleKey,
				kCopyThreadCreatedDateKey,
				kCopyThreadModifiedDateKey,
				nil};

	SEL			*mp;
	NSString	**key;

	for (mp = messages, key = keys; *mp != NULL && *key != nil; mp++, key++) {
		v = [self performSelector:*mp withObject:theThread];
		s = v ? [v stringValue] : kNFStringValue;
		[theBuffer replaceCharacters:*key toString:s];
	}

	// dat size (bytes)
	v = [theThread numberForKey:ThreadPlistLengthKey];
	s = v ? [v stringValue] : kNFStringValue;
	[theBuffer replaceCharacters:kCopyThreadDATSizeKey toString:s];

	// dat size (Kb)
	v = [theThread numberForKey:ThreadPlistLengthKey];
	bytes = v ? [v unsignedIntegerValue] : 0;
	bytes /=  1024;
	v = (0 == bytes) ? nil : [NSNumber numberWithUnsignedInteger:bytes];
	s = v ? [v stringValue] : kNFStringValue;
	[theBuffer replaceCharacters:kCopyThreadDATSizeKbKey toString:s];

	// location of thread log file
	s = [self pathFromDictionary:theThread];
	if (!s) {
        s = kNFStringValue;
    }
	[theBuffer replaceCharacters:kCopyThreadPathKey toString:s];
}

+ (void)replaceKeywords:(NSMutableString *)theBuffer attributes:(CMRThreadAttributes *)theThread
{
	[self replaceKeywords:theBuffer dictionary:[theThread dictionaryRepresentation]];
}

+ (void)fillBuffer:(NSMutableString *)theBuffer withThreadInfoForCopying:(NSArray *)threadAttrsAry
{
	NSString		*template_;
	NSEnumerator	*iter_;
	NSDictionary	*dict_;

	template_ = SGTemplateResource(kCopyThreadFormatKey);
	UTILAssertKindOfClass(template_, NSString);

	iter_ = [threadAttrsAry objectEnumerator];

	if (!iter_) {
        return;
    }
	while (dict_ = [iter_ nextObject]) {
		[theBuffer appendString:template_];
		[self replaceKeywords:theBuffer dictionary:dict_];
	}
}
@end
