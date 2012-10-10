//
//  CMRThreadDictReader.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/29. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRThreadContentsReader.h"


@interface CMRThreadDictReader : CMRThreadContentsReader
{
    @private
    id      bs_attributes;  /* threadAttributes cache */
}
@end
