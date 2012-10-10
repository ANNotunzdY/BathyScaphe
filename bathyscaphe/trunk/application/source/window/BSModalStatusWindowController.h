//
//  BSModalStatusWindowController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 09/07/04.
//  Copyright 2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSModalStatusWindowController : NSWindowController {
    IBOutlet NSTextField *m_messageTextField;
    IBOutlet NSProgressIndicator *m_progressIndicator;
    IBOutlet NSTextField *m_infoTextField;
}

- (NSTextField *)messageTextField;
- (NSProgressIndicator *)progressIndicator;
- (NSTextField *)infoTextField;
@end
