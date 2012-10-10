//
//  CMRThreadPlistComposer.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/02/26.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadPlistComposer.h"
#import "CMRThreadMessage.h"
#import "CocoMonar_Prefix.h"

// for debugging only
static NSUInteger current_index_;
#define UTIL_DEBUGGING      0
#import "UTILDebugging.h"


@interface CMRThreadPlistComposer(Private)
- (void)addNewEntry:(id)obj forKey:(NSString *)key;
- (NSMutableDictionary *)dictionary;
- (void)clearDictionary;
- (NSMutableArray *)threadsArray;
- (void)setThreadsArray:(NSMutableArray *)aThreadsArray;
@end


@implementation CMRThreadPlistComposer
+ (id)composerWithThreadsArray:(NSMutableArray *)threads
{
    return [[[self alloc] initWithThreadsArray:threads] autorelease];
}

- (id)initWithThreadsArray:(NSMutableArray *)threads
{
    if (self = [self init]) {
        [self setThreadsArray:threads];
    }
    return self;
}

- (void)dealloc
{
    [m_thread release];
    [m_threadsArray release];
    [super dealloc];
}

- (void)prepareForComposing:(CMRThreadMessage *)aMessage
{
    NSDictionary *next_;

    // create next dictionary
    next_ = [self dictionary];
    NSAssert(next_ && 0 == [next_ count], @"next message invalid");
}

- (void)concludeComposing:(CMRThreadMessage *)aMessage
{
    NSDictionary *next_;

    // save message attributes
    [self addNewEntry:[[aMessage messageAttributes] propertyListRepresentation] forKey:CMRThreadContentsStatusKey];

    next_ = [self dictionary];
    NSAssert(next_ && [next_ count] > 0, @"message not completed.");
    [[self threadsArray] addObject:next_];
    [self clearDictionary];
}

- (void)composeIndex:(CMRThreadMessage *)aMessage
{
    current_index_ = [aMessage index];
}

- (void)composeName:(CMRThreadMessage *)aMessage
{
    [self addNewEntry:[aMessage name] forKey:ThreadPlistContentsNameKey];
}

- (void)composeMail:(CMRThreadMessage *)aMessage
{
    [self addNewEntry:[aMessage mail] forKey:ThreadPlistContentsMailKey];
}

- (void)composeDate:(CMRThreadMessage *)aMessage
{
    [self addNewEntry:[aMessage date] forKey:ThreadPlistContentsDateKey];
    [self addNewEntry:[aMessage dateRepresentation] forKey:ThreadPlistContentsDateRepKey];
}

- (void)composeID:(CMRThreadMessage *)aMessage
{
    [self addNewEntry:[aMessage IDString] forKey:ThreadPlistContentsIDKey];
}

- (void)composeBeProfile:(CMRThreadMessage *)aMessage
{
    [self addNewEntry:[aMessage beProfile] forKey:ThreadPlistContentsBeProfileKey];
}

- (void)composeHost:(CMRThreadMessage *)aMessage
{
    [self addNewEntry:[aMessage host] forKey:CMRThreadContentsHostKey];
}

- (void)composeMessage:(CMRThreadMessage *)aMessage
{
    [self addNewEntry:[aMessage messageSource] forKey:ThreadPlistContentsMessageKey];
}

- (id)getMessages
{
    NSArray     *messages_;

    messages_ = [[self threadsArray] retain];
    [self setThreadsArray:nil];

    return [messages_ autorelease];
}
@end


@implementation CMRThreadPlistComposer(Private)
- (void)addNewEntry:(id)obj forKey:(NSString *)key
{
    UTILAssertNotNil(key);
#if UTIL_DEBUGGING
    if (!obj) {
        UTIL_DEBUG_WRITE2(@"Can't create field\"%@\" at index:%lu", key, (unsigned long)current_index_);
    }
#endif  
    [[self dictionary] setNoneNil:obj forKey:key];
}

- (NSMutableDictionary *)dictionary
{
    if (!m_thread) {
        m_thread = [[NSMutableDictionary alloc] init];
    }
    return m_thread;
}

- (void)clearDictionary
{
    id tmp;

    tmp = m_thread;
    m_thread = nil;
    [tmp release];
}

- (NSMutableArray *)threadsArray
{
    if (!m_threadsArray) {
        m_threadsArray = [[NSMutableArray alloc] init];
    }
    return m_threadsArray;
}

- (void)setThreadsArray:(NSMutableArray *)aThreadsArray
{
    [aThreadsArray retain];
    [m_threadsArray release];
    m_threadsArray = aThreadsArray;
}
@end
