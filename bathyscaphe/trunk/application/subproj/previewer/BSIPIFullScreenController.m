//
//  BSIPIFullScreenController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/01/14.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIFullScreenController.h"
#import "BSIPIPathTransformer.h"
#import "BSIPIArrayController.h"
#import "BSIPIDefaults.h"
#import <Carbon/Carbon.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CocoMonar/CMRSingletonObject.h>
#import <SGAppKit/BSHistoryOverlayController.h>


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

@interface NSObject(FullScreenDelegateMethodsStub)
- (void)saveImage:(id)sender;
- (CGFloat)fullScreenWheelAmount;
@end


@implementation BSIPIFullScreenController
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance) 

- (id)init
{
    if (self = [super init]) {
        id transformer = [[[BSIPIImageIgnoringDPITransformer alloc] init] autorelease];
        [NSValueTransformer setValueTransformer:transformer forName:@"BSIPIImageIgnoringDPITransformer"];

        [NSBundle loadNibNamed:@"BSIPIFullScreen" owner:self];
    }
    return self;
}

- (void)awakeFromNib
{
    NSView  *contentView;

    _fullScreenWindow = [[NSClassFromString(@"BSIPIFullScreenWindow") alloc] initWithContentRect:[[_baseWindow contentView] frame]
                                                                 styleMask:NSBorderlessWindowMask
                                                                   backing:[_baseWindow backingType]
                                                                     defer:NO];
    [_fullScreenWindow setDelegate:self];

    contentView = [[_baseWindow contentView] retain];
    [contentView removeFromSuperview];
    [_fullScreenWindow setContentView:contentView];
    [contentView release];
}

- (id)delegate
{
    return m_delegate;
}

- (void)setDelegate:(id)aDelegate
{
    m_delegate = aDelegate;
}

- (NSArrayController *)arrayController
{
    return m_cube;
}

- (void)setArrayController:(id)aController
{
    if (aController != m_cube) {
        m_cube = aController;
    }
}

- (void)dealloc
{
    m_delegate = nil;
    m_cube = nil;
    [super dealloc];
}

