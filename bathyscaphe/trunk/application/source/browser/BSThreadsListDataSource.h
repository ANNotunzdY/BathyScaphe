//
//  BSThreadsListDataSource.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 12/03/18.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSTableView.h>
#import "CMRThreadSignature.h"

@protocol CMRThreadsListDataSource <NSObject>
@required
- (NSString *)threadFilePathAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView status:(ThreadStatus *)status;
- (NSString *)threadTitleAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView;
- (NSArray *)tableView:(NSTableView *)aTableView threadFilePathsArrayAtRowIndexes:(NSIndexSet *)rowIndexes;
- (void)tableView:(NSTableView *)aTableView revealFilesAtRowIndexes:(NSIndexSet *)rowIndexes;
- (void)tableView:(NSTableView *)aTableView quickLookAtRowIndexes:(NSIndexSet *)rowIndexes;
- (void)tableView:(NSTableView *)aTableView quickLookAtRowIndexes:(NSIndexSet *)rowIndexes keepLook:(BOOL)flag;
- (void)tableView:(NSTableView *)aTableView openURLsAtRowIndexes:(NSIndexSet *)rowIndexes;

@optional
- (NSUInteger)indexOfThreadWithPath:(NSString *)filepath ignoreFilter:(BOOL)ignores;
- (NSDictionary *)threadAttributesAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView;
- (NSArray *)tableView:(NSTableView *)aTableView threadAttibutesArrayAtRowIndexes:(NSIndexSet *)rowIndexes exceptingPath:(NSString *)filepath;
@end


@protocol BSThreadsListDataSource <NSTableViewDataSource, NSObject, CMRThreadsListDataSource>
@required
- (BOOL)isThreadLogCachedAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView label:(NSUInteger *)label;
- (BOOL)isThreadLogCachedAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView isDatOchi:(BOOL *)datOchiFlag;
- (NSUInteger)threadLabelAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView;
- (NSUInteger)indexOfThreadWithPath:(NSString *)filepath;
- (NSIndexSet *)indexesOfFilePathsArray:(NSArray *)filepaths ignoreFilter:(BOOL)flag;
- (CMRThreadSignature *)threadSignatureWithTitle:(NSString *)title;
- (void)tableView:(NSTableView *)aTableView removeFromDBAtRowIndexes:(NSIndexSet *)rowIndexes;
- (void)tableView:(NSTableView *)aTableView setLabel:(NSUInteger)label atRowIndexes:(NSIndexSet *)rowIndexes;
- (void)tableView:(NSTableView *)aTableView setIsDatOchi:(BOOL)flag atRowIndexes:(NSIndexSet *)rowIndexes;
@end
