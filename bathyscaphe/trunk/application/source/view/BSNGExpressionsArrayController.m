//
//  BSNGExpressionsArrayController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/07/28.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSNGExpressionsArrayController.h"
#import <CocoMonar/CMRPropertyListCoding.h>
#import "BSNGExpression.h"

NSString *const BSNGExpressionPboardType = @"BSNGExpressionPboardType";
static NSString *const kObjectsKey = @"NGExpressions";
static NSString *const kIndexesKey = @"RowIndexes";

@implementation BSNGExpressionsArrayController
- (void)awakeFromNib
{
	[[self tableView] registerForDraggedTypes:[NSArray arrayWithObject:BSNGExpressionPboardType]];
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    NSArray *objectsAtRows = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
    NSMutableArray *plist = [NSMutableArray arrayWithCapacity:[objectsAtRows count]];

    for (id<CMRPropertyListCoding> eachObj in objectsAtRows) {
        id object = [eachObj propertyListRepresentation];
        [plist addObject:object];
    }

	NSData *archivedIndexes = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];

	NSArray *pboardTypes = [NSArray arrayWithObject:BSNGExpressionPboardType];
	[pboard declareTypes:pboardTypes owner:self];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:plist, kObjectsKey, archivedIndexes, kIndexesKey, NULL];
    [pboard setPropertyList:dictionary forType:BSNGExpressionPboardType];

	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id<NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	NSDragOperation dragOp = NSDragOperationNone;
	
	id pboardContent = [[info draggingPasteboard] propertyListForType:BSNGExpressionPboardType];
	
	if (pboardContent) {
        // 同一アプリケーションからのドラッグであれば -draggingSource は nil でない
        // 同一ビュー内でのドラッグは単なる行の入れ替え：Move で処理。それ以外は Copy で処理。
        if ([info draggingSource] == [self tableView]) {
            dragOp = NSDragOperationMove;
        } else {
            dragOp = NSDragOperationCopy;
        }

		[tv setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
    return dragOp;
}

- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id<NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)op
{
	id pboardContent = [[info draggingPasteboard] propertyListForType:BSNGExpressionPboardType];
	
	if (!pboardContent || ![pboardContent isKindOfClass:[NSDictionary class]]) {
		return NO;
	}

    NSArray *plist = [(NSDictionary *)pboardContent objectForKey:kObjectsKey];
    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[plist count]];
    for (id plistedObject in plist) {
        id<CMRPropertyListCoding> object = [BSNGExpression objectWithPropertyListRepresentation:plistedObject];
        [objects addObject:object];
    }

    NSIndexSet *startedIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:[(NSDictionary *)pboardContent objectForKey:kIndexesKey]];
    NSUInteger startedIndex = [startedIndexes firstIndex];
    if ([info draggingSource] == [self tableView]) {
        NSUInteger adjustedIndex;

        if (startedIndex == row) return YES;

        if (startedIndex > row) {
            adjustedIndex = row;
        } else {
            NSUInteger upperEnd = [startedIndexes indexLessThanIndex:row];
            NSUInteger adjust = 0;
            if (upperEnd != NSNotFound) {
                NSRange upperRange = NSMakeRange(startedIndex, startedIndex + upperEnd + 1);
                adjust = [startedIndexes countOfIndexesInRange:upperRange];
            }
            adjustedIndex = row - adjust;
        }

        [self removeObjectsAtArrangedObjectIndexes:startedIndexes];
        NSIndexSet *adjustedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(adjustedIndex, [startedIndexes count])];
        [self insertObjects:objects atArrangedObjectIndexes:adjustedIndexes];
    } else {
        NSIndexSet *insertionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(row, [startedIndexes count])];
        [self insertObjects:objects atArrangedObjectIndexes:insertionIndexes];
    }

	return YES;
}
@end
