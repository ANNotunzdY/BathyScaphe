//
//  BSTGrepResult.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/09/20.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@class CMRThreadSignature;

@interface BSTGrepResult : NSObject<NSPasteboardWriting> {
    NSUInteger m_order;
    NSString *m_threadURLString;
    NSString *m_threadTitle;
}

- (id)initWithOrderStr:(NSString *)orderStr URL:(NSString *)URLStr titleWithBoldTag:(NSString *)titleContainsBoldTag;
- (id)initWithOrderNo:(NSUInteger)orderNo URL:(NSString *)URLStr titleWithoutBoldTag:(NSString *)titleContainsNoBoldTag;

- (NSUInteger)order;
- (NSString *)threadURLString;
- (NSString *)threadTitle;

- (NSURL *)threadURL;
- (NSString *)boardName;

- (CMRThreadSignature *)threadSignature;
@end
