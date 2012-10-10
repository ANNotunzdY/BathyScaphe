//
//  CMRFilterPrefController.m
//  BachyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/11.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRFilterPrefController.h"
#import "PreferencePanes_Prefix.h"
#import "BSNGExpressionsEditorController.h"

static NSString *const kLabelKey = @"Filter Label";
static NSString *const kToolTipKey = @"Filter ToolTip";
static NSString *const kImageName = @"FilterPreferences";


@implementation CMRFilterPrefController
- (NSString *)mainNibName
{
	return @"FilterPreferences";
}

- (NSMatrix *)hostSymbols
{
    return m_hostSymbols;
}

- (NSObjectController *)preferencesObjectController
{
    return m_preferencesObjectController;
}

#pragma mark IBActions
- (IBAction)resetSpamDB:(id)sender
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];

	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:PPLocalizedString(@"ResetSpamFilterDBTitle")];
	[alert setInformativeText:PPLocalizedString(@"ResetSpamFilterDBMessage")];
	[alert addButtonWithTitle:PPLocalizedString(@"OK")];
	[alert addButtonWithTitle:PPLocalizedString(@"Cencel")];

	if ([alert runModal] == NSAlertFirstButtonReturn) {
		[[self preferences] resetSpamFilter];
	}
}

- (IBAction)openNGExpressionsEditorSheet:(id)sender
{
    static BSNGExpressionsEditorController *editor = nil;
    if (!editor) {
        editor = [[NSClassFromString(@"BSNGExpressionsEditorController") alloc] initWithDelegate:self boardName:nil];
        [editor bindNGExpressionsArrayTo:[self preferencesObjectController] withKeyPath:@"selection.spamMessageCorpus"];
    }
    [editor openEditorSheet:self];
}

- (IBAction)openThemeEditorForColorSetting:(id)sender
{
    [[[self window] windowController] editCurrentThemeInPreferencesPane];
}

- (void)NGExpressionsEditorDidClose:(BSNGExpressionsEditorController *)controller
{
	[[self preferences] setSpamFilterNeedsSaveToFiles:YES];
}

- (NSWindow *)windowForNGExpressionsEditor:(BSNGExpressionsEditorController *)controller
{
    return [self window];
}

- (void)updateUIComponents
{
    NSSet *symbols = [[self preferences] spamHostSymbols];
    NSArray *cells = [[self hostSymbols] cells];
    for (NSActionCell *cell in cells) {
        BOOL isSpamSymbol = [symbols containsObject:[cell title]];
        [cell setState:(isSpamSymbol ? NSOnState : NSOffState)];
    }
}

- (void)setupUIComponents
{
	if (!_contentView) return;
	[self updateUIComponents];
}

- (void)willUnselect
{
    [super willUnselect];
    NSMutableSet *symbols = [[NSMutableSet alloc] initWithCapacity:7];
    NSArray *cells = [[self hostSymbols] cells];
    for (NSActionCell *cell in cells) {
        if ([cell state] == NSOnState) {
            [symbols addObject:[cell title]];
        }
    }
    NSSet *immutableSymbols = [[NSSet alloc] initWithSet:symbols];
    [[self preferences] setSpamHostSymbols:immutableSymbols];
    [immutableSymbols release];
    [symbols release];
}
@end



@implementation CMRFilterPrefController(Toolbar)
- (NSString *)identifier
{
	return PPFilterPreferencesIdentifier;
}
- (NSString *)helpKeyword
{
	return PPLocalizedString(@"Help_Filter");
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
	return kImageName;
}
@end
