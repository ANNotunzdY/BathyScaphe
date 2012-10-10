//
//  BSThemeEditor.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/04/22.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThemeEditor.h"
#import "PreferencePanes_Prefix.h"
#import "AppDefaults.h"

@implementation BSThemeEditor
#pragma mark Overrides
- (id)init
{
	if (self = [super initWithWindowNibName:@"ThemeEditor"]) {
        BOOL isDebugMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"BSUserDebugEnabled"];
		[self window];
        [m_debugInternalThemeSetButton setHidden:!isDebugMode];
        [m_debugPopupAlphaField setHidden:!isDebugMode];
	}
	return self;
}

- (void)dealloc
{
	m_delegate = nil;
	[self setSaveThemeIdentifier:nil];
	[self setThemeFileName:nil];
	[super dealloc];
}

#pragma mark Accessors
- (id)delegate
{
	return m_delegate;
}

- (void)setDelegate:(id)aDelegate
{
	m_delegate = aDelegate;
}

- (NSString *)saveThemeIdentifier
{
	return m_saveThemeIdentifier;
}

- (void)setSaveThemeIdentifier:(NSString *)aString
{
	[aString retain];
	[m_saveThemeIdentifier release];
	m_saveThemeIdentifier = aString;
}

- (BOOL)isNewTheme
{
	return m_isNewTheme;
}

- (void)setIsNewTheme:(BOOL)flag
{
	m_isNewTheme = flag;
}

- (NSString *)themeFileName
{
	return m_fileName;
}

- (void)setThemeFileName:(NSString *)filename
{
	[filename retain];
	[m_fileName release];
	m_fileName = filename;
}

- (NSObjectController *)themeGreenCube
{
	return m_themeGreenCube;
}

#pragma mark Utilities
- (BOOL)isUniqueThemeIdentifier:(NSString *)identifier
{
	if ([identifier isEqualToString:[[[self themeGreenCube] content] identifier]]) {
		return YES;
	}
    
    NSArray *array = [[[self delegate] preferences] installedThemes];

	NSArray *identifiers = [array valueForKey:@"Identifier"];
	NSArray *fileNames = [array valueForKey:@"ThemeFilePath"];

	if (![identifiers containsObject:identifier]) { // 重複していない
		return YES;
	} else {
		if ([self isNewTheme]) {
			return NO;
		}
        // カスタムテーマに限定して考えて良いから -createFullPathFromThemeFileName: を使って良いはず
		NSUInteger idx = [fileNames indexOfObject:[[[self delegate] preferences] createFullPathFromThemeFileName:[self themeFileName]]];
		if (idx == NSNotFound) { // 重複していない
			return YES;
		}
		return NO;
	}
}

- (BOOL)saveThemeCore
{
	NSString *fileName;
	id	content = [[self themeGreenCube] content];

	if ([self themeFileName]) {
		fileName = [self themeFileName];
	} else {
// #warning 64BIT: Check formatting arguments
// 2010-03-22 tsawada2 検討済
		fileName = [NSString stringWithFormat:@"UserTheme%.0f.plist", [[NSDate date] timeIntervalSince1970]];
		[self setThemeFileName:fileName];
	}
	NSString *filePath = [[[self delegate] preferences] createFullPathFromThemeFileName:fileName];

	[content setIdentifier:[self saveThemeIdentifier]];
	NSError *theError;
	if ([content writeToFile:filePath options:NSAtomicWrite error:&theError]) {
		return YES;
	} else {
		[[NSAlert alertWithError:theError] runModal];
		return NO;
	}
}

- (void)showOverlappingThemeIdAlert
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	NSString *saveIdentifier = [self saveThemeIdentifier];

	[alert setAlertStyle:NSWarningAlertStyle];
// #warning 64BIT: Check formatting arguments
// 2010-03-22 tsawada2 検討済
	[alert setMessageText:[NSString stringWithFormat: PPLocalizedString(@"overlappingThemeIdAlertTitle"), saveIdentifier]];
	[alert setInformativeText:PPLocalizedString(@"overlappingThemeIdAlertMsg")];
	[alert addButtonWithTitle:PPLocalizedString(@"overlappingThemeIdBtn1")];
	[alert addButtonWithTitle:PPLocalizedString(@"overlappingThemeIdBtn2")];
	if ([alert runModal] == NSAlertFirstButtonReturn) {
		if ([self saveThemeCore]) {
			[NSApp endSheet:[self window] returnCode:NSOKButton];
		}
	}
}

#pragma mark IBActions
- (IBAction)cancelEditingTheme:(id)sender
{
	[NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)saveTheme:(id)sender
{
	[[self themeGreenCube] commitEditing];

	if ([self isUniqueThemeIdentifier:[self saveThemeIdentifier]]) {
		if ([self saveThemeCore]) {
			[NSApp endSheet:[self window] returnCode:NSOKButton];
		}
	} else {
		[self showOverlappingThemeIdAlert];
	}
}

- (IBAction)openHelpForEditingCustomTheme:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:PPLocalizedString(@"Help_View_Edit_Custom_Theme")
											   inBook:[NSBundle applicationHelpBookName]];
}

#pragma mark Public
- (void)beginSheetModalForWindow:(NSWindow *)window
				   modalDelegate:(id)delegate
					 contextInfo:(void *)contextInfo
{
	[NSApp beginSheet:[self window]
	   modalForWindow:window
		modalDelegate:delegate
	   didEndSelector:@selector(themeEditSheetDidEnd:returnCode:contextInfo:) 
		  contextInfo:contextInfo];
}

#pragma mark NSFontPanel Validation
- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel
{
	return [[self delegate] validModesForFontPanel:fontPanel];
}
@end
