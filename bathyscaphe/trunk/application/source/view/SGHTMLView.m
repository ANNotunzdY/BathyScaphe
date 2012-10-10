//
//  SGHTMLView.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/06.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGHTMLView_p.h"
#import "AppDefaults.h"
#import "CMRThreadLinkProcessor.h"
#import "CMRThreadSignature.h"

// for debugging only
#define UTIL_DEBUGGING              0
#import "UTILDebugging.h"

NSString *const SGHTMLViewMouseEnteredNotification = @"SGHTMLViewMouseEnteredNotification";
NSString *const SGHTMLViewMouseExitedNotification = @"SGHTMLViewMouseExitedNotification";

static NSString *const kThreadKeyBindingsFile = @"ThreadKeyBindings.plist";

static inline BOOL validateLinkForImage(id aLink);

#define MOUSE_CLICK_TRACKING_TIME   0.18


@implementation SGHTMLView
- (void)dealloc
{
    [self removeTrackingArea:[self visibleArea]];
    [self removeAllLinkTrackingRects];

    [super dealloc];
}

#pragma mark Overrides
- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self resetCursorRectsImp];
}

/*
2003-11-17 Takanori Ishikawa <takanori@gd5.so-net.ne.jp>
------------------------------------------------------------
- [NSTextView mouseEntered:]
- [NSTextView mouseExited:]
は何故か、- [NSWindow setAcceptsMouseMovedEvents:] を呼ぶ実装になっている。
acceptsMouseMovedEvents == YES だと resetCursorRects が頻繁に呼ばれる
ので、super のメソッドは実行しない。
*/
- (void)mouseEntered:(NSEvent *)theEvent
{
//  [super mouseEntered:theEvent];
    [self responseMouseEvent:theEvent mouseEntered:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
//  [super mouseExited:theEvent];
    [self responseMouseEvent:theEvent mouseEntered:NO];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSPoint         mouseLocation_;
    NSEventType     type_;
    id              link_;
    NSRange         effectiveRange_;
    
    UTILRequireCondition(theEvent != nil, default_menu);
    
    type_ = [theEvent type];
    UTILRequireCondition(
        NSLeftMouseDown == type_ || 
        NSRightMouseDown == type_ || 
        NSOtherMouseDown == type_,
        default_menu);
    
    mouseLocation_ = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    // Link Menu:
    // ==========================================
    // リンクをクリックした場合はリンク全体を選択
    // リンク専用のメニューも追加
    link_ = [self attribute:NSLinkAttributeName atPoint:mouseLocation_ effectiveRange:&effectiveRange_];
    UTILRequireCondition([self validateLinkByFiltering:link_], default_menu);
    
    [self setSelectedRange:effectiveRange_];
    return [self linkMenuWithLink:link_];

default_menu:
    return [self menu];
}

- (id<SGHTMLViewDelegate>)delegate
{
    return (id<SGHTMLViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<SGHTMLViewDelegate>)aDelegate
{
    [super setDelegate:aDelegate];
}

#pragma mark Key Binding Support
+ (SGKeyBindingSupport *)keyBindingSupport
{
    static SGKeyBindingSupport *stKeyBindingSupport_;
    
    if (!stKeyBindingSupport_) {
        NSDictionary    *dict;
        
        dict = [NSBundle mergedDictionaryWithName:kThreadKeyBindingsFile];
        UTILAssertKindOfClass(dict, NSDictionary);
        
        stKeyBindingSupport_ = [[SGKeyBindingSupport alloc] initWithDictionary:dict];
    }
    return stKeyBindingSupport_;
}

- (void)interpretKeyEvents:(NSArray *)eventArray
{
    id  targets_[] = {
            self,
            [self window],
            NULL
        };
    
    id  *p;

    for (p = targets_; *p != NULL; p++) {
        if ([[[self class] keyBindingSupport] 
                interpretKeyBindings:eventArray target:*p]) {
            return;
        }
    }
    
    [super interpretKeyEvents:eventArray];
}

#pragma mark Mouse Actions
- (BOOL)mouseClicked:(NSEvent *)theEvent atIndex:(NSUInteger)charIndex
{
    id<SGHTMLViewDelegate> delegate_ = [self delegate];
    SEL selector_ = @selector(HTMLView:mouseClicked:atIndex:);

    if (delegate_ && [delegate_ respondsToSelector:selector_]) {
        return [delegate_ HTMLView:self mouseClicked:theEvent atIndex:charIndex];
    }
    return NO;
}

- (BOOL)mouseClicked:(NSEvent *)theEvent
{
    NSPoint     mouseLocation_;
    NSUInteger  charIndex_;
    
    mouseLocation_ = [theEvent locationInWindow];
    mouseLocation_ = [[self window] convertBaseToScreen:mouseLocation_];

    charIndex_ = [self characterIndexForPoint:mouseLocation_];
    // characterIndexForPoint: は見つからないとき、0 を返す。
    if (charIndex_ != NSNotFound && charIndex_ < [[self string] length])
        return [self mouseClicked:theEvent atIndex:charIndex_];
    
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSEventType         type;
    NSUInteger      modifierFlags_;
    
    NSEvent             *nextEvent_;
    NSUInteger      eventMask_;
    
    if (!theEvent) return;
    
    type = [theEvent type];
    modifierFlags_ = [theEvent modifierFlags];
    
    if (NSCommandKeyMask & modifierFlags_) {
        [self commandMouseDown:theEvent];
        return;
    }

    if ([self shouldHandleContinuousMouseDown:theEvent]) {
//      NSNumber    *interval_;
        double      doubleInterval;
        
        eventMask_ = (  NSLeftMouseUpMask | 
                        NSLeftMouseDraggedMask | 
                        NSPeriodicMask);
        
//      interval_ = [NSNumber numberWithFloat:[CMRPref mouseDownTrackingTime]];
//      UTILAssertKindOfClass(interval_, NSNumber);
//      doubleInterval = [interval_ doubleValue];
        doubleInterval = [CMRPref mouseDownTrackingTime];
        [NSEvent startPeriodicEventsAfterDelay:doubleInterval withPeriod:doubleInterval];
        nextEvent_ = [[self window] nextEventMatchingMask:eventMask_
                                                untilDate:[NSDate distantFuture]
                                                   inMode:NSEventTrackingRunLoopMode
                                                  dequeue:NO];
        
        [NSEvent stopPeriodicEvents];

        if (nextEvent_ && NSPeriodic == [nextEvent_ type]) {
            if ([self handleContinuousMouseDown:nextEvent_]) {
                return;
            }
        }
    }
    if (NSLeftMouseDown == type){
        NSEvent     *nextEvent_;
        NSUInteger  eventMask_;
        
        eventMask_ = (NSLeftMouseUpMask | NSLeftMouseDraggedMask);
        nextEvent_ = [[self window] nextEventMatchingMask:eventMask_
                                                untilDate:[NSDate dateWithTimeIntervalSinceNow:MOUSE_CLICK_TRACKING_TIME]
                                                   inMode:NSEventTrackingRunLoopMode
                                                  dequeue:NO];
        type = [nextEvent_ type];
        if (NSLeftMouseUp == type) {
            if ([self mouseClicked:nextEvent_])
                return;
        }
    }

    [super mouseDown:theEvent];
}
@end


@implementation SGHTMLView(CMRLocalizableStringsOwner)
+ (NSString *)localizableStringsTableName
{
    return kLocalizableFile;
}
@end


@implementation SGHTMLView(ResponderExtensions)
- (NSArray *)HTMLViewFilteringLinkSchemes:(SGHTMLView *)aView
{
    id<SGHTMLViewDelegate> delegate_;

    delegate_ = [aView delegate];
    if (!delegate_ || ![delegate_ respondsToSelector:_cmd]) {
        return nil;
    }
    return [delegate_ HTMLViewFilteringLinkSchemes:aView];
}

- (NSMenuItem *)commandItemWithLink:(id)aLink command:(Class)aFunctorClass title:(NSString *)aTitle
{
    NSString        *linkstr_;
    NSMenuItem      *menuItem_;
    id              cmd_;
    
    UTILAssertConformsTo(aFunctorClass, @protocol(SGFunctor));

    linkstr_ = [aLink respondsToSelector:@selector(absoluteString)]
                ? [aLink absoluteString]
                : [aLink description];
    cmd_ = [aFunctorClass functorWithObject:linkstr_];
    if ([cmd_ respondsToSelector:@selector(setRefererThreadInfo:)] && [[[self window] windowController] respondsToSelector:@selector(refererThreadInfoForLinkDownloader)]) {
        [cmd_ setRefererThreadInfo:[[[self window] windowController] refererThreadInfoForLinkDownloader]];
    }
    menuItem_ = [[NSMenuItem alloc] initWithTitle:aTitle action:@selector(execute:) keyEquivalent:@""];
    [menuItem_ setRepresentedObject:cmd_];
    [menuItem_ setTarget:cmd_];
    [menuItem_ setEnabled:YES];

    return [menuItem_ autorelease];
}

- (NSMenu *)linkMenuWithLink:(id)aLink
{
    NSString        *title_;
    NSMenu          *menu_;
    NSMenuItem      *menuItem_;
    NSString *boardName;
    CMRThreadSignature *signature;
    
    title_ = [self localizedString:kLinkStringKey];
    menu_ = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:title_];

    // リンクをコピー
    title_ = [self localizedString:kCopyLinkStringKey];
    menuItem_ = [self commandItemWithLink:aLink command:[SGCopyLinkCommand class] title:title_];
    [menu_ addItem:menuItem_];
    
    // リンクを開く
    title_ = [self localizedString:kOpenLinkStringKey];
    menuItem_ = [self commandItemWithLink:aLink command:[SGOpenLinkCommand class] title:title_];
    [menu_ addItem:menuItem_];
    
    if ([CMRThreadLinkProcessor parseThreadLink:aLink boardName:&boardName threadSignature:&signature]) {
        BOOL isDir;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[signature threadDocumentPath] isDirectory:&isDir] && !isDir) {
            menuItem_ = [[NSMenuItem alloc] initWithTitle:[self localizedString:@"Pass from this link"] action:@selector(passLinkerCoreFromLink:) keyEquivalent:@""];
            [menuItem_ setRepresentedObject:signature];
            [menuItem_ setTarget:nil];
            [menuItem_ setEnabled:YES];
            [menu_ addItem:menuItem_];
            [menuItem_ release];
        } else {
            NSLog(@"Log file does not exist");
        }
    } else {
    
        if (validateLinkForImage(aLink)) {
            // リンクをプレビュー
            title_ = [self localizedString:kPreviewLinkStringKey];
            menuItem_ = [self commandItemWithLink:aLink command:[SGPreviewLinkCommand class] title:title_];
            [menu_ addItem:menuItem_];
        }

        // リンク先をダウンロード
        title_ = [self localizedString:kDownloadLinkStringKey];
        menuItem_ = [self commandItemWithLink:aLink command:[SGDownloadLinkCommand class] title:title_];
        [menu_ addItem:menuItem_];
    }

    return [menu_ autorelease];
}

