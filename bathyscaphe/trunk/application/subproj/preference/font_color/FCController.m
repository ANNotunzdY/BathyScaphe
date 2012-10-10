//
//  FCController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/05/17.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "FCController.h"
#import "PreferencePanes_Prefix.h"
#import <SGAppKit/NSEvent-SGExtensions.h>
#import <SGAppKit/NSWorkspace-SGExtensions.h>
#import "BSThemeEditor.h"
#import "BSThemePreView.h"

#define kLabelKey       @"Appearance Label"
#define kToolTipKey     @"Appearance ToolTip"
#define kImageName      @"ViewPreferences"

@implementation FCController
- (NSString *)mainNibName
{
    return @"ViewPreferences";
}

- (void)dealloc
{
    [m_themeEditor release];
    m_themeEditor = nil;
    [super dealloc];
}

#pragma mark Accessors
- (BSThemeEditor *)themeEditor
{
    if (!m_themeEditor) {
        m_themeEditor = [[BSThemeEditor alloc] init];
        [m_themeEditor setDelegate:self];
    }
    return m_themeEditor;
}

- (NSTableView *)themesList
{
    return m_themesList;
}

- (BSThemePreView *)preView
{
    return m_preView;
}

- (NSTextField *)themeNameField
{
    return m_themeNameField;
}

- (NSTextField *)themeStatusField
{
    return m_themeStatusField;
}

- (NSTextField *)themeDivField
{
    return m_themeDivField;
}

- (NSButton *)deleteButton
{
    return m_deleteBtn;
}

- (NSTabView *)tabView
{
    return m_tabView;
}

#pragma mark IBActions
- (IBAction)fixRowHeightToFont:(id)sender
{
    [[self preferences] fixRowHeightToFontSize];
}

- (IBAction)newTheme:(id)sender
{
    // 新規テーマ作成の際は、現在リストで選択されているテーマを下地にする
    // 現在リストで選択されているテーマが内蔵テーマの場合は、内蔵属性を外し、自動選択されている AA フォントの設定を
    // コピーして焼き付ける
    NSInteger selectedRow = [[self themesList] selectedRow];
    NSString *filePath;
    NSString *newId;
    NSArray *array = [[self preferences] installedThemes];
    filePath = [[array objectAtIndex:selectedRow] valueForKey:@"ThemeFilePath"];

    newId = PPLocalizedString(@"newThemeId");

    BSThreadViewTheme *content = [[BSThreadViewTheme alloc] initWithContentsOfFile:filePath];
    [content setIdentifier:newId];
    if ([content isInternalTheme]) {
        NSFont *copiedFont = [[self preferences] firstAvailableAAFont:content];
        [content setIsInternalTheme:NO];
        [content setAAFont:(copiedFont ?: [content baseFont])];
    }

    BSThemeEditor *editor = [self themeEditor];
    [[editor themeGreenCube] setContent:content];
    [content release];
    [editor setSaveThemeIdentifier:newId];
    [editor setIsNewTheme:YES];
    [editor setThemeFileName:nil];
    [editor beginSheetModalForWindow:[self window] modalDelegate:self contextInfo:NULL];
}

- (IBAction)editCustomTheme:(id)sender
{
    // 現在使用中のテーマではなく、現在リストで選択されているテーマを編集する
    NSInteger selectedRow = [[self themesList] selectedRow];
    NSArray *array = [[self preferences] installedThemes];

    if ([[[array objectAtIndex:selectedRow] valueForKey:@"IsInternalTheme"] boolValue]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:PPLocalizedString(@"editThemeAlertTitle")];
        [alert addButtonWithTitle:PPLocalizedString(@"editThemeBtnContinue")];
        [alert addButtonWithTitle:PPLocalizedString(@"editThemeBtnCancel")];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(editThemeAlertDidEnd:returnCode:contextInfo:)
                            contextInfo:(void *)sender];
        return;
    }

    NSString *fullPath = [[array objectAtIndex:selectedRow] valueForKey:@"ThemeFilePath"];
    BSThreadViewTheme *content = [[BSThreadViewTheme alloc] initWithContentsOfFile:fullPath];
    BSThemeEditor *editor = [self themeEditor];

    [[editor themeGreenCube] setContent:content];
    NSString *hoge = [[content identifier] copy];
    [editor setSaveThemeIdentifier:hoge];
    [hoge release];
    [content release];
    [editor setIsNewTheme:NO];
    [editor setThemeFileName:[fullPath lastPathComponent]];
    [editor beginSheetModalForWindow:[self window] modalDelegate:self contextInfo:NULL];
}

