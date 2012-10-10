//
//  CMRThreadMessageBuffer.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/23. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRMessageComposer.h"

@class CMRThreadMessage;


@interface CMRThreadMessageBuffer : CMRMessageComposer
{
	@private
	NSMutableArray *bs_messages;
}
+ (id)buffer;

// Querying the messages
//- (NSMutableArray *)messages;
- (NSArray *)messages;
- (NSUInteger)count;

- (NSUInteger)indexOfMessage:(id)aMessage;
- (NSUInteger)indexOfMessageWithIndex:(NSUInteger)aMessageIndex;
- (BOOL)hasMessage:(id)aMessage;

- (CMRThreadMessage *)firstMessage;
- (CMRThreadMessage *)lastMessage;
- (CMRThreadMessage *)messageAtIndex:(NSUInteger)anIndex;
- (NSArray *)messagesAtIndexes:(NSIndexSet *)indexes; // array of CMRThreadMessage

/* returns NO, if index was not sequancial. */
- (BOOL)canAppend:(CMRThreadMessageBuffer *)other;
- (BOOL)addMessagesFromBuffer:(CMRThreadMessageBuffer *)aSource;

- (void)addMessage:(CMRThreadMessage *)aMessage;
- (void)replaceMessages:(NSArray *)aMessages;
- (void)replaceMessages:(NSArray *)aMessages mergeAttributes:(BOOL)merge;

- (void)removeAll;

- (void)changeAllMessageAttributes:(BOOL)onOffFlag flags:(UInt32)mask;
@end
