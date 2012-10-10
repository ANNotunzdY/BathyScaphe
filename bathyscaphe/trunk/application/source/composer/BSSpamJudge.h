//
//  BSSpamJudge.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/04/11.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class CMRThreadSignature, CMRThreadMessageBuffer;

@interface BSSpamJudge : NSObject {
    @private
    NSSet *m_spamHostSymbols;
    NSArray *m_NGExpressions;
    // Arrays of NSString (not BSMessageSample.)
    NSArray *m_nameSamples;
    NSArray *m_mailSamples;
    NSArray *m_idSamples;
    BOOL m_treatsNoSageAsSpamFlag;
}

- (id)initWithThreadSignature:(CMRThreadSignature *)signature;

- (void)judgeMessages:(CMRThreadMessageBuffer *)aBuffer;
@end
