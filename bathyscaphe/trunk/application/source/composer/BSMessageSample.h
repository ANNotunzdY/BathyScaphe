//
//  BSMessageSample.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/04/17.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


enum {
    BSMessageSampleIDType = 2, // 0010
    BSMessageSampleNameType = 4, // 0100
    BSMessageSampleMailType = 8, // 1000
};
typedef NSUInteger BSMessageSampleType;


@class CMRThreadSignature;
@protocol CMRPropertyListCoding;


@interface BSMessageSample : NSObject<CMRPropertyListCoding> {
    @private
    BSMessageSampleType m_sampleType;
    NSString *m_sampleObject;
    CMRThreadSignature *m_sampledThreadIdentifier;
    NSUInteger m_matchedCount;
    NSDate *m_sampledDate;
}

@property(readwrite, assign) BSMessageSampleType sampleType;
@property(readwrite, copy) NSString *sampleObject;
@property(readwrite, retain) CMRThreadSignature *sampledThreadIdentifier;
@property(readwrite, assign) NSUInteger matchedCount;
@property(readwrite, retain) NSDate *sampledDate;

- (void)incrementMatchedCount;
@end
