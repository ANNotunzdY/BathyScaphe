//
//  AdvancedPrefController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/05/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "AdvancedPrefController.h"
#import "PreferencePanes_Prefix.h"

static NSString *const kAdvancedPaneLabelKey = @"Advanced Label";
static NSString *const kAdvancedPaneToolTipKey = @"Advanced ToolTip";
static NSString *const kAdvancedPaneHelpAnchorKey = @"Help_Advanced";


@implementation AdvancedPrefController
- (NSString *)mainNibName
{
	return @"AdvancedPreferences";
}

/*- (NSComboBox *)bbsMenuURLChooser
{
    return m_bbsMenuURLChooser;
}*/

- (void)updateUIComponents
{
//    [[self bbsMenuURLChooser] setStringValue:[[[self preferences] BBSMenuURL] absoluteString]];
}

- (void)setupUIComponents
{
	if (!_contentView) {
        return;
    }
	[self updateUIComponents];
}

/*- (IBAction)didChooseBbsMenuURL:(id)sender
{
	NSString *typedText = [sender stringValue];
	NSString *currentURLStr = [[[self preferences] BBSMenuURL] absoluteString];

	if (!typedText || [typedText isEqualToString:@""]) {
		[sender setStringValue:currentURLStr];
		return;
	}

	if ([typedText isEqualToString:currentURLStr]) {
        return;
    }

	[[self preferences] setBBSMenuURL:[NSURL URLWithString:typedText]];     
}*/
@end


@implementation AdvancedPrefController(Toolbar)
- (NSString *)identifier
{
	return PPAdvancedPreferencesIdentifier;
}
- (NSString *)helpKeyword
{
	return PPLocalizedString(kAdvancedPaneHelpAnchorKey);
}
- (NSString *)label
{
	return PPLocalizedString(kAdvancedPaneLabelKey);
}
- (NSString *)paletteLabel
{
	return PPLocalizedString(kAdvancedPaneLabelKey);
}
- (NSString *)toolTip
{
	return PPLocalizedString(kAdvancedPaneToolTipKey);
}
- (NSString *)imageName
{
	return NSImageNameAdvanced;
}
@end

