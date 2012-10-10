//
//  CMRThreadViewerTbDelegate.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/09/23.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRToolbarDelegateImp.h"

@interface CMRThreadViewerTbDelegate : CMRToolbarDelegateImp {
    IBOutlet NSSegmentedControl *m_historyButton;
    IBOutlet NSSegmentedControl *m_scaleButton;
    IBOutlet NSButton *m_thunderButton;
    IBOutlet NSButton *m_reloadThreadButton;
    IBOutlet NSButton *m_stopTaskButton;
    
    IBOutlet NSButton *m_replyButton;
    IBOutlet NSButton *m_addFavoritesButton;
    IBOutlet NSButton *m_deleteButton;
    IBOutlet NSButton *m_orderFrontBrowserButton;
    IBOutlet NSButton *m_threadTitleSearchButton;

    IBOutlet NSButton *m_sharingServiceButton; // Mountain Lion or later
}
@end


@interface CMRThreadViewerTbDelegate(Private)
- (NSString *)reloadThreadItemIdentifier;
- (NSString *)replyItemIdentifier;
- (NSString *)addFavoritesItemIdentifier;
- (NSString *)deleteItemIdentifier;
- (NSString *)toggleOnlineModeIdentifier;

// Available in BathyScaphe 1.0.2 and later.
- (NSString *)stopTaskIdentifier;

// Available in SledgeHammer and later.
- (NSString *)historySegmentedControlIdentifier;
- (NSString *)orderFrontBrowserItemIdentifier;

// Available in ReinforceII and later.
- (NSString *)scaleSegmentedControlIdentifier;

// Reserved
//- (NSString *)actionButtonItemIdentifier;

// Available in BathyScaphe 2.1 ".Invader" and later.
- (NSString *)threadTitleSearchIdentifier;

// Available in BathyScaphe 2.2 "Baby Universe Day" and later.
- (NSString *)sharingServiceItemIdentifer;
@end
