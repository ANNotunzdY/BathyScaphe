//
//  BSSegmentedControlTbItem.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/08/30.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSSegmentedControlTbItem.h"

@implementation BSSegmentedControlTbItem
- (id)delegate
{
    return _delegate;
}

- (void)setDelegate:(id)aDelegate
{
    _delegate = aDelegate;
}

- (void)validate
{
    id segmentedControl_ = [self view];
    id myDelegate = [self delegate];
    NSInteger i;
    NSInteger numOfSegments;

    if (!segmentedControl_) {
        return;
    }
    if (!myDelegate) {
        [segmentedControl_ setEnabled:NO];
        return;
    }

    if(![myDelegate respondsToSelector:@selector(segCtrlTbItem:validateSegment:)]) {
        [segmentedControl_ setEnabled:NO];
        return;
    }

    numOfSegments = [segmentedControl_ segmentCount];
    for(i = 0; i < numOfSegments; i++) {
        BOOL validation = [myDelegate segCtrlTbItem:self validateSegment:i];
        [segmentedControl_ setEnabled:validation forSegment:i];
    }
}

- (void)dealloc
{
    [self setDelegate:nil];
    [super dealloc];
}
@end
