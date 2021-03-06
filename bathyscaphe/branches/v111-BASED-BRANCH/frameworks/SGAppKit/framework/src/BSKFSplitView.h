/**
  * $Id: BSKFSplitView.h,v 1.1.2.2 2006-09-01 13:46:56 masakih Exp $
  * 
  * BathyScaphe
  *
  * Copyright 2005-2006 BathyScaphe Project.
  * All rights reserved.
  */
#import <Cocoa/Cocoa.h>
#import "KFSplitView.h"

@interface BSKFSplitView : KFSplitView
{
	@private
	NSImage	*_splitterBg;
	NSImage *_splitterDimple;
	NSImage *_splitterBgVertical;
	NSImage *_splitterDimpleVertical;
}

- (void) kfSetupResizeCursors;
@end
