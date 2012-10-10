//
//  ThreadsListTable.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/30.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "ThreadsListTable.h"
#import "CMRThreadsList.h"
#import "AppDefaults.h"
#import <SGAppKit/SGKeyBindingSupport.h>
#import "missing.h"
#import "CMRThreadAttributes.h"
#import "BSLabelManager.h"

static NSString *const kBrowserKeyBindingsFile = @"BrowserKeyBindings.plist";

@implementation ThreadsListTable
#pragma mark Services Menu Support
+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized) {
        [NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] returnTypes:nil];
        initialized = YES;
    }
}

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
    if ([sendType isEqualToString:NSStringPboardType] && !returnType) {
        if ([self selectedRow] != -1) {
            return self;
        } else if ([self clickedRow] != -1) { // 10.6 のコンテキストメニューにくっつくサービスメニュー項目、かつ、選択行以外の行を右クリックされたときのために必要
            return self;
        }
    }
    return [super validRequestorForSendType:sendType returnType:returnType];
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
    if (![types containsObject:NSStringPboardType]) {
        return NO;
    }
    NSIndexSet *indexes = [self targetIndexesForLabelMenuItem:nil];
    NSArray *attributes = [[self dataSource] tableView:self threadAttibutesArrayAtRowIndexes:indexes exceptingPath:nil];
    if (!attributes || ([attributes count] == 0)) {
        return NO;
    }

    NSMutableString *tmp = SGTemporaryString();
    NSURL *url;
    for (id attr in attributes) {
        url = [CMRThreadAttributes threadURLWithDefaultParameterFromDictionary:attr];
        if (url) {
            [tmp appendString:[url absoluteString]];
            [tmp appendString:@"\n"];
        }
    }
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pboard setString:tmp forType:NSStringPboardType];
    [tmp deleteCharactersInRange:[tmp range]];
    return YES;
}

#pragma mark Drawing Label Color
- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
    if (![CMRPref drawsLabelColorOnRowBackground]) {
        [super drawRow:rowIndex clipRect:clipRect];
        return;
    }

    NSUInteger label;
    id dataSource = [self dataSource];
    if (dataSource && [dataSource respondsToSelector:@selector(threadLabelAtRowIndex:inTableView:)]) {
        label = [dataSource threadLabelAtRowIndex:rowIndex inTableView:self];
    } else {
        label = 0;
    }

    if (label < 1 || label > 7) {
        [super drawRow:rowIndex clipRect:clipRect];
        return;
    }

    NSArray *colors = [[BSLabelManager defaultManager] backgroundColors];
    BOOL isHighlighted = ([self selectedRow] == rowIndex);
    NSRect rectOfRow = [self rectOfRow:rowIndex];
    if ([self columnWithIdentifier:@"Status"] == 0) {
        NSRect rectOfStatusColumn = [self rectOfColumn:0];
        CGFloat width = rectOfStatusColumn.size.width;
        rectOfRow.origin.x += width;
        rectOfRow.size.width -= width;
    }
    rectOfRow.size.height -= 1;
    CGFloat radius = rectOfRow.size.height / 2;

    if (!isHighlighted) {
        [(NSColor *)[colors objectAtIndex:(label - 1)] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rectOfRow xRadius:radius yRadius:radius];
        [path fill];
    }
    [super drawRow:rowIndex clipRect:clipRect];
    if (isHighlighted) {
        [(NSColor *)[colors objectAtIndex:(label - 1)] set];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(rectOfRow, 1.0, 1.0) xRadius:radius yRadius:radius];
        [path setLineWidth:2.0];
        [path stroke];
    }
}

#pragma mark Drag & Drop
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	if (isLocal) return NSDragOperationEvery;

	return (NSDragOperationCopy|NSDragOperationDelete|NSDragOperationLink);
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows
							tableColumns:(NSArray *)tableColumns
								   event:(NSEvent *)dragEvent
								  offset:(NSPointPointer)dragImageOffset
{
	id	dataSource = [self dataSource];
	if (dataSource && [dataSource respondsToSelector:@selector(dragImageForRowIndexes:inTableView:offset:)]) {
		return [dataSource dragImageForRowIndexes:dragRows inTableView:self offset:dragImageOffset];
	}
	
	return [super dragImageForRowsWithIndexes:dragRows tableColumns:tableColumns event:dragEvent offset:dragImageOffset];
}