- (void)editCurrentTheme:(id)sender
{
    // 現在使用中のテーマを編集するため、現在のテーマを選択する。
    if (![self selectCurrentTheme]) {
        [self updateSelectedThemeInfo:[[self themesList] selectedRow]];
    }
    // 画面がせわしないので少しだけ待ってから
    [self performSelector:@selector(editCustomTheme:) withObject:sender afterDelay:0.3];
}

- (IBAction)revealInFinder:(id)sender
{
    // 現在リストで選択されているテーマを下地にする
    NSInteger selectedRow = [[self themesList] selectedRow];
    NSString *filePath = [[[[self preferences] installedThemes] objectAtIndex:selectedRow] valueForKey:@"ThemeFilePath"];
    [[NSWorkspace sharedWorkspace] revealFilesInFinder:[NSArray arrayWithObject:filePath]];
}

- (IBAction)showMoreInfoAboutAA:(id)sender
{
    NSURL *url = [NSURL URLWithString:PPLocalizedString(@"AAMoreInfoURL")];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark Delegate Methods
- (void)themeEditSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSOKButton) {
        [[self preferences] invalidateInstalledThemes];
        [[self themesList] reloadData];
        if ([[self themeEditor] isNewTheme]) {
            NSArray *array = [[self preferences] installedThemes];
            NSString *newThemeFullPath = [[self preferences] createFullPathFromThemeFileName:[[self themeEditor] themeFileName]];
            NSInteger idx = [[array valueForKey:@"ThemeFilePath"] indexOfObject:newThemeFullPath];
            [[self themesList] selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
        } else {
            NSString *currentThemeFileName = [[self preferences] themeFileName];
            if ([currentThemeFileName isEqualToString:[[self themeEditor] themeFileName]]) {
                // 使用中のテーマを編集した
                BSThreadViewTheme *newObj = [[[self themeEditor] themeGreenCube] content];
                [[self preferences] setThreadViewTheme:newObj];
                [[self preView] setTheme:newObj];
            } else {
                // 使用中ではないテーマを編集した
                BSThreadViewTheme *newObj = [[[self themeEditor] themeGreenCube] content];
                [[self preView] setTheme:newObj];
            }
        }
        [self updateSelectedThemeInfo:[[self themesList] selectedRow]];
    }

    [sheet close];
}

- (void)deleteThemeAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)code contextInfo:(void *)contextInfo
{
    if (code == NSAlertFirstButtonReturn) {
        [self deleteTheme:(NSString *)contextInfo];
    }
    [(NSString *)contextInfo release];
    [self updateUIComponents];
}

- (NSUInteger)validModesForFontPanel:(NSFontPanel *)fontPanel
{
    return (NSFontPanelFaceModeMask|NSFontPanelSizeModeMask|NSFontPanelCollectionModeMask);
}

- (void)editThemeAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)code contextInfo:(void *)contextInfo
{
    if (code == NSAlertFirstButtonReturn) {
        [[alert window] orderOut:nil];
        [self newTheme:(id)contextInfo];
    }
}

- (BOOL)selectCurrentTheme
{
    NSInteger currentRow = [[self themesList] selectedRow];
    NSUInteger rowIndex = 0;
    NSString *currentTheme = [[self preferences] themeFileName];
    if (currentTheme) {
        NSArray *array = [[self preferences] installedThemes];
        for (NSUInteger i = 0; i < [array count]; i++) {
            NSString *fileName = [[[array objectAtIndex:i] valueForKey:@"ThemeFilePath"] lastPathComponent];
            if ([fileName isEqualToString:currentTheme]) {
                rowIndex = i;
                break;
            }
        }
    }
    [[self themesList] selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
    return (currentRow != rowIndex);
}

#pragma mark Utilities
- (IBAction)themeDoubleClicked:(id)sender
{
    NSInteger clickedRow = [(NSTableView *)sender clickedRow];
    if (clickedRow == -1) return;

    [self editCustomTheme:sender];
}       

- (void)deleteTheme:(NSString *)fileName
{
    if (!fileName) {
        return;
    }
    BOOL serious = [[[self preferences] themeFileName] isEqualToString:[fileName lastPathComponent]];
//    NSString *fullPath = [[self preferences] createFullPathFromThemeFileName:fileName];
    NSFileManager *fm_ = [NSFileManager defaultManager];
    if (![fm_ fileExistsAtPath:fileName]) return;

    if ([fm_ removeItemAtPath:fileName error:NULL]) {
        [[self preferences] invalidateInstalledThemes];
        [[self themesList] reloadData];
        if (serious) {
            [[self preferences] setThemeFileNameWithFullPath:[[self preferences] defaultThemeFilePath] isCustomTheme:NO];
        }
        if (![self selectCurrentTheme]) {
            [self updateSelectedThemeInfo:[[self themesList] selectedRow]];
        }
    }
}

- (IBAction)tryDeleteTheme:(id)sender
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];

    NSArray *themes = [[self preferences] installedThemes];
    id object = [themes objectAtIndex:[[self themesList] selectedRow]];
    NSString *fileName = [object valueForKey:@"ThemeFilePath"];
    NSString *title = [object valueForKey:@"Identifier"];
    BOOL serious = [[[self preferences] themeFileName] isEqualToString:[fileName lastPathComponent]];
    NSString *titleBase = serious ? PPLocalizedString(@"deleteThemeAlertSeriousTitle") : PPLocalizedString(@"deleteThemeAlertTitle");
    [alert setAlertStyle:serious ? NSCriticalAlertStyle : NSWarningAlertStyle];
