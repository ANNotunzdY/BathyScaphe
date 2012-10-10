//
//  CMRHostHandler.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/12/13.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRHostHandler_p.h"
#import "CMR2channelHandler.h"
#import "CMRHostHTMLHandler.h"


@implementation CMRHostHandler
+ (NSMutableArray *)registeredHostHandlers
{
    static NSMutableArray *kRegisteredHostHandlers;

    if (!kRegisteredHostHandlers) {
        kRegisteredHostHandlers = [[NSMutableArray alloc] initWithCapacity:3];
    }
    return kRegisteredHostHandlers;
}

+ (void)registerAllKnownHostHandlerClasses
{
    [self registerHostHandlerClass:[CMR2channelHandler class]];
    [self registerHostHandlerClass:[BSHostLivedoorHandler class]];
    [self registerHostHandlerClass:[CMRMachibbsHandler class]];

    // 上記以外 = 2channel互換
    // datの改行を<br>にしていない板などが存在するので、サポートやめ
    [self registerHostHandlerClass:[CMR2channelOtherHandler class]];
}

+ (void)initialize
{
    static BOOL isFirst_ = YES;
    
    if (!isFirst_) {
        return;
    }
    isFirst_ = NO;

    [self registerAllKnownHostHandlerClasses];
}

+ (id)hostHandlerForURL:(NSURL *)anURL
{
    NSMutableArray *handlerArray_ = [self registeredHostHandlers];
    
    if (!anURL) {
        return nil;
    }

    for (id instance in handlerArray_) {
        if ([[instance class] canHandleURL:anURL]) {
            return instance;
        }
    }
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat: 
                        @"<%@ %p> identifier=%@ name=%@",
                        [self className],
                        self,
                        [self identifier],
                        [self name]];
}

#pragma mark Managing subclasses
+ (BOOL)canHandleURL:(NSURL *)anURL
{
    UTILAbstractMethodInvoked;
    return NO;
}

+ (void)registerHostHandlerClass:(Class)aHostHandlerClass
{
    NSMutableArray *handlerArray_ = [self registeredHostHandlers];
    NSEnumerator *iter_ = [handlerArray_ objectEnumerator];
    id instance_;

    UTILAssertNotNilArgument(aHostHandlerClass, @"HostHandler Class");
    // 既に登録されていないか
    while (instance_ = [iter_ nextObject]) {
        if ([(id)[instance_ class] isEqual:aHostHandlerClass]) {
            return;
        }
    }

    instance_ = [[aHostHandlerClass alloc] init];
    [handlerArray_ addObject:instance_];

    [instance_ release];
}

- (NSDictionary *)properties
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (NSString *)name
{
    return [[self properties] objectForKey:kHostNameKey];
}

- (NSString *)identifier
{
    return [[self properties] objectForKey:kHostIdentifierKey];
}

- (NSDictionary *)readCGIProperties
{
    return [[self properties] objectForKey:kReadCGIPropertiesKey];
}

- (BOOL)canReadDATFile
{
    return [[self properties] boolForKey:kCanReadDATFileKey];
}

