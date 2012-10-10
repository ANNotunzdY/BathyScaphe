//
//  CMR2chDATReader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/04/10. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMR2chDATReader.h"
#import "AppDefaults.h"
#import "CMXTextParser.h"
#import "CMRThreadMessage.h"
#import "CocoMonar_Prefix.h"
#import "CMRMessageComposer.h"
//#import "CMRThreadVisibleRange.h"


@interface CMR2chDATReader(Private)
- (NSArray *)lineArray;
- (void)setupLineArrayWithContents:(NSString *)datContents;
- (NSEnumerator *)lineEnumerator;
- (void)setLineEnumerator:(NSEnumerator *)aLineEnumerator;

/* utility */
- (NSDate *)firstLineDateWithEnumerator:(NSEnumerator *)iter;
@end


@implementation CMR2chDATReader
- (id)initWithContents:(id)fileContents
{
    if (self = [super initWithContents:fileContents]) {
        [self setupLineArrayWithContents:fileContents];
    }
    return self;
}

- (void)dealloc
{
    [m_lineArray release];
    [m_title release];
    [m_lineEnumerator release];
    [super dealloc];
}

- (NSUInteger)numberOfLines
{
    return [[self lineArray] count];
}

- (NSString *)threadTitle
{
    NSEnumerator *iter_;
    NSString *line_;
    
    if (m_title) { 
        return m_title;
    }
    iter_ = [[self lineArray] objectEnumerator];
    while (line_ = [iter_ nextObject]) {
        NSArray     *components_;
        
        components_ = [CMXTextParser separatedLine:line_];
        // skips empty/blank lines
        if (!components_) {
            continue;
        }
        if ((k2chDATTitleIndex +1) == [components_ count]) {
            m_title = [components_ objectAtIndex:k2chDATTitleIndex];
            m_title = [m_title stringByReplaceEntityReference];
            m_title = [m_title copyWithZone:[self zone]];
        }
        break;
    }
    return m_title;
}

- (NSDate *)firstMessageDate
{
    NSEnumerator *iter_;
    
    iter_ = [[self lineArray] objectEnumerator];
    return [self firstLineDateWithEnumerator:iter_];
}

- (NSDate *)lastMessageDate
{
    NSEnumerator *iter_;
    
    iter_ = [[self lineArray] reverseObjectEnumerator];
    return [self firstLineDateWithEnumerator:iter_];
}

// override
- (NSUInteger)numberOfMessages
{
    return [[self lineArray] count];
}

- (NSDictionary *)threadAttributes
{
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] initWithCapacity:3];
    [dict setNoneNil:[self threadTitle] forKey:CMRThreadTitleKey];
    [dict setNoneNil:[self firstMessageDate] forKey:CMRThreadCreatedDateKey];
    [dict setNoneNil:[self lastMessageDate] forKey:CMRThreadModifiedDateKey];

    return [dict autorelease];
}

- (BOOL)composeNextMessageWithComposer:(id<CMRMessageComposer>)composer
{
    NSString *line_;
    CMRThreadMessage *message_;

    line_ = [[self lineEnumerator] nextObject];
    if (!line_) {
        return NO;
    }
    message_ = [CMXTextParser messageWithDATLine:line_];
    if (!message_) {
        if (line_ && [line_ length] > 0) {
            NSLog (
    @"=======================================================\n"
    @"   WARNING:\n"
    @"   Maybe line was not in form of 2ch dat text.\n"
    @"   \n"
    @"   LINE: %lu\n"
    @"   TEXT: \"%@\"\n"
    @"   \n"
    @"   If TEXT was html, it's InternalError.\n"
    @"=======================================================",
// #warning 64BIT: Inspect use of unsigned long
// 2010-04-10 tsawada2 検討済
            (unsigned long)[self nextMessageIndex], line_);

            // 自動変換
            message_ = [CMXTextParser messageWithInvalidDATLineDetected:line_];
        }

        if (!message_) {
            // 解析に失敗した場合でも、空行が挟まれているだけかも
            // しれないので試しに次の行も解析してみる。
            return [self composeNextMessageWithComposer:composer];
        }
    }
    UTILAssertNotNil(message_);
    [message_ setIndex:[self nextMessageIndex]];

    [composer composeThreadMessage:message_];
    [self incrementNextMessageIndex];
    return YES;
}
@end


@implementation CMR2chDATReader(Private)
- (NSArray *)lineArray
{
    if (!m_lineArray) {
        return [NSArray empty];
    }
    return m_lineArray;
}

- (void)setupLineArrayWithContents:(NSString *)datContents
{
    id tmp = m_lineArray;

    m_lineArray = [[datContents componentsSeparatedByNewline] retain];
    [tmp release];

    [self setLineEnumerator:[m_lineArray objectEnumerator]];

    [m_title release];
    m_title = nil;
}

- (NSEnumerator *)lineEnumerator
{
    return m_lineEnumerator;
}

- (void)setLineEnumerator:(NSEnumerator *)aLineEnumerator
{
    [aLineEnumerator retain];
    [m_lineEnumerator release];
    m_lineEnumerator = aLineEnumerator;
}

- (NSDate *)firstLineDateWithEnumerator:(NSEnumerator *)iter
{
    NSString *line_;
    
    while (line_ = [iter nextObject]) {
        CMRThreadMessage *message_;
        id  tmp_;
        
        message_ = [CMXTextParser messageWithDATLine:line_];
        if (!message_ || [message_ isAboned]) {
            continue;
        }

        // NSDate でない形式の場合は、ここでブロックして
        // nil を返しておく。
        tmp_ = [message_ date];
        return ([tmp_ isKindOfClass:[NSDate class]]) ? tmp_ : nil ;
    }
    return nil;
}
@end
