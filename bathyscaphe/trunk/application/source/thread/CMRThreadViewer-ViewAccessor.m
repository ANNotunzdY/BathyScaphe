//
//  CMRThreadViewer-ViewAccessor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/12.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"

#import "CMRThreadView.h"
#import "CMRMainMenuManager.h"
#import "CMRMessageAttributesTemplate.h"
#import <SGAppKit/BSLayoutManager.h>
#import <SGAppKit/BSTitleRulerAppearance.h>
#import "CMRThreadFileLoadingTask.h"
#import "CMRThreadViewerTbDelegate.h"
#import "BSIndexPanelController.h"
#import "BSAddNGExWindowController.h"
#import "BSThreadLinkerCorePasser.h"
#import <SGAppKit/BSHistoryOverlayController.h>

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"


#define kComponentsLoadNibName	@"CMRThreadViewerComponents"
#define HTMLVIEW_CLASS			CMRThreadView

// 10.6 SDK でビルド警告が出ないようにするために
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6
enum {
    NSEventPhaseNone        = 0, // event not associated with a phase.
    NSEventPhaseBegan       = 0x1 << 0,
    NSEventPhaseStationary  = 0x1 << 1,
    NSEventPhaseChanged     = 0x1 << 2,
    NSEventPhaseEnded       = 0x1 << 3,
    NSEventPhaseCancelled   = 0x1 << 4,
};
typedef NSUInteger NSEventPhase;

enum {
    NSEventSwipeTrackingLockDirection = 0x1 << 0,
    NSEventSwipeTrackingClampGestureAmount = 0x1 << 1
};
typedef NSUInteger NSEventSwipeTrackingOptions;

@interface NSEvent(LionStub)
- (CGFloat)scrollingDeltaX;
- (CGFloat)scrollingDeltaY;
- (NSUInteger)phase;
+ (BOOL)isSwipeTrackingFromScrollEventsEnabled;
- (void)trackSwipeEventWithOptions:(NSUInteger)options
          dampenAmountThresholdMin:(CGFloat)minDampenThreshold
                               max:(CGFloat)maxDampenThreshold
                      usingHandler:(void (^)(CGFloat gestureAmount, NSUInteger phase, BOOL isComplete, BOOL *stop))trackingHandler;
@end
#endif

@implementation CMRThreadViewer(ViewAccessor)
- (NSScrollView *)scrollView
{
	return m_scrollView;
}

- (NSTextView *)textView
{
	return m_textView;
}

- (void)setTextView:(NSTextView *)aTextView
{
	m_textView = aTextView;
}

- (BSIndexPanelController *)indexPanelController
{
    if (!m_indexPanelController) {
        m_indexPanelController = [[BSIndexPanelController alloc] init];
    }
    return m_indexPanelController;
}

- (BSAddNGExWindowController *)addNGExWindowController
{
    if (!m_addNGExWindowController) {
        m_addNGExWindowController = [[BSAddNGExWindowController alloc] init];
    }
    return m_addNGExWindowController;
}

- (BSThreadLinkerCorePasser *)threadLinkerCorePasser
{
    if (!m_passer) {
        m_passer = [[BSThreadLinkerCorePasser alloc] init];
    }
    return m_passer;
}

- (BOOL)wantsScrollEventsForSwipeTrackingOnAxis:(NSInteger)axis
{
    if (![CMRPref multitouchGestureEnabled]) {
        return NO;
    }
    return axis == 1;
}

- (void)scrollWheel:(NSEvent *)event
{
    // NSScrollView is instructed to only forward horizontal scroll gesture events (see code above). However, depending
    // on where your controller is in the responder chain, it may receive other scrollWheel events that we don't want
    // to track as a fluid swipe because the event wasn't routed though an NSScrollView first.
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6) {
        return;
    }

    if ([event phase] == NSEventPhaseNone) {
        return; // Not a gesture scroll event.
    }
    
    // スレッドの内容表示領域以外でのイベントはスルーする
    NSRect rect = [[self scrollView] frame];
    rect = [[self scrollView] convertRect:rect toView:nil];
    if (!NSPointInRect([event locationInWindow], rect)) {
        return;
    }

    CGFloat foo = [event scrollingDeltaX];
    CGFloat bar = [event scrollingDeltaY];
    if (fabsf(foo) <= fabsf(bar)) { // Not horizontal
        return;
    }
    // If the user has disabled tracking scrolls as fluid swipes in system preferences, we should respect that.
    // NSScrollView will do this check for us, however, depending on where your controller is in the responder chain,
    // it may scrollWheel events that are not filtered by an NSScrollView.
    if (![NSEvent isSwipeTrackingFromScrollEventsEnabled]) {
        return;
    }
    
    id prevObj = [self threadIdentifierFromHistoryWithRelativeIndex:-1];
    id nextObj = [self threadIdentifierFromHistoryWithRelativeIndex:1];
    BOOL goForward = (foo < 0);
    // Released by the tracking handler once the gesture is complete.
    HistoryOverlayController* historyOverlay =
    [[HistoryOverlayController alloc]
     initForMode:goForward ? kHistoryOverlayModeForward :
     kHistoryOverlayModeBack];

    [event trackSwipeEventWithOptions:NSEventSwipeTrackingClampGestureAmount
             dampenAmountThresholdMin:(nextObj ? -1 : 0)
                                  max:(prevObj ? 1 : 0)
                         usingHandler:^(CGFloat gestureAmount, NSUInteger phase, BOOL isComplete, BOOL *stop) {
                             if (phase == NSEventPhaseBegan) {
                                 NSRect rect = [[self scrollView] frame];
                                 rect = [[self scrollView] convertRect:rect toView:nil];
                                 NSPoint point = rect.origin;
                                 point = [[self window] convertBaseToScreen:point];
                                 rect.origin = point;
                                 [historyOverlay showPanelWithinRect:rect];
                                 return;
                             }

                             if (phase == NSEventPhaseEnded) {
                                 if (goForward) {
                                     [self historyMenuPerformForward:self];
                                 } else {
                                     [self historyMenuPerformBack:self];
                                 }
                             }
                             [historyOverlay setProgress:gestureAmount];

        if (isComplete) {
            [historyOverlay dismiss];
            [historyOverlay release];
        }
    }];
}
@end


