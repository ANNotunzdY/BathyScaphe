//
//  SmartBoardListItemEditor.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/12/27.
//  Copyright 2005 BathyScaphe Project. All rights reserved.
//

#import "SmartBoardListItemEditor.h"
#import "SmartBoardListItem.h"
#import "UTILKit.h"
#import "BoardManager.h"

#import "XspfMRuleEditorDelegate.h"


NSString *const SBLIEditorDidEditSmartBoardListItemNotification = @"SBLIEditorDidEditSmartBoardListItemNotification";

@implementation SmartBoardListItemEditor

static NSMutableArray *editors = nil;
+ (void)initialize
{
	BOOL isFIrst = YES;
	if(isFIrst) {
		editors = [[NSMutableArray alloc] init];
	}
}

+ (id)editor
{
	id editor = [[[self alloc] init] autorelease];
	[editors addObject:editor];
	return editor;
}

- (id)init
{
	if(self = [super init]) {
		[NSBundle loadNibNamed:@"SmartBoardItemEditor"
						 owner:self];
	}
	
	return self;
}
- (void)dealloc
{
	[mInvocation release];
	
	[super dealloc];
}
- (void)awakeFromNib
{
	[XspfMRuleEditorDelegate registerStringTypeKeyPaths:[NSArray arrayWithObjects:@"boardName", @"threadName", nil]];
	[XspfMRuleEditorDelegate registerDateTypeKeyPaths:[NSArray arrayWithObjects:@"threadID", @"modifiedDate", @"LastWrittenDate", nil]];
	[XspfMRuleEditorDelegate registerNumberTypeKeyPaths:[NSArray arrayWithObjects:@"numberOfAll", @"numberOfRead", @"numberOfDifference", nil]];
	[XspfMRuleEditorDelegate setUseRating:NO];
	[XspfMRuleEditorDelegate setUseLablel:YES];
	[XspfMRuleEditorDelegate setLabelKeyPath:@"threadLabel"];
}
static inline NSInvocation *checkMethodSignature(id obj, SEL selector)
{
	NSInvocation *result = nil;
	NSMethodSignature *sig;
//	const char *argType;
	
	if(!obj || !selector) return nil;
	
	sig = [obj methodSignatureForSelector:selector];
	if(!sig) return nil;
	
	if(4 != [sig numberOfArguments]) return nil;
	
//	argType = [sig getArgumentTypeAtIndex:2];
//	if(argType[0] != NSObjCObjectType) return nil;
	
//	argType = [sig getArgumentTypeAtIndex:3];
/*	switch(argType[0]) {
		case NSObjCObjectType:
		case NSObjCPointerType:
		case NSObjCArrayType:
		case NSObjCUnionType:
		case NSObjCSelectorType:
		case NSObjCStringType:
		case '#': // Class型
		case '?': // 不明な型。関数ポインタの可能性あり。
			break;
		default:
			return nil;
	}*/
	
	result = [NSInvocation invocationWithMethodSignature:sig];
	if(!result) return nil;
	
	[result setTarget:obj];
	[result setSelector:selector];
	
	return result;
}

- (NSString *)usableItemName
{
	NSString *result = NSLocalizedString(@"New SmartBoard", @"New SmartBoard");
	SmartBoardList *bl = [[BoardManager defaultManager] userList];
	id item;
	
	item = [bl itemForName:result];
	if (!item) {
		return result;
	}
	
	NSUInteger i;
	for(i = 2; i < NSUIntegerMax; i++) {
		result = [[NSString alloc] initWithFormat:NSLocalizedString(@"New SmartBoard %lu", @"New SmartBoard %lu"), (unsigned long)i];
		if (![bl itemForName:result]) {
            result = [result autorelease];
			break;
		}
		[result release];
		result = nil;
	}
	
	return result;
}

- (id)preparPredicate:(id)predicate
{
	if(predicate && ![predicate isKindOfClass:[NSCompoundPredicate class]]) {
		predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObject:predicate]];
	}
	return predicate;
}

