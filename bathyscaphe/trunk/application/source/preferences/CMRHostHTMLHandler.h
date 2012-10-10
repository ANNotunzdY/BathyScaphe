//
//  CMRHostHTMLHandler.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/27.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRHostHandler_p.h"


@interface CMRHostHTMLHandler : CMRHostHandler {

}

- (NSURL *)rawmodeURLWithBoard:(NSURL *)boardURL;

- (NSURL *)rawmodeURLWithBoard:(NSURL *)boardURL
                       datName:(NSString *)datName
                         start:(NSUInteger)startIndex
                           end:(NSUInteger)endIndex
                       nofirst:(BOOL)nofirst;

// parse HTML
- (id)parseHTML:(NSString *)inputSource with:(id)thread count:(NSUInteger)loadedCount lastReadedCount:(NSUInteger *)lastCount;
@end


@interface CMRMachibbsHandler : CMRHostHTMLHandler
@end

// Described in BSHostLivedoorHandler.m
@interface BSHostLivedoorHandler: CMRHostHTMLHandler
@end

#define MACHI_OFFLAW_FORMAT @"%@/%@/%@/"
#define READ_URL_FORMAT_SHITARABA   @"%@/%@/%s/%@/"
