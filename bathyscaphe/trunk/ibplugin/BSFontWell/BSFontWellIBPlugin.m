//
//  BSFontWellIBPlugin.m
//  BSFontWell
//
//  Created by Tsutomu Sawada on 08/11/02.
//  Copyright 2008-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSFontWellIBPlugin.h"

@implementation BSFontWellIBPlugin
- (NSArray *)libraryNibNames
{
    return [NSArray arrayWithObject:@"BSFontWell_ibPluginLibrary"];
}

- (NSArray *)requiredFrameworks
{
    return [NSArray arrayWithObject:[NSBundle bundleWithIdentifier:@"jp.tsawada2.BathyScaphe.framework.bsfontwell"]];
}
@end
