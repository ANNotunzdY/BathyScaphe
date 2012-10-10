//
//  CMRThreadLinkProcessor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 12/08/14.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadLinkProcessor.h"

#import "CMRMessageAttributesStyling.h"
#import "BoardManager.h"
#import "CMRDocumentFileManager.h"
#import "CMRHostHandler.h"
#import "NSCharacterSet+CMXAdditions.h"
#import "CMRThreadSignature.h"

// for debugging only
#define UTIL_DEBUGGING				0
#import "UTILDebugging.h"


static void scanResLinkElement_(NSString *str, NSMutableIndexSet *buffer);


@implementation CMRThreadLinkProcessor
+ (BOOL)parseBoardLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL
{
	NSURL *link_;
	NSString *boardName_ = nil;
	BOOL result_ = NO;

	link_ = [NSURL URLWithLink:aLink];
	UTILRequireCondition(link_, ReturnResult);

	// 最低限の救済措置として、末尾に「index.html」などがくっついていた場合は除去を試みる
	{
		CFStringRef lastPathExt = CFURLCopyPathExtension((CFURLRef)link_);
		if (lastPathExt != NULL) {
			CFURLRef anotherLink_ = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, (CFURLRef)link_);
			link_ = [[(NSURL *)anotherLink_ copy] autorelease];
			CFRelease(anotherLink_);
			CFRelease(lastPathExt);
		}
	}

	boardName_ = [[BoardManager defaultManager] boardNameForURL:link_];

	UTILRequireCondition(boardName_, ReturnResult);
	result_ = YES;

ReturnResult:
	if (pBoardName != NULL) *pBoardName = boardName_;
	if (pBoardURL  != NULL) *pBoardURL = link_;

	return result_;
}

+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL filepath:(NSString **)pFilepath
{
    return [self parseThreadLink:aLink boardName:pBoardName boardURL:pBoardURL filepath:pFilepath parsedHost:NULL];
}

+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL filepath:(NSString **)pFilepath parsedHost:(NSString **)pH
{
	NSURL			*link_;
	CMRHostHandler	*handler_;
	
	NSString	*bbs_;
	NSString	*key_;
	
	NSURL		*boardURL_  = nil;
    NSURL       *currentBoardURL_ = nil;
	NSString	*boardName_ = nil;
	NSString	*filepath_  = nil;
	
	BOOL		result_ = NO;
	
	
	link_ = [NSURL URLWithLink:aLink];
	UTILRequireCondition(link_, ReturnResult);
	handler_ = [CMRHostHandler hostHandlerForURL:link_];
	UTILRequireCondition(handler_, ReturnResult);
	
	if (![handler_ parseParametersWithReadURL:link_ bbs:&bbs_ key:&key_ start:NULL to:NULL showFirst:NULL]) {
		goto ReturnResult;
	}

	boardURL_ = [handler_ boardURLWithURL:link_ bbs:bbs_];
	UTILRequireCondition(boardURL_, ReturnResult);

	boardName_ = [[BoardManager defaultManager] boardNameForURL:boardURL_];
	UTILRequireCondition(boardName_, ReturnResult);

    currentBoardURL_ = [[BoardManager defaultManager] URLForBoardName:boardName_];
    UTILRequireCondition(currentBoardURL_, ReturnResult);

	filepath_ = [[CMRDocumentFileManager defaultManager] threadPathWithBoardName:boardName_ datIdentifier:key_];
	result_ = YES;

ReturnResult:
	if (pBoardName != NULL) {
        *pBoardName = boardName_;
    }
	if (pBoardURL != NULL) {
        *pBoardURL = currentBoardURL_;
    }
	if (pFilepath != NULL) {
        *pFilepath = filepath_;
	}
    if (pH != NULL) {
        *pH = [boardURL_ host];
    }
	return result_;
}

+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName threadSignature:(CMRThreadSignature **)pSignature
{
	NSURL			*link_;
	CMRHostHandler	*handler_;
	
	NSString	*bbs_;
	NSString	*key_;
	
	NSURL		*boardURL_  = nil;
	NSString	*boardName_ = nil;
	CMRThreadSignature	*signature_  = nil;
	
	BOOL		result_ = NO;
	
	
	link_ = [NSURL URLWithLink:aLink];
	UTILRequireCondition(link_, ReturnResult);
	handler_ = [CMRHostHandler hostHandlerForURL:link_];
	UTILRequireCondition(handler_, ReturnResult);
	
	if (![handler_ parseParametersWithReadURL:link_ bbs:&bbs_ key:&key_ start:NULL to:NULL showFirst:NULL]) {
		goto ReturnResult;
	}
    
	boardURL_ = [handler_ boardURLWithURL:link_ bbs:bbs_];
	UTILRequireCondition(boardURL_, ReturnResult);
    
	boardName_ = [[BoardManager defaultManager] boardNameForURL:boardURL_];
	UTILRequireCondition(boardName_, ReturnResult);
    
    signature_ = [CMRThreadSignature threadSignatureWithIdentifier:key_ boardName:boardName_];
	result_ = YES;
    
ReturnResult:
	if (pBoardName != NULL) {
        *pBoardName = boardName_;
    }
	if (pSignature != NULL) {
        *pSignature = signature_;
	}

	return result_;
}