#pragma mark (For Future Use)
- (NSArray *)attributesArrayForSelectedRowsExceptingPath:(NSString *)exceptingPath
{
	id dataSource = [self dataSource];
	if (!dataSource || ![dataSource respondsToSelector:@selector(tableView:threadAttibutesArrayAtRowIndexes:exceptingPath:)]) {
		NSBeep();
		return nil;
	}

	return [dataSource tableView:self threadAttibutesArrayAtRowIndexes:[self selectedRowIndexes] exceptingPath:exceptingPath];
}

#pragma mark Events
+ (SGKeyBindingSupport *)keyBindingSupport
{
	static SGKeyBindingSupport *stKeyBindingSupport_;
	
	if (!stKeyBindingSupport_) {
		NSDictionary	*dict;
		
		dict = [NSBundle mergedDictionaryWithName:kBrowserKeyBindingsFile];
		UTILAssertKindOfClass(dict, NSDictionary);
		
		stKeyBindingSupport_ = [[SGKeyBindingSupport alloc] initWithDictionary:dict];
	}
	return stKeyBindingSupport_;
}

// [Keybinding Responder Chain]
// self --> target --> [self window]
- (BOOL)interpretKeyBinding:(NSEvent *)theEvent
{
	id	targets_[] = {
			self,
			[self target],
			[self window],
			NULL
		};
	
	id	*p;
	
	for (p = targets_; *p != NULL; p++) {
		if([[[self class] keyBindingSupport] interpretKeyBindingWithEvent:theEvent target:*p]) {
			return YES;
		}
	}
	return NO;
}

- (void)keyDown:(NSEvent *)theEvent
{
	// デバッグ用	
	UTILDescription(theEvent);
	UTILDescUnsignedInt([theEvent modifierFlags]);
	UTILDescription([theEvent characters]);
	UTILDescription([theEvent charactersIgnoringModifiers]);
	
	if ([self interpretKeyBinding:theEvent]) {
		return;
	}
	[super keyDown:theEvent];
}

// Cocoaはさっぱり!!! version.4 スレッドの54-55 がドンピシャだった
/*- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSInteger row = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];

	if (row < 0) return nil;

	if (![self isRowSelected:row]) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	}
	
	return [self menu];
}*/
/*- (NSMenu *)menuForEvent:(NSEvent *)event
{
    NSMenu *menu = [super menuForEvent:event];
    [menu setAllowsContextMenuPlugIns:NO];
    return menu;
}*/

- (NSIndexSet *)targetIndexesForLabelMenuItem:(id)sender
{
    NSInteger clickedRow = [self clickedRow];
    if (clickedRow != -1) {
        if ([self isRowSelected:clickedRow] && ([self numberOfSelectedRows] > 1)) {
            return [self selectedRowIndexes];
        } else {
            return [NSIndexSet indexSetWithIndex:clickedRow];
        }
    } else {
        return [self selectedRowIndexes];
    }
    
    return nil;
}

- (NSIndexSet *)targetIndexesForActionSender:(id)sender
{
    NSInteger tag = [sender tag];
    SEL action = [sender action];
    BOOL isLabel = (action == @selector(toggleLabeledThread:));
    if (!isLabel && (tag != 782 && tag != 784)) {
        return [self selectedRowIndexes];
    }
    NSInteger clickedRow = [self clickedRow];
    if (clickedRow != -1) {
        if ([self isRowSelected:clickedRow] && ([self numberOfSelectedRows] > 1)) {
            if (isLabel || (tag == 782)) {
                return [self selectedRowIndexes];
            } else {
                return [NSIndexSet indexSetWithIndex:clickedRow];
            }
        } else {
            return [NSIndexSet indexSetWithIndex:clickedRow];
        }
    } else {
        if (isLabel) {
            return [self selectedRowIndexes];
        }
    }

    return nil;
}

#pragma mark Manual-save Table columns

/*
	2005-10-07 tsawada2 <ben-sawa@td5.so-net.ne.jp>
	NSTableView の AutoSave 機能に頼らず、自力でカラムの幅、順序、表示／非表示を記憶する。
	以下のコードは http://www.cocoabuilder.com/archive/message/cocoa/2003/11/16/77603 から拝借した。
	これらのメソッドを実際にどこでどう呼び出しているかは、CMRBrowser-ViewAccessor.m, CMRBrowser-Delegate.m を
	参照のこと。
*/

