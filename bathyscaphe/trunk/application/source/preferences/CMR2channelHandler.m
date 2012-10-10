//
//  CMR2channelHandler.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/03/25.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMR2channelHandler.h"
#import "CMRHostHandler_p.h"


@implementation CMR2channelHandler
+ (BOOL)canHandleURL:(NSURL *)anURL
{
    const char *hs = [[anURL host] UTF8String];
    
    if (NULL == hs) {
        return NO;
    }
    return is_2channel(hs);
}

- (NSDictionary *)properties
{
    return CMRHostPropertiesForKey(@"2channel");
}

- (NSString *)makeURLStringWithBoard:(NSURL *)boardURL datName:(NSString *)datName
{
    NSString        *absolute_;
    const char      *bbs_ = NULL;
    NSURL           *location_;
    NSDictionary    *properties_;
    
    UTILRequireCondition(boardURL && datName, ErrReadURL);

    location_ = [self readURLWithBoard:boardURL];
    UTILRequireCondition(location_, ErrReadURL);
    
    properties_ = [self readCGIProperties];
    UTILRequireCondition(properties_, ErrReadURL);
    
    CMRGetHostCStringFromBoardURL(boardURL, &bbs_);
    UTILRequireCondition(bbs_, ErrReadURL);

// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 検証済
    absolute_ = [NSString stringWithFormat:
                    READ_URL_FORMAT_2CH,
                    [location_ absoluteString],
                    bbs_,
                    datName];

    return absolute_;

ErrReadURL:
    return nil;
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
{
    NSString        *absolute_;
    NSURL           *location_;

    absolute_ = [self makeURLStringWithBoard:boardURL datName:datName];
    UTILRequireCondition(absolute_, ErrReadURL);

    location_ = [NSURL URLWithString:absolute_];

    return location_;
    
ErrReadURL:
    return nil;
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                latestCount:(NSInteger)count
{
    NSString *base_;
    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    if (!base_) {
        return nil;
    }
// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
    return [NSURL URLWithString:[base_ stringByAppendingFormat:@"l%ld", (long)count]];
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                  headCount:(NSInteger)count
{
    NSString *base_;
    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    if (!base_) {
        return nil;
    }
// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
    return [NSURL URLWithString:[base_ stringByAppendingFormat:@"-%ld", (long)count]];
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                      start:(NSUInteger)startIndex
                        end:(NSUInteger)endIndex
                    nofirst:(BOOL)nofirst
{
    id              tmp;
    NSURL           *location_;
    NSString        *base_;

    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    UTILRequireCondition(base_, ErrReadURL);

    tmp = SGTemporaryString();
    [tmp setString:base_];
    if (startIndex != NSNotFound) {
// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
        [tmp appendFormat:@"%lu", (unsigned long)startIndex];
    }
    if (endIndex != NSNotFound && endIndex != startIndex) {
        if (NSNotFound == startIndex) {
            [tmp appendString:@"1"];
        }
// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
        [tmp appendFormat:@"-%lu", (unsigned long)endIndex];
    }

    location_ = [NSURL URLWithString:tmp];

    return location_;

ErrReadURL:
    return nil;
}
@end


@implementation CMR2channelOtherHandler
+ (BOOL)canHandleURL:(NSURL *)anURL
{
	const char *hs = [[anURL host] UTF8String];
	
	if (NULL == hs) {
		return NO;
	}
	return YES;
}
@end
