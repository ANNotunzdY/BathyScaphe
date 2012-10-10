//
//  CMRThreadMessageAttributes.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/SGFoundation.h>
#import <CocoMonar/CMRPropertyListCoding.h>
#import "CMRThreadMessageAttributesMask.h"


@interface CMRThreadMessageAttributes : NSObject<NSCopying, CMRPropertyListCoding>
{
	@private
	UInt32		_flags;
}
+ (id)attributesWithStatus:(UInt32)status;
- (id)initWithStatus:(UInt32)status;

- (void)addAttributes:(CMRThreadMessageAttributes *)anAttrs;

// flags 下位20bit
- (UInt32)status;
// flags 32 bit
- (UInt32)flags;

// !isInvisibleAboned && !isTemporaryInvisible
- (BOOL)isVisible;

// あぼーん
- (BOOL)isAboned;

// ローカルあぼーん
- (BOOL)isLocalAboned;

// 透明あぼーん
- (BOOL)isInvisibleAboned;

// AA
- (BOOL)isAsciiArt;

// ブックマーク
// Finder like label, 3bit unsigned integer value.
- (NSUInteger)bookmark;

// このレスは壊れています
- (BOOL)isInvalid;

// 迷惑レス
- (BOOL)isSpam;

// [Temporary Attributes]
// Visible Range
- (BOOL)isTemporaryInvisible;

- (void)setFlags:(UInt32)flag;
- (BOOL)flagAt:(UInt32)flag;
- (void)setFlag:(UInt32)flag on:(BOOL)isSet;
- (void)setStatus:(UInt32)status;
@end