- (BOOL)validateLinkByFiltering:(id)aLink
{
    NSArray         *filter_;
    NSString        *scheme_;
    NSURL           *url_;
    
    if (!aLink) return NO;
    
    url_ = [NSURL URLWithLink:aLink];
    if (!url_) return NO;
    filter_ = [self HTMLViewFilteringLinkSchemes:self];
    if (!filter_) return YES;
    
    scheme_ = [url_ scheme];
    return (NO == [filter_ containsObject:scheme_]);
}

static inline BOOL validateLinkForImage(id aLink)
{
    if (!aLink) {
        return NO;
    }
    NSURL *url_ = [NSURL URLWithLink:aLink];
    if (!url_) {
        return NO;
    }
    id<BSLinkPreviewing> previewer = [CMRPref sharedLinkPreviewer];
    if (previewer) {
        return [previewer validateLink:url_];
    } else {
        id<BSImagePreviewerProtocol> oldPreviewer = [CMRPref sharedImagePreviewer];
        if (oldPreviewer) {
            return [oldPreviewer validateLink:url_];
        }
    }
    return NO;
}

- (NSArray *)linksArrayForRange:(NSRange)range_
{
    NSTextStorage   *storage_ = [self textStorage]; 

    if (NSNotFound == range_.location || NSMaxRange(range_) > [storage_ length]) {
        return nil;
    }

    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSUInteger      charIndex_;
    id              v;
    NSRange         effectiveRange_;

    charIndex_ = range_.location;
    while (charIndex_ < NSMaxRange(range_)) {
        v = [storage_ attribute:NSLinkAttributeName
                        atIndex:charIndex_
          longestEffectiveRange:&effectiveRange_
                        inRange:range_];
        if (v && [self validateLinkByFiltering:v]) {
            [array addObject:[NSURL URLWithLink:v]];
        }
        charIndex_ = NSMaxRange(effectiveRange_);
    }

    if ([array count] == 0) {
        [array release];
        return nil;
    } else {
        return [array autorelease];
    }
}

