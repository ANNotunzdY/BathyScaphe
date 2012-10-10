//
//  BSIndexPanelController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/05/09.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIndexPanelController.h"
#import "CMRThreadViewer.h"
#import "CMRThreadLayout.h"


@implementation BSIndexPanelController
@synthesize numberOfMessages;
@synthesize threadViewer;

- (id)init
{
    if (self = [super initWithWindowNibName:@"BSIndexPanel"]) {
        ;
    }
    return self;
}

- (NSTextField *)indexField
{
    return m_indexField;
}

- (NSTextField *)numberOfMessagesField
{
    return m_numberOfMessagesField;
}

- (void)beginSheetModalForThreadViewer:(id)viewer
{
    self.threadViewer = viewer;
	self.numberOfMessages = [[viewer threadLayout] firstUnlaidMessageIndex];

	[NSApp beginSheet:[self window]
       modalForWindow:[viewer window]
        modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:NULL];
}

- (IBAction)cancelSelectingIndex:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)selectIndex:(id)sender
{
    NSString *stringValue = [[self indexField] stringValue];
    NSUInteger index = [stringValue unsignedIntegerValue];
    if (index == 0 || index > self.numberOfMessages) {
        NSBeep();
        return;
    }
    [self.threadViewer scrollMessageAtIndex:(index - 1)];
    [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [[self window] close];
    self.threadViewer = nil;
    self.numberOfMessages = 0;
    [[self indexField] setStringValue:@""];
}
@end
