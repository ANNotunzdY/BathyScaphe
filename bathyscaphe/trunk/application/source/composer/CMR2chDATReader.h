//
//  CMR2chDATReader.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/04/10. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRThreadContentsReader.h"


@interface CMR2chDATReader : CMRThreadContentsReader {
    @private
    NSString        *m_title;
    NSArray         *m_lineArray;
    NSEnumerator    *m_lineEnumerator;
}

- (NSString *)threadTitle;
- (NSDate *)firstMessageDate;
- (NSDate *)lastMessageDate;
@end
