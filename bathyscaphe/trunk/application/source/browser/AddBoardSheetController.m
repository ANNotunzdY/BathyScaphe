//
//  AddBoardSheetController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/10/12.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CocoMonar_Prefix.h"
#import "AddBoardSheetController.h"
#import "SmartBoardList.h"
#import "BoardManager.h"
#import "DatabaseManager.h"


static NSString *const kABSNibFileNameKey					= @"AddBoardSheet";
static NSString *const kABSLocalizableStringsFileNameKey	= @"BoardListEditor"; 

static NSString *const kABSContextInfoDelegateKey			= @"delegate";
static NSString *const kABSContextInfoObjectKey				= @"object";

@implementation AddBoardSheetController
+ (NSString *)localizableStringsTableName
{
	return kABSLocalizableStringsFileNameKey;
}

- (id) init
{
	if (self = [super initWithWindowNibName : kABSNibFileNameKey]) {
		;
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver : self];
	[_currentSearchStr release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[[NSNotificationCenter defaultCenter]
		addObserver : self
		selector : @selector(boardListDidChange:)
		name : CMRBBSListDidChangeNotification
		object : [[BoardManager defaultManager] defaultList]];

	[[self defaultListOLView] setDataSource : [[BoardManager defaultManager] defaultList]];
	[[self defaultListOLView] setAutoresizesOutlineColumn : NO];
	[[self defaultListOLView] setVerticalMotionCanBeginDrag : NO];
	[[self defaultListOLView] setDoubleAction: @selector(doAddAndClose:)];
	[[self OKButton] setEnabled : NO];
}

#pragma mark Accessors

- (NSOutlineView *) defaultListOLView
{
	return m_defaultListOLView;
}
- (NSSearchField *) searchField
{
	return m_searchField;
}

- (NSTextFieldCell *) brdNameField
{
	return m_brdNameField;
}
- (NSTextFieldCell *) brdURLField
{
	return m_brdURLField;
}

- (NSButton *) OKButton
{
	return m_OKButton;
}
- (NSButton *) cancelButton
{
	return m_cancelButton;
}
- (NSButton *) helpButton
{
	return m_helpButton;
}

- (NSString *) currentSearchStr
{
	return _currentSearchStr;
}
- (void) setCurrentSearchStr : (NSString *) newStr
{
	[newStr retain];
	[_currentSearchStr release];
	_currentSearchStr = newStr;
}

#pragma mark IBActions

- (IBAction) searchBoards : (id) sender
{
	[self showMatchedItemsWithCurrentSearchStr];
}

- (IBAction)openHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[self localizedString:@"Boards list"] inBook:[NSBundle applicationHelpBookName]];
}

- (IBAction) close : (id) sender
{
	[NSApp endSheet : [self window]
		 returnCode : NSCancelButton];
}

- (IBAction) doAddAndClose : (id) sender
{
	BOOL	shouldClose;
	//NSLog(@"%@",[sender description]);
	if (sender == [self defaultListOLView]) { //  Maybe OLView doucle-clicked
		if ([[self defaultListOLView] clickedRow] == -1) return; // Maybe double click table column!!
		
		shouldClose = [self addToUserListFromOLView: sender];
	} else {
		if ([[self defaultListOLView] selectedRow] == -1) {
			shouldClose = [self addToUserListFromForm : sender];
		} else {
			NSString *name_;
			NSString *url_;

			name_ = [[self brdNameField] stringValue];
			url_  = [[self brdURLField] stringValue];
			
			if ([name_ isEqualToString : @""] && [url_ isEqualToString : @""]) {
				shouldClose = [self addToUserListFromOLView : sender];
			} else {
				shouldClose = [self addToUserListFromForm : sender];
			}
		}
	}

	if (shouldClose)
		[NSApp endSheet : [self window] returnCode : NSOKButton];
}

