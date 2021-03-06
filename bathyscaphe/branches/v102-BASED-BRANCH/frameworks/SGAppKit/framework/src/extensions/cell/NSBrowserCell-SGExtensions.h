//: NSBrowserCell-SGExtensions.h
/**
  * $Id: NSBrowserCell-SGExtensions.h,v 1.1.1.1 2005-05-11 17:51:26 tsawada2 Exp $
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.
  * See the file LICENSE for copying permission.
  */

#import <Foundation/Foundation.h>
#import <AppKit/NSBrowserCell.h>

@class NSTableColumn;

@interface NSBrowserCell(SGExtensions)
+ (void) attachDataCellOfTableColumn : (NSTableColumn *) tableColumn;
@end
