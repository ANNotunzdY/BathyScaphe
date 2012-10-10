//
//  BSThreadLinkerCore.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2012/08/19.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@interface BSThreadLinkerCore : NSObject {
    NSString *m_replyName;
    NSString *m_replyMail;
    NSString *m_replyDraft;
    NSRect m_replyWindowFrame;

    NSUInteger m_threadLabel;
    BOOL m_aaThread;
    NSRect m_threadWindowFrame;
}

@property(readwrite, retain) NSString *replyName;
@property(readwrite, retain) NSString *replyMail;
@property(readwrite, retain) NSString *replyDraft;
@property(readwrite, assign) NSRect replyWindowFrame;

@property(readwrite, assign) NSUInteger threadLabel;
@property(readwrite, assign, getter = isAAThread, setter = setAAThread:) BOOL aaThread;
@property(readwrite, assign) NSRect threadWindowFrame;

@end
