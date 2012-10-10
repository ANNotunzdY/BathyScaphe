//
//  BSMessageSampleRegistrant.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/04/11.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSMessageSampleRegistrant.h"
#import "CMRThreadSignature.h"
#import "CMRThreadMessage.h"
#import "CMXTextParser.h"
#import "BSMessageSample.h"
#import "BoardManager.h"
#import "CMRSpamFilter.h"

@interface BSMessageSampleRegistrant(Private)
- (void)addSample:(NSString *)object forType:(BSMessageSampleType)type;
- (BSMessageSample *)sampleOfType:(BSMessageSampleType)type object:(NSString *)sampleObject;
- (void)registerMessageWithMail:(NSString *)mail orIDString:(NSString *)idString;
- (void)registerMessageNameOrMailImp:(CMRThreadMessage *)message hasIDString:(NSString *)idString;
- (void)unregisterMessageMailOrNameImp:(CMRThreadMessage *)message;
@end


@implementation BSMessageSampleRegistrant
@synthesize threadIdentifier = m_threadIdentifier;

- (id)initWithThreadSignature:(CMRThreadSignature *)signature
{
    if (self = [super init]) {
        m_threadIdentifier = [signature retain];
    }
    return self;
}

- (void)dealloc
{
    [m_threadIdentifier release];
    m_threadIdentifier = nil;

    m_delegate = nil;

    [super dealloc];
}

- (id<BSMessageSampleRegistrantDelegate>)delegate
{
    return m_delegate;
}

- (void)setDelegate:(id<BSMessageSampleRegistrantDelegate>)aDelegate
{
    m_delegate = aDelegate;
}

- (void)registerMessage:(CMRThreadMessage *)message
{
    if ([message isSpam]) {
        return;
    }

    NSString *idString = [message IDString];
    // ID があるか？
    if (!idString || [idString hasPrefix:@"???"]) {
        // ID が無い
        // 名前とメール欄をチェック
        [self registerMessageNameOrMailImp:message hasIDString:nil];
    } else {
        // ID がある
        if ([self delegate]) {
            // 単発 ID か？（delegate に問い合わせる）
            NSUInteger count = [[self delegate] registrant:self numberOfMessagesWithIDString:idString];
            if (count > 1) { // このメッセージ自身をカウントするから、最低でも count == 1 であるはず（0 はない）
                // 単発 ID でない
                // ID でサンプル登録
                [self addSample:idString forType:BSMessageSampleIDType];
            } else {
                // 単発 ID
                // 名前とメール欄をチェック
                [self registerMessageNameOrMailImp:message hasIDString:idString];
            }
        } else {
            // delegate が無い場合は単発 ID と同じ扱いとする。名前とメール欄をチェック
            [self registerMessageNameOrMailImp:message hasIDString:idString];
        }
    }
    // とにかく“迷惑レス”にはする
    [message setSpam:YES];
}

- (void)unregisterMessage:(CMRThreadMessage *)message
{
    if (![message isSpam]) {
        return;
    }

    NSString *idString = [message IDString];
    if (idString && ![idString hasPrefix:@"???"]) {
        BSMessageSample *sample = [self sampleOfType:BSMessageSampleIDType object:idString];
        if (sample) {
            // 削除する
            [[CMRSpamFilter sharedInstance] removeMessageSample:sample];
        } else {
            [self unregisterMessageMailOrNameImp:message];
        }
    } else {
        [self unregisterMessageMailOrNameImp:message];
    }

    [message setSpam:NO];
}
@end


@implementation BSMessageSampleRegistrant(Private)
- (void)addSample:(NSString *)object forType:(BSMessageSampleType)type
{
    BSMessageSample *sample = [[BSMessageSample alloc] init];
    sample.sampleType = type;
    sample.sampleObject = object;
    sample.sampledThreadIdentifier = self.threadIdentifier;
    sample.matchedCount = 1;
    sample.sampledDate = [NSDate date];

    [[CMRSpamFilter sharedInstance] addMessageSample:sample];
    [sample release];
}

