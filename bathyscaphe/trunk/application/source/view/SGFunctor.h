//
//  SGFunctor.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/16.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@protocol SGFunctor<NSObject>
- (void)execute:(id)sender;
@end


@interface SGFunctor : NSObject<SGFunctor> {
    id m_objectValue;
}
+ (id)functorWithObject:(id)obj;
- (id)initWithObject:(id)obj;
- (id)objectValue;
- (void)setObjectValue:(id)anObjectValue;
@end
