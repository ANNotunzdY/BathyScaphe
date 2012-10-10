//
//  BSIndexPanelController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/05/09.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class CMRThreadViewer;

@interface BSIndexPanelController : NSWindowController {
    IBOutlet NSTextField *m_indexField;
    IBOutlet NSTextField *m_numberOfMessagesField;

    NSUInteger numberOfMessages;
    CMRThreadViewer *threadViewer;
}

- (NSTextField *)indexField;
- (NSTextField *)numberOfMessagesField;

- (void)beginSheetModalForThreadViewer:(id)viewer;

- (IBAction)cancelSelectingIndex:(id)sender;
- (IBAction)selectIndex:(id)sender;

- (id)threadViewer;

@property(readwrite, assign) NSUInteger numberOfMessages;
@property(readwrite, assign) CMRThreadViewer *threadViewer;

@end