@implementation CMRThreadViewer(UIComponents)
- (BOOL)loadComponents
{
	return [NSBundle loadNibNamed:kComponentsLoadNibName owner:self];
}

- (NSView *)containerView
{
	return m_containerView;
}

- (void)setupLoadedComponents
{
	NSString	*fs = [CMRPref windowDefaultFrameString];
	NSView		*containerView_;
	NSView		*contentView_ = [[self window] contentView];
	NSRect		vframe_;
	
	containerView_ = [self containerView];
	vframe_ = [m_windowContentView frame];
	
	[containerView_ retain];
	[containerView_ removeFromSuperviewWithoutNeedingDisplay];
	[containerView_ setFrame:vframe_];
	
	[contentView_ setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
	[contentView_ setAutoresizesSubviews:YES];
	
	// ダミーのNSViewと入れ替える
	[m_windowContentView retain];
	[contentView_ replaceSubview:m_windowContentView with:containerView_];
	[m_windowContentView release];
	m_windowContentView = nil;

	[containerView_ release];
	
	// 以前に保存しておいたウインドウの領域を
	// デフォルトのものとして使用する
	if (fs) [[self window] setFrameFromString:fs];
}
@end


@implementation CMRThreadViewer(ViewInitializer)
#pragma mark Contextual Menu Stuff
+ (NSMenu *)loadContextualMenuForTextView
{
	NSMenu	*menu_;

	NSMenu	*textViewMenu_;
	NSEnumerator *iter_;
	NSMenuItem	*item_;

	menu_ = [[CMRMainMenuManager defaultManager] threadContexualMenuTemplate];
	textViewMenu_ = [HTMLVIEW_CLASS messageMenu];

	[menu_ addItem:[NSMenuItem separatorItem]];

	iter_ = [[textViewMenu_ itemArray] objectEnumerator];
	while (item_ = [iter_ nextObject]) {
		item_ = [item_ copy];
		[menu_ addItem:item_];
		[item_ release];
	}
	
	return menu_;
}

#pragma mark Override super implementation
+ (Class)toolbarDelegateImpClass
{
	return [CMRThreadViewerTbDelegate class];
}

#pragma mark Title Ruler
+ (BOOL)shouldShowTitleRulerView
{
	return NO;
}

+ (BSTitleRulerModeType)rulerModeForInformDatOchi
{
	return BSTitleRulerShowInfoOnlyMode;
}

+ (NSString *)titleRulerAppearanceFilePath
{
	NSString *path;
	NSBundle *appSupport = [NSBundle applicationSpecificBundle];

	path = [appSupport pathForResource:@"BSTitleRulerAppearance" ofType:@"plist"];
	if (!path) {
		path = [[NSBundle mainBundle] pathForResource:@"BSTitleRulerAppearance" ofType:@"plist"];
	}
	return path;
}

- (void)setupTitleRulerWithScrollView:(NSScrollView *)scrollView_
{
	id ruler;
	NSString *path = [[self class] titleRulerAppearanceFilePath];
	UTILAssertNotNil(path);
	BSTitleRulerAppearance *foo = [NSKeyedUnarchiver unarchiveObjectWithFile:path];

	[[scrollView_ class] setRulerViewClass:[BSTitleRulerView class]];
	ruler = [[BSTitleRulerView alloc] initWithScrollView:scrollView_ appearance:foo];
	[ruler setTitleStr:NSLocalizedString(@"titleRuler default title", @"Startup Message")];

	[scrollView_ setHorizontalRulerView:ruler];
    [ruler release];
	[scrollView_ setHasHorizontalRuler:YES];
	[scrollView_ setRulersVisible:[[self class] shouldShowTitleRulerView]];
}

- (void)cleanUpTitleRuler:(NSTimer *)aTimer
{
	BSTitleRulerView *view_ = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];

	[[self scrollView] setRulersVisible:[[self class] shouldShowTitleRulerView]];
	[view_ setCurrentMode:BSTitleRulerShowTitleOnlyMode];
}

