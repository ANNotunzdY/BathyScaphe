//
//  SoundsPaneController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/01/27.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SoundsPaneController.h"

#import "AppDefaults.h"
#import "PreferencePanes_Prefix.h"

@implementation SoundsPaneController
static BOOL addFileListsToMenu(NSMenu *menu_, short ofWhichDomain)
{
    CFURLRef        soundsFolderURL;
    FSRef           soundsFolderRef;
    CFStringRef     soundsFolderPath;
    OSErr           err;
	NSDirectoryEnumerator	*tmpEnum;
	NSString		*file;
    NSFileManager   *mgr = [NSFileManager defaultManager];
	NSArray			*typesArray = [NSSound soundUnfilteredTypes];
	BOOL			actuallyAdded = NO;

    err = FSFindFolder(ofWhichDomain, kSystemSoundsFolderType, kDontCreateFolder, &soundsFolderRef);
    if (err == noErr) {
		soundsFolderURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &soundsFolderRef);
		if (soundsFolderURL) {
			soundsFolderPath = CFURLCopyFileSystemPath (soundsFolderURL, kCFURLPOSIXPathStyle);
			if (soundsFolderPath) {
				tmpEnum = [mgr enumeratorAtPath : (NSString *)soundsFolderPath];

				while (file = [tmpEnum nextObject]) {
                    NSString *fullPath = [(NSString *)soundsFolderPath stringByAppendingPathComponent:file];
                    NSString *type = [[NSWorkspace sharedWorkspace] typeOfFile:fullPath error:NULL];
                    if ([typesArray containsObject:type]) {
//					if ([typesArray containsObject : [file pathExtension]]) {
						[menu_ addItemWithTitle : [file stringByDeletingPathExtension]
										 action : @selector(soundChosen:)
								  keyEquivalent : @""];
						actuallyAdded = YES;
					}
				}

				CFRelease(soundsFolderPath);
			}
			CFRelease(soundsFolderURL);
		}
	}
	
	return actuallyAdded;
}

- (void) setUpMenu : (NSMenu *) menu_
{
	NSInteger		itemCount_;

	addFileListsToMenu(menu_, kSystemDomain);
	itemCount_ = [menu_ numberOfItems];
	if(addFileListsToMenu(menu_, kLocalDomain))
		[menu_ insertItem : [NSMenuItem separatorItem] atIndex : itemCount_];

	itemCount_ = [menu_ numberOfItems];
	if(addFileListsToMenu(menu_, kUserDomain))
		[menu_ insertItem : [NSMenuItem separatorItem] atIndex : itemCount_];
		
	[[self soundForHEADCheckNewArrivedBtn] setMenu : menu_];
	[[[self soundForHEADCheckNewArrivedBtn] menu] setTitle : @"setHEADCheckNewArrivedSound:"];

	NSMenu *menu2 = [menu_ copy];
	[[self soundForHEADCheckNoUpdateBtn] setMenu:menu2];
	[menu2 release];
	[[[self soundForHEADCheckNoUpdateBtn] menu] setTitle : @"setHEADCheckNoUpdateSound:"];

	NSMenu *menu3 = [menu_ copy];
	[[self soundForReplyDidFinishBtn] setMenu:menu3];
	[menu3 release];
	[[[self soundForReplyDidFinishBtn] menu] setTitle : @"setReplyDidFinishSound:"];
}

#pragma mark Accessors
- (NSPopUpButton *) soundForHEADCheckNewArrivedBtn
{
	return _soundForHEADCheckNewArrivedBtn;
}
- (NSPopUpButton *) soundForHEADCheckNoUpdateBtn
{
	return _soundForHEADCheckNoUpdateBtn;
}
- (NSPopUpButton *) soundForReplyDidFinishBtn
{
	return _soundForReplyDidFinishBtn;
}
- (NSMenu *) soundsListMenu
{
	return _soundsListMenu;
}

#pragma mark IBActions
- (IBAction) soundChosen : (id) sender
{
	NSString		*title_ = [(NSMenuItem *)sender title];
	NSSound			*sound_ = [NSSound soundNamed : title_];
	[sound_ play];
	[[self preferences] performSelector : NSSelectorFromString([[(NSMenuItem *)sender menu] title])
							 withObject : title_
							 afterDelay : 0];
}

- (IBAction) soundNone : (id) sender
{
	[[self preferences] performSelector : NSSelectorFromString([[(NSMenuItem *)sender menu] title])
							 withObject : @""
							 afterDelay : 0];
}

#pragma mark Private Methods

- (NSString *) mainNibName
{
	return @"SoundsPreferences";
}

- (void) updateUIComponents
{
	NSString *tmp_;

	tmp_ = [[self preferences] HEADCheckNewArrivedSound];
	if([tmp_ isEqualToString : @""])
		[[self soundForHEADCheckNewArrivedBtn] selectItemAtIndex : 0];
	else
		[[self soundForHEADCheckNewArrivedBtn] selectItemWithTitle : tmp_];
	[[self soundForHEADCheckNewArrivedBtn] synchronizeTitleAndSelectedItem];

	tmp_ = [[self preferences] HEADCheckNoUpdateSound];
	if([tmp_ isEqualToString : @""])
		[[self soundForHEADCheckNoUpdateBtn] selectItemAtIndex : 0];
	else
		[[self soundForHEADCheckNoUpdateBtn] selectItemWithTitle : tmp_];
	[[self soundForHEADCheckNoUpdateBtn] synchronizeTitleAndSelectedItem];

	tmp_ = [[self preferences] replyDidFinishSound];
	if([tmp_ isEqualToString : @""])
		[[self soundForReplyDidFinishBtn] selectItemAtIndex : 0];
	else
		[[self soundForReplyDidFinishBtn] selectItemWithTitle : tmp_];
	[[self soundForReplyDidFinishBtn] synchronizeTitleAndSelectedItem];
}

- (void) setupUIComponents
{
	if (nil == _contentView)
		return;

	[self setUpMenu : [self soundsListMenu]];
	[self updateUIComponents];
}


@end

@implementation SoundsPaneController(Toolbar)
- (NSString *) identifier
{
	return PPSoundsPreferencesIdentifier;
}
- (NSString *) helpKeyword
{
	return PPLocalizedString(@"Help_Sounds");
}
- (NSString *) label
{
	return PPLocalizedString(@"Sounds Label");
}
- (NSString *) paletteLabel
{
	return PPLocalizedString(@"Sounds Label");
}
- (NSString *) toolTip
{
	return PPLocalizedString(@"Sounds ToolTip");
}
- (NSString *) imageName
{
	return @"SoundsPreferences";
}
@end