#pragma mark Other Actions
static void showLocalizedAddBoardErrorAlert(NSString *messageKey, NSString *informativeText)
{
    NSBeep();
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setMessageText:NSLocalizedStringFromTable(messageKey, @"BoardListEditor", nil)];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
    [alert runModal];
}

- (void) beginSheetModalForWindow : (NSWindow *) docWindow
					modalDelegate : (id        ) modalDelegate
					  contextInfo : (id		   ) info
{
	NSMutableDictionary		*info_;
	
	info_ = [NSMutableDictionary dictionary];
	[info_ setNoneNil : modalDelegate forKey : kABSContextInfoDelegateKey];
	[info_ setNoneNil : info forKey : kABSContextInfoObjectKey];
	
	[NSApp beginSheet : [self window]
	   modalForWindow : docWindow
		modalDelegate : self
	   didEndSelector : @selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo : [info_ retain]];
}

- (BOOL)addToUserListFromOLView:(id)sender
{
    NSIndexSet  *indexes;   
    NSMutableArray *error_names;

    error_names = [NSMutableArray array];

    indexes = [[self defaultListOLView] selectedRowIndexes];
    if (!indexes || [indexes count] == 0) {
        return YES;
    }

    NSUInteger index;
    NSInteger size = [indexes lastIndex] + 1;
    NSRange range = NSMakeRange(0, size);

    while ([indexes getIndexes:&index maxCount:1 inIndexRange:&range] > 0) {
        id item_;

        item_ = [[self defaultListOLView] itemAtRow:index];
        if (![[[BoardManager defaultManager] userList] addItem:item_ afterObject:nil]) {
            [error_names addObject:[item_ representName]];
        }
    }

    if ([error_names count] > 0) {
        NSString *message_;
        message_ = [error_names componentsJoinedByString:[self localizedString:@"ErrNamesSeparater"]];
// #warning 64BIT: Check formatting arguments
        // 2011-08-27 tsawada2 検討済
        message_ = [NSString stringWithFormat:[self localizedString:@"ErrNamesCover"], message_];
// #warning 64BIT: Check formatting arguments
        // 2011-08-27 tsawada2 検討済
        NSString *infoText = [NSString stringWithFormat:[self localizedString:@"%@ are not added to your Boards List."], message_];
        showLocalizedAddBoardErrorAlert(@"Same Name Exists", infoText);
        return NO;
    }
    return YES;
}

- (BOOL)addToUserListFromForm:(id)sender
{
	BoardListItem *newItem_;
	NSString *name_;
	NSString *url_;

	name_ = [[self brdNameField] stringValue];
	url_  = [[self brdURLField] stringValue];

	if ([name_ isEqualToString:@""] || [url_ isEqualToString:@""]) {
		return NO;
    } else if ([[[BoardManager defaultManager] invalidBoardURLsToBeRemoved] containsObject:url_]) {
// #warning 64BIT: Check formatting arguments
        // 2011-08-27 tsawada2 検討済
        showLocalizedAddBoardErrorAlert(@"Add Board Error Msg info2chnet", [NSString stringWithFormat:[self localizedString:@"Edit Board Error Info info2chnet"], url_]);
        return NO;
	} else {
		id userList = [[BoardManager defaultManager] userList];
        BOOL tmpFlag = NO;

		if ([userList itemForName:name_]) {
            showLocalizedAddBoardErrorAlert(@"Same Name Exists", [self localizedString:@"So could not add to your Boards List."]);
			return NO;
		}

		DatabaseManager *DBM = [DatabaseManager defaultManager];
		NSUInteger boardID = [DBM boardIDForURLString:url_];
		if (boardID == NSNotFound) {
			[DBM registerBoardName:name_ URLString:url_];
		} else {
			[DBM renameBoardID:boardID toName:name_]; // 過去に同じ URL の掲示板を登録した経験有り -- IDを再利用、名前だけ新しくする
            tmpFlag = YES;
		}

		newItem_ = [BoardListItem boardListItemWithURLString:url_];
        if (tmpFlag) {
            [newItem_ setRepresentName:name_];
        }

		[userList addItem:newItem_ afterObject:nil];
		return YES;
	}
}