- (NSArray *)previewlinksArrayForRange:(NSRange)range_
{
    NSTextStorage   *storage_ = [self textStorage]; 

    if (NSNotFound == range_.location || NSMaxRange(range_) > [storage_ length]) {
        return nil;
    }

    __block NSMutableArray *array = [[NSMutableArray alloc] init];
/*    NSUInteger      charIndex_;
    id              v;
    NSRange         effectiveRange_;

    charIndex_ = range_.location;
    while (charIndex_ < NSMaxRange(range_)) {
        v = [storage_ attribute:NSLinkAttributeName
                        atIndex:charIndex_
          longestEffectiveRange:&effectiveRange_
                        inRange:range_];
        if (v && validateLinkForImage(v)) {
            [array addObject:[NSURL URLWithLink:v]];
        }
        charIndex_ = NSMaxRange(effectiveRange_);
    }*/
    [storage_ enumerateAttribute:NSLinkAttributeName inRange:range_ options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (validateLinkForImage(value)) {
            [array addObject:[NSURL URLWithLink:value]];
        }
    }];

    if ([array count] == 0) {
        [array release];
        return nil;
    } else {
        return [array autorelease];
    }
}

#pragma mark Command-Dragging Support
- (void)pushCloseHandCursorIfNeeded
{
    NSCursor    *cursor_;
    
    cursor_ = [NSCursor currentCursor];
    if (cursor_ == [NSCursor openHandCursor]) {
        [cursor_ pop];
        [[NSCursor closedHandCursor] push];
    }
}

