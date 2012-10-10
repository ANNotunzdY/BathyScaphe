//
//  LabelsPrefController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/15.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "LabelsPrefController.h"
#import "PreferencePanes_Prefix.h"
#import "BSLabelManager.h"

#define kLabelKey   @"Labels Label"
#define kToolTipKey @"Labels ToolTip"
#define kImageName  @"LabelsPreferences"


@implementation LabelsPrefController
@synthesize currentNamesSS = m_currentNamesSnapshot;
@synthesize currentColorsSS = m_currentColorsSnapshot;

- (NSString *)mainNibName
{
    return @"LabelsPreferences";
}

- (void)loadLabelSettings
{
    BSLabelManager *mgr = (BSLabelManager *)[NSClassFromString(@"BSLabelManager") defaultManager];
    self.currentNamesSS = [mgr displayNames];
    self.currentColorsSS = [mgr backgroundColors];

    NSInteger i;
    for (i = 0; i < 7; i++) {
        [[labelNamesForm cellAtIndex:i] setStringValue:[self.currentNamesSS objectAtIndex:i]];
        [(NSColorWell *)[labelColorsView viewWithTag:(i + 1)] setColor:[self.currentColorsSS objectAtIndex:i]];
    }
}

- (void)setupUIComponents
{
    if (!_contentView) {
        return;
    }
    [self updateUIComponents];
}

- (void)didSelect
{
    [super didSelect];
    [self loadLabelSettings];
}

- (void)willUnselect
{
    [super willUnselect];
    BOOL shouldSaveToFile = NO;
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:7];
    NSMutableArray *newColorsArray = [NSMutableArray arrayWithCapacity:7];
    BSLabelManager *manager = (BSLabelManager *)[NSClassFromString(@"BSLabelManager") defaultManager];
    NSInteger i;
    NSString *name;
    NSColor *color;
    for (i = 0; i < 7; i++) {
        name = [[labelNamesForm cellAtIndex:i] stringValue];
        if (!name || [name length] == 0) {
            name = [[manager displayNames] objectAtIndex:i];
        }
        [newArray addObject:name];
        color = [(NSColorWell *)[labelColorsView viewWithTag:(i + 1)] color];
        [newColorsArray addObject:color];
    }

    if (![newArray isEqualToArray:self.currentNamesSS]) {
        [manager setDisplayNames:newArray];
        shouldSaveToFile = YES;
    }

    if (![newColorsArray isEqualToArray:self.currentColorsSS]) {
        [manager setBackgroundColors:newColorsArray];
        shouldSaveToFile = YES;
    }

    if (shouldSaveToFile) {
        [manager saveToFile];
    }

    self.currentNamesSS = nil;
    self.currentColorsSS = nil;
}

- (IBAction)restoreDefaults:(id)sender
{
    NSUInteger flag = [[NSApp currentEvent] modifierFlags];
    BSLabelManager *manager = (BSLabelManager *)[NSClassFromString(@"BSLabelManager") defaultManager];
    if (flag & NSAlternateKeyMask) {
        [manager restoreFinderSettings];
    } else {
        [manager restoreGASettings];
    }
    [self loadLabelSettings];
    [manager saveToFile];
}
@end


@implementation LabelsPrefController(Toolbar)
- (NSString *)identifier
{
    return PPLabelsPreferencesIdentifier;
}

- (NSString *)helpKeyword
{
    return PPLocalizedString(@"Help_Labels");
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

/*- (NSString *)imageName
{
    return kImageName;
}*/
- (NSImage *)image
{
    return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kToolbarLabelsIcon)];
}
@end
