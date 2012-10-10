//
//  BSMessageSampleRegistrant.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/04/11.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@class CMRThreadSignature, CMRThreadMessage;
@protocol BSMessageSampleRegistrantDelegate;


@interface BSMessageSampleRegistrant : NSObject {
    @private
    CMRThreadSignature *m_threadIdentifier;
    id<BSMessageSampleRegistrantDelegate> m_delegate;
}

- (id)initWithThreadSignature:(CMRThreadSignature *)signature;

- (id<BSMessageSampleRegistrantDelegate>)delegate;
- (void)setDelegate:(id<BSMessageSampleRegistrantDelegate>)aDelegate;

- (void)registerMessage:(CMRThreadMessage *)message;
- (void)unregisterMessage:(CMRThreadMessage *)message;

@property(readwrite, retain) CMRThreadSignature *threadIdentifier;

@end


@protocol BSMessageSampleRegistrantDelegate<NSObject>
@required
- (NSUInteger)registrant:(BSMessageSampleRegistrant *)aRegistrant numberOfMessagesWithIDString:(NSString *)idString;
- (BOOL)registrant:(BSMessageSampleRegistrant *)aRegistrant shouldRegardNameAsDefaultNanashi:(NSString *)name;
@end
