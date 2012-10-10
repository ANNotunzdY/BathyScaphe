//
//  CMRPropertyListCoding.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

// Protocol
@protocol CMRPropertyListCoding<NSObject>
+ (id)objectWithPropertyListRepresentation:(id)rep;
- (id)propertyListRepresentation;

@optional
- (id)initWithPropertyListRepresentation:(id)rep;
- (BOOL)initializeFromPropertyListRepresentation:(id)rep;
@end