- (void)cretateFromUIWindow:(NSWindow *)inModalForWindow
					delegate:(id)delegate
			 settingSelector:(SEL)settingSelector
					userInfo:(void *)contextInfo
{
	mInvocation = checkMethodSignature(delegate, settingSelector);
	if(delegate && settingSelector && !mInvocation) {
		NSLog(@"settingSelector misssmatch.");
		return;
	}
	if(mInvocation) {
		[mInvocation setArgument:&contextInfo atIndex:3];
		[mInvocation retain];
	}
	
	if([ruleEditor numberOfRows] == 0) {
		[ruleEditor addRow:self];
	}
	
	[nameField setStringValue:[self usableItemName]];
	if(inModalForWindow) {
		[NSApp beginSheet:editorWindow
		   modalForWindow:inModalForWindow
			modalDelegate:self
		   didEndSelector:@selector(endSelector:returnCode:contextInfo:)
			  contextInfo:NULL];
	} else {
		[editorWindow makeKeyAndOrderFront:self];
	}
}
- (void)endSelector:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	id newItem = nil;
	
	if(sheet != editorWindow) return;
	
	[editorWindow orderOut:self];
	if(returnCode) {
		NSPredicate *predicate = [self preparPredicate:[ruleEditor predicate]];
		newItem = [BoardListItem baordListItemWithName:[nameField stringValue]
											 condition:predicate];
	}
	
	if(mInvocation) {
		[mInvocation setArgument:&newItem atIndex:2];
		[mInvocation invoke];
	}
	
	[editorWindow close];
	[editors removeObject:self];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[[alert window] orderOut:self];
}
- (void)ok:(id)sender
{
	if(![nameField stringValue] || [[nameField stringValue] length] == 0) {
		NSAlert *alert = [NSAlert alertWithMessageText:[self localizedString:@"Error"]
										 defaultButton:[self localizedString:@"OK"]
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:[self localizedString:@"Name is empty"]];
		if([sender isKindOfClass:[NSView class]] && [sender window]) {
			[alert beginSheetModalForWindow:[sender window]
							  modalDelegate:self
							 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
								contextInfo:NULL];
		} else {
			[alert runModal];
		}
		return;
	}	
	[ruleEditor reloadPredicate];
	
	if([editorWindow isSheet]) {
		[NSApp endSheet:editorWindow returnCode:NSOKButton];
	} else {
		[self endSelector:editorWindow returnCode:NSOKButton contextInfo:NULL];
	}
}
- (void)cancel:(id) sender
{
	if([editorWindow isSheet]) {
		[NSApp endSheet:editorWindow returnCode:NSCancelButton];
	} else {
		[self endSelector:editorWindow returnCode:NSCancelButton contextInfo:NULL];
	}
}

- (void)editWithUIWindow:(NSWindow *)inModalForWindow
		  smartBoardItem:(BoardListItem *)smartBoardItem
{
	[nameField setStringValue:[smartBoardItem name]];
	[editorDelegate setPredicate:[(SmartBoardListItem *)smartBoardItem condition]];
	if(inModalForWindow) {
		[NSApp beginSheet:editorWindow
		   modalForWindow:inModalForWindow
			modalDelegate:self
		   didEndSelector:@selector(endEditSelector:returnCode:contextInfo:)
			  contextInfo:[smartBoardItem retain]];
	} else {
		[editorWindow makeKeyAndOrderFront:self];
	}
	
}
- (void)endEditSelector:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	if(returnCode && context) {
		SmartBoardListItem *item = context;
		NSString *newName = [nameField stringValue];
		[[BoardManager defaultManager] passPropertiesOfBoardName: [(id)context name] toBoardName: newName]; 
		[item setName:newName];
		[item setCondition:[self preparPredicate:[ruleEditor predicate]]];
		UTILNotifyInfo(SBLIEditorDidEditSmartBoardListItemNotification, (id)context);
		[item release];
	}
	
	[editorWindow close];
	[editors removeObject:self];
}


// windowWillClose: で[self cancel:self]を呼ぶと、[NSWindow close] が呼ばれるため無限ループに陥る。
- (BOOL)windowShouldClose:(id)sender
{
	[self cancel:self];
	return YES;
}

- (IBAction)dumpPredicate:(id)sender
{
	[ruleEditor reloadPredicate];
	id predicate = [ruleEditor predicate];
	NSLog(@"Predicate -> %@", predicate);
}

@end

@implementation SmartBoardListItemEditor(CMRLocalizableStringsOwner)
+ (NSString *) localizableStringsTableName
{
	return NSStringFromClass(self);
}
@end
