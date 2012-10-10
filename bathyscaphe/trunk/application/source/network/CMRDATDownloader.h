//
//  CMRDATDownloader.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "ThreadTextDownloader.h"



@interface CMRDATDownloader : ThreadTextDownloader
@end

extern NSString *const CMRDATDownloaderDidDetectDatOchiNotification; // Available in CometBlaster and later.
extern NSString *const CMRDATDownloaderDidSuspectBBONNotification; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.
extern NSString *const CMRDATDownloaderDidDetectInvalidHEADUpdatedNotification; // Available in BathyScaphe 2.0 "Final Moratorium" and later.
