//
//  CMRBrowserTbDelegate.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/27.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRThreadViewerTbDelegate.h"

@interface CMRBrowserTbDelegate : CMRThreadViewerTbDelegate {
    IBOutlet NSButton *m_quickLookButton;
    IBOutlet NSButton *m_reloadListButton;
    IBOutlet NSButton *m_boardListButton;
    IBOutlet NSButton *m_newThreadButton;
}
@end


@interface CMRBrowserTbDelegate(Private)
- (void)setupSearchToolbarItem:(NSToolbarItem *)anItem itemView:(NSView *)aView;
- (void)setupSwitcherToolbarItem:(NSToolbarItem *)anItem itemView:(NSView *)aView delegate:(id)delegate;
- (void)setupNobiNobiToolbarItem:(NSToolbarItem *)anItem;
- (void)setupLayoutSwitcherToolbarItem:(NSToolbarItem *)anItem itemView:(NSView *)aView;
@end