/*
If that can help you, here is some code I wrote that you can add to an
NSTableView subclass to do the trick.

This code allows you to:
- hide and show columns very simply,
- save and restore the order, size and visible state of the columns
(but NOT the sorting state, since I wrote it before Panther and I had
implemented my own sorting system -- I leave that to you as an
exercise!).

Here is how to use it:
- Once your table view is set up with all its columns, call
setInitialState (you must call it before any other method provided
here).
- To retrieve the current state in order to save it, call columnState
(this gives you a codable object, which happens to be an NSArray).
- To set the current state back, call restoreColumnState:.
- To hide or show a column, call setColumnWithIdentifier:visible:. (To
query the visible state, call isColumnWithIdentifierVisible:.)
- To retrieve the NSTableColumn object of a currently column given its
identifier, call initialColumnWithIdentifier:. (This works also with
columns that are currently hidden.)

Hope this helps...


(You also have to add an instance variable of type NSArray named
"allColumns". You also have to take care about its deallocation.)
*/

- (void)dealloc
{
	[allColumns release];
	[super dealloc];
}

- (NSObject<NSCoding> *)columnState
{
	NSMutableArray	*state;
	NSArray			*columns;
	NSEnumerator	*enumerator;
	NSTableColumn	*column;

	columns = [self tableColumns];
	state = [NSMutableArray arrayWithCapacity:[columns count]];
	enumerator = [columns objectEnumerator];

	while (column = [enumerator nextObject]) {
		[state addObject:[NSDictionary dictionaryWithObjectsAndKeys: 
														[column identifier], @"Identifier",
														[NSNumber numberWithDouble:[column width]], @"Width",
														nil]];
	}

	return state;
}

- (void)restoreColumnState:(NSObject *)columnState
{
	NSArray			*state;
	NSEnumerator	*enumerator;
	NSDictionary	*params;
	NSTableColumn	*column;

	NSAssert(columnState != nil, @"nil columnState!" );
	NSAssert([columnState isKindOfClass:[NSArray class]], @"columnState is not an NSArray!" );

	state = (NSArray *)columnState;

	enumerator = [state objectEnumerator];
	[self removeAllColumns];
	while (params = [enumerator nextObject]) {
		column = [self initialColumnWithIdentifier:[params objectForKey:@"Identifier"]];

		if (column) {
			[column setWidth:[[params objectForKey:@"Width"] doubleValue]];
			[self addTableColumn:column];
			[self setIndicatorImage:nil inTableColumn:column];
			[self setNeedsDisplay:YES];
		}
	}

	//[self sizeLastColumnToFit];
}

- (void)setColumnWithIdentifier:(id)identifier visible:(BOOL)visible
{
	NSTableColumn	*column;

	column = [self initialColumnWithIdentifier:identifier];

	NSAssert(column != nil, @"nil column!");

	if (visible) {
		if(![self isColumnWithIdentifierVisible:identifier]) {
			if (![CMRPref isSplitViewVertical] && ![identifier isEqualToString:CMRThreadTitleKey]) {
				CGFloat tmp;
				NSTableColumn	*tmp2;
				
				[self addTableColumn:column];
				
				tmp = [column width];
				tmp2 = [self initialColumnWithIdentifier:CMRThreadTitleKey];
				[tmp2 setWidth:([tmp2 width] - tmp)];
			} else {
				[self addTableColumn:column];	
			}
			[self sizeLastColumnToFit];
			[self setNeedsDisplay:YES];
		}
	} else {
		if ([self isColumnWithIdentifierVisible:identifier]) {
			if (![CMRPref isSplitViewVertical] && ![identifier isEqualToString:CMRThreadTitleKey]) {			
				CGFloat tmp = [column width];
				NSTableColumn	*tmp2 = [self initialColumnWithIdentifier:CMRThreadTitleKey];
				
				[self removeTableColumn:column];
				[tmp2 setWidth:([tmp2 width] + tmp)];
			} else {
				[self removeTableColumn:column];
			}
			if (![identifier isEqualToString:CMRThreadTitleKey]) {
				[self sizeLastColumnToFit];
			}
			[self setNeedsDisplay:YES];
		}
	}
}

- (BOOL)isColumnWithIdentifierVisible:(id)identifier
{
	return ([self columnWithIdentifier:identifier] != -1);
}

- (NSTableColumn *)initialColumnWithIdentifier:(id)identifier
{
	NSEnumerator	*enumerator;
	NSTableColumn	*column = nil;

	enumerator = [allColumns objectEnumerator];

	while (column = [enumerator nextObject]) {
		if ([[column identifier] isEqual:identifier]) {
			break;
		}
	}
	return column;
}

- (void)removeAllColumns
{
	NSArray			*columns;
	NSEnumerator	*enumerator;
	NSTableColumn	*column;

	columns = [NSArray arrayWithArray:[self tableColumns]];
	enumerator = [columns objectEnumerator];

	while (column = [enumerator nextObject]) {
		[self removeTableColumn:column];
	}
}

