//
//  CMRThreadDictReader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/29. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadDictReader.h"
#import "CMRThreadMessage.h"
#import "CocoMonar_Prefix.h"
#import "CMRMessageComposer.h"
#import "AppDefaults.h"


@implementation CMRThreadDictReader
+ (Class)resourceClass
{
	return [NSDictionary class];
}

- (NSArray *)messageDictArray
{
	NSArray *array;
	
	array = [[self fileContents] objectForKey:ThreadPlistContentsKey];
	if (!array) {
        return [NSArray empty];
	}
	return array;
}

- (void)dealloc
{
	[bs_attributes release];
	[super dealloc];
}

- (NSUInteger)numberOfMessages
{
	NSNumber	*n;
	
	n = [[self threadAttributes] objectForKey:CMRThreadLastLoadedNumberKey];
	UTILAssertNotNil(n);
	
	return [n unsignedIntegerValue];
}

- (NSDictionary *)threadAttributes
{
	if (!bs_attributes && [self fileContents]) {
		id v;

		bs_attributes = [[NSMutableDictionary alloc] initWithCapacity:16];
		[bs_attributes addEntriesFromDictionary:[self fileContents]];
		[bs_attributes removeObjectForKey:ThreadPlistContentsKey];
		
		v = [NSNumber numberWithUnsignedInteger:[[self messageDictArray] count]];
		[bs_attributes setObject:v forKey:CMRThreadLastLoadedNumberKey];

		/* check */
		v = [bs_attributes objectForKey:ThreadPlistBoardNameKey];
		if (!v) goto INVALID_LOG_FILE;
		v = [bs_attributes objectForKey:ThreadPlistIdentifierKey];
		if (!v) goto INVALID_LOG_FILE;

		goto END_ATTRIBUTES;
		/* Log file was invalid */
INVALID_LOG_FILE:
		[NSException raise:NSGenericException
                    format:
            @"*** REPORT ***\n\n"
            @"Log file was incompleted.\n"
            @"Please edit manually:\n"
            @"(1)open file by your editor (Property List Editor, etc)\n"
            @"(2)edit [%@] value --> board name\n"
            @"(3)edit [%@] value --> dat number\n\n"
            @"Thanks!¥n",
            ThreadPlistBoardNameKey,
            ThreadPlistIdentifierKey];
	}
END_ATTRIBUTES:
	if (!bs_attributes) {
		return [NSDictionary empty];
	}
	return bs_attributes;
}

- (BOOL)composeNextMessageWithComposer:(id<CMRMessageComposer>)composer
{
	NSArray				*ary = [self messageDictArray]; 
	NSUInteger			idx  = [self nextMessageIndex];
	NSDictionary		*messageDict_;
	CMRThreadMessage	*message_;
	id					rep;

	if (idx >= [ary count]) {
        return NO;
	}
	messageDict_ = [ary objectAtIndex:idx];
	message_ = [[CMRThreadMessage alloc] init];

#define OBJECT_KEY(key)		[messageDict_ objectForKey:(key)]
	[message_ setIndex:idx];
	[message_ setName:OBJECT_KEY(ThreadPlistContentsNameKey)];
	[message_ setMail:OBJECT_KEY(ThreadPlistContentsMailKey)];
	[message_ setDate:OBJECT_KEY(ThreadPlistContentsDateKey)];
	[message_ setIDString:OBJECT_KEY(ThreadPlistContentsIDKey)];
	[message_ setBeProfile:OBJECT_KEY(ThreadPlistContentsBeProfileKey)];
	[message_ setHost:OBJECT_KEY(CMRThreadContentsHostKey)];
	[message_ setMessageSource:OBJECT_KEY(ThreadPlistContentsMessageKey)];
	[message_ setDateRepresentation:OBJECT_KEY(ThreadPlistContentsDateRepKey)];
	rep = OBJECT_KEY(CMRThreadContentsStatusKey);
	rep = [CMRThreadMessageAttributes objectWithPropertyListRepresentation:rep];
	[message_ setMessageAttributes:rep];
#undef OBJECT_KEY

	[composer composeThreadMessage:message_];
	[message_ release];

	[self incrementNextMessageIndex];
	return YES;
}
@end
