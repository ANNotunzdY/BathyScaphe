//
//  AppDefaults-PPSupport.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 09/05/17.
//  Copyright 2009-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "AppDefaults_p.h"

static NSString *const kSubpaneIdForReplyPaneKey = @"LastShownSubpane(Reply)";
static NSString *const kSubpaneIdForViewPaneKey = @"LastShownSubpane(View)";
static NSString *const kPaneIdForBoardInfoInspectorKey = @"LastShownPane(BoardInfoInspector)";

@implementation AppDefaults(PreferencesPaneSupport)
- (NSString *)lastShownSubpaneIdentifierForPaneIdentifier:(NSString *)paneIdentifier
{
	NSString *result = nil;

	if ([paneIdentifier isEqualToString:PPReplyDefaultIdentifier]) {
		result = [[self defaults] stringForKey:kSubpaneIdForReplyPaneKey];
		if (!result) {
			result = PPReplyMailAndNameSubpaneIdentifier;
		}
	} else if ([paneIdentifier isEqualToString:PPFontsAndColorsIdentifier]) {
		result = [[self defaults] stringForKey:kSubpaneIdForViewPaneKey];
		if (!result) {
			result = PPViewThemesSubpaneIdentifier;
		}
	}

	return result;
}

- (void)setLastShownSubpaneIdentifier:(NSString *)subpaneId forPaneIdentifier:(NSString *)paneId
{
	if ([paneId isEqualToString:PPReplyDefaultIdentifier]) {
		if (!subpaneId) {
			[[self defaults] removeObjectForKey:kSubpaneIdForReplyPaneKey];
		} else {
			[[self defaults] setObject:subpaneId forKey:kSubpaneIdForReplyPaneKey];
		}
	} else if ([paneId isEqualToString:PPFontsAndColorsIdentifier]) {
		if (!subpaneId) {
			[[self defaults] removeObjectForKey:kSubpaneIdForViewPaneKey];
		} else {
			[[self defaults] setObject:subpaneId forKey:kSubpaneIdForViewPaneKey];
		}
	}
}

- (NSString *)lastShownBoardInfoInspectorPaneIdentifier
{
    NSString *paneId = [[self defaults] stringForKey:kPaneIdForBoardInfoInspectorKey];
    if (!paneId) {
        paneId = DEFAULT_PANE_ID_BOARD_INFO_INSPECTOR;
    }
    return paneId;
}

- (void)setLastShownBoardInfoInspectorPaneIdentifier:(NSString *)paneId
{
    if (!paneId) {
        [[self defaults] removeObjectForKey:kPaneIdForBoardInfoInspectorKey];
    } else {
        [[self defaults] setObject:paneId forKey:kPaneIdForBoardInfoInspectorKey];
    }
}
@end