- (void)setInitialState
{
	allColumns = [[NSArray arrayWithArray:[self tableColumns]] retain];
}

#pragma mark IBActions
- (IBAction)scrollRowToTop:(id)sender
{
	[self scrollRowToVisible:0];
}

- (IBAction)scrollRowToEnd:(id)sender
{
	[self scrollRowToVisible:([self numberOfRows]-1)];
}
/*
- (IBAction)deleteThread:(id)sender
{
	id dataSource = [self dataSource];
	if (!dataSource || ![dataSource respondsToSelector:@selector(tableView:removeFilesAtRowIndexes:ask:)]) {
		NSBeep();
		return;
	}
	[dataSource tableView:self removeFilesAtRowIndexes:[self selectedRowIndexes] ask:(![CMRPref quietDeletion])];
}
*/
- (IBAction)revealInFinder:(id)sender
{
	id dataSource = [self dataSource];
	if (!dataSource || ![dataSource respondsToSelector:@selector(tableView:revealFilesAtRowIndexes:)]) {
		NSBeep();
		return;
	}
	[dataSource tableView:self revealFilesAtRowIndexes:[self selectedRowIndexes]];
}

- (IBAction)openInBrowser:(id)sender
{
	id dataSource = [self dataSource];
	if (!dataSource || ![dataSource respondsToSelector:@selector(tableView:openURLsAtRowIndexes:)]) {
		NSBeep();
		return;
	}
	[dataSource tableView:self openURLsAtRowIndexes:[self targetIndexesForActionSender:sender]];
}

- (IBAction)quickLook:(id)sender
{
    id dataSource = [self dataSource];
    if (!dataSource || ![dataSource respondsToSelector:@selector(tableView:quickLookAtRowIndexes:keepLook:)]) {
        NSBeep();
        return;
    }
    NSIndexSet *indexes = [self targetIndexesForActionSender:sender];
    if ([indexes count] == 0) {
        return;
    }
    [dataSource tableView:self quickLookAtRowIndexes:indexes keepLook:NO];
}

- (IBAction)toggleLabeledThread:(id)sender
{
    NSUInteger newLabel;
    BOOL fromLabelMenuItem = [sender isKindOfClass:[BSLabelMenuItemView class]];
    if (fromLabelMenuItem) {
        newLabel = [sender clickedLabel];
    } else {
        NSCellStateValue state = [sender state];
        if (state == NSOnState) {
            newLabel = 0;
        } else {
            newLabel = [sender tag];
        }
    }
    id dataSource = [self dataSource];
    if (!dataSource || ![dataSource respondsToSelector:@selector(tableView:setLabel:atRowIndexes:)]) {
        NSBeep();
        return;
    }
    [dataSource tableView:self setLabel:newLabel atRowIndexes:(fromLabelMenuItem ? [self targetIndexesForLabelMenuItem:sender] : [self targetIndexesForActionSender:sender])];
}

- (IBAction)toggleDatOchiThread:(id)sender
{
    NSCellStateValue state = [sender state];
    BOOL newFlag = (state == NSOnState) ? NO : YES;
    
    id dataSource = [self dataSource];
    if (!dataSource || ![dataSource respondsToSelector:@selector(tableView:setIsDatOchi:atRowIndexes:)]) {
        NSBeep();
        return;
    }
    [dataSource tableView:self setIsDatOchi:newFlag atRowIndexes:[self selectedRowIndexes]];
}

- (IBAction)removeFromDB:(id)sender
{
    [[self dataSource] tableView:self removeFromDBAtRowIndexes:[self selectedRowIndexes]];
}

