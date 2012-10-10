//
// BSAsciiArtDetector.m
// BathyScaphe
//
// Written by Tsutomu Sawada on 06/09/10.
// Copyright 2006-2010 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "BSAsciiArtDetector.h"
#import "CMRThreadMessageBuffer.h"
#import "CMRThreadMessage.h"
#import "CMRThreadSignature.h"
#import "BoardManager.h"
#import <CocoMonar/CocoMonar.h>
#import <CocoaOniguruma/OnigRegexp.h>

static NSString *const kAADRegExpKey = @"Thread - AAD Regular Expression";

@implementation BSAsciiArtDetector
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance);

- (id)init
{
    if (self = [super init]) {
        NSString *expStr = SGTemplateResource(kAADRegExpKey);
        if (!expStr || [expStr isEqualToString: @""]) {
            NSLog(@"BSAsciiArtDetector: AAD Regular Expression String is empty!");
            return self;
        }
        m_regExpForAA = [[OnigRegexp compile:expStr] retain];
        if (!m_regExpForAA) {
            NSLog(@"BSAsciiArtDetecotr: AAD Regular Expression String is inValid!");
        }
    }
    return self;
}

- (void)dealloc
{
    [m_regExpForAA release];
    m_regExpForAA = nil;
    [super dealloc];
}

- (void)runDetectorWithMessages:(CMRThreadMessageBuffer *)aBuffer with:(CMRThreadSignature *)aThread allowConcurrency:(BOOL)allows
{
    BOOL watch = [[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey];
    NSDate			*before = nil;
    NSTimeInterval	elapsed = 0;
    if (watch) {
        before = [NSDate date];
    }
    // ----
    if (!aBuffer || [aBuffer count] == 0) {
        return;
    }

    NSArray *messages = [aBuffer messages];
    if (!messages) {
        return;
    }

    BOOL treatAsSpamFlag = [[BoardManager defaultManager] treatsAsciiArtAsSpamAtBoard:[aThread boardName]];
/*    NSString *source;
    OnigResult *match;
    
    for (CMRThreadMessage *message in messages) {
        if ([message isAsciiArt]) {
            if (treatAsSpamFlag) {
                [message setSpam:YES];
            }
            continue;
        }

        source = [message cachedMessage];
        if (!source || [source length] < 7) {
            continue;
        }
        match = [m_regExpForAA search:source];
        if (match) {
            [message setAsciiArt:YES];
            if (treatAsSpamFlag) {
                [message setSpam:YES];
            }
        }
    }*/
 
    [messages enumerateObjectsWithOptions:(allows ? NSEnumerationConcurrent : 0) usingBlock:^(CMRThreadMessage *message, NSUInteger idx, BOOL *stop) {
        NSString *source;
        OnigResult *match;

        if ([message isAsciiArt]) {
            if (treatAsSpamFlag) {
                [message setSpam:YES];
            }
            return;
        }
        
        source = [message cachedMessage];
        if (!source || [source length] < 7) {
            return;
        }
        match = [m_regExpForAA search:source];
        if (match) {
            [message setAsciiArt:YES];
            if (treatAsSpamFlag) {
                [message setSpam:YES];
            }
        }
    }];
    if (watch) {
        elapsed = [[NSDate date] timeIntervalSinceDate:before];
        NSLog(@"AAD Performance - used %.4f seconds", elapsed);
    }
}
@end