- (NSURL *)datURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName
{
    NSString        *relativePath_;
    NSURL           *location_;

    UTILRequireCondition(boardURL && datName, ErrDATURL);
    UTILRequireCondition([self canReadDATFile], ErrDATURL);

    relativePath_ = [[self properties] objectForKey:kRelativeDATDirectoryKey];
    UTILRequireCondition(relativePath_, ErrDATURL);

    location_ = [NSURL URLWithString:relativePath_ relativeToURL:boardURL];
    location_ = [location_ URLByAppendingPathComponent:datName];

    return location_;

ErrDATURL:
    return nil;
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL
{
    id property_;
    NSURL *location_;

    UTILRequireCondition(boardURL, ErrReadURL);

    property_ = [[self readCGIProperties] objectForKey:kRelativePathKey];
    UTILRequireCondition(property_, ErrReadURL);
    location_ = [NSURL URLWithString:property_ relativeToURL:boardURL];

    return location_;

ErrReadURL:
    return nil;
}

- (NSString *)makeURLStringWithBoard:(NSURL *)boardURL datName:(NSString *)datName
{
    NSString        *absolute_;
    NSURL           *location_;
    NSDictionary    *properties_;

    UTILRequireCondition(boardURL && datName, ErrReadURL);

    location_ = [self readURLWithBoard:boardURL];
    UTILRequireCondition(location_, ErrReadURL);

    properties_ = [self readCGIProperties];
    UTILRequireCondition(properties_, ErrReadURL);

// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 検証済
    absolute_ = [NSString stringWithFormat:
                    READ_URL_FORMAT_DEF,
                    [location_ absoluteString],
                    [properties_ objectForKey:kReadCGIParamBBSKey],
                    [[boardURL absoluteString] lastPathComponent],
                    [properties_ objectForKey:kReadCGIParamIDKey],
                    datName];

    return absolute_;
ErrReadURL:
    return nil;
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName
{
    NSString *absolute_;
    NSURL *location_;

    absolute_ = [self makeURLStringWithBoard:boardURL datName:datName];
    UTILRequireCondition(absolute_, ErrReadURL);

    location_ = [NSURL URLWithString:absolute_];

    return location_;
    
ErrReadURL:
    return nil;
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName latestCount:(NSInteger)count
{
    return [self readURLWithBoard:boardURL datName:datName];
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName headCount:(NSInteger)count;
{
    return [self readURLWithBoard:boardURL datName:datName];
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                      start:(NSUInteger)startIndex
                        end:(NSUInteger)endIndex
                    nofirst:(BOOL)nofirst
{
    id              tmp;
    NSURL           *location_;
    NSDictionary    *properties_;
    NSString        *paramKey_;
    NSString    *base_;
    
    properties_ = [[self properties] objectForKey:kReadCGIPropertiesKey];
    UTILRequireCondition(properties_, ErrReadURL);
    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    UTILRequireCondition(base_, ErrReadURL);
    
    tmp = SGTemporaryString();
    [tmp setString:base_];
    if (startIndex != NSNotFound) {
        paramKey_ = [properties_ objectForKey:kReadCGIParamStartKey];
        UTILAssertKindOfClass(paramKey_, NSString);

// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 修正済
        [tmp appendFormat:@"&%@=%lu", paramKey_, (unsigned long)startIndex];
    }
    if (endIndex != NSNotFound) {
        paramKey_ = [properties_ objectForKey:kReadCGIParamEndKey];
        UTILAssertKindOfClass(paramKey_, NSString);

// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 修正済
        [tmp appendFormat:@"&%@=%lu", paramKey_, (unsigned long)endIndex];
    }
    if (nofirst) {
        paramKey_ = [properties_ objectForKey:kReadCGIParamNoFirstKey];
        [tmp appendFormat:@"&%@=", paramKey_];
        paramKey_ = [properties_ objectForKey:kReadCGIParamTrueKey];
        [tmp appendString:paramKey_];
    }

    location_ = [NSURL URLWithString:tmp];

    return location_;

ErrReadURL:
    return nil;
}

/* エンコーディング関連 */
- (CFStringEncoding)subjectEncoding
{
    NSNumber    *v;
    
    v = [[self properties] numberForKey:@"SubjectEncoding"];
    return v ? [v unsignedIntegerValue] : kCFStringEncodingDOSJapanese;
}

- (CFStringEncoding)threadEncoding
{
    NSNumber    *v;
    
    v = [[self properties] numberForKey:@"ThreadEncoding"];
    return v ? [v unsignedIntegerValue] : kCFStringEncodingDOSJapanese;
}

- (NSURL *)boardURLWithURL:(NSURL *)anURL bbs:(NSString *)bbs
{
    if (!anURL || !bbs || [bbs isEmpty]) {
        return nil;
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/%@/", [anURL host], bbs]];
}

- (BOOL)parseParametersWithReadURL:(NSURL *)link
                               bbs:(NSString **)bbs
                               key:(NSString **)key
                             start:(NSUInteger *)startIndex
                                to:(NSUInteger *)endIndex
                         showFirst:(BOOL *)showFirst
{
    NSArray *comps_;
    id tmp;

    id cgiName_;
    NSString *directory_;
    NSUInteger directoryIndex_;
    NSDictionary *properties_;

    if (bbs != NULL) *bbs = nil;
    if (key != NULL) *key = nil;
    if (startIndex != NULL) *startIndex = NSNotFound;
    if (endIndex != NULL) *endIndex = NSNotFound;
    if (showFirst != NULL) *showFirst = YES;

    UTILRequireCondition(link, ErrParse);
    UTILRequireCondition([[self class] canHandleURL:link], ErrParse);

    properties_ = [self readCGIProperties];
    tmp = [properties_ objectForKey:kReadCGIDirectoryIndexKey];
    UTILAssertKindOfClass(tmp, NSNumber);
    directoryIndex_ = [tmp unsignedIntegerValue];

    cgiName_ = [properties_ objectForKey:kReadCGINameKey];
    UTILRequireCondition(([cgiName_ isKindOfClass:[NSString class]] || [cgiName_ isKindOfClass:[NSArray class]]), ErrParse);

    directory_ = [properties_ objectForKey:kReadCGIDirectoryKey];
    UTILAssertKindOfClass(directory_, NSString);

    comps_ = [[link path] pathComponents];
    UTILRequireCondition(([comps_ count] > directoryIndex_ +1), ErrParse);
    
    // ディレクトリとCGIの名前
    tmp = [comps_ objectAtIndex:directoryIndex_];
    UTILRequireCondition([tmp isEqualToString:directory_], ErrParse);
    tmp = [comps_ objectAtIndex:directoryIndex_ +1];

    if ([cgiName_ isKindOfClass:[NSString class]]) {
        UTILRequireCondition([tmp hasPrefix:cgiName_], ErrParse);
    } else { // NSArray
        NSEnumerator *iter = [cgiName_ objectEnumerator];
        NSString *eachName;
        BOOL flag = NO;
        while (eachName = [iter nextObject]) {
            if ([tmp hasPrefix:eachName]) {
                flag = YES;
                break;
            }
        }
        UTILRequireCondition(flag, ErrParse);
    }
    
    // クエリによるパラメータ指定ならそれを解析。
    // そうでなければ、最後のパス要素をスキャン。
    if ([link query]) {
        NSDictionary *params_;
        NSString *bbs_;
        NSString *key_;
        NSString *st_;
        NSString *to_;
        NSString *nofirst_;
        
        params_ = [link queryDictionary];
        UTILRequireCondition(params_, ErrParse);
        

        tmp = [properties_ objectForKey:kReadCGIParamBBSKey];
        bbs_ = [params_ objectForKey:tmp];

        if (!bbs_) {
            return NO;
        }
        if (bbs != NULL) {
            *bbs = bbs_;
        }
        tmp = [properties_ objectForKey:kReadCGIParamIDKey];
        key_ = [params_ objectForKey:tmp];

        if (!key_) {
            return NO;
        }
        if (key != NULL) {
            *key = key_;
        }
        tmp = [properties_ objectForKey:kReadCGIParamStartKey];
        st_ = [params_ objectForKey:tmp];
        if (startIndex != NULL) {
            *startIndex = st_ ? [st_ integerValue] : NSNotFound;
        }
        tmp = [properties_ objectForKey:kReadCGIParamEndKey];
        to_ = [params_ objectForKey:tmp];
        if (endIndex != NULL) {
            *endIndex = to_ ? [to_ integerValue] : NSNotFound;
        }
        tmp = [properties_ objectForKey:kReadCGIParamNoFirstKey];
        nofirst_ = [params_ objectForKey:tmp];
        tmp = [properties_ objectForKey:kReadCGIParamTrueKey];
        if (!nofirst_) {
            nofirst_ = tmp;
        }

        if (showFirst != NULL) {
            *showFirst = (NO == [nofirst_ isEqualToString:tmp]);
        }
        
        return YES;

    } else if ([comps_ count] > directoryIndex_ + 3) {
        if (bbs != NULL) {
            *bbs = [comps_ objectAtIndex:directoryIndex_ + 2];
        }
        if (key != NULL) {
            *key = [comps_ objectAtIndex:directoryIndex_ + 3];
        }
        if ([comps_ count] > directoryIndex_ + 4) {
            NSString  *mesIndexStr_;
            NSScanner *scanner_;
            NSString  *skiped_;
            NSInteger index_;
            
            skiped_ = nil;
            
            // 最後のパス文字列がインデックス文字列
            // になっているので、そこからインデックス
            // をスキャン
            mesIndexStr_ = [comps_ lastObject];
            scanner_ = [NSScanner scannerWithString:mesIndexStr_];
            [scanner_ scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&skiped_];
// #warning 64BIT: scanInt: argument is pointer to int, not NSInteger; you can use scanInteger:
// 2010-03-27 tsawada2 修正済
            if ([scanner_ scanInteger:&index_]) {
                if (startIndex != NULL) {
                    *startIndex = index_;
                }
                if (endIndex != NULL) {
                    *endIndex = index_;
                }
                // 範囲が指定されているか
                if ([scanner_ scanString:@"-" intoString:NULL]) {
// #warning 64BIT: scanInt: argument is pointer to int, not NSInteger; you can use scanInteger:
// 2010-03-27 tsawada2 修正済
                    if ([scanner_ scanInteger:&index_]) {
                        if (endIndex != NULL) {
                            *endIndex = index_;
                        }
                    }
                }
            }
            if (showFirst != NULL) {
                *showFirst = NO;
            }
        }

        return YES;

    }   

ErrParse:
    return NO;
}
@end


@implementation CMRHostHandler(WriteCGI)
#define kWriteCGIPropertiesKey      @"CGI - Write"
#define kFormKeyDictKey             @"FormKeys"
#define kWriteCGISubmitValueKey     @"submitValue"
#define kWriteCGISubmitNewThreadValueKey        @"submitValue_newThread"

- (NSDictionary *)writeCGIProperties
{
    return [[self properties] objectForKey:kWriteCGIPropertiesKey];
}

- (NSDictionary *)formKeyDictionary
{
    return [[self writeCGIProperties] dictionaryForKey:kFormKeyDictKey];
}

- (NSURL *)writeURLWithBoard:(NSURL *)boardURL
{
    NSString    *path_;

    if (!boardURL) {
        return nil;
    }
    path_ = [[self writeCGIProperties] stringForKey:kRelativePathKey];
    if (path_) {
        return [NSURL URLWithString:path_ relativeToURL:boardURL];
    }
    path_ = [[self writeCGIProperties] stringForKey:kAbsolutePathKey];
    if (path_) {
        return [NSURL URLWithString:path_];
    }
    return nil;
}

- (NSURL *)threadCreationWriteURLWithBoard:(NSURL *)boardURL
{
    return [self writeURLWithBoard:boardURL];
}

- (NSString *)submitValue
{
    return [[self writeCGIProperties] stringForKey:kWriteCGISubmitValueKey];
}

- (NSString *)submitNewThreadValue
{
    return [[self writeCGIProperties] stringForKey:kWriteCGISubmitNewThreadValueKey];
}
@end


NSDictionary *CMRHostPropertiesForKey(NSString *aKey)
{
    static NSDictionary     *allProperties_;
    
    if (!allProperties_) {
        allProperties_ = [[NSBundle mergedDictionaryWithName:kHostPropertiesFile] retain];
    }
    return [allProperties_ dictionaryForKey:aKey];
}
