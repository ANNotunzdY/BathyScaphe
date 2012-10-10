//
//  BSFontWellIBPluginView.m
//  BSFontWell
//
//  Created by Tsutomu Sawada on 08/11/02.
//  Copyright 2008-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#import <BSFontWell/BSFontWell.h>
#import "BSFontWellIBPluginInspector.h"


@implementation BSFontWell(BSFontWellIBPluginViewIntegration)
- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths
{
    [super ibPopulateKeyPaths:keyPaths];	
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObject:@"fontValue"]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes
{
    [super ibPopulateAttributeInspectorClasses:classes];
}

- (NSSize)ibPreferredDesignSize
{
	return NSMakeSize(190, 23);
}
@end
