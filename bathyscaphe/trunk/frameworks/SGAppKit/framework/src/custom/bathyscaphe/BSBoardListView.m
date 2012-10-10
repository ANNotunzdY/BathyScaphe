//
//  BSBoardListView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/09/20.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//

#import "BSBoardListView.h"

#define useLog 0

/*@interface NSOutlineView(LionStub)
- (NSInteger)rowSizeStyle;
- (NSInteger)effectiveRowSizeStyle;
- (void)setRowSizeStyle:(NSInteger)rowSizeStyle;
@end*/


@implementation BSBoardListView
- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (!newWindow) {
        return;
    }
	isInstalledTextInputEvent = NO;
	isFindBegin = NO;
	isUsingInputWindow = NO;
	resetTimer = nil;
}
// 10.7.2 以降不要
/*
- (NSRect)frameOfCellAtColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex
{
    NSRect defaultFrame = [super frameOfCellAtColumn:columnIndex row:rowIndex];
    // Lion Fix: ソースリストスタイルだとなぜかルートから一つ下の階層がインデントされないので、強引に
    if (floor(NSAppKitVersionNumber) > 1038) { // 1038 == NSAppKitVersionNumber10_6
        if ([self levelForRow:rowIndex] > 0) {
            CGFloat indent = [self indentationPerLevel];
            defaultFrame.origin.x += indent;
            defaultFrame.size.width -= indent;
        }
    }
    return defaultFrame;
}
*/
- (void)dealloc
{
	if (isInstalledTextInputEvent) {
		OSStatus err = RemoveEventHandler(textInputEventHandler);
		if (err != noErr) {
// #warning 64BIT: Check formatting arguments
// 2010-03-09 tsawada2 対策済

//typedef SInt32                          OSStatus;

//#if __LP64__
//typedef signed int                      SInt32;
//#else
//typedef signed long                     SInt32;
//#endif

#if __LP64__
			NSLog(@"%@", [NSString stringWithFormat:@"Fail to Remove EventHandler with : %d", err]);
#else
			NSLog(@"%@", [NSString stringWithFormat:@"Fail to Remove EventHandler with : %ld", (long)err]);
#endif
		}
	}

	fieldEditor = nil;
	[self stopResetTimer];
	[super dealloc];
}
/*
- (BSBoardListRowSizeStyle)bsRowSizeStyle
{
    if ([self respondsToSelector:@selector(effectiveRowSizeStyle)]) {
        return [self effectiveRowSizeStyle];
    }
    return bs_rowSizeStyle;
}

- (void)setBsRowSizeStyle:(BSBoardListRowSizeStyle)style
{
    if ([self respondsToSelector:@selector(setRowSizeStyle:)]) {
        NSLog(@"Ignored. Use System Preferences to set the size.");
        return;
    }
    bs_rowSizeStyle = style;
}

- (NSInteger)rowSizeStyle // Called 10.7 only
{
    return -1; // NSTableViewRowSizeStyleDefault
}

- (CGFloat)rowHeight // Never called on 10.7
{
    if (bs_rowSizeStyle == BSBoardListRowSizeStyleLarge) {
        return 34;
    } else if (bs_rowSizeStyle == BSBoardListRowSizeStyleMedium) {
        return 24;
    }
    return 20;
}*/
@end

//
// Type-To-Select Support
// Available in Starlight Breaker.
//
// From FileTreeView.m (part of StationaryPalette by 栗田哲郎)
// BathyScaphe プロジェクトに対し、栗田氏のご厚意により特別に FileTreeView.m を
// 修正 BSD ライセンスに基づいて使用する許可を得ています。
//
#pragma mark -

@implementation BSBoardListView(TypeToSelect)
static OSStatus inputText(EventHandlerCallRef nextHandler, EventRef theEvent, void* userData)
{
#if useLog    
	NSLog(@"inputText");
#endif
	unsigned long dataSize;
	/*OSStatus err =*/ GetEventParameter(theEvent, kEventParamTextInputSendText, typeUTF16ExternalRepresentation, NULL, 0, &dataSize, NULL);
	UniChar *dataPtr = (UniChar *)malloc(dataSize);
	/*err =*/ GetEventParameter(theEvent, kEventParamTextInputSendText, typeUTF16ExternalRepresentation, NULL, dataSize, NULL, dataPtr);
	NSString *aString =[[NSString alloc] initWithBytes:dataPtr length:dataSize encoding:NSUnicodeStringEncoding];
	[(id)userData insertTextInputSendText:aString];
    [aString release];
	free(dataPtr);
#if useLog	
	NSLog(@"end inputText");
#endif
	return(CallNextEventHandler(nextHandler, theEvent));
}

