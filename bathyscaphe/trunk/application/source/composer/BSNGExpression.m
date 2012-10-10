//
//  BSNGExpression.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/08/09.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSNGExpression.h"
#import <CocoaOniguruma/OnigRegexp.h>

static NSString *const kExpressionKey = @"Expression";
static NSString *const kTargetMaskKey = @"TargetMask";
static NSString *const kIsRegularExpressionKey = @"RegularExpression";
static NSString *const kOGRegExpInstanceKey = @"OGRegularExpressionInstanceArchive";

@implementation BSNGExpression
- (id)init
{
	return [self initWithExpression:nil targetMask:BSNGExpressionAtAll regularExpression:NO];
}

- (OnigRegexp *)createRegexInstance
{
    if (![self ngExpression]) {
        return nil;
    }

    return [OnigRegexp compile:[self ngExpression]];
}

- (id)initWithExpression:(NSString *)string targetMask:(NSUInteger)mask regularExpression:(BOOL)isRE
{
	if (self = [super init]) {
		[self setTargetMask:mask];
		[self setIsRegularExpression:isRE];
		[self setNgExpression:string];
	}
	return self;
}

- (void)dealloc
{
    [self setRegex:nil];
	[self setNgExpression:nil];
	[super dealloc];
}

#pragma mark Accessors
- (NSString *)ngExpression
{
	return m_NGExpression;
}

- (void)setNgExpression:(NSString *)string
{
	[string retain];
	[m_NGExpression release];
	m_NGExpression = string;

    [self setRegex:nil];
}

- (BOOL)validateExpression:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == nil) {
        if (outError != NULL) {
            NSString *errorString = NSLocalizedString(@"BSNGExpression setExpression Error", @"");
            NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
            NSError *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSNGExpressionNilExpressionError userInfo:userInfoDict];
            *outError = error;
        }
        return NO;
    }
    return YES;
}

- (NSUInteger)targetMask
{
	return m_NGTargetMask;
}

- (void)setTargetMask:(NSUInteger)mask
{
	m_NGTargetMask = mask;
}

- (BOOL)isLogicalANDForMask:(NSUInteger)mask
{
	return ([self targetMask] & mask);
}

- (void)setBool:(BOOL)boolValue forMask:(NSUInteger)mask
{
	NSUInteger baseMask = [self targetMask];
	if (boolValue) {
		baseMask |= mask;
	} else {
		baseMask ^= mask;
	}
	[self setTargetMask:baseMask];
}

- (BOOL)checksName
{
	return [self isLogicalANDForMask:BSNGExpressionAtName];
}

- (void)setChecksName:(BOOL)check
{
	[self setBool:check forMask:BSNGExpressionAtName];
}

- (BOOL)checksMail
{
	return[self isLogicalANDForMask:BSNGExpressionAtMail];
}

- (void)setChecksMail:(BOOL)check
{
	[self setBool:check forMask:BSNGExpressionAtMail];
}

- (BOOL)checksMessage
{
	return [self isLogicalANDForMask:BSNGExpressionAtMessage];
}

- (void)setChecksMessage:(BOOL)check
{
	[self setBool:check forMask:BSNGExpressionAtMessage];
}

- (BOOL)isRegularExpression
{
	return m_isRegularExpression;
}

- (void)setIsRegularExpression:(BOOL)isRE
{
	m_isRegularExpression = isRE;
    if (!isRE) {
        [self setRegex:nil];
    }
}

- (BOOL)validateIsRegularExpression:(id *)ioValue error:(NSError **)outError
{
	if ([*ioValue boolValue]) {
		if (![self ngExpression] || [self validAsRegularExpression]) {
			return YES;
		} else {
            if (outError != NULL) {
                NSString *errorString = NSLocalizedString(@"BSNGExpression setIsRegularExpression Error", @"");
                NSDictionary *userInfoDict = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
                NSError *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSNGExpressionInvalidAsRegexError userInfo:userInfoDict];
                *outError = error;
            }
			return NO;
		}
	} else {
		return YES;
	}
}

- (BOOL)validAsRegularExpression
{
    NSString *str = [self ngExpression];
    if (!str) {
        return NO;
    }
    return ([OnigRegexp compile:str] != nil);
}

- (OnigRegexp *)regex
{
    if (!m_regex && [self isRegularExpression]) {
        m_regex = [[self createRegexInstance] retain];
    }
    return m_regex;
}

- (void)setRegex:(OnigRegexp *)obj
{
    [obj retain];
    [m_regex release];
    m_regex = obj;
}

#pragma mark NSObject
- (NSUInteger)hash
{
	return [[self ngExpression] hash];
}

- (BOOL)isEqual:(id)anObject
{
	if (![anObject isKindOfClass:[self class]]) {
        return NO;
    }
	return [[self ngExpression] isEqual:[anObject ngExpression]];
}

#pragma mark CMRPropertyListCoding
+ (id)objectWithPropertyListRepresentation:(id)rep
{
    if (!rep || ![rep isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

	id instance;
	instance = [[[self class] alloc] init];
	[instance setNgExpression:[rep stringForKey:kExpressionKey]];
	[instance setTargetMask:[rep unsignedIntegerForKey:kTargetMaskKey]];
	[instance setIsRegularExpression:[rep boolForKey:kIsRegularExpressionKey]];
	return [instance autorelease];
}

- (id)propertyListRepresentation
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setNoneNil:[self ngExpression] forKey:kExpressionKey];
	[dict setNoneNil:[NSNumber numberWithUnsignedInteger:[self targetMask]] forKey:kTargetMaskKey];
	[dict setNoneNil:[NSNumber numberWithBool:[self isRegularExpression]] forKey:kIsRegularExpressionKey];
	return (NSDictionary *)dict;
}
@end
