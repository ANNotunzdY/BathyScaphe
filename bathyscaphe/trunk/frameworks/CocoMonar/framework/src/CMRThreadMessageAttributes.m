//
//  CMRThreadMessageAttributes.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadMessageAttributes.h"
#import "UTILKit.h"


@implementation CMRThreadMessageAttributes
+ (id)attributesWithStatus:(UInt32)status
{
	return [[[self alloc] initWithStatus:status] autorelease];
}

- (id)initWithStatus:(UInt32)status
{
	if (self = [super init]){
		[self setStatus:status];
	}
	return self;
}

// NSObject
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
	id		tmp;

	tmp = [[[self class] allocWithZone:aZone] initWithStatus:[self status]];
	[tmp setFlags:[self flags]];

	return tmp;
}

// CMRPropertyListCoding
+ (id)objectWithPropertyListRepresentation:(id)rep
{
	UInt32		version_;
	UInt32		flags_;
	
	UTILRequireCondition((rep && [rep respondsToSelector:@selector(unsignedIntegerValue)]), ErrRepresentation);

	flags_ = [rep unsignedIntegerValue];

	version_ = (flags_ & MA_VERSION_MASK);
	if (0 == version_) {
		// 旧バージョンかもしれない
		if (flags_ & MA_VERSION_1_0_MAGIC) {
			flags_ &= (~MA_VERSION_1_0_MAGIC);
			flags_ &= MA_VERSION_1_1_MAGIC;
		}
	}

	UTILRequireCondition(((flags_ & MA_VERSION_1_1_MAGIC) > 0), ErrRepresentation);

	flags_ &= MA_FL_NOT_TEMP_MASK;
	return [self attributesWithStatus:flags_];

ErrRepresentation:
	return nil;
}

- (id)propertyListRepresentation
{
	UInt32		flags_ = [self status];

	// [self status] がすでに一時フラグを除去している
	flags_ |= MA_VERSION_1_1_MAGIC;
	return [NSNumber numberWithUnsignedInteger:flags_];
}

- (void)addAttributes:(CMRThreadMessageAttributes *)anAttrs
{
	UInt32		flags_ = _flags;

	if (!anAttrs) {
		return;
	}
	flags_ |= [anAttrs flags];
	_flags = flags_;
}

- (UInt32)status
{
	return (_flags & MA_FL_NOT_TEMP_MASK);
}

- (UInt32)flags
{
	return _flags;
}

- (BOOL)isVisible
{
	return (![self isInvisibleAboned] && ![self isTemporaryInvisible]);
}

// あぼーん
- (BOOL)isAboned
{
	return [self flagAt:ABONED_FLAG];
}

// ローカルあぼーん
- (BOOL)isLocalAboned
{
	return [self flagAt:LOCAL_ABONED_FLAG];
}

// 透明あぼーん
- (BOOL)isInvisibleAboned
{
	return [self flagAt:INVISIBLE_ABONED_FLAG];
}

// AA
- (BOOL)isAsciiArt
{
	return [self flagAt:ASCII_ART_FLAG];
}

// ブックマーク
// Finder like label, 3bit unsigned integer value.
- (NSUInteger)bookmark
{
	return BOOKMARK2INT([self flags]);
}

// このレスは壊れています
- (BOOL)isInvalid
{
	return [self flagAt:INVALID_FLAG];
}

// 迷惑レス
- (BOOL)isSpam
{
	return [self flagAt:SPAM_FLAG];
}

// Visible Range
- (BOOL)isTemporaryInvisible
{
	return [self flagAt:TEMP_INVISIBLE_FLAG];
}

- (void)setFlags:(UInt32)flags
{
	_flags = flags;
}

- (BOOL)flagAt:(UInt32)flag
{
	return ((_flags & flag) > 0);
}

- (void)setFlag:(UInt32)flag on:(BOOL)isSet
{
	_flags = isSet ? (_flags | flag) : (_flags & ~flag);
}

- (void)setStatus:(UInt32)aStatus
{
	UInt32 status_ = aStatus;

	status_ = (status_ & MA_FL_NOT_TEMP_MASK);
	_flags = (_flags | status_);
}
@end
