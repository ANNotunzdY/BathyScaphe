//: CMRDATDownloader.h
/**
  * $Id: CMRDATDownloader.h,v 1.1.1.1.6.1 2006-06-04 16:16:05 tsawada2 Exp $
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  */

#import <Foundation/Foundation.h>
#import "ThreadTextDownloader.h"



@interface CMRDATDownloader : ThreadTextDownloader
@end

extern NSString *const CMRDATDownloaderDidDetectDatOchiNotification; // available in CometBlaster and later.