- (NSTimeInterval)findTimeoutInterval
{
    // from Dan Wood's 'Table Techniques Taught Tastefully', as pointed out by someone
    // on cocoadev.com
    
    // Timeout is two times the key repeat rate "InitialKeyRepeat" user default.
    // (converted from sixtieths of a second to seconds), but no more than two seconds.
    // This behavior is determined based on Inside Macintosh documentation on the List Manager.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger keyThreshTicks = [defaults integerForKey:@"InitialKeyRepeat"]; // undocumented key.  Still valid in 10.3. 
    if (0 == keyThreshTicks)	// missing value in defaults?  Means user has never changed the default.
    {
        keyThreshTicks = 35;	// apparent default value. translates to 1.17 sec timeout.
    }
    
    return MIN(2.0/60.0*keyThreshTicks, 2.0);
}


BOOL isReturnOrEnterKeyEvent(NSEvent *keyEvent) {
	unsigned short key_code = [keyEvent keyCode];
	return ((key_code == 36) || (key_code == 76));
}


BOOL isEscapeKeyEvent(NSEvent *keyEvent) {
	unsigned short key_code = [keyEvent keyCode];
	return (key_code == 53);
}

BOOL shouldBeginFindForKeyEvent(NSEvent *keyEvent)
{
    if (([keyEvent modifierFlags] & (NSCommandKeyMask | NSControlKeyMask | NSFunctionKeyMask)) != 0) {
        return NO;
    }
    
	unsigned short key_code = [keyEvent keyCode];
	// if true, arrow key's event.
	if ((123 <= key_code) && (key_code <= 126)) {
		return NO;
	}
	
	//escape key
	if (isEscapeKeyEvent(keyEvent)) return NO;
	
	if (isReturnOrEnterKeyEvent(keyEvent)) return NO;
	
	//space and tab and newlines are ignored
	unichar character = [[keyEvent characters] characterAtIndex:0];
	if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:character]){
		return NO;
	}
    return YES;    
}

- (BOOL)canChangeSelection
{
    id delegate = [self delegate];
    
    if (   [self isKindOfClass:[NSOutlineView class]] 
           && [delegate respondsToSelector:@selector(selectionShouldChangeInOutlineView:)])
    {
        return [delegate selectionShouldChangeInOutlineView:(NSOutlineView *)self];
    }
    else if ([delegate respondsToSelector:@selector(selectionShouldChangeInTableView:)])
    {
        return [delegate selectionShouldChangeInTableView:self];
    }
    else
    {
        return YES;
    }    
}

- (void)resetFind:(NSTimer *)aTimer
{
#if useLog
	NSLog(@"start restFind");
#endif	
	if (!isUsingInputWindow) {
		isFindBegin = NO;
		// it seems that RemoveEventHandler is not required -- 2007-01-10
		/* 
		OSStatus err = RemoveEventHandler(textInputEventHandler);
		if (err != noErr) {
			NSLog([NSString stringWithFormat:@"Fail to Remove EventHandler with : %d", err]);
		}
		*/
		isUsingInputWindow = NO;
		[self stopResetTimer];
	}
}

- (void)stopResetTimer
{
#if useLog
	NSLog(@"stop startResetTimer");
#endif	
	if (resetTimer != nil) {
		[resetTimer invalidate];
		[resetTimer release];
		resetTimer = nil;
	}
}

- (void)startResetTimer
{
#if useLog
	NSLog(@"start startResetTimer");
#endif	
	if (resetTimer != nil) {
		[resetTimer release];
	}
	
	resetTimer = [NSTimer scheduledTimerWithTimeInterval:[self findTimeoutInterval]
							target:self selector:@selector(resetFind:)
							userInfo:nil repeats:YES];
	[resetTimer retain];
}

