//
//  BSAppResetPanelController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/07/16.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSAppResetPanelController.h"
#import "CocoMonar_Prefix.h"
#import "AppDefaults.h"

@implementation BSAppResetPanelController
- (id)init
{
    if (self = [super initWithWindowNibName:@"BSAppReset"]) {
        ;
    }
    return self;
}

- (void)windowDidLoad
{
    NSUInteger mask = [CMRPref appResetTargetMask];
    NSArray *cells = [[self resetTargetMatrix] cells];
    for (NSCell *cell in cells) {
        if (mask & [cell tag]) {
            [cell setState:NSOnState];
        } else {
            [cell setState:NSOffState];
        }
        if ([cell tag] == BSAppResetPreviewer) {
            NSString *label;
            BOOL shouldEnable = [CMRPref previewerSupportsAppReset:&label];
            if (shouldEnable) {
                [cell setTitle:label];
            } else {
                [cell setState:NSOffState];
            }

            [cell setEnabled:shouldEnable];
        }
    }
    [[self resetTargetMatrix] sizeToCells];
}

- (NSMatrix *)resetTargetMatrix
{
    return m_resetTargetMatrix;
}

- (IBAction)okOrCancel:(id)sender
{
    NSUInteger baseMask = BSAppResetNone;
    NSArray *cells = [[self resetTargetMatrix] cells];
    for (NSCell *cell in cells) {
        if ([cell state] == NSOnState) {
            baseMask |= [cell tag];
        }
    }
    [CMRPref setAppResetTargetMask:baseMask];
    [NSApp stopModalWithCode:[sender tag]];
}

- (IBAction)help:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:NSLocalizedString(@"Reset:HelpAnchor", @"Reset dialog help anchor") inBook:[NSBundle applicationHelpBookName]];
}
@end
