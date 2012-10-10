/**
  * $Id: SGContextHelpPanel.h,v 1.1.1.1 2005-05-11 17:51:08 tsawada2 Exp $
  * 
  * SGContextHelpPanel.h
  *
  * Copyright (c) 2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  * encoding="UTF-8"
  */
#import <Cocoa/Cocoa.h>

@class SGContextHelpPanel;

@protocol SGContextHelpPanelDelegate<NSWindowDelegate, NSObject>
@optional
- (void)contextHelpPanel:(SGContextHelpPanel *)panel firstResponderWillChange:(NSResponder *)newResponder;
@end


@interface NSWindow(PopUpWindow)
- (BOOL)isPopUpWindow;
@end



@interface SGContextHelpPanel : NSPanel
- (void)updateBackgroundColorWithRoundedCorner:(NSColor *)bgColor;

- (id<SGContextHelpPanelDelegate>)delegate;
- (void)setDelegate:(id<SGContextHelpPanelDelegate>)aDelegate;
@end
