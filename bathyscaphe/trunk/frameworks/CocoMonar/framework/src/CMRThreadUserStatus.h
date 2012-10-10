//
//  CMRThreadUserStatus.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/06.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/SGFoundation.h>
#import "CMRPropertyListCoding.h"
#import "CMRThreadUserStatusMask.h"

@interface CMRThreadUserStatus : NSObject<NSCopying, CMRPropertyListCoding>
{
	@private
	UInt32		_flags;
}
+ (id)statusWithUInt32Value:(UInt32)flags;
- (id)initWithUInt32Value:(UInt32)flags;

- (UInt32)flags;
- (void)setFlags:(UInt32)aFlags;

// AA
- (BOOL)isAAThread;
- (void)setAAThread:(BOOL)flag;

/* Available in BathyScaphe 1.2 and later. */
// Dat 落ち
- (BOOL)isDatOchiThread;
- (void)setDatOchiThread:(BOOL)flag;

// フラグ付き
- (BOOL)isMarkedThread;
- (void)setMarkedThread:(BOOL)flag;

// ラベル
- (BOOL)isLabeledThread; // Same as -isMarkedThread.
// 0 : no label / 1-7 : label No.
- (NSUInteger)label;
- (void)setLabel:(NSUInteger)labelNumber;
@end