- (BSMessageSample *)sampleOfType:(BSMessageSampleType)type object:(NSString *)sampleObject
{
    // 探す。今は板レベルの一致にしておく。
    // 見つからなければ nil を返す
    return [[CMRSpamFilter sharedInstance] sampleOfType:type object:sampleObject withBoard:[self.threadIdentifier boardName]];
}

- (void)registerMessageWithMail:(NSString *)mail orIDString:(NSString *)idString
{
    if (!mail || [mail length] == 0) {
        return;
    }
    if ([mail isEqualToString:CMRThreadMessage_SAGE_String] ||
        [mail isEqualToString:CMRThreadMessage_AGE_String] ||
        [mail isEqualToString:@"0"]) {
        if (idString) {
            [self addSample:idString forType:BSMessageSampleIDType];
        }
    } else {
        [self addSample:mail forType:BSMessageSampleMailType];
    }
}

- (void)registerMessageNameOrMailImp:(CMRThreadMessage *)message hasIDString:(NSString *)idString
{
    BoardManager *bm = [BoardManager defaultManager];
    NSString *boardName = [self.threadIdentifier boardName];
    // サンプル登録時に名前欄を考慮するか？
    BOOL considersName = [bm registrantShouldConsiderNameAtBoard:boardName];
    if (considersName) {
        NSArray *nanashis = [bm defaultNoNameArrayForBoard:boardName];
        NSString *messageName = [message name];
        if (!messageName) {
            return;
        }
        NSMutableString *name = [NSMutableString stringWithString:messageName];
        // name コンバート
        [CMXTextParser convertMessageSourceToCachedMessage:name];

        // 名前欄がデフォルト名無しか？
        if ([nanashis containsObject:name]) {
            // メール欄で判定続行
            [self registerMessageWithMail:[message mail] orIDString:idString];
        } else {
            // 名無し可能の板か？
            if ([bm allowsNanashiAtBoard:boardName]) {
                // 名前でサンプル登録
                [self addSample:messageName forType:BSMessageSampleNameType];
            } else {
                // スレッド内で再頻出の名前（事実上のデフォルト名無しさん）か？
                if ([[self delegate] registrant:self shouldRegardNameAsDefaultNanashi:messageName]) {
                    // 名前欄を考慮しないで、メール欄で判定続行
                    [self registerMessageWithMail:[message mail] orIDString:idString];
                } else {
                    // 名前でサンプル登録
                    [self addSample:messageName forType:BSMessageSampleNameType];
                }
            }
        }
    } else {
        // 名前欄を考慮しないで、メール欄で判定続行
        [self registerMessageWithMail:[message mail] orIDString:idString];
    }
}

- (void)unregisterMessageMailOrNameImp:(CMRThreadMessage *)message
{
    NSString *mail = [message mail];
    if (!mail || [mail length] == 0) {
        return;
    }
    if ([mail isEqualToString:CMRThreadMessage_SAGE_String] ||
        [mail isEqualToString:CMRThreadMessage_AGE_String] ||
        [mail isEqualToString:@"0"]) {
        NSString *messageName = [message name];
        if (!messageName) {
            return;
        }
        BSMessageSample *sampleByName = [self sampleOfType:BSMessageSampleNameType object:messageName];
        if (sampleByName) {
            // 削除
            [[CMRSpamFilter sharedInstance] removeMessageSample:sampleByName];
        }
    } else {
        BSMessageSample *sampleByMail = [self sampleOfType:BSMessageSampleMailType object:mail];
        if (sampleByMail) {
            // 削除
            [[CMRSpamFilter sharedInstance] removeMessageSample:sampleByMail];
        } else {
            NSString *messageName2 = [message name];
            if (!messageName2) {
                return;
            }
            BSMessageSample *sampleByName2 = [self sampleOfType:BSMessageSampleNameType object:messageName2];
            if (sampleByName2) {
                // 削除
                [[CMRSpamFilter sharedInstance] removeMessageSample:sampleByName2];
            }
        }
    }
}
@end
