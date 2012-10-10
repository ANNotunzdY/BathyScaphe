//
//  BSTGrepSoulGem.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/03/16.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSTGrepSoulGem.h"
#import <CocoaOniguruma/OnigRegexp.h>
#import "BSTGrepResult.h"
#import "CMXTextParser.h"


@implementation BSTGrepSoulGem

@synthesize searchOptionType = m_searchOptionType;

- (id)init
{
    if (self = [super init]) {
        self.searchOptionType = BSTGrepSearchByNew;
    }
    return self;
}

- (NSString *)HTMLSourceAtPath:(NSString *)filepath
{
    return [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:NULL];
}

- (NSString *)queryStringForSearchString:(NSString *)searchStr
{
    NSString *encodedString = [searchStr stringByURLEncodingUsingEncoding:NSUTF8StringEncoding];
    if (!encodedString || [encodedString isEqualToString:@""]) {
        return nil;
    }
    NSString *option = (self.searchOptionType == BSTGrepSearchByNew) ? @"new" : @"fast";
    NSString *queryString = [NSString stringWithFormat:@"http://page2.xrea.jp/tgrep/search?q=%@&o=%@&n=250&v=2", encodedString, option];
    return queryString;
}

- (NSTimeInterval)cacheTimeInterval
{
    return 3600;
}

- (BOOL)canHandleSearchOptionType:(BSTGrepSearchOptionType)type
{
    if (type == BSTGrepSearchByCount || type == BSTGrepSearchByLast) {
        return NO;
    }
    return YES;
}

- (NSArray *)parseHTMLSource:(NSString *)source error:(NSError **)errorPtr
{
    static OnigRegexp *re = nil;
    if (!re) {
        re = [[OnigRegexp compile:@"<a id=\"tt([0-9]*)\" href=\"(.*)\" target=\"_blank\">(.*)</a>" ignorecase:NO multiline:NO] retain];
    }
    NSUInteger length = [source length];
    NSRange searchRange = NSMakeRange(0, length);
    NSMutableArray *foo = [NSMutableArray arrayWithCapacity:250];
    OnigResult *result;
    BSTGrepResult *obj;
    NSRange foundRange;
    while (searchRange.length > 0) {
        result = [re search:source range:searchRange];
        if (!result) {
            break;
        }
        obj = [[BSTGrepResult alloc] initWithOrderStr:[result stringAt:1] URL:[result stringAt:2] titleWithBoldTag:[result stringAt:3]];
        [foo addObject:obj];
        [obj release];
        foundRange = [result bodyRange];
        searchRange.location = NSMaxRange(foundRange);
        searchRange.length = length - searchRange.location;
    }
    
    return foo;
}

- (BSTGrepSearchOptionType)defaultSearchOptionType
{
    return BSTGrepSearchByNew;
}
@end


@implementation BSFind2chSoulGem
- (NSString *)HTMLSourceAtPath:(NSString *)filepath
{
    NSData *data = [NSData dataWithContentsOfFile:filepath options:NSUncachedRead error:NULL];
    return [CMXTextParser stringWithData:data CFEncoding:kCFStringEncodingEUC_JP];
}

- (NSString *)queryStringForSearchString:(NSString *)searchStr
{
    NSString *encodedString = [searchStr stringByURLEncodingUsingEncoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingEUC_JP)];
    if (!encodedString || [encodedString isEqualToString:@""]) {
        return nil;
    }
    NSString *option = (self.searchOptionType == BSTGrepSearchByLast) ? @"MODIFIED" : @"NPOSTS";
    NSString *queryString = [NSString stringWithFormat:@"http://find.2ch.net/index.php?TYPE=TITLE&STR=%@&SCEND=A&SORT=%@&COUNT=50", encodedString, option];
    return queryString;
}

- (NSTimeInterval)cacheTimeInterval
{
    return 600;
}

- (BOOL)canHandleSearchOptionType:(BSTGrepSearchOptionType)type
{
    if (type == BSTGrepSearchByFast || type == BSTGrepSearchByNew) {
        return NO;
    }
    return YES;
}

- (NSArray *)parseHTMLSource:(NSString *)source error:(NSError **)errorPtr
{
    static OnigRegexp *re = nil;
    if (!re) {
        re = [[OnigRegexp compile:@"<dt><a (?:target=\"_blank\" )*href=\"(.*?/)[0-9]*-[0-9]*\">(.*)</a> \\([0-9]*\\)" ignorecase:NO multiline:NO] retain];
    }
    NSUInteger orderNo = 1;
    NSUInteger length = [source length];
    NSRange searchRange = NSMakeRange(0, length);
    NSMutableArray *foo = [NSMutableArray arrayWithCapacity:50];
    OnigResult *result;
    BSTGrepResult *obj;
    NSRange foundRange;
    while (searchRange.length > 0) {
        result = [re search:source range:searchRange];
        if (!result) {
            if (errorPtr != NULL) {
                NSRange timeoutMessageFound = [source rangeOfString:NSLocalizedString(@"BSFind2chSoulGem Error Detect", nil) options:NSLiteralSearch];
                if (timeoutMessageFound.length != 0) {
                    *errorPtr = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSFind2chSoulGemServerCapacityError userInfo:nil];
                }
            }
            break;
        }
        obj = [[BSTGrepResult alloc] initWithOrderNo:orderNo URL:[result stringAt:1] titleWithoutBoldTag:[result stringAt:2]];
        [foo addObject:obj];
        [obj release];
        foundRange = [result bodyRange];
        searchRange.location = NSMaxRange(foundRange);
        searchRange.length = length - searchRange.location;
        orderNo++;
    }
    
    return foo;
}

- (BSTGrepSearchOptionType)defaultSearchOptionType
{
    return BSTGrepSearchByLast;
}
@end