- (NSColor *)suitableTextColorForBackground
{
    CGFloat r,g,b;
    CGFloat distanceWhite, distanceBlack;
    NSColor *color = [windowBackgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [color getRed:&r green:&g blue:&b alpha:NULL];
    distanceBlack = fabs(r) + fabs(g) + fabs(b);
    distanceWhite = fabs(r - 1.0) + fabs(g - 1.0) + fabs(b - 1.0);

    return (distanceBlack < distanceWhite) ? [NSColor whiteColor] : [NSColor blackColor];
}

- (void)startFullScreen
{
    [self startFullScreen:[NSScreen mainScreen]];
}

- (void)startFullScreen:(NSScreen *)whichScreen
{
    CGDisplayFadeReservationToken   tokenPtr1, tokenPtr2;
    NSRect                          curWinRect, curScreenRect;

    // if whichScreen is the screen which contains the menu bar, ...
    if (!whichScreen) return;
    NSArray *allScreens = [NSScreen screens];
    if ([allScreens count] == 0) return;
    
    if (whichScreen == [allScreens objectAtIndex:0]) {
        SetSystemUIMode(kUIModeAllHidden, kUIOptionDisableProcessSwitch);
    } else {
        SetSystemUIMode(kUIModeNormal, 0);
    }

    // adjust fullScreenWindow frame
    curWinRect = [_fullScreenWindow frame];
    curScreenRect = [whichScreen frame];
    
    if (!NSEqualRects(curWinRect, curScreenRect)) {
        [_fullScreenWindow setFrame:curScreenRect display:YES];
    }
    
    [_fullScreenWindow setBackgroundColor:windowBackgroundColor];
    [m_statusField setTextColor:[self suitableTextColorForBackground]];

    // Quartz!
    if (kCGErrorSuccess == CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &tokenPtr1)) {
        CGDisplayFade(
            tokenPtr1,
            0.8,                            // フェードにかける秒数：0.8
            kCGDisplayBlendNormal,          // 開始状態
            kCGDisplayBlendSolidColor,      // 終了状態
            0.0, 0.0, 0.0,                  // R, G, B：真っ黒
            FALSE                           // 完了を待つか：待たない
        );

        CGReleaseDisplayFadeReservation(tokenPtr1);
    }

    [_fullScreenWindow makeKeyAndOrderFront:nil];
    
    if (kCGErrorSuccess == CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &tokenPtr2)) {
        CGDisplayFade(
            tokenPtr2,
            0.5,                            // 0.5 seconds
            kCGDisplayBlendSolidColor,      // 開始状態
            kCGDisplayBlendNormal,          // 終了状態
            0.0, 0.0, 0.0,                  // R, G, B：真っ黒
            FALSE                           // 完了を待つか：待たない
        );

        CGReleaseDisplayFadeReservation(tokenPtr2);
    }

    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (void)endFullScreen
{
    CGDisplayFadeReservationToken tokenPtr;

    [NSCursor setHiddenUntilMouseMoves:NO]; // 念のため

    if (kCGErrorSuccess == CGAcquireDisplayFadeReservation(kCGMaxDisplayReservationInterval, &tokenPtr)) {
        CGDisplayFade(
            tokenPtr,
            0.8,                            // 0.8 seconds
            kCGDisplayBlendSolidColor,      // starting state
            kCGDisplayBlendNormal,          // ending state
            0.0, 0.0, 0.0,                  // black
            FALSE                           // don't wait for completion
        );

        CGReleaseDisplayFadeReservation(tokenPtr);
    }
    [_fullScreenWindow orderOut:nil];

    SetSystemUIMode(kUIModeNormal, 0);

    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [m_noMoreView setHidden:YES];

    if ([[self delegate] respondsToSelector:@selector(fullScreenDidEnd:)]) {
        [[self delegate] fullScreenDidEnd:_fullScreenWindow];
    }
}

- (BOOL)fullScreenShowPrevImage:(NSWindow *)window modifierFlags:(NSInteger)flags
{
    BSIPIArrayController *controller = (BSIPIArrayController *)[self arrayController];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (flags & NSAlternateKeyMask) {
        [m_noMoreView setHidden:YES];
        [controller selectFirst:window];
    } else if ([controller canSelectPrevious]) {
        [m_noMoreView setHidden:YES];
        [controller selectPrevious:window];
    } else {
        NSString *msg = [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"No Prev Image" value:@"Localized String Not Found" table:nil];
        [m_noMoreField setStringValue:msg];
        [m_noMoreView setNeedsDisplay:YES];
        [m_noMoreView setHidden:NO];
        [self performSelector:@selector(restoreNoMoreField) withObject:nil afterDelay:3.0];
    }
    return YES;
}

- (BOOL)fullScreenShowNextImage:(NSWindow *)window modifierFlags:(NSInteger)flags
{
    BSIPIArrayController *controller = (BSIPIArrayController *)[self arrayController];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (flags & NSAlternateKeyMask) {
        [m_noMoreView setHidden:YES];
        [controller selectLast:window];
    } else if ([controller canSelectNext]) {
        [m_noMoreView setHidden:YES];
        [controller selectNext:window];
    } else {
        NSString *msg = [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"No Next Image" value:@"Localized String Not Found" table:nil];
        [m_noMoreField setStringValue:msg];
        [m_noMoreView setNeedsDisplay:YES];
        [m_noMoreView setHidden:NO];
        [self performSelector:@selector(restoreNoMoreField) withObject:nil afterDelay:3.0];
    }
    return YES;
}

