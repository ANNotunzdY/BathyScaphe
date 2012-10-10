//
//  PreferencesPane.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/16.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "PreferencesPane.h"
#import "AppDefaults.h"
#import "PreferencesController.h"

#define DefineConstStr(symbol, value)		NSString *const symbol = value

DefineConstStr(PPLastOpenPaneIdentifier, @"PPLastOpenPaneIdentifier");
//DefineConstStr(PPShowAllIdentifier, @"ShowAll");

@implementation PreferencesPane
- (id)initWithPreferences:(AppDefaults *)prefs
{
	if (self = [super initWithWindowNibName:@"PreferencesPane"]) {
		[self setPreferences:prefs];
		[self makePreferencesControllers];

		// For use in GeneralPref
//		id transformer = [[[BSTagValueTransformer alloc] init] autorelease];
//		[NSValueTransformer setValueTransformer:transformer forName:@"BSTagValueTransformer"];

		// For use in FilterPane
//		id transformer2 = [[[BSTagToBoolTransformer alloc] init] autorelease];
//		[NSValueTransformer setValueTransformer:transformer2 forName:@"BSTagToBoolTransformer"];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[self window]]; 

	[_preferences release];
	[_toolbarItems release];
	[_controllers release];
	[_currentIdentifier release];
	[super dealloc];
}

- (AppDefaults *)preferences
{
	return _preferences;
}

- (void)setPreferences:(AppDefaults *)aPreferences
{
	[aPreferences retain];
	[_preferences release];
	_preferences = aPreferences;
}

- (void)awakeFromNib
{
	[self setupUIComponents];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(windowWillClose:)
			   name:NSWindowWillCloseNotification
			 object:[self window]];
}

- (IBAction)showWindow:(id)sender
{
	[super showWindow:sender];	
	if ([self isWindowLoaded]) {
		[self updateUIComponents];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	PreferencesController	*cntl;
	
	cntl = [self currentController];
	[cntl willUnselect];
}

- (NSString *)currentIdentifier
{
	return _currentIdentifier;
}

- (void)setCurrentIdentifier:(NSString *)aCurrentIdentifier
{
	[self removeContentViewWithCurrentIdentifier];

	[aCurrentIdentifier retain];
	[_currentIdentifier release];
	_currentIdentifier = aCurrentIdentifier;
	if (!_currentIdentifier) return;

	[[NSUserDefaults standardUserDefaults] setObject:_currentIdentifier forKey:PPLastOpenPaneIdentifier];

	[self insertContentViewWithCurrentIdentifier];
	[[[self window] toolbar] setSelectedItemIdentifier:aCurrentIdentifier];
}

- (id)showPreferencesPaneWithIdentifier:(NSString *)identifier
{
	[self showWindow:self];
	[self setCurrentIdentifier:identifier];
    return [self currentController];
}

- (id)showSubpaneWithIdentifier:(NSString *)subpaneId atPaneIdentifier:(NSString *)paneId
{
	if (paneId && ![paneId isEqualToString:[self currentIdentifier]]) {
		[self showPreferencesPaneWithIdentifier:paneId];
	}
    id controller = [self currentController];
	[controller showSubpaneWithIdentifier:subpaneId];
    return controller;
}

- (void)editCurrentThemeInPreferencesPane
{
    id controller = [self showSubpaneWithIdentifier:PPViewThemesSubpaneIdentifier atPaneIdentifier:PPFontsAndColorsIdentifier];
    if ([controller conformsToProtocol:@protocol(BSCurrentThemeEditing)]) {
        [(id<BSCurrentThemeEditing>)controller editCurrentTheme:nil];
    }
}
@end

@implementation PreferencesPane(ViewAccessor)
- (void)setupUIComponents
{
	NSString       *identifier_;	
	identifier_ = [[NSUserDefaults standardUserDefaults] stringForKey:PPLastOpenPaneIdentifier];
	
	if (![[[self controllers] valueForKey:@"identifier"] containsObject:identifier_]) {
		identifier_ = PPGeneralPreferencesIdentifier;
	}

	[self setupToolbar];
	[self setCurrentIdentifier:identifier_];

	[[self window] center];
}

- (NSString *)displayName
{
	PreferencesController	*controller_;
	
	controller_ = [self currentController];
	
	if (!controller_) return @"";	
	return [controller_ label];
}

- (void)updateUIComponents
{
	[[self window] setTitle:[self displayName]];
	[[self currentController] updateUIComponents];
}
@end