- (void)commandMouseDragged:(NSEvent *)theEvent
{
    NSPoint     newOrigin_;
    NSRect      bounds_;
    CGFloat     deltaY_;

    [self pushCloseHandCursorIfNeeded];
    
    deltaY_ = [theEvent deltaY];
    bounds_ = [self visibleRect];
    newOrigin_ = bounds_.origin;
    
    if (deltaY_ > newOrigin_.y) return;
    newOrigin_.y -= deltaY_;
    
    [self scrollPoint:newOrigin_];
}

- (void)commandMouseUp:(NSEvent *)theEvent
{
    NSCursor    *cursor_;   
    
    cursor_ = [NSCursor currentCursor];
    if (cursor_ != [NSCursor closedHandCursor] && cursor_ != [NSCursor openHandCursor]) {
        return;
    }

    [cursor_ pop];
}

- (void)commandMouseDown:(NSEvent *)theEvent
{
    BOOL    keepOn_     = YES;
    BOOL    isInside_   = YES;
    NSPoint mouseLocation_;

    [[NSCursor openHandCursor] push];

    while (keepOn_) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask)];
        mouseLocation_ = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        isInside_ = [self mouse:mouseLocation_ inRect:[self bounds]];

        switch([theEvent type]) {
            case NSLeftMouseDragged:
                [self commandMouseDragged:theEvent];
                break;
            case NSLeftMouseUp:
                if (isInside_) [self commandMouseUp:theEvent];
                keepOn_ = NO;
                break;
            default:
                /* Ignore any other kind of event. */
                break;
        }
    };

    return;
}
@end
