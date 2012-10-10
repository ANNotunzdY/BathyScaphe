//
//  CMROpenURLManager.m
//  BathyScaphe
//
//  Created by minamie on Sun Jan 25 2004.
//  Copyright (c) 2004 CocoMonar Project, (c) 2006, 2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMROpenURLManager.h"
#import "CocoMonar_Prefix.h"
#import <Cocoa/Cocoa.h>

#import "CMRThreadLinkProcessor.h"
#import "CMRDocumentFileManager.h"
#import "CMRDocumentController.h"

#import "missing.h"

/* .nib file name */
#define kOpenURLControllerNib	@"CMROpenURL"

/* Input Panel */
@interface OpenURLController : NSWindowController
{
	IBOutlet NSTextField	*_textField;
	NSString				*_typedText;
}
- (NSURL *) askUserURL;
- (NSString *) typedText;
- (void) setTypedText: (NSString *) aText;
- (IBAction) ok : (id) sender;
- (IBAction) cancel : (id) sender;
@end



@implementation OpenURLController
- (id) init
{
	return [self initWithWindowNibName : kOpenURLControllerNib];
}
- (void) dealloc
{
	[_typedText release];
	[super dealloc];
}
- (IBAction) ok : (id) sender { [NSApp stopModalWithCode : NSOKButton]; }
- (IBAction) cancel : (id) sender { [NSApp stopModalWithCode : NSCancelButton]; }
- (NSString *) typedText { return _typedText; }
- (void) setTypedText: (NSString *) aText
{
	[aText retain];
	[_typedText release];
	_typedText = aText;
}

- (NSURL *) askUserURL
{	
	int				code;

	[self setTypedText: nil];
	[self window];
	//[_textField setStringValue:@""];
	[_textField selectText:self];
	code = [NSApp runModalForWindow : [self window]];
	
	[[self window] close];
	return (NSOKButton == code)
		? [NSURL URLWithString:[self typedText]]//[_textField stringValue]]
		: nil;
}
@end

@implementation CMROpenURLManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (NSURL *) askUserURL
{
	OpenURLController	*controller_;
	NSURL				*u;	
	
	controller_ = [[OpenURLController alloc] init];
	u = [controller_ askUserURL];
	
	if (u != nil) {
		[self openLocation : u];
	}
	[controller_ release];
	
	return u;
}

- (BOOL)openLocation:(NSURL *)url
{
	NSString		*boardName_;
	NSURL			*boardURL_;
	NSString		*filepath_;
    NSString *parsedHost_;
	
	if ([[url scheme] isEqualToString:@"bathyscaphe"]) {
		NSString *host_ = [url host];
		NSString *path_ = [url path];
		
		url = [[[NSURL alloc] initWithScheme:@"http" host:host_ path:path_] autorelease];
	}

	if ([CMRThreadLinkProcessor parseThreadLink:url boardName:&boardName_ boardURL:&boardURL_ filepath:&filepath_ parsedHost:&parsedHost_]) {
		CMRDocumentFileManager	*dm;
		NSDictionary			*contentInfo_;
		NSString				*datIdentifier_;
		
		dm = [CMRDocumentFileManager defaultManager];
		datIdentifier_ = [dm datIdentifierWithLogPath:filepath_];
		contentInfo_ = [NSDictionary dictionaryWithObjectsAndKeys: 
			[boardURL_ absoluteString], BoardPlistURLKey,
			boardName_, ThreadPlistBoardNameKey,
			datIdentifier_, ThreadPlistIdentifierKey,
            parsedHost_, @"candidateHost",
			NULL];
		
		[dm ensureDirectoryExistsWithBoardName:boardName_];
		return [[CMRDocumentController sharedDocumentController] showDocumentWithContentOfFile:[NSURL fileURLWithPath:filepath_] boardInfo:contentInfo_];
	} else if ([CMRThreadLinkProcessor parseBoardLink:url boardName:&boardName_ boardURL:&boardURL_]) {
		[[NSApp delegate] showThreadsListForBoard:boardName_ selectThread:nil addToListIfNeeded:YES];
		return YES;
	} else {
		int		code;
		NSAlert	*alert_ = [[[NSAlert alloc] init] autorelease];
        NSString *table = [self className];
			
		[alert_ setMessageText:NSLocalizedStringFromTable(@"Could Not Open Title", table, nil)];
		[alert_ setInformativeText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could Not Open Message", table, nil), [url absoluteString]]];
		[alert_ addButtonWithTitle:NSLocalizedStringFromTable(@"Open in Web Browser", table, nil)];
		[alert_ addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];

		code = [alert_ runModal];

		if (code == NSAlertFirstButtonReturn) {
			[[NSWorkspace sharedWorkspace] openURL:url];
		}
		
	}
	
	return NO;
}

#pragma mark AppleEvent Support
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString	*urlStr_;
    NSURL		*url_;

    urlStr_ = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	url_ = [NSURL URLWithString:urlStr_];

    [self openLocation:url_];
}

#pragma mark Service Menu Support
- (void) _showAlertForViaService
{
	NSAlert *alert_;
	
	alert_ = [[NSAlert alloc] init];
	[alert_ setMessageText : NSLocalizedStringFromTable(@"Could Not Open Via Service Title", [self className], nil)];
	[alert_ setInformativeText : NSLocalizedStringFromTable(@"Could Not Open Via Service Message", [self className], nil)];
	[alert_ addButtonWithTitle :NSLocalizedString(@"Cancel", @"Cancel")];
	
	[alert_ runModal];
	[alert_ release];
}

- (void) openURL : (NSPasteboard *) pboard
		userData : (NSString *) data
		   error : (NSString **) error
{
	NSArray		*types			= nil;
	NSString	*pboardString   = nil;
	NSURL		*u				= nil;
	
	[NSApp activateIgnoringOtherApps : YES];
	types = [pboard types];
	if ([types containsObject : NSStringPboardType] == NO) {
		*error = @"[pboard types] dosen't contain NSStringPboardType.";
	
		[self _showAlertForViaService];
		return;
	}
	pboardString = [pboard stringForType : NSStringPboardType];
	if (pboardString == nil) {
		*error = @"pboardString is nil.";
		
		[self _showAlertForViaService];
		return;
	}
	u = [NSURL URLWithString : pboardString];
	if (u == nil) {
		*error = @"Can't create NSURL from pboardString.";
		
		[self _showAlertForViaService];
		return;
	}

	[self openLocation : u];	
	return;
}
@end
