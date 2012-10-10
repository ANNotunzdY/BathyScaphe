//
//  CMRHostHTMLHandler.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/27.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRHostHandler_p.h"
#import "CMRHostHTMLHandler.h"

@implementation CMRHostHTMLHandler
- (NSURL *)rawmodeURLWithBoard:(NSURL *)boardURL
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (NSURL *)rawmodeURLWithBoard:(NSURL *)boardURL
                       datName:(NSString *)datName
                         start:(NSUInteger)startIndex
                           end:(NSUInteger)endIndex
                       nofirst:(BOOL)nofirst
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (id)parseHTML:(NSString *)inputSource with:(id)thread count:(NSUInteger)loadedCount lastReadedCount:(NSUInteger *)lastCount
{
    UTILAbstractMethodInvoked;
    return nil;
}
@end


@implementation CMRMachibbsHandler
+ (BOOL)canHandleURL:(NSURL *)anURL
{
    const char *hostName_ = [[anURL host] UTF8String];
    if (NULL == hostName_) {
        return NO;
    }
    return is_machi(hostName_);
}

- (NSDictionary *)properties
{
    return CMRHostPropertiesForKey(@"machibbs");
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName latestCount:(NSInteger)count
{
    NSString    *base_;
    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    if (!base_) {
        return nil;
    }
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 修正済
    return [NSURL URLWithString:[base_ stringByAppendingFormat:@"&LAST=%ld", (long)count]];
}

/*
■パラメタ
http://[SERVER]/bbs/offlaw.cgi/[BBS]/[KEY]/[OPTION]

■オプション
オプションなし：スレッド全文取得(read.cgi共通)
x：レス番xのレスを取得(read.cgi共通)
x-y：xからyの範囲を取得(read.cgi共通)
x-：x以降のレスを取得(read.cgi共通)
-x：xまでのレスを取得(read.cgi共通)
lx：最後から数えてx個のレスを取得(read.cgi共通)
m：Last-Modifiedを取得(offlaw.cgiのみ)

まちBBS　削除FAQ　～携帯・専ブラ利用者用～
http://hokkaido.machi.to/bbs/read.cgi?BBS=hokkaidou&KEY=1235446469

*/
- (NSURL *)rawmodeURLWithBoard:(NSURL *)boardURL
{
    id property_;
    NSURL *location_;

    UTILRequireCondition(boardURL, ErrReadURL);

    property_ = [[self readCGIProperties] objectForKey:kRelativePathRawModeKey];
    UTILRequireCondition(property_, ErrReadURL);
    location_ = [NSURL URLWithString:property_ relativeToURL:boardURL];

    return location_;
    
ErrReadURL:
    return nil;
}

- (NSURL *)rawmodeURLWithBoard:(NSURL *)boardURL
                       datName:(NSString *)datName
                         start:(NSUInteger)startIndex
                           end:(NSUInteger)endIndex
                       nofirst:(BOOL)nofirst
{
    NSMutableString *absolute_;
    NSURL           *location_;
    NSDictionary    *properties_;

    UTILRequireCondition(boardURL && datName, ErrReadURL);

    location_ = [self rawmodeURLWithBoard:boardURL];
    UTILRequireCondition(location_, ErrReadURL);

    properties_ = [self readCGIProperties];
    UTILRequireCondition(properties_, ErrReadURL);
    
    absolute_ = [NSMutableString stringWithFormat:
                    MACHI_OFFLAW_FORMAT,
                    [location_ absoluteString],
                    [[boardURL absoluteString] lastPathComponent],
                    datName];

    if (startIndex != NSNotFound) {
        [absolute_ appendFormat:@"%lu-", (unsigned long)startIndex];
    }
    if (endIndex != NSNotFound) {
        if (endIndex != startIndex) {
            if (NSNotFound == startIndex) {
                [absolute_ appendString:@"1-"];
            }
            [absolute_ appendFormat:@"%lu", (unsigned long)endIndex];
        } else {
            NSUInteger length = [absolute_ length];
            [absolute_ deleteCharactersInRange:NSMakeRange(length-1, 1)];
        }
    }

    return [NSURL URLWithString:absolute_];
ErrReadURL:
    return nil;
}

#pragma mark HTML Parser
- (void)addDatLine:(NSArray *)components with:(id)thread count:(NSUInteger *)pLoadedCount
{
    NSUInteger actualIndex = [[components objectAtIndex:0] integerValue];

    if (actualIndex == 0) return;

    if (*pLoadedCount != NSNotFound && *pLoadedCount +1 != actualIndex) {
        NSUInteger  i;

        // 適当に行を詰める
        NSLog(@"CMRMachibbsHandler: Invisible Abone Detected(%lu)", (unsigned long)actualIndex);
        for (i = *pLoadedCount +1; i < actualIndex; i++) {
            [thread appendString:@"<><><><>\n"];
        }
    }

    *pLoadedCount = actualIndex;

    NSString *tmp_ = [NSString stringWithFormat:@"%@<>%@<>%@<>%@<>\n",
                                                [components objectAtIndex:1],
                                                [components objectAtIndex:2],
                                                [components objectAtIndex:3],
                                                [components objectAtIndex:4]];

    [thread appendString:tmp_];
}

- (id)parseHTML:(NSString *)inputSource with:(id)thread count:(NSUInteger)loadedCount lastReadedCount:(NSUInteger *)lastCount
{
    NSArray *eachLineArray_ = [inputSource componentsSeparatedByString:@"\n"];
    NSEnumerator *iter_ = [eachLineArray_ objectEnumerator];
    NSString *eachLine_;
    BOOL titleParsed_ = NO;
    NSUInteger parsedCount = loadedCount;

    while (eachLine_ = [iter_ nextObject]) {
        NSArray *components_ = [eachLine_ componentsSeparatedByString:@"<>"];
/*
ログフォーマットは、
レス番<>投稿者名<>メールアドレス<>日付 時刻 ID<>本文<>サブジェクト[改行]

となっております。
*/        
        [self addDatLine:components_ with:thread count:&parsedCount];
        
        if (!titleParsed_) {
            NSString *title_ = [components_ objectAtIndex:5];
            if (![title_ isEqualToString:@""]) {
                NSRange found;

                found = [thread rangeOfString:@"\n"];
                if (found.length != 0) {
                    [thread insertString:title_ atIndex:found.location];
                }
            }
            titleParsed_ = YES;
        }
    }
    if (lastCount != NULL) {
        *lastCount = parsedCount;        
    }
    return thread;
}
@end
