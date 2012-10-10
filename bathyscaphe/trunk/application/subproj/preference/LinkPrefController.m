//
//  LinkPrefController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/14.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "LinkPrefController.h"
#import "PreferencePanes_Prefix.h"
#import "BSPathExtensionFormatter.h"

@implementation LinkPrefController
- (NSString *)mainNibName
{
	return @"LinkPreferences";
}

#pragma mark IBActions
/*- (void)didEndChooseFolderSheet:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		NSString	*folderPath_;

		folderPath_ =	[sheet directory];
		[[self preferences] setLinkDownloaderDestination:folderPath_];
	}
	[self updateFolderButtonUI];
}*/

- (IBAction)chooseDestination:(id)sender
{
	NSOpenPanel	*panel_ = [NSOpenPanel openPanel];
	[panel_ setCanChooseFiles:NO];
	[panel_ setCanChooseDirectories:YES];
	[panel_ setResolvesAliases:YES];
	[panel_ setAllowsMultipleSelection:NO];
	
/*	[panel_ beginSheetForDirectory:nil
							  file: nil
							 types:nil
					modalForWindow:[self window]
					 modalDelegate:self
					didEndSelector:@selector(didEndChooseFolderSheet:returnCode:contextInfo:)
					   contextInfo:nil];*/
    [panel_ beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [[self preferences] setLinkDownloaderDestination:[[[panel_ URLs] lastObject] path]];
        }
        [self updateFolderButtonUI];
    }];
}

- (IBAction)openPreviewerPrefs:(id)sender
{
	[[self preferences] letPreviewerShowPreferences:sender];
}

#pragma mark Accessors
- (NSPopUpButton *)downloadDestinationChooser
{
	return m_downloadDestinationChooser;
}

- (NSTextField *)previewerNameField
{
	return m_previewerNameField;
}

- (NSTextField *)previewerIdField
{
	return m_previewerIdField;
}

- (NSInteger)previewOption
{
	return [[self preferences] previewLinkWithNoModifierKey] ? 0 : 1;
}

- (void)setPreviewOption:(NSInteger)selectedTag
{
	BOOL	tmp_ = (selectedTag == 0) ? YES : NO;
	[[self preferences] setPreviewLinkWithNoModifierKey:tmp_];
}

#pragma mark Setting up UIs
- (void)updateFolderButtonUI
{
	NSString	*fullPath = [[self preferences] linkDownloaderDestination];
	NSString	*displayTitle = [[NSFileManager defaultManager] displayNameAtPath:fullPath];
	NSImage		*icon = [[NSWorkspace sharedWorkspace] iconForFile:fullPath];
	NSMenuItem	*theItem = [[self downloadDestinationChooser] itemAtIndex:0];

	[icon setSize:NSMakeSize(16,16)];

	[theItem setTitle:displayTitle];
	[theItem setToolTip:fullPath];
	[theItem setImage:icon];

	[[self downloadDestinationChooser] selectItem:nil];
	[[self downloadDestinationChooser] synchronizeTitleAndSelectedItem];
}

- (void)updatePreviewerFields
{
	NSBundle *info = [[self preferences] installedPreviewerBundle];
	NSString *displayName = [info objectForInfoDictionaryKey:@"BSPreviewerDisplayName"];
	if (!displayName) {
		displayName = [info objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	}
	BOOL	hoge = [[info bundlePath] hasPrefix:[[NSBundle mainBundle] builtInPlugInsPath]];
	
	NSString *bar = hoge ? PPLocalizedString(@"Built-in") : PPLocalizedString(@"Custom");

// #warning 64BIT: Check formatting arguments
// 2010-03-22 tsawada2 検証済
	NSString *foo = [NSString stringWithFormat:PPLocalizedString(@"PreviewerDisplayName"),
						displayName , bar, [info objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	[[self previewerNameField] setStringValue:foo];
	[[self previewerIdField] setStringValue:[info objectForInfoDictionaryKey:@"NSHumanReadableCopyright"]];
}

- (void)updateUIComponents
{
	[self updateFolderButtonUI];
	[self updatePreviewerFields];
}

- (void)setupUIComponents
{
	BSPathExtensionFormatter *formatter;

	if (!_contentView) return;
	[self updateUIComponents];
	
	id cell = [m_pathExtensionColumn dataCell];
	formatter = [[BSPathExtensionFormatter alloc] init];
	[cell setFormatter:formatter];
	[formatter release];
}
@end


@implementation LinkPrefController(Toolbar)
- (NSString *)identifier
{
	return @"Link";
}
- (NSString *)helpKeyword
{
	return PPLocalizedString(@"Help_Link");
}
- (NSString *)label
{
	return PPLocalizedString(@"Link Label");
}
- (NSString *)paletteLabel
{
	return PPLocalizedString(@"Link Label");
}
- (NSString *)toolTip
{
	return PPLocalizedString(@"Link ToolTip");
}
- (NSString *)imageName
{
	return @"LinkPreferences";
}
@end
