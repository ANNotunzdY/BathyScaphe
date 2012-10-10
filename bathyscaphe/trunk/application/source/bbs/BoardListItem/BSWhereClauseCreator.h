//
//  BSWhereClauseVisitor.h
//
//  Created by Hori,Masaki on 10/05/09.
// Copyright 2006-2010 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSWhereClauseCreator : NSObject
+ (NSString *)whereClauseFromPredicate:(NSPredicate *)predicate;
@end


@interface NSObject(SQLSupport)
- (NSString *)sqlStatementPart;
@end
