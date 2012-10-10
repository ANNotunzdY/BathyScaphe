//
//  BSIPILeopardSlideshowHelper.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/12.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "BSIPILeopardSlideshowHelperProtocol.h"

@interface BSIPILeopardSlideshowHelper : NSObject<IKSlideshowDataSource, BSIPILeopardSlideshowHelperProtocol> {
	NSArrayController	*m_cube;
}

+ (id)sharedInstance;
@end
