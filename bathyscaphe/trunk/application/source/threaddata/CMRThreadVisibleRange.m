//
//  CMRThreadVisibleRange.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/09/23.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadVisibleRange.h"

static NSString *const CMRThreadFirstVisibleLengthKey	= @"First Visible Length";
static NSString *const CMRThreadLastVisibleLengthKey	= @"Last Visible Length";


@implementation CMRThreadVisibleRange
+ (id)visibleRangeWithFirstVisibleLength:(NSUInteger)aFirstVisibleLength
					   lastVisibleLength:(NSUInteger)aLastVisibleLength
{
	return [[[self alloc] initWithFirstVisibleLength:aFirstVisibleLength
								   lastVisibleLength:aLastVisibleLength] autorelease];
}

- (id)initWithFirstVisibleLength:(NSUInteger)aFirstVisibleLength
			   lastVisibleLength:(NSUInteger)aLastVisibleLength
{
	if (self = [self init]) {
		[self setFirstVisibleLength:aFirstVisibleLength];
		[self setLastVisibleLength:aLastVisibleLength];
	}
	return self;
}

#pragma mark CMRPropertyListCoding
+ (id)objectWithPropertyListRepresentation:(id)rep
{
	if (!rep) return nil;
	
	return [[[self alloc] initWithPropertyListRepresentation:rep] autorelease];
}

- (id)initWithPropertyListRepresentation:(id)rep
{
	if (self = [self init]) {
		if (![self initializeFromPropertyListRepresentation:rep]) {
			[self autorelease];
			return nil;
		}
	}
	return self;
}

- (id)propertyListRepresentation
{
	return [self dictionaryRepresentation];
}

- (BOOL)initializeFromPropertyListRepresentation:(id)rep
{
	if ([rep isKindOfClass:[NSDictionary class]]) {
		return [self initializeFromDictionaryRepresentation:rep];
	}
	return NO;
}

- (NSDictionary *)dictionaryRepresentation
{
	NSDictionary		*dict_;
	
	dict_ = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithUnsignedInteger:[self firstVisibleLength]],
				CMRThreadFirstVisibleLengthKey,
				[NSNumber numberWithUnsignedInteger:[self lastVisibleLength]],
				CMRThreadLastVisibleLengthKey,
				NULL];

	return dict_;
}

- (BOOL)initializeFromDictionaryRepresentation:(NSDictionary *)rep
{
	NSUInteger		firstVisibleLength_;
	NSUInteger		lastVisibleLength_;
	
	if (!rep) return NO;
	
	firstVisibleLength_ = [rep unsignedIntegerForKey:CMRThreadFirstVisibleLengthKey];
	lastVisibleLength_ = [rep unsignedIntegerForKey:CMRThreadLastVisibleLengthKey];
	
	[self setFirstVisibleLength:firstVisibleLength_];
	[self setLastVisibleLength:lastVisibleLength_];
	
	return YES;
}

#pragma mark Accessors
- (BOOL)isShownAll
{
	return (CMRThreadShowAll == [self firstVisibleLength] ||
			CMRThreadShowAll == [self lastVisibleLength]);
}

- (BOOL)isEmpty
{
	return (0 == [self firstVisibleLength] && 0 == [self lastVisibleLength]);
}

- (NSUInteger)firstVisibleLength
{
	return _firstVisibleLength;
}

- (void) setFirstVisibleLength : (NSUInteger) aFirstVisibleLength
{
	_firstVisibleLength = aFirstVisibleLength;
}

- (NSUInteger)lastVisibleLength
{
	return _lastVisibleLength;
}

- (void) setLastVisibleLength : (NSUInteger) aLastVisibleLength
{
	_lastVisibleLength = aLastVisibleLength;
}

- (NSUInteger)visibleLength
{
	if ([self isShownAll]) return CMRThreadShowAll;
	
	return [self firstVisibleLength] + [self lastVisibleLength];
}

#pragma mark NSObject
- (BOOL)isEqual:(id)other
{
	BOOL	isEqual_;
	
	if (self == other) return YES;
	if (!other || ![other isKindOfClass:[self class]]) return NO;

	isEqual_ = ([self firstVisibleLength] == [other firstVisibleLength]);
	isEqual_ = isEqual_ && ([self lastVisibleLength] == [other lastVisibleLength]);
	
	return isEqual_;
}

- (NSString *)description
{
#warning 64BIT: Check formatting arguments
	return [NSString stringWithFormat: 
						@"(%@) {%u, %u} <%p>",
						NSStringFromClass([self class]),
						[self firstVisibleLength],
						[self lastVisibleLength],
						self];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)aZone
{
	id		tmp;

	tmp = [[[self class] allocWithZone:aZone] initWithFirstVisibleLength:[self firstVisibleLength]
													   lastVisibleLength:[self lastVisibleLength]];

	return tmp;
}
@end
