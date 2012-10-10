//
//  BSQuickLookPanelController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/02/02.
//  Copyright 2008-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSQuickLookPanelController : NSWindowController {
	IBOutlet NSObjectController *m_objectController;
	IBOutlet NSTextView			*m_textView;
	IBOutlet NSTabView			*m_tabView;
	id	m_parent; // Do not retain/release
}

+ (id)sharedInstance;

- (NSObjectController *)objectController;
- (BOOL)isLooking;

- (id)qlPanelParent;
- (void)setQlPanelParent:(id)obj;
@end