+ (BOOL)isMessageLinkUsingLocalScheme:(id)aLink messageIndexes:(NSIndexSet **)indexSetPtr
{
	NSString			*str_;
	NSArray				*comps_;
//	NSEnumerator		*iter_;
//	NSString			*elem_;

	NSMutableIndexSet	*buffer_ = [NSMutableIndexSet indexSet];
	
	UTIL_DEBUG_METHOD;
	UTIL_DEBUG_WRITE1(@"aLink = %@", [aLink stringValue]);
	
	UTILRequireCondition(aLink, RetMessageLink);
	
	str_ = [aLink stringValue];
	str_ = [str_ stringByDeletingURLScheme:CMRAttributeInnerLinkScheme];
	comps_ = [str_ componentsSeparatedByCharacterSequenceFromSet:[NSCharacterSet innerLinkSeparaterCharacterSet]];

	UTIL_DEBUG_WRITE1(@"str_ = %@", [str_ stringValue]);
	UTIL_DEBUG_WRITE1(@"comps_ = %@", [comps_ stringValue]);
	
	UTILRequireCondition(comps_ && [comps_ count], RetMessageLink);
	
//	iter_ = [comps_ objectEnumerator];
//	while (elem_ = [iter_ nextObject]) {
//		scanResLinkElement_(elem_, buffer_);
//	}
    
    for (NSString *element in comps_) {
        scanResLinkElement_(element, buffer_);
    }

	if ([buffer_ count] > 0) {
		if (indexSetPtr != NULL) *indexSetPtr = buffer_;
		return YES;
	}

RetMessageLink:
	return NO;
}

+ (BOOL)isBeProfileLinkUsingLocalScheme:(id)aLink linkParam:(NSString **)aParam
{
	NSString *str_ = nil;
	BOOL ret = NO;

	UTILRequireCondition(aLink, RetMessageLink);

	str_ = [aLink stringValue];
	str_ = [str_ stringByDeletingURLScheme:CMRAttributesBeProfileLinkScheme];

	if (str_) {
        ret = YES;
	}
RetMessageLink:
	if (aParam != NULL) {
        *aParam = str_;
    }
	return ret;
}
@end

/*
A - B ==> {A, B-A}
A - B - C ==> {A, 1}, {B, 1}, {C, 1}, 
*/
static void scanResLinkElement_(NSString *str, NSMutableIndexSet *buffer)
{
	if (!str || [str length] == 0) {
		return;
	}

	NSMutableString *tmp;
	NSMutableIndexSet *tmpIndexes = [NSMutableIndexSet indexSet];

	UTIL_DEBUG_FUNCTION;
	tmp = [[NSMutableString alloc] initWithString:str];
	CFStringTransform((CFMutableStringRef)tmp, NULL, kCFStringTransformFullwidthHalfwidth, false);
	UTIL_DEBUG_WRITE1(@"string: %@", tmp);

	[tmp replaceCharactersInSet:[NSCharacterSet innerLinkRangeCharacterSet] toString:@" "];
	UTIL_DEBUG_WRITE1(@"Replace separater, trim: %@", tmp);

	NSScanner *scan = [NSScanner scannerWithString:tmp];
	NSInteger idx = 0;
	[tmp release];
	[scan setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
	while (1) {
// #warning 64BIT: scanInt: argument is pointer to int, not NSInteger; you can use scanInteger:
// 2012-08-14 tsawada2 修正済
		if (![scan scanInteger:&idx]) {
			break;
        }
		if (idx < 1) {
            continue;
        }
		// 他のメソッドはレス番号を０ベースとして扱うので
		UTIL_DEBUG_WRITE1(@"Index: %ld", (long)(idx - 1));
		[tmpIndexes addIndex:(idx - 1)];
	}

	NSUInteger numOfIdxes = [tmpIndexes count];

	UTIL_DEBUG_WRITE1(@"tmpIndexes: %@", bar);

	if (numOfIdxes == 0) {
		return;
	} else if (numOfIdxes == 2) {
		NSUInteger first = [tmpIndexes firstIndex];
		NSUInteger last = [tmpIndexes lastIndex];
        NSUInteger length = last - first + 1;
        if (length > 100) { // 100個以上連続するレスアンカー（>>1-1001など）は、100個までしか処理しないようにする
            length = 100;
        }
		NSRange	foo = NSMakeRange(first, length);
		[buffer addIndexesInRange:foo];
	} else {
		[buffer addIndexes:tmpIndexes];
	}

	UTIL_DEBUG_WRITE1(@"IndexSet(buffer): %@", buffer);
}
