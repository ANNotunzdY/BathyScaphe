//
//  BSThreadLinkerCore.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2012/08/19.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadLinkerCore.h"

@implementation BSThreadLinkerCore
@synthesize replyName = m_replyName;
@synthesize replyMail = m_replyMail;
@synthesize replyDraft = m_replyDraft;
@synthesize replyWindowFrame = m_replyWindowFrame;

@synthesize threadLabel = m_threadLabel;
@synthesize aaThread = m_aaThread;
@synthesize threadWindowFrame = m_threadWindowFrame;

- (id)init
{
    if ((self = [super init])) {
        m_replyWindowFrame = NSZeroRect;
        m_threadWindowFrame = NSZeroRect;
        m_threadLabel = 0;
    }
    return self;
}

- (void)dealloc
{
    self.replyName = nil;
    self.replyMail = nil;
    self.replyDraft = nil;
    [super dealloc];
}
@end