#pragma mark Others
- (NSScrollerKnobStyle)appropriateKnobStyleForThreadViewBGColor
{
    CGFloat r,g,b;
    CGFloat distanceWhite, distanceBlack;
    NSColor *color = [[[CMRPref threadViewTheme] backgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [color getRed:&r green:&g blue:&b alpha:NULL];
    distanceBlack = fabs(r) + fabs(g) + fabs(b);
    distanceWhite = fabs(r - 1.0) + fabs(g - 1.0) + fabs(b - 1.0);
    
    return (distanceBlack < distanceWhite) ? NSScrollerKnobStyleLight : NSScrollerKnobStyleDefault;
}

- (void)setupScrollView
{
	NSScrollView	*scrollView_ = [self scrollView];
	NSClipView		*contentView_;
		
	contentView_ = [scrollView_ contentView];
	[contentView_ setPostsBoundsChangedNotifications:YES];
		
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(contentViewBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:contentView_];
	
	[scrollView_ setBorderType:NSNoBorder];
	[scrollView_ setHasHorizontalScroller:NO];
	[scrollView_ setHasVerticalScroller:YES];
	[self setupTitleRulerWithScrollView:scrollView_];
}

- (void)setupTextView
{
	NSLayoutManager		*layout;
	NSTextContainer		*container;
	NSTextView			*view;
	NSRect				cFrame;
	
	cFrame.origin = NSZeroPoint; 
	cFrame.size = [[self scrollView] contentSize];
	
	/* LayoutManager */
	layout = [[BSLayoutManager alloc] init];
	[layout setAllowsNonContiguousLayout:YES];

	[[(CMRThreadDocument *)[self document] textStorage] addLayoutManager:layout];
	[layout release];
	
	/* TextContainer */
	container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(NSWidth(cFrame), CGFLOAT_MAX)];//1e7)];
	[layout addTextContainer:container];
	[container release];
	
	/* TextView */
	view = [[HTMLVIEW_CLASS alloc] initWithFrame:cFrame textContainer:container];

	[view setMinSize : NSMakeSize(0.0, NSHeight(cFrame))];
	[view setMaxSize : NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];//1e7, 1e7)];
	[view setVerticallyResizable:YES];
	[view setHorizontallyResizable:NO];
	[view setAutoresizingMask:NSViewWidthSizable];

	[container setWidthTracksTextView:YES];
	
	[view setEditable:NO];
	[view setSelectable:YES];
	[view setAllowsUndo:NO];
	[view setImportsGraphics:NO];
	[view setFieldEditor:NO];

	[view setMenu:[[self class] loadContextualMenuForTextView]];
	[view setDelegate:self];

    [view setDisplaysLinkToolTips:NO];

	[self setTextView:view];

	[self setupTextViewBackground];
	[self updateLayoutSettings];

	[[self scrollView] setDocumentView:view];

	[view release];
}

- (void)threadViewThemeDidChange:(NSNotification *)notification
{
	[self setupTextViewBackground];

	if ([self synchronize]) {
		[self setChangeThemeTaskIsInProgress:YES];
		[self loadFromContentsOfFile:[self path]];
		// linkTextAttributes は -loadFromContentsOfFile: の後、-threadComposingDidFinished: の中で -updateLayoutSettings を
		// 遅延実行して更新する。
	}
}

- (void)updateLayoutSettings
{
	[(BSLayoutManager *)[[self textView] layoutManager] setShouldAntialias:[CMRPref shouldThreadAntialias]];
	[[self textView] setLinkTextAttributes:[[CMRMessageAttributesTemplate sharedTemplate] attributesForAnchor]];
}

- (void)setupTextViewBackground
{
	NSColor		*color = [[CMRPref threadViewTheme] backgroundColor];

	// textView
	[[self textView] setDrawsBackground:YES];
	[[self textView] setBackgroundColor:color];
	// scrollView
	[[self scrollView] setDrawsBackground:YES];
	[[self scrollView] setBackgroundColor:color];
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6) {
        [[self scrollView] setScrollerKnobStyle:[self appropriateKnobStyleForThreadViewBGColor]];
    }
}

- (void)setWindowFrameUsingCache
{
	NSRect		frame_;
	
	if (![self threadAttributes]) return;
	frame_ = [[self threadAttributes] windowFrame];
	
	// デフォルト
	if (NSEqualRects(NSZeroRect, frame_)) {
		return;
	}
	if (NSEqualRects(frame_, [[self window] frame])) {
		return;
	}
	[[self window] setFrame:frame_ display:YES];
	[self synchronizeWindowTitleWithDocumentName];
}
@end


@implementation CMRThreadViewer(NibOwner)
- (void)setupUIComponents
{
	[super setupUIComponents];
    [[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
    [[self window] setContentBorderThickness:22 forEdge:NSMinYEdge];
	
	// ロードしたComponentsの配置
	[self setupLoadedComponents];

	[self setupScrollView];
	[self setupTextView];
	
	[self validateIndexingNavigator];
}
@end