- (void)insertTextInputSendText:(NSString *)aString
{
	if (isUsingInputWindow) {
		[fieldEditor insertText:aString];
		[self findForString:[fieldEditor string] ];
	}
}

- (void)keyDown:(NSEvent *)keyEvent
{
#if useLog	
	NSLog([NSString stringWithFormat:@"start KeyDown with event : %@", [keyEvent description]]);
#endif	
	BOOL eatEvent = NO;
//	if (searchColumnIdentifier == nil) goto bail;
 	if (![self canChangeSelection]) goto bail;
	
	BOOL shouldFindFlag = shouldBeginFindForKeyEvent(keyEvent);
	
	if (isFindBegin) {
		if (isUsingInputWindow) {
			if (! isEscapeKeyEvent(keyEvent)) eatEvent = YES;
		}
		else if (shouldFindFlag) {
			eatEvent = YES;
		}
	}
	else if (shouldFindFlag) {
		eatEvent = YES;
	}
	
bail:
	if (eatEvent) {
		#if useLog
		NSLog(@"eat key event");
		#endif
		[self stopResetTimer];
		fieldEditor = [[self window] fieldEditor:YES forObject:self];
		
		if (!isFindBegin) {
			[fieldEditor setString:@""];
			isFindBegin = YES;
		}

		if (!isInstalledTextInputEvent) {
			EventTypeSpec spec = { kEventClassTextInput, kEventTextInputUnicodeForKeyEvent };
			EventHandlerUPP handlerUPP = NewEventHandlerUPP(inputText);
			OSStatus err = InstallApplicationEventHandler(handlerUPP, 1, &spec, (void*)self, &textInputEventHandler);
			DisposeEventHandlerUPP(handlerUPP);
// #warning 64BIT: Check formatting arguments
// 2010-03-09 tsawada2 対策済
#if __LP64__
			NSAssert1(err == noErr, @"Fail to install TextInputEvent with error :%d", err);
#else
			NSAssert1(err == noErr, @"Fail to install TextInputEvent with error :%ld", err);
#endif
			isInstalledTextInputEvent = YES;
		}
		
		NSString *before_string = [NSString stringWithString:[fieldEditor string]];
	#if useLog
		NSLog([NSString stringWithFormat:@"before String : %@", before_string]);
	#endif
		[fieldEditor interpretKeyEvents:[NSArray arrayWithObject:keyEvent]];
		NSString *after_string = [fieldEditor string];
		
	#if useLog
		NSLog([NSString stringWithFormat:@"after String : %@", after_string]);
	#endif
	
		isUsingInputWindow = [before_string isEqualToString:after_string];
	#if useLog
// #warning 64BIT: Check formatting arguments
// 2010-03-09 tsawada2 対策済
//		printf("isUsingInputWindow : %d\n", isUsingInputWindow);
        NSLog(@"isUsingInputWindow : %@\n", isUsingInputWindow ? @"YES" : @"NO");
	#endif
		if (!isUsingInputWindow) {
			[self findForString:after_string ];
		}
		[self startResetTimer];
	}
	else {
		if (isFindBegin) {
			[self stopResetTimer];
			isFindBegin = NO;
		}
		[super keyDown:keyEvent];	
	}
}

- (void)findForString:(NSString *)aString {
#if useLog
	NSLog([NSString stringWithFormat:@"start findForString:%@", aString]);
#endif
	
/*	NSTableColumn *column = [self tableColumnWithIdentifier:searchColumnIdentifier];
	int nrows = [self numberOfRows];
	id dataSource = [self dataSource];
	for (int i = 0; i< nrows; i++) {
		id item = [self itemAtRow:i];
		id display_name = [dataSource outlineView:self objectValueForTableColumn:column byItem:item];
		if (NSOrderedSame == [display_name compare:aString options:NSCaseInsensitiveSearch range:NSMakeRange(0, [aString length])]) {
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
			break;
		}
		
	}*/
	id			delegate_ = [self delegate];
	NSIndexSet	*indexes = nil;

	if (delegate_ && [delegate_ respondsToSelector:@selector(outlineView:findForString:)]) {
		indexes = [delegate_ outlineView:self findForString:aString];
	}
	if (indexes) {
		[self selectRowIndexes:indexes byExtendingSelection:NO];
	}
}
@end
