//
//  CMRLocalizableStringsOwner.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRLocalizableStringsOwner.h"
#import "UTILKit.h"


@implementation NSObject(CMRLocalizableStringsOwner)
+ (NSString *)localizableStringsTableName
{
    UTILAbstractMethodInvoked;
    return nil;
}

- (NSString *)localizedString:(NSString *)aKey
{
    return NSLocalizedStringFromTable(aKey, [[self class] localizableStringsTableName], nil);
}
@end