- (BOOL)fullScreenSaveImage:(NSWindow *)window
{
    if ([[BSIPIDefaults sharedIPIDefaults] autoCollectImages]) {
        NSBeep();
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSString *msg = [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"Image Saved 2" value:@"Localized String Not Found" table:nil];
        [m_noMoreField setStringValue:msg];
        [m_noMoreView setNeedsDisplay:YES];
        [m_noMoreView setHidden:NO];
        [self performSelector:@selector(restoreNoMoreField) withObject:nil afterDelay:3.0];
        return YES;
    }

    if ([[self delegate] respondsToSelector:@selector(saveImage:)]) {
        AudioServicesPlaySystemSound(1);
        [[self delegate] saveImage:window];

        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSString *msg = [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"Image Saved" value:@"Localized String Not Found" table:nil];
        [m_noMoreField setStringValue:msg];
        [m_noMoreView setNeedsDisplay:YES];
        [m_noMoreView setHidden:NO];
        [self performSelector:@selector(restoreNoMoreField) withObject:nil afterDelay:3.0];
        return YES;
    }
    return NO;
}

- (BOOL)fullScreenDeleteImage:(NSWindow *)window
{
    AudioServicesPlaySystemSound(15);
    [[self arrayController] remove:window];
    if ([[[self arrayController] arrangedObjects] count] == 0) {
        [self endFullScreen];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        NSString *msg = [[NSBundle bundleForClass:[self class]] localizedStringForKey:@"Image Deleted" value:@"Localized String Not Found" table:nil];
        [m_noMoreField setStringValue:msg];
        [m_noMoreView setNeedsDisplay:YES];
        [m_noMoreView setHidden:NO];
        [self performSelector:@selector(restoreNoMoreField) withObject:nil afterDelay:3.0];        
    }

    return YES;
}

- (void)restoreNoMoreField
{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:m_noMoreView, NSViewAnimationTargetKey,
            NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, NULL];
    NSArray *array = [NSArray arrayWithObject:dict];
    NSViewAnimation *anime = [[[NSViewAnimation alloc] initWithViewAnimations:array] autorelease];
    [anime startAnimation];
}

- (void)toggleInfoViewHidden:(BOOL)flag
{
    NSDictionary *dict;

    if (!m_animation) {
        m_animation = [[NSViewAnimation alloc] initWithViewAnimations:nil];
    }
    
    if (flag) { // hide
        dict = [NSDictionary dictionaryWithObjectsAndKeys:m_imageInfoView, NSViewAnimationTargetKey,
            NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey, NULL];
    } else {
        dict = [NSDictionary dictionaryWithObjectsAndKeys:m_imageInfoView, NSViewAnimationTargetKey,
            NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, NULL];
    }
    
    [m_animation setViewAnimations:[NSArray arrayWithObject:dict]];
    [m_animation setDuration:0.5];
    [m_animation startAnimation];
}

#pragma mark Delegates
- (BOOL)handlesKeyDown:(NSEvent *)keyDown inWindow:(NSWindow *)window
{
    NSInteger modFlags = [keyDown modifierFlags];

    NSString    *pressedKey = [keyDown charactersIgnoringModifiers];
    unichar     keyChar = 0;

    NSUInteger length = [pressedKey length];
    if (length != 1) {
        return NO;
    }

    keyChar = [pressedKey characterAtIndex:0];

    if (keyChar == NSLeftArrowFunctionKey) {
        return [self fullScreenShowPrevImage:window modifierFlags:modFlags];
    }
    
    if (keyChar == NSRightArrowFunctionKey) {
        return [self fullScreenShowNextImage:window modifierFlags:modFlags];
    }
    
    if (keyChar == 'i') {
        if ([m_imageInfoView window] != _fullScreenWindow) {
            [[_fullScreenWindow contentView] addSubview:m_imageInfoView];
            [m_imageInfoView setFrameOrigin:NSMakePoint(10,10)];
            [m_imageInfoView setHidden:YES];
        }
        [self toggleInfoViewHidden:![m_imageInfoView isHidden]];
        return YES;
    }
    
    if (keyChar == 's') {
        return [self fullScreenSaveImage:window];
    }

    if (keyChar == NSDeleteCharacter) {
//      if ((modFlags & NSDeviceIndependentModifierFlagsMask) == 0) {
        return [self fullScreenDeleteImage:window];
//      }
    }

    [self endFullScreen];
    return YES;
}

