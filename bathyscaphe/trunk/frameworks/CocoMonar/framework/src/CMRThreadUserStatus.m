//
//  CMRThreadUserStatus.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/06.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadUserStatus.h"
#import "UTILKit.h"

@implementation CMRThreadUserStatus
+ (id)statusWithUInt32Value:(UInt32)flags
{
	return [[[self alloc] initWithUInt32Value:flags] autorelease];
}

- (id)initWithUInt32Value:(UInt32)flags
{
	if (self = [super init]){
		[self setFlags:flags];
	}
	return self;
}

- (UInt32)flags
{
	return _flags;
}

- (void)setFlags:(UInt32)aFlags
{
	_flags = aFlags;
}

#pragma mark NSObject
- (BOOL)isEqual:(id)other
{
	if (other == self) {
		return YES;
	}
	if (!other || ![other isKindOfClass:[self class]]) {
		return NO;
	}
	return ([self flags] == [other flags]);
}

- (id)copyWithZone:(NSZone *)aZone
{
	id tmp;
	tmp = [[[self class] allocWithZone:aZone] initWithUInt32Value:[self flags]];
	return tmp;
}

#pragma mark CMRPropertyListCoding
+ (id)objectWithPropertyListRepresentation:(id)rep
{
	UInt32 version_;
	UInt32 flags_;

//	UTILRequireCondition((rep && [rep respondsToSelector:@selector(unsignedIntegerValue)]), ErrRepresentation);
    UTILRequireCondition((rep && [rep isKindOfClass:[NSNumber class]]), ErrRepresentation);

	flags_ = [rep unsignedIntegerValue];
	version_ = (flags_ & TUS_VERSION_MASK);

	UTILRequireCondition((version_ == TUS_VERSION_1_0_MAGIC), ErrRepresentation);

	flags_ &= TUS_FL_NOT_TEMP_MASK;
	return [self statusWithUInt32Value:flags_];

ErrRepresentation:
	return nil;
}

- (id)propertyListRepresentation
{
	UInt32 flags_ = [self flags];

	flags_ |= TUS_VERSION_1_0_MAGIC;
	return [NSNumber numberWithUnsignedInteger:flags_];
}

- (BOOL)isAAThread
{
	return (([self flags] & TUS_ASCII_ART_FLAG) > 0);
}

- (void)setAAThread:(BOOL)setOn
{
	_flags = setOn ? (_flags|TUS_ASCII_ART_FLAG) : (_flags&~TUS_ASCII_ART_FLAG);
}

- (BOOL)isDatOchiThread
{
	return (([self flags] & TUS_DAT_OCHI_FLAG) > 0);
}

- (void)setDatOchiThread:(BOOL)setOn
{
	_flags = setOn ? (_flags|TUS_DAT_OCHI_FLAG) : (_flags&~TUS_DAT_OCHI_FLAG);
}

- (BOOL)isMarkedThread
{
	return (([self flags] & TUS_MARKED_FLAG) > 0);
}

- (void)setMarkedThread:(BOOL)setOn
{
	_flags = setOn ? (_flags|TUS_MARKED_FLAG) : (_flags&~TUS_MARKED_FLAG);
}

- (BOOL)isLabeledThread
{
    return [self isMarkedThread];
}

- (NSUInteger)label
{
    UInt32 flags_ = [self flags];
    flags_ &= TUS_LABEL_MASK;
    NSUInteger label_ = (NSUInteger)flags_;
    return (label_ == 0) ? 0 : ((label_ + 1) / 2);
}

- (void)setLabel:(NSUInteger)labelNumber
{
    // まずラベルを一回剥がす
    _flags = _flags&~TUS_LABEL_MASK;
    
    if (labelNumber == 0) {
        // ここで終わり
        return;
    }
    if (labelNumber > 7) {
        return;
    }
    // 新しいラベルを貼る
    UInt32 labelFlag = (labelNumber * 2 - 1);
    _flags = _flags|labelFlag;
}
@end
