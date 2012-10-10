//
//  PreferencesPane-ViewAccessor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "AppDefaults.h"
#import "PreferencesPane.h"
#import "PreferencesController.h"
#import "PreferencePanes_Prefix.h"



@implementation PreferencesPane(ViewAccessor)
- (void) setupUIComponents
{
	PreferencesController *controller_;
	NSUserDefaults *defaults_;
	NSString       *identifier_;
	
	defaults_ = [NSUserDefaults standardUserDefaults];
	identifier_ = [defaults_ stringForKey : PPLastOpenPaneIdentifier];
	
	controller_ = [self controllerWithIdentifier : identifier_];
	if(nil == controller_)
		identifier_ = PPFontsAndColorsIdentifier;
	controller_ = [self controllerWithIdentifier : identifier_];
	UTILAssertNotNil(controller_);
	
	[self setContentViewWithController : controller_];
	[self setupToolbar];
	[[[self window] toolbar] setSelectedItemIdentifier: identifier_];
}

- (void) updateUIComponents
{
	[[self controllerWithIdentifier : 
		[self currentIdentifier]] updateUIComponents];
	[[self window] setTitle : [self displayName]];
}
@end