- (BOOL)handlesMouseDown:(NSEvent *)mouseDown inWindow:(NSWindow *)window
{
    //  Close the panel on any click
    [self endFullScreen];
    return YES;
}

- (BOOL)handlesScrollWheel:(NSEvent *)scrollWheel inWindow:(NSWindow *)window
{
    if ([scrollWheel respondsToSelector:@selector(phase)]) {
        // 10.7...
        if ([scrollWheel phase] == NSEventPhaseNone) {
            goto old_action;
        }
        
        CGFloat foo = [scrollWheel scrollingDeltaX];
        CGFloat bar = [scrollWheel scrollingDeltaY];
        if (fabsf(foo) <= fabsf(bar)) { // Not horizontal
            goto old_action;
        }
        // If the user has disabled tracking scrolls as fluid swipes in system preferences, we should respect that.
        // NSScrollView will do this check for us, however, depending on where your controller is in the responder chain,
        // it may scrollWheel events that are not filtered by an NSScrollView.
        if (![NSEvent isSwipeTrackingFromScrollEventsEnabled]) {
            goto old_action;
        }

        BOOL goForward = (foo < 0);
        // Released by the tracking handler once the gesture is complete.
/*        HistoryOverlayController* historyOverlay =
        [[HistoryOverlayController alloc]
         initForMode:goForward ? kHistoryOverlayModeForward :
         kHistoryOverlayModeBack level:(NSScreenSaverWindowLevel + 1)];*/
        
        [scrollWheel trackSwipeEventWithOptions:NSEventSwipeTrackingClampGestureAmount
                 dampenAmountThresholdMin:-1
                                      max:1
                             usingHandler:^(CGFloat gestureAmount, NSUInteger phase, BOOL isComplete, BOOL *stop) {
                                 if (phase == NSEventPhaseBegan) {
//                                     [historyOverlay showPanelWithinRect:[_fullScreenWindow frame]];
                                     return;
                                 }
                                 
                                 if (phase == NSEventPhaseEnded) {
                                     if (goForward) {
                                         [self fullScreenShowNextImage:window modifierFlags:[scrollWheel modifierFlags]];
                                     } else {
                                         [self fullScreenShowPrevImage:window modifierFlags:[scrollWheel modifierFlags]];
                                     }
                                 }
//                                 [historyOverlay setProgress:gestureAmount];
                                 
                                 if (isComplete) {
//                                     [historyOverlay dismiss];
//                                     [historyOverlay release];
                                 }
                             }];
        return YES;
       
    }

old_action:
    {
    CGFloat dY = [scrollWheel deltaY];
    CGFloat threshold = [[BSIPIDefaults sharedIPIDefaults] fullScreenWheelAmount];

    if (dY < -1*threshold) { // 下回転で次のイメージへ
        return [self fullScreenShowNextImage:window modifierFlags:[scrollWheel modifierFlags]];
    }

    if (dY > threshold) { // 上回転で前のイメージへ
        return [self fullScreenShowPrevImage:window modifierFlags:[scrollWheel modifierFlags]];
    }
    }
    return YES;
}

- (BOOL)handlesSwipe:(NSEvent *)event inWindow:(NSWindow *)window
{
    CGFloat dX = [event deltaX];
    
    if (dX == 1.0) { // 右へスワイプ
        return [self fullScreenShowPrevImage:window modifierFlags:[event modifierFlags]];
    } else if (dX == -1.0) { // 左へスワイプ
        return [self fullScreenShowNextImage:window modifierFlags:[event modifierFlags]];
    }

    return YES;
}
@end
