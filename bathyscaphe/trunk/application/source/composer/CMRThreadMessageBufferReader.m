//
//  CMRThreadMessageBufferReader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/29. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadMessageBufferReader.h"
#import "CMRThreadMessageBuffer.h"
#import "CocoMonar_Prefix.h"
#import "CMRMessageComposer.h"
#import "CMRThreadMessage.h"



@implementation CMRThreadMessageBufferReader
+ (Class)resourceClass 
{
	return [CMRThreadMessageBuffer class];
}

- (CMRThreadMessageBuffer *)messageBuffer
{
	return [self fileContents];
}

- (NSUInteger)numberOfMessages
{
	return [[self messageBuffer] count];
}

- (BOOL)composeNextMessageWithComposer:(id<CMRMessageComposer>)composer
{
	CMRThreadMessage	*message_;
	NSUInteger			index_ = [self nextMessageIndex];

	if ([self numberOfMessages] <= index_) {
		return NO;
    }
	message_ = [[self messageBuffer] messageAtIndex:index_];
	[composer composeThreadMessage:message_];
	[self incrementNextMessageIndex];
	return YES;
}
@end
