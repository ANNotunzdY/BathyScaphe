//
//  BSTGrepSoulGem.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/03/16.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CocoMonar_Prefix.h"

@interface BSTGrepSoulGem : NSObject {
    BSTGrepSearchOptionType m_searchOptionType;
}

@property(readwrite, assign) BSTGrepSearchOptionType searchOptionType;

- (NSString *)HTMLSourceAtPath:(NSString *)filepath;
- (NSString *)queryStringForSearchString:(NSString *)searchStr;
- (NSTimeInterval)cacheTimeInterval;
- (BOOL)canHandleSearchOptionType:(BSTGrepSearchOptionType)type;
- (NSArray *)parseHTMLSource:(NSString *)source error:(NSError **)errorPtr;
- (BSTGrepSearchOptionType)defaultSearchOptionType;
@end


@interface BSFind2chSoulGem : BSTGrepSoulGem {
}
@end
