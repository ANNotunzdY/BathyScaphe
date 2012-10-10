//
//  BSLayoutManager.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/06/28.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSLayoutManager : NSLayoutManager
{
    @private
    BOOL bs_liveResizing;
    BOOL bs_shouldAntialias;
}

- (BOOL)textContainerInLiveResize;
- (void)setTextContainerInLiveResize:(BOOL)flag;

- (BOOL)shouldAntialias;
- (void)setShouldAntialias:(BOOL)flag;
@end