#pragma mark Validations
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	if (action == @selector(revealInFinder:)) {
		NSInteger selectedRow = [self selectedRow];
		id dataSource = [self dataSource];

		if (selectedRow == -1) {
            return NO;
        }

        if (!dataSource || ![dataSource respondsToSelector:@selector(isThreadLogCachedAtRowIndex:inTableView:label:)]) {
            return NO;
        }
        return [dataSource isThreadLogCachedAtRowIndex:selectedRow inTableView:self label:NULL];
    } else if (action == @selector(toggleLabeledThread:)) {
        BOOL shouldEnabled = NO;
        NSIndexSet *selection = [self targetIndexesForActionSender:anItem];
        NSUInteger selectionCount = [selection count];

        if (selectionCount < 1) {
            setUserInterfaceItemState(anItem, NO);
            return NO;
        }

        id dataSource = [self dataSource];
        if (!dataSource || ![dataSource respondsToSelector:@selector(isThreadLogCachedAtRowIndex:inTableView:label:)]) {
            setUserInterfaceItemState(anItem, NO);
            return NO;
        }
        
        NSUInteger i;
        NSInteger size = [selection lastIndex]+1;
        NSRange e = NSMakeRange(0, size);
        NSCellStateValue state = NSOffState;
        NSUInteger itemLabelCount = 0;
        while ([selection getIndexes:&i maxCount:1 inIndexRange:&e] > 0) {
            NSUInteger label;
            if ([dataSource isThreadLogCachedAtRowIndex:i inTableView:self label:&label]) {
                shouldEnabled = YES;
                if (label == [anItem tag]) {
                    itemLabelCount++;
                }
            }
        }
        
        if (itemLabelCount > 0) {
            if (itemLabelCount == selectionCount) {
                state = NSOnState;
            } else {
                state = NSMixedState;
            }
        } else {
            state = NSOffState;
        }

        setUserInterfaceItemStateDirectly(anItem, state);
        return shouldEnabled;
    } else if (action == @selector(toggleDatOchiThread:)) {
        BOOL shouldEnabled = NO;
        NSUInteger datOchiCount = 0;
        NSIndexSet *selection = [self selectedRowIndexes];
        NSUInteger selectionCount = [selection count];

        if (selectionCount < 1) {
            setUserInterfaceItemState(anItem, NO);
            return NO;
        }

        id dataSource = [self dataSource];
        if (!dataSource || ![dataSource respondsToSelector:@selector(isThreadLogCachedAtRowIndex:inTableView:isDatOchi:)]) {
            setUserInterfaceItemState(anItem, NO);
            return NO;
        }

        NSUInteger i;
        NSInteger size = [selection lastIndex]+1;
        NSRange e = NSMakeRange(0, size);

        while ([selection getIndexes:&i maxCount:1 inIndexRange:&e] > 0) {
            BOOL datOchi;
            if ([[self dataSource] isThreadLogCachedAtRowIndex:i inTableView:self isDatOchi:&datOchi]) {
                shouldEnabled = YES;
                if (datOchi) {
                    datOchiCount++;
                }
            }
        }

        if (!shouldEnabled) {
            setUserInterfaceItemState(anItem, NO);
            return NO;
        }

        if ([(id)anItem isKindOfClass:[NSMenuItem class]]) {
            NSCellStateValue state = NSMixedState;
            if (datOchiCount == selectionCount) {
                state = NSOnState;
            } else if (datOchiCount == 0) {
                state = NSOffState;
            }
            [(NSMenuItem *)anItem setState:state];
        }
        return YES;
	} else if (action == @selector(removeFromDB:)) {
		return ([[self selectedRowIndexes] count] == 1);
	} else if (action == @selector(quickLook:) || action == @selector(openInBrowser:)) {
		return ([[self targetIndexesForActionSender:anItem] count] > 0);
	}
	return [super validateUserInterfaceItem:anItem];
}

- (BOOL)validateLabelMenuItem:(BSLabelMenuItemView *)item
{
    BOOL shouldEnabled = NO;
    NSIndexSet *selection = [self targetIndexesForLabelMenuItem:item];
    NSUInteger selectionCount = [selection count];
    
    if (selectionCount < 1) {
        return NO;
    }
    
    id dataSource = [self dataSource];
    if (!dataSource || ![dataSource respondsToSelector:@selector(isThreadLogCachedAtRowIndex:inTableView:label:)]) {
        return NO;
    }

    [item deselectAll];
    
    NSUInteger i;
    NSInteger size = [selection lastIndex]+1;
    NSRange e = NSMakeRange(0, size);

    while ([selection getIndexes:&i maxCount:1 inIndexRange:&e] > 0) {
        NSUInteger label;
        if ([dataSource isThreadLogCachedAtRowIndex:i inTableView:self label:&label]) {
            shouldEnabled = YES;
            [item setSelected:YES forLabel:label clearOthers:NO];
        }
    }
    
    return shouldEnabled;
}

- (BOOL)validateNSControlToolbarItem:(NSToolbarItem *)item
{
	SEL action = [(NSControl *)[item view] action];
	if (action == @selector(quickLook:)) {
		return ([[self selectedRowIndexes] count] == 1);
	}
	return YES;
}

- (id<BSThreadsListDataSource>)dataSource
{
    return (id<BSThreadsListDataSource>)[super dataSource];
}

- (void)setDataSource:(id<BSThreadsListDataSource>)anObject
{
    [super setDataSource:anObject];
}
@end
