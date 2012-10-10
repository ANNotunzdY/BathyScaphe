// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// BathyScaphe
// encoding="UTF-8"

#import <Cocoa/Cocoa.h>

@class OverlayFrameView;

enum {
  kHistoryOverlayModeBack,
  kHistoryOverlayModeForward
};
typedef NSInteger HistoryOverlayMode;

// The HistoryOverlayController manages the overlay HUD panel which displays
// navigation gesture icons within a browser window.
@interface HistoryOverlayController : NSWindowController<NSWindowDelegate> {
 @private
  HistoryOverlayMode mode_;

  // The content view of the window that this controller manages.
//  OverlayFrameView* contentView_;  // Weak, owned by the window.

//  scoped_nsobject<NSWindow> parent_;
	NSWindow *parent_;
    NSRect withinRect;
}

// Designated initializer.
- (id)initForMode:(HistoryOverlayMode)mode;
- (id)initForMode:(HistoryOverlayMode)mode level:(NSInteger)windowLevel;

// Shows the panel.
- (void)showPanelForWindow:(NSWindow*)window;

- (void)showPanelWithinRect:(NSRect)screenCoordinateRect;

// Updates the appearance of the overlay based on track gesture progress.
- (void)setProgress:(CGFloat)gestureAmount;

// Schedules a fade-out animation and then closes the window,
// which will release the controller.
- (void)dismiss;
@end
