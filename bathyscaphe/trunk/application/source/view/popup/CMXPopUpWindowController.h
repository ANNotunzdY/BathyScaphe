//
//  CMXPopUpWindowController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/23.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CMRThreadView.h"
#import "SGContextHelpPanel.h"

@class BSThreadViewTheme, BSPopUpTitlebar;

@interface CMXPopUpWindowController : NSWindowController<SGContextHelpPanelDelegate>
{
	@private
	NSScrollView		*_scrollView;
	NSTextView			*_textView;
	NSTextStorage		*_textStorage;
	BSPopUpTitlebar		*m_titlebar;
	id					_object;
	BSThreadViewTheme	*m_theme;

	BOOL	m_closable;	
	BOOL	bs_usesSmallScroller;
	BOOL	bs_shouldAntialias;
	BOOL	bs_linkTextHasUnderline;
    // For Lion
    // 辞書のポップオーバーのインスタンスを一時保管
    id m_popover;
}

+ (CGFloat)popUpTrackingInsetWidth;
+ (CGFloat)popUpMaxWidthRate;

- (NSScrollView *)scrollView;
- (NSTextView *)textView;
- (NSTextStorage *)textStorage;
- (BSPopUpTitlebar *)titlebar;

- (BOOL)canPopUpWindow;
- (BOOL)mouseInWindowFrameInset:(CGFloat)anInset;

- (void)showPopUpWindowWithContext:(NSAttributedString *)context owner:(id<CMRThreadViewDelegate, NSTextViewDelegate>)owner locationHint:(NSPoint)point;
- (void)performClose;

- (id)object;
- (void)setObject : (id)anObject;

- (BOOL)isClosable;
- (void)setClosable:(BOOL)closable;

- (NSString *)contextAsString;

// textView delegate
- (id<CMRThreadViewDelegate, NSTextViewDelegate>)owner;
- (void)setOwner:(id<CMRThreadViewDelegate, NSTextViewDelegate>)anOwner;
- (NSWindow *)ownerWindow;

- (IBAction)extractUsingSelectedText:(id)sender;
- (IBAction)addToNGWords:(id)sender;
@end


@interface CMXPopUpWindowController(Accessor)
- (NSScrollerKnobStyle)appropriateKnobStyleForBGColor;
- (void)updateBGColor;

- (BOOL)usesSmallScroller;
- (void)setUsesSmallScroller:(BOOL)TorF;
- (BOOL)shouldAntialias;
- (void)setShouldAntialias:(BOOL)TorF;
- (BOOL)linkTextHasUnderline;
- (void)setLinkTextHasUnderline:(BOOL)TorF;
- (BSThreadViewTheme *)theme;
- (void)setTheme:(BSThreadViewTheme *)aTheme;
@end