- (void)showMatchedItems:(NSString *)keyword
{
	id newSource_;

	if (!keyword || [keyword isEqualToString:@""]) {
		newSource_ = [[BoardManager defaultManager] defaultList];
	} else {
		newSource_ = [[[BoardManager defaultManager] filteredListWithString:keyword] retain];
	}

	[[self defaultListOLView] setDataSource:newSource_];
	[[self defaultListOLView] reloadData];
}

- (void)showMatchedItemsWithCurrentSearchStr
{
	[self showMatchedItems:[self currentSearchStr]];
}

- (void)cleanUpUI
{
	[self setCurrentSearchStr:@""];
	[self showMatchedItemsWithCurrentSearchStr];

	[[self brdNameField] setStringValue:@""];
	[[self brdURLField] setStringValue:@""];
	[m_warningField setStringValue:@""];

	[[self OKButton] setEnabled:NO];

	[[self defaultListOLView] deselectAll:self];
	[[self window] makeFirstResponder:[self searchField]];
}

#pragma mark Delegate & Notifications

- (void) sheetDidEnd : (NSWindow *) sheet
		  returnCode : (NSInteger       ) returnCode
		 contextInfo : (void     *) contextInfo
{
	NSDictionary	*infoDict_;
//	id				delegate_;
//	id				userInfo_;
//	SEL				sel_;
	
	infoDict_ = (NSDictionary *)contextInfo;
	UTILAssertKindOfClass(infoDict_, NSDictionary);
	
//	sel_ = @selector(controller:sheetDidEnd:contextInfo:);
//	delegate_ = [infoDict_ objectForKey : kABSContextInfoDelegateKey];
//	userInfo_ = [infoDict_ objectForKey : kABSContextInfoObjectKey];
	
	[infoDict_ autorelease];
	[sheet close];
	// 今は必要ない
	/*if(delegate_ != nil && [delegate_ respondsToSelector : sel_]){
		[delegate_ controller : self
				  sheetDidEnd : sheet 
				  contextInfo : userInfo_];
	}*/
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, NSOutlineViewSelectionDidChangeNotification);

	if ([[self defaultListOLView] selectedRow] != -1) {
		[[self OKButton] setEnabled:YES];
		[[self brdNameField] setStringValue:@""];
		[[self brdURLField] setStringValue:@""];
		[m_warningField setStringValue:@""];
	} else {
		[[self OKButton] setEnabled:NO];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self cleanUpUI];
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
	[[self defaultListOLView] deselectAll:self];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	NSString *partialBoardName = [[self brdNameField] stringValue];
	NSString *partialURL = [[self brdURLField] stringValue];

	if ([partialBoardName isEqualToString:@""]) {
		[m_warningField setStringValue:[self localizedString:@"Validation Error 3"]];
		[[self OKButton] setEnabled:NO];
		return;
	} else if ([partialURL isEqualToString:@""]) {
		[m_warningField setStringValue:[self localizedString:@"Validation Error 4"]];
		[[self OKButton] setEnabled:NO];
		return;
	} else if (![partialURL hasPrefix:@"http://"]) {
		[m_warningField setStringValue:[self localizedString:@"Validation Error 1"]];
		[[self OKButton] setEnabled:NO];
		return;
	} else if (![partialURL hasSuffix:@"/"]) {
		[m_warningField setStringValue:[self localizedString:@"Validation Error 2"]];
		[[self OKButton] setEnabled:NO];
		return;
	}		
	[m_warningField setStringValue:@""];
	[[self OKButton] setEnabled:YES];
}

- (void)boardListDidChange:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, CMRBBSListDidChangeNotification);

	if ([notification object] == [[BoardManager defaultManager] defaultList]) {
		[self showMatchedItemsWithCurrentSearchStr];
	}
}
@end
