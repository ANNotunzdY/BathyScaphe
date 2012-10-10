//
//  CMRReplyControllerTbDelegate.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/09.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRToolbarDelegateImp.h"

@interface CMRReplyControllerTbDelegate : CMRToolbarDelegateImp {
    IBOutlet NSButton *m_sendButton;
    IBOutlet NSButton *m_fontButton;
    IBOutlet NSButton *m_localRulesButton;
}

- (NSButton *)sendButton;
- (NSButton *)fontButton;
- (NSButton *)localRulesButton;

@end


@interface BSNewThreadControllerTbDelegate : CMRReplyControllerTbDelegate

@end
