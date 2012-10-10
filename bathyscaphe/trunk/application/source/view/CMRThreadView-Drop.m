//
//  CMRThreadView-Drop.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/09/07.
//  Copyright 2006-2007 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadView_p.h"

@implementation CMRThreadView(NSDraggingDestination)
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];

    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObject:BSPasteboardTypeThreadSignature]]) {
        draggingHilited = YES;
        draggingTimer = [NSDate timeIntervalSinceReferenceDate];
        [self setNeedsDisplay:YES];
        return NSDragOperationCopy;
    }

    return [super draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];

    if ([pboard canReadItemWithDataConformingToTypes:[NSArray arrayWithObject:BSPasteboardTypeThreadSignature]]) {
        NSWindow *window_ = [sender draggingDestinationWindow];
        if (![window_ isKeyWindow]){
            if (([NSDate timeIntervalSinceReferenceDate] - draggingTimer) > 1.0) {
                [window_ makeKeyAndOrderFront:nil];
            }
        }
        [self setNeedsDisplay:YES];
        return NSDragOperationCopy;
    }

    return [super draggingUpdated:sender];
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    draggingHilited = NO;
    draggingTimer = 0.0;
    [self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *threadSignatures = [pboard readObjectsForClasses:[NSArray arrayWithObject:[CMRThreadSignature class]] options:[NSDictionary dictionary]];

    if (threadSignatures) {
        id delegate_ = [self delegate];
        CMRThreadSignature *threadSignature_ = [threadSignatures objectAtIndex:0];

        if (threadSignature_ && delegate_ && [delegate_ respondsToSelector:@selector(setThreadContentWithThreadIdentifier:)]) {
            [delegate_ setThreadContentWithThreadIdentifier:threadSignature_];
        }
    }

    draggingHilited = NO;
    draggingTimer = 0.0;
    [self setNeedsDisplay:YES];

    [super concludeDragOperation:sender];
}
@end
