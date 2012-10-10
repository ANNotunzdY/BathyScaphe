//
//  PreferencesController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/05/17.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "PreferencesController.h"

#import <SGFoundation/NSBundle-SGExtensions.h>

@implementation PreferencesController
- (id)initWithPreferences:(AppDefaults *)pref
{
	if (self = [super init]) {
		[self setPreferences:pref];
	}
	return self;
}

- (void)dealloc
{
	[_contentView release];
	[_preferences release];
	[super dealloc];
}

- (NSView *)contentView
{
	return [self mainView];
}

- (NSWindow *)window
{
	return _window;
}

- (void)setWindow:(NSWindow *)aWindow
{
	_window = aWindow;
	[_window setDelegate:self];
}

- (AppDefaults *)preferences
{
	return _preferences;
}

- (void)setPreferences:(AppDefaults *)aPreferences
{
	id		tmp;
	
	tmp = _preferences;
	_preferences = [aPreferences retain];
	[tmp release];
}

- (void)setupUIComponents
{
	;
}

- (void)updateUIComponents
{
	;
}

- (void)showSubpaneWithIdentifier:(NSString *)subpaneId
{
	;
}

- (NSString *)currentSubpaneIdentifier
{
    return nil;
}

// same as NSPreferencePane
- (NSView *)loadMainView
{
	if (![self mainNibName]) return nil;
	
	[NSBundle loadNibNamed:[self mainNibName] owner:self];
	
	[self mainViewDidLoad];
	
	return _contentView;
}

- (NSView *)mainView
{
	if (!_contentView) {
		[self loadMainView];
	}
	return _contentView;
}

- (NSString *)mainNibName
{
	return nil;
}

- (void)mainViewDidLoad
{
	[self setupUIComponents];
}

// invoked by parent PreferencesPane
- (void)willUnselect 
{
	NSWindow *window = [self window];
	if ([window makeFirstResponder:window]) {
		/* All fields are now valid; it’s safe to use fieldEditor:forObject:
		to claim the field editor. */
		;
	} else {
		/* Force first responder to resign. */
		[window endEditingFor:nil];
	}
}

- (void)didSelect
{
	[[self window] recalculateKeyViewLoop];
}

- (IBAction)openHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[self helpKeyword]
											   inBook:[NSBundle applicationHelpBookName]];
}
@end


@implementation PreferencesController(Toolbar)
- (NSToolbarItem *)makeToolbarItem
{
	NSToolbarItem		*item_;
	
	item_ = [[NSToolbarItem alloc] initWithItemIdentifier:[self identifier]];
	[item_ setLabel:[self label]];
	[item_ setPaletteLabel:[self paletteLabel]];
	[item_ setToolTip:[self toolTip]];
	[item_ setImage:[self image]];

	return [item_ autorelease];
}

- (NSString *)identifier
{
	return nil;
}

- (NSString *)helpKeyword
{
	return nil;
}

- (NSString *)label
{
	return nil;
}

- (NSString *)paletteLabel
{
	return nil;
}

- (NSString *)toolTip
{
	return nil;
}

- (NSImage *)image
{
	NSString	*filepath_;
	
	filepath_ = [[NSBundle bundleForClass:[self class]] pathForImageResource:[self imageName]];
	
	if (filepath_) {
		return [[[NSImage alloc] initWithContentsOfFile:filepath_] autorelease];
	} else {
		return [NSImage imageNamed:[self imageName]];
	}
}

- (NSString *)imageName
{
	return nil;
}
@end
