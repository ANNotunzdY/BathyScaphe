//
//  BSNobiNobiToolbarItem.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/27.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSNobiNobiView : NSView {
	BOOL    m_shouldDrawBorder;
}

- (BOOL)shouldDrawBorder;
- (void)setShouldDrawBorder:(BOOL)draw;
@end


@interface BSNobiNobiToolbarItem : NSToolbarItem {
}

- (void)adjustWidth:(CGFloat)width;
@end
