//
//  BSMessageSample.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/04/17.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSMessageSample.h"
#import "CocoMonar_Prefix.h"
#import "CMRThreadSignature.h"

@implementation BSMessageSample
@synthesize sampleType = m_sampleType;
@synthesize sampleObject = m_sampleObject;
@synthesize sampledThreadIdentifier = m_sampledThreadIdentifier;
@synthesize matchedCount = m_matchedCount;
@synthesize sampledDate = m_sampledDate;

- (void)dealloc
{
    [m_sampleObject release];
    m_sampleObject = nil;
    self.sampledThreadIdentifier = nil;
    self.sampledDate = nil;
    [super dealloc];
}

- (void)incrementMatchedCount
{
    self.matchedCount ++;
}

#pragma mark CMRPropertyListCoding
+ (id)objectWithPropertyListRepresentation:(id)rep
{
    BSMessageSample *sample = [[self alloc] init];
    sample.sampleType = [rep unsignedIntegerForKey:@"Type"];
    sample.sampleObject = [rep objectForKey:@"Sample"];
    sample.sampledThreadIdentifier = [CMRThreadSignature objectWithPropertyListRepresentation:[rep objectForKey:@"ThreadIdentifier"]];
    sample.matchedCount = [rep unsignedIntegerForKey:@"Count"];
    sample.sampledDate = [rep objectForKey:@"SampledDate"]; // nil でも良い
    return [sample autorelease];
}

- (id)propertyListRepresentation
{
    NSMutableDictionary *rep = [NSMutableDictionary dictionaryWithCapacity:5];
    [rep setUnsignedInteger:self.sampleType forKey:@"Type"];
    [rep setObject:self.sampleObject forKey:@"Sample"];
    [rep setObject:[self.sampledThreadIdentifier propertyListRepresentation] forKey:@"ThreadIdentifier"];
    [rep setUnsignedInteger:self.matchedCount forKey:@"Count"];
    if (self.sampledDate != nil) {
        [rep setObject:self.sampledDate forKey:@"SampledDate"];
    }
    return rep;
}

#pragma mark NSObject
- (BOOL)isEqual:(id)anObject
{
	if (!anObject) {
        return NO;
    }
	if (self == anObject) {
        return YES;
	}
	if (![anObject isKindOfClass:[self class]]) {
        return NO;
    }
    BSMessageSample *other = (BSMessageSample *)anObject;
    if (self.sampleType != other.sampleType) {
        return NO;
    }
    if (self.matchedCount != other.matchedCount) {
        return NO;
    }
	if (![self.sampleObject isEqual:other.sampleObject]) {
        return NO;
	}
    if (![self.sampledThreadIdentifier isEqual:other.sampledThreadIdentifier]) {
        return NO;
    }
    if (self.sampledDate != nil) {
        if (other.sampledDate == nil) {
            return NO;
        }
        if (![self.sampledDate isEqual:other.sampledDate]) {
            return NO;
        }
    } else {
        if (other.sampledDate != nil) {
            return NO;
        }
    }
	
	return YES;
}

- (NSUInteger)hash
{
    NSUInteger hash1;
    NSUInteger hash2;
    NSUInteger hash3;
	hash1 = [self.sampleObject hash];
	hash2 = [self.sampledThreadIdentifier hash];
	hash3 = [self.sampledDate hash];
	
	return (self.sampleType ^ hash1 ^ hash2 ^ self.matchedCount ^ hash3);
}
@end
