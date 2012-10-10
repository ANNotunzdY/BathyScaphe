//
//  CMRThreadComposingTask.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/18.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadComposingTask_p.h"
#import "CMRThreadMessageBuffer.h"
#import "CMRThreadMessage.h"
#import "CMRAttributedMessageComposer.h"
#import "CMRThreadContentsReader.h"
#import "CMRThreadLinkProcessor.h"

@implementation CMRThreadComposingTask
- (id)init
{
	if (self = [super init]) {
        ;
	}
	return self;
}

+ (id)taskWithThreadReader:(CMRThreadContentsReader *)aReader
{
	return [[[self alloc] initWithThreadReader:aReader] autorelease];
}

- (id)initWithThreadReader:(CMRThreadContentsReader *)aReader
{
	if (self = [self init]) {
		[self setReader:aReader];
		[self setThreadTitle:[[aReader threadAttributes] objectForKey:CMRThreadTitleKey]];
	}
	return self;
}

- (void) dealloc
{
	[_threadTitle release];
	[_reader release];

	_delegate = nil;
	[super dealloc];
}

#pragma mark Accessors
- (NSString *)threadTitle
{
	return _threadTitle;
}

- (void)setThreadTitle:(NSString *)aThreadTitle
{
	[aThreadTitle retain];
	[_threadTitle release];
	_threadTitle = aThreadTitle;
	if (aThreadTitle) {
        [self setMessage:[NSString stringWithFormat:[self messageFormat], aThreadTitle]];
    }
}

- (CMRThreadContentsReader *)reader
{
	return _reader;
}

- (void)setReader:(CMRThreadContentsReader *)aReader
{
	[aReader retain];
	[_reader release];
	_reader = aReader;
}

- (id)delegate
{
	return _delegate;
}

- (void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}

#pragma mark CMRTask Protocol (and more)
- (NSString *)titleFormat
{
	return [self localizedString:@"%@ Converting..."];
}

- (NSString *)messageFormat
{
	return [self localizedString:@"Now Converting..."];
}

- (NSString *)title
{
	return [NSString stringWithFormat:[self titleFormat], [self threadTitle]];
}

#pragma mark Others
- (void)postInterruptedNotification
{
	[[self delegate] performSelectorOnMainThread:@selector(threadTaskDidInterrupt:) withObject:self waitUntilDone:YES];
}

- (void)analyzeReverseReferences:(NSMutableAttributedString *)aTextBuffer
{
    NSRange allRange = NSMakeRange(0, [aTextBuffer length]);
    NSUInteger charIndex_ = 0;
    NSUInteger toIndex_ = NSMaxRange(allRange);
    id linkString;
    NSRange coloringRange;
    
    while (1) {
        if (charIndex_ >= toIndex_) {
            break;
        }
        
        linkString = [aTextBuffer attribute:NSLinkAttributeName atIndex:charIndex_ longestEffectiveRange:&coloringRange inRange:allRange];
        if (linkString) {
            if (![[[aTextBuffer string] substringWithRange:coloringRange] isEqualToString:NSLocalizedStringFromTable(@"ShowLocalAbone", @"MessageComposer", nil)]) {
                NSMutableIndexSet *indexes = nil;
                if ([CMRThreadLinkProcessor isMessageLinkUsingLocalScheme:linkString messageIndexes:&indexes] && indexes) {
                    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        [[[self layout] reverseReferencesCountedSet] addObject:[NSNumber numberWithUnsignedInteger:idx]];
                    }];
                }
            }
        }
        charIndex_ = NSMaxRange(coloringRange);
    }
}

// 追加して、バッファを消去
- (void)performsAppendingTextFromBuffer:(NSMutableAttributedString *)aTextBuffer
{
	[self checkIsInterrupted];
	if (aTextBuffer && [aTextBuffer length]) {
		[aTextBuffer fixAttributesInRange:[aTextBuffer range]];
		[[[self layout] textStorage] performSelectorOnMainThread:@selector(appendAttributedString:) withObject:aTextBuffer waitUntilDone:YES];
		[aTextBuffer deleteCharactersInRange:[aTextBuffer range]];
	}
	[self checkIsInterrupted];
}

- (BOOL)delegateWillCompleteMessages:(CMRThreadMessageBuffer *)aMessageBuffer
{
	id delegate_ = [self delegate];

	if (delegate_ && [delegate_ respondsToSelector:@selector(threadComposingTask:willCompleteMessages:)]) {
		return [delegate_ threadComposingTask:self willCompleteMessages:aMessageBuffer];
	}
	
	return YES;
}

- (void)doExecuteWithLayoutImp:(CMRThreadLayout *)theLayout
{
	CMRThreadMessageBuffer			*buffer_;
	CMRThreadContentsReader			*reader_;
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	
	NSTextStorage	*textStorage_ = [theLayout textStorage];
	NSUInteger		textLength_ = [textStorage_ length];
	NSRange			mesRange_;
	
	buffer_ = [[[CMRThreadMessageBuffer alloc] init] autorelease];
	reader_ = [[self reader] retain];
	UTILAssertNotNil(reader_);

	// compose message chain
	[reader_ composeWithComposer:buffer_];
    [reader_ release];

    // Delegate
	if (![self delegateWillCompleteMessages:buffer_]) {		
		// cancel: raise exception.
		[self setIsInterrupted:YES];
		[self checkIsInterrupted];
	}

	[theLayout addMessagesFromBuffer:buffer_];

	// compose text storage
	composer_ = [[CMRAttributedMessageComposer alloc] init];
	textBuffer_ = [[NSMutableAttributedString alloc] init];
	[composer_ setContentsStorage:textBuffer_];

    NSArray *messages = [buffer_ messages];

    for (CMRThreadMessage *message in messages) {
		mesRange_ = NSMakeRange([textBuffer_ length], 0);
		[composer_ composeThreadMessage:message];
		mesRange_.length = [textBuffer_ length] - mesRange_.location;

		// 範囲を補正、 addMessageRange: は直列化されている
		mesRange_.location += textLength_;
		[theLayout addMessageRange:mesRange_];
        
        // IDカウント
        if ([message IDString]) {
            [[theLayout countedSet] addObject:[message IDString]];
        }
	}

    [self analyzeReverseReferences:textBuffer_];

	[self performsAppendingTextFromBuffer:textBuffer_];

	[[self delegate] performSelectorOnMainThread:@selector(threadComposingDidFinish:) withObject:self waitUntilDone:NO];

	[textBuffer_ release];
	[composer_ release];
}

- (void)doExecuteWithLayout:(CMRThreadLayout *)theLayout
{
    BOOL watch = [[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey];
    NSDate			*before = nil;
    NSTimeInterval	elapsed = 0;
    if (watch) {
        before = [NSDate date];
    }

	[self doExecuteWithLayoutImp:theLayout];

    if (watch) {
        elapsed = [[NSDate date] timeIntervalSinceDate:before];
        NSLog(@"used %.2f seconds", elapsed);
    }
}
@end