// #warning 64BIT: Check formatting arguments
// 2010-03-22 tsawada2 検討済
    [alert setMessageText:[NSString stringWithFormat:titleBase, title]];
    [alert setInformativeText:serious ? PPLocalizedString(@"deleteThemeAlertSeriousMsg") : PPLocalizedString(@"deleteThemeAlertMsg")];
    [alert addButtonWithTitle:PPLocalizedString(@"deleteThemeBtnDelete")];
    [alert addButtonWithTitle:PPLocalizedString(@"deleteThemeBtnCancel")];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(deleteThemeAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:[fileName retain]];
}

- (IBAction)openThemeEditorForIDColorSetting:(id)sender
{
    [[[self window] windowController] editCurrentThemeInPreferencesPane];
}

- (void)setupUIComponents
{
    if (!_contentView) {
        return;
    }

    [[self themesList] setDoubleAction:@selector(themeDoubleClicked:)];
    [self updateUIComponents];
    [self updateAAFontStatusReport];
    if (![self selectCurrentTheme]) {
        [self updateSelectedThemeInfo:[[self themesList] selectedRow]];
    }
}

- (void)updateUIComponents
{
    [[self themesList] reloadData];
}

- (void)willUnselect
{
    [super willUnselect];
    [[self preferences] setLastShownSubpaneIdentifier:[self currentSubpaneIdentifier] forPaneIdentifier:[self identifier]];
}

- (void)didSelect
{
    [[self tabView] selectTabViewItemWithIdentifier:[[self preferences] lastShownSubpaneIdentifierForPaneIdentifier:[self identifier]]];
    [super didSelect];
}

- (NSString *)currentSubpaneIdentifier
{
    return [[[self tabView] selectedTabViewItem] identifier];
}

