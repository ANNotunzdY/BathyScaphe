//
//  BSIPILeopardSlideshowHelperProtocol.h
//  BSIPILeopardSlideshowHelper
//
//  Created by Tsutomu Sawada on 09/09/19.
//  Copyright 2009 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol BSIPILeopardSlideshowHelperProtocol
// Do not retain/release
- (NSArrayController *)arrayController;
- (void)setArrayController:(id)aController;

- (void)startSlideshow;
@end
