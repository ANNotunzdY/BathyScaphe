//
// BSAsciiArtDetector.h
// BathyScaphe
//
// Written by Tsutomu Sawada on 06/09/10.
// Copyright 2006-2010 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class CMRThreadMessageBuffer, CMRThreadSignature, OnigRegexp;

@interface BSAsciiArtDetector: NSObject {
    @private
    OnigRegexp *m_regExpForAA;
}

+ (id)sharedInstance;

- (void)runDetectorWithMessages:(CMRThreadMessageBuffer *)aBuffer with:(CMRThreadSignature *)aThread allowConcurrency:(BOOL)allows;
@end
