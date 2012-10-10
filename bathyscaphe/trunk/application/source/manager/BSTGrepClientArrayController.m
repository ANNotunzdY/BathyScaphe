//
//  BSTGrepClientArrayController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/09/20.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSTGrepClientArrayController.h"
#import "CMRThreadSignature.h"
#import "BSQuickLookPanelController.h"
#import "BSQuickLookObject.h"


@implementation BSTGrepClientArrayController
- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
/*	NSArray *types;
	NSUInteger index;
	CMRThreadSignature *threadSignature;
    NSString *urlString;
    
	index = [rowIndexes firstIndex];
	threadSignature = [[[self arrangedObjects] objectAtIndex:index] valueForKey:@"threadSignature"];
    urlString = [[[self arrangedObjects] objectAtIndex:index] valueForKey:@"threadURLString"];

    if (!threadSignature || !urlString) {
        return NO;
    }

    types = [NSArray arrayWithObjects:NSStringPboardType, BSThreadItemsPboardType, nil];
	[pboard declareTypes:types owner:nil];
	[pboard setPropertyList:[NSArray arrayWithObject:[threadSignature propertyListRepresentation]] forType:BSThreadItemsPboardType];
    [pboard setString:urlString forType:NSStringPboardType];

	return YES;*/
    NSArray *tGrepResults = [[self arrangedObjects] objectsAtIndexes:rowIndexes];
    if (!tGrepResults || [tGrepResults count] == 0) {
        return NO;
    }
    [pboard clearContents];
    [pboard writeObjects:tGrepResults];
    return YES;
}

- (void)quickLook:(NSIndexSet *)indexes parent:(NSWindow *)parentWindow keepLook:(BOOL)flag
{
	BSQuickLookPanelController *qlc = [BSQuickLookPanelController sharedInstance];
	if (![qlc isLooking] || !flag) {
		[qlc showWindow:self];
	}

	if ([[qlc window] isVisible]) {
        id object = [[self arrangedObjects] objectAtIndex:[indexes firstIndex]];

		[qlc setQlPanelParent:parentWindow];

		NSString *title = [object valueForKey:@"threadTitle"];
		CMRThreadSignature *signature = [object valueForKey:@"threadSignature"];
        if (!signature) {
            return;
        }

		BSQuickLookObject *bar = [[BSQuickLookObject alloc] initWithThreadTitle:title signature:signature];
		[[qlc objectController] setContent:bar];
		[bar release];
	}
}
@end
