//
//  CMRLocalizableStringsOwner.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface NSObject(CMRLocalizableStringsOwner)
+ (NSString *)localizableStringsTableName;
- (NSString *)localizedString:(NSString *)aKey;
@end
