//
//  GeneralPrefController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/07/19.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "GeneralPrefController.h"
#import "PreferencePanes_Prefix.h"


#define kLabelKey   @"General Label"
#define kToolTipKey @"General ToolTip"
// #define kImageName  @"GeneralPreferences"


@implementation GeneralPrefController
- (NSString *)mainNibName
{
    return @"GeneralPreferences";
}

- (IBAction)changeAutoscrollMask:(id)sender
{
    CMRAutoscrollCondition mask = CMRAutoscrollNone;
    NSEnumerator *iter = [[[self autoscrollMaskCheckBox] cells] objectEnumerator];
    NSCell *checkBox;
    while (checkBox = [iter nextObject]) {
        if ([checkBox state] == NSOnState) {
            CMRAutoscrollCondition checkBoxValue = (NSUInteger)[checkBox tag];
            mask = (mask | checkBoxValue);
        }
    }
    [[self preferences] setThreadsListAutoscrollMask:mask];
}

- (NSMatrix *)autoscrollMaskCheckBox
{
    return m_autoscrollMaskCheckBox;
}

- (void)updateUIComponents
{
    CMRAutoscrollCondition mask = [[self preferences] threadsListAutoscrollMask];
    NSEnumerator *iter = [[[self autoscrollMaskCheckBox] cells] objectEnumerator];
    NSCell *checkBox;
    while (checkBox = [iter nextObject]) {
        CMRAutoscrollCondition checkBoxValue = (NSUInteger)[checkBox tag];
        NSCellStateValue state = (mask & checkBoxValue) ? NSOnState : NSOffState;
        [checkBox setState:state];
    }
}

- (void)setupUIComponents
{
    if (!_contentView) {
        return;
    }
    [self updateUIComponents];
}
@end


@implementation GeneralPrefController(Toolbar)
- (NSString *)identifier
{
    return PPGeneralPreferencesIdentifier;
}

- (NSString *)helpKeyword
{
    return PPLocalizedString(@"Help_General");
}

- (NSString *)label
{
    return PPLocalizedString(kLabelKey);
}

- (NSString *)paletteLabel
{
    return PPLocalizedString(kLabelKey);
}

- (NSString *)toolTip
{
    return PPLocalizedString(kToolTipKey);
}

- (NSString *)imageName
{
    return NSImageNamePreferencesGeneral; // kImageName;
}
@end
