//
//  ThreadsListTable.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/30.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import <SGAppKit/BSDraggingEndedTableView.h>
#import "BSLabelMenuItemView.h"
#import "BSThreadsListDataSource.h"

@interface ThreadsListTable : BSDraggingEndedTableView<BSLabelMenuItemViewValidation> {
	@private
	NSArray	*allColumns;
}

- (id<BSThreadsListDataSource>)dataSource;
- (void)setDataSource:(id<BSThreadsListDataSource>)anObject;

- (NSIndexSet *)targetIndexesForLabelMenuItem:(id)sender;
- (NSArray *)attributesArrayForSelectedRowsExceptingPath:(NSString *)exceptingPath; // Available in SilverGull and later.

// Saving Column State
- (NSObject<NSCoding> *)columnState;
- (void)restoreColumnState:(NSObject *)columnState;
- (void)setColumnWithIdentifier:(id)identifier visible:(BOOL)visible;
- (BOOL)isColumnWithIdentifierVisible:(id)identifier;
- (NSTableColumn *) initialColumnWithIdentifier:(id)identifier;
- (void)removeAllColumns;
- (void)setInitialState;

// IBActions
- (IBAction)scrollRowToTop:(id)sender;
- (IBAction)scrollRowToEnd:(id)sender;
- (IBAction)openInBrowser:(id)sender;

- (IBAction)revealInFinder:(id)sender; // Available in Twincam Angel and later.
- (IBAction)quickLook:(id)sender; // Available in SilverGull and later.

- (IBAction)removeFromDB:(id)sender; // Available in BathyScaphe 1.7 "Prima Aspalas" and later. For debugging use.
@end
