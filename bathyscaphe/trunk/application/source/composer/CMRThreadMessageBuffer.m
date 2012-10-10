//
//  CMRThreadMessageBuffer.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/23. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadMessageBuffer.h"
#import "CMRThreadMessage.h"
#import "CocoMonar_Prefix.h"


@implementation CMRThreadMessageBuffer
+ (id)buffer
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        bs_messages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
	[bs_messages release];
	bs_messages = nil;
	[super dealloc];
}

// NSObject
- (NSString *)description
{
	NSMutableString		*s;
	CMRThreadMessage	*m;
	
	s = [NSMutableString string];
	[s appendFormat: @"<%@ %p>\n",
		[self className], self];
	
	m = [self firstMessage];
// #warning 64BIT: Check formatting arguments
// 2010-03-23 tsawada2 修正済
	[s appendFormat: @"  index: %lu - ", m ? (unsigned long)[m index]:0];
	m = [self lastMessage];
// #warning 64BIT: Check formatting arguments
// 2010-03-23 tsawada2 修正済
	[s appendFormat: @"%lu\n", m ? (unsigned long)[m index]:0];
	
	return s;
}

- (NSArray *)messages
{
/*	if (!bs_messages) {
        bs_messages = [[NSMutableArray alloc] init];
	}*/
    @synchronized(self) {
        return [NSArray arrayWithArray:bs_messages];
    }
}

- (NSUInteger)count
{
	return [bs_messages count];
}

- (CMRThreadMessage *)messageAtIndex:(NSUInteger)anIndex
{
    if (!bs_messages || anIndex >= [bs_messages count]) {
        return nil;
    }
    return [bs_messages objectAtIndex:anIndex];
}

- (NSArray *)messagesAtIndexes:(NSIndexSet *)indexes
{
    if (!bs_messages || !indexes || [indexes count] > [bs_messages count]) {
        return nil;
    }
    return [bs_messages objectsAtIndexes:indexes];
}

- (NSUInteger)indexOfMessage:(id)aMessage
{
	return [bs_messages indexOfObject:aMessage];
}

- (NSUInteger)indexOfMessageWithIndex:(NSUInteger)aMessageIndex
{
	NSUInteger idx = 0;
	
	if (NSNotFound == aMessageIndex) {
		return NSNotFound;
	}
    for (CMRThreadMessage *message_ in bs_messages) {
		if (aMessageIndex == [message_ index]) {
			return idx;
		}
		idx++;
	}
	return NSNotFound;
}

- (BOOL)hasMessage:(id)aMessage
{
	return ([self indexOfMessage:aMessage] != NSNotFound);
}

- (CMRThreadMessage *)firstMessage
{
	return [bs_messages head];
}

- (CMRThreadMessage *)lastMessage
{
	return [bs_messages lastObject];
}

- (void)addMessagesFromArray:(NSArray *)anArray
{
/*	NSEnumerator		*iter_ = [anArray objectEnumerator];
	CMRThreadMessage	*message_;
	
	while (message_ = [iter_ nextObject]) {
		[self addMessage:message_];
	}*/
    @synchronized(self) {
        [bs_messages addObjectsFromArray:anArray];
    }
}

- (BOOL)canAppend:(CMRThreadMessageBuffer *)other
{
	CMRThreadMessage	*myLast_;
	CMRThreadMessage	*othersFirst_;
	
	if (!other) {
		return NO;
	}
	if (0 == [self count] || 0 == [other count]) {
		return YES;
	}
	myLast_ = [self lastMessage];
	othersFirst_ = [other firstMessage];

	if (!myLast_) {
		return (othersFirst_ != nil);
	}
	if (!othersFirst_) {
		return YES;
	}
	return ([myLast_ index] +1 == [othersFirst_ index]);
}

- (BOOL)addMessagesFromBuffer:(CMRThreadMessageBuffer *)otherBuffer
{
	if (![self canAppend:otherBuffer]) {
		return NO;
	}
	if ([otherBuffer count] > 0) {
		[self addMessagesFromArray:[otherBuffer messages]];
	}
	return YES;
}

- (void)addMessage:(CMRThreadMessage *)aMessage
{
    @synchronized(self) {
        [bs_messages addObject:aMessage];
    }
}

- (void)replaceMessages:(NSArray *)aMessages
{
    @synchronized(self) {
        [bs_messages removeAllObjects];
        [self addMessagesFromArray:aMessages];
    }
}

- (void)replaceMessages:(NSArray *)aMessages mergeAttributes:(BOOL)merge
{
	NSMutableArray		*newArray_  = nil;
	NSEnumerator		*myIter_    = nil;
//	NSEnumerator		*otherIter_ = nil;

	if (!merge) {
		[self replaceMessages:aMessages];
		return;
	}

	newArray_  = [[NSMutableArray alloc] init];
	myIter_    = [bs_messages objectEnumerator];
//	otherIter_ = [aMessages objectEnumerator];

//	while (message_ = [otherIter_ nextObject]){
    for (CMRThreadMessage *message_ in aMessages) {
		CMRThreadMessage			*oldOne_ = [myIter_ nextObject];
		CMRThreadMessageAttributes	*attributes_;
		
		attributes_ = [message_ messageAttributes];
		[attributes_ addAttributes:[oldOne_ messageAttributes]];
		
		[message_ setMessageAttributes:attributes_];
		[newArray_ addObject:message_];
	}
	
	[self replaceMessages:newArray_];
	[newArray_ release];
}

- (void)removeAll
{
    @synchronized(self) {
        [bs_messages removeAllObjects];
    }
}

- (void)changeAllMessageAttributes:(BOOL)onOffFlag flags:(UInt32)mask
{
	for (CMRThreadMessage *message in bs_messages) {
		[message setMessageAttributeFlag:mask on:onOffFlag];
	}
}

// CMRMessageComposer
- (void)composeThreadMessage:(CMRThreadMessage *)message
{
	[self addMessage:message];
}

- (id)getMessages
{
	return [self messages];
}
@end
