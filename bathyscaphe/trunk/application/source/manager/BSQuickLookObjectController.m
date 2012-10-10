//
//  BSQuickLookObjectController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 09/04/29.
//  Copyright 2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSQuickLookObjectController.h"
#import "BSQuickLookObject.h"

@implementation BSQuickLookObjectController
- (void)setContent:(id)content
{
	[(BSQuickLookObject *)[self content] cancelDownloading];
	[super setContent:content];
}
@end
