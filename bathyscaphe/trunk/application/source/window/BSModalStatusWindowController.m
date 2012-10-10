//
//  BSModalStatusWindowController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 09/07/04.
//  Copyright 2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSModalStatusWindowController.h"


@implementation BSModalStatusWindowController
- (id)init
{
    if (self = [super initWithWindowNibName:@"BSModalStatusWindow"]) {
        [self loadWindow];
    }
    return self;
}

- (NSTextField *)messageTextField
{
    return m_messageTextField;
}

- (NSProgressIndicator *)progressIndicator
{
    return m_progressIndicator;
}

- (NSTextField *)infoTextField
{
    return m_infoTextField;
}
@end