#pragma mark NSTableView Delegate & DataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSArray *array = [[self preferences] installedThemes];
    return [array count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *array = [[self preferences] installedThemes];

    if ([[aTableColumn identifier] isEqualToString:@"Identifier"]) {
        return [[array objectAtIndex:rowIndex] valueForKey:@"Identifier"];
    }

    NSString *fileNameForRow = [[[array objectAtIndex:rowIndex] valueForKey:@"ThemeFilePath"] lastPathComponent];
    return [NSNumber numberWithBool:[fileNameForRow isEqualToString:[[self preferences] themeFileName]]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *array = [[self preferences] installedThemes];
    NSString *fullPath = [[array objectAtIndex:rowIndex] valueForKey:@"ThemeFilePath"];

    if (![[fullPath lastPathComponent] isEqualToString:[[self preferences] themeFileName]]) {
        [[self preferences] setThemeFileNameWithFullPath:fullPath isCustomTheme:![[[array objectAtIndex:rowIndex] valueForKey:@"IsInternal"] boolValue]];
        [self updateUIComponents];
        [self updateAAFontStatusReport];
    }
}

- (void)updateSelectedThemeInfo:(NSInteger)newSelectedRow
{
    if (newSelectedRow == -1) {
        return;
    }

    NSArray *array = [[self preferences] installedThemes];
    id info = [array objectAtIndex:newSelectedRow];
    BOOL isInternal = [[info valueForKey:@"IsInternalTheme"] boolValue];
    NSString *fileNameForRow = [info valueForKey:@"ThemeFilePath"];

    BSThreadViewTheme *theme = [[BSThreadViewTheme alloc] initWithContentsOfFile:fileNameForRow];
    [[self preView] setTheme:theme];
    [theme release];

    [[self deleteButton] setEnabled:!isInternal];
    [[self themeNameField] setStringValue:[info valueForKey:@"Identifier"]];
    
    [[self themeDivField] setStringValue:isInternal ? PPLocalizedString(@"themeStatusYes") : PPLocalizedString(@"themeStatusNo")];

    if (![[fileNameForRow lastPathComponent] isEqualToString:[[self preferences] themeFileName]]) {
        [[self themeStatusField] setStringValue:PPLocalizedString(@"themeStatusNo")];
    } else {
        [[self themeStatusField] setStringValue:PPLocalizedString(@"themeStatusYes")];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger newSelectedRow = [[aNotification object] selectedRow];
    [self updateSelectedThemeInfo:newSelectedRow];
}

- (void)updateAAFontStatusReport
{
    BOOL isInternal = [[[self preferences] threadViewTheme] isInternalTheme];
    NSString *baseString = PPLocalizedString(@"AAFontStatusSummaryBase");
    if (!isInternal) {
        NSString *fontName = [[[[self preferences] threadViewTheme] AAFont] displayName];
        [m_aaFontSelectionStatusSummaryField setStringValue:[baseString stringByAppendingString:PPLocalizedString(@"AAFontStatusSummary3")]];
        [m_aaFontSelectionStatusDescField setStringValue:[NSString stringWithFormat:PPLocalizedString(@"AAFontStatus3"), fontName]];
        [m_aaFontSelectionStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
    } else {
        if ([[self preferences] firstAvailableAAFont]) {
            NSString *availableName = [[[self preferences] firstAvailableAAFont] displayName];
            [m_aaFontSelectionStatusSummaryField setStringValue:[baseString stringByAppendingString:PPLocalizedString(@"AAFontStatusSummary1")]];
            [m_aaFontSelectionStatusDescField setStringValue:[NSString stringWithFormat:PPLocalizedString(@"AAFontStatus1"), availableName]];
            [m_aaFontSelectionStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        } else {
            [m_aaFontSelectionStatusSummaryField setStringValue:[baseString stringByAppendingString:PPLocalizedString(@"AAFontStatusSummary2")]];
            [m_aaFontSelectionStatusDescField setStringValue:PPLocalizedString(@"AAFontStatus2")];
            [m_aaFontSelectionStatusImageView setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
        }
    }
}

- (BOOL)validateUserInterfaceItem:(id < NSValidatedUserInterfaceItem >)anItem
{
    if ([anItem action] == @selector(revealInFinder:)) {
        NSInteger idx = [[self themesList] selectedRow];
        if (idx < 0) {
            return NO;
        }
        NSArray *array = [[self preferences] installedThemes];
        BOOL isInternalTheme = [[[array objectAtIndex:idx] valueForKey:@"IsInternal"] boolValue]; 
        return !isInternalTheme;
    }
    return YES;
}

- (NSInteger)mailFieldOption
{
    BOOL    _mailAddressShown = [[self preferences] mailAddressShown];
    BOOL    _mailIconShown = [[self preferences] mailAttachmentShown];
    
    if (_mailAddressShown && _mailIconShown) {
        return 1;
    } else if (_mailAddressShown) {
        return 0;
    } else {
        return 2;
    }
}

- (void)setMailFieldOption:(NSInteger)selectedTag
{
    
    switch(selectedTag) {
    case 0:
        [[self preferences] setMailAddressShown:YES];
        [[self preferences] setMailAttachmentShown:NO];
        break;
    case 1:
        [[self preferences] setMailAddressShown:YES];
        [[self preferences] setMailAttachmentShown:YES];
        break;
    case 2:
        [[self preferences] setMailAddressShown:NO];
        [[self preferences] setMailAttachmentShown:YES];
        break;
    default:
        break;
    }
}

- (void)showSubpaneWithIdentifier:(NSString *)identifier
{
    [[self tabView] selectTabViewItemWithIdentifier:identifier];
}
@end


@implementation FCController(Toolbar)
- (NSString *)identifier
{
    return PPFontsAndColorsIdentifier;
}
- (NSString *)helpKeyword
{
//  return PPLocalizedString(@"Help_View");
    NSString *base = @"Help_View_";
    NSString *tmp = [base stringByAppendingString:[self currentSubpaneIdentifier]];
    return PPLocalizedString(tmp);
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
