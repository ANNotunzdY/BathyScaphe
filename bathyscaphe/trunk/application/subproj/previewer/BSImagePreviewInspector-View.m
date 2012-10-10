//
//  BSImagePreviewInspector-View.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/07/15.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSImagePreviewInspector.h"
#import "BSIPITextFieldCell.h"
#import "BSIPIImageView.h"
#import "BSIPIDefaults.h"
#import <SGFoundation/NSDictionary-SGExtensions.h>
#import <SGFoundation/NSMutableDictionary-SGExtensions.h>
#import <SGAppKit/NSCell-SGExtensions.h>
#import <SGAppKit/NSWorkspace-SGExtensions.h>

static NSString *const kIPIFrameAutoSaveNameKey	= @"BathyScaphe:ImagePreviewInspector Panel Autosave";

@implementation BSImagePreviewInspector(ViewAccessor)
- (NSPopUpButton *)actionBtn
{
	return m_actionBtn;
}

- (NSTextField *)infoField
{
	return m_infoField;
}

- (NSImageView *)imageView
{
	return m_imageView;
}

- (NSProgressIndicator *)progIndicator
{
	return m_progIndicator;
}

- (NSSegmentedControl *)cacheNavigationControl
{
	return m_cacheNaviBtn;
}

- (NSTabView *)tabView
{
	return m_tabView;
}

- (NSSegmentedControl *)paneChangeBtn
{
	return m_paneChangeBtn;
}

- (NSTableColumn *)nameColumn
{
	return m_nameColumn;
}

- (NSMenu *)cacheNaviMenuFormRep
{
	return m_cacheNaviMenuFormRep;
}

- (BSIPIArrayController *)tripleGreenCubes
{
	return m_tripleGreenCubes;
}

#pragma mark Setup UIs
- (void)setupWindow
{
	NSWindow	*window_ = [self window];

    [window_ setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
    [window_ setContentBorderThickness:20 forEdge:NSMinYEdge];
	[window_ setFrameAutosaveName:kIPIFrameAutoSaveNameKey];
	[window_ setDelegate:self];
	[(NSPanel *)window_ setBecomesKeyOnlyIfNeeded:(![[BSIPIDefaults sharedIPIDefaults] alwaysBecomeKey])];
	[(NSPanel *)window_ setFloatingPanel:[[BSIPIDefaults sharedIPIDefaults] floating]];
	[window_ setAlphaValue:[[BSIPIDefaults sharedIPIDefaults] alphaValue]];
	[window_ useOptimizedDrawing:YES];
}

- (void)setupTableView
{
	BSIPITextFieldCell *cell;
	NSTableView	*tableView = [[self nameColumn] tableView];

	cell = [[BSIPITextFieldCell alloc] initTextCell:@""];
	[cell setAttributesFromCell:[[self nameColumn] dataCell]];
	[[self nameColumn] setDataCell:cell];
	[cell release];

	[tableView setDataSource:[BSIPIHistoryManager sharedManager]];
	[tableView setDoubleAction:@selector(changePaneAndShow:)];
	[tableView setVerticalMotionCanBeginDrag:NO];
}

- (void)setupControls
{
    [[[self paneChangeBtn] imageForSegment:0] setTemplate:YES];
    [[[self paneChangeBtn] imageForSegment:1] setTemplate:YES];

	[[self cacheNavigationControl] setLabel:nil forSegment:0];
	[[self cacheNavigationControl] setLabel:nil forSegment:1];
	
	[(BSIPIImageView *)[self imageView] setFocusRingType:NSFocusRingTypeNone];
	[(BSIPIImageView *)[self imageView] setDelegate:self];
	NSColor *color = [NSUnarchiver unarchiveObjectWithData:[[BSIPIDefaults sharedIPIDefaults] imageViewBgColorData]];
	[(BSIPIImageView *)[self imageView] setBackgroundColor:color];
	
	NSInteger	tabIndex = [[BSIPIDefaults sharedIPIDefaults] preferredView];
	if (tabIndex == -1) {
		tabIndex = [[BSIPIDefaults sharedIPIDefaults] lastShownViewTag];
	}
	[[self tabView] selectTabViewItemAtIndex:tabIndex];
	[[self paneChangeBtn] setSelectedSegment:tabIndex];

    [[m_infoField cell] setBackgroundStyle:NSBackgroundStyleRaised];
}

- (void)setupTimer
{
    NSView *containingView = [[[self window] contentView] superview];

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[containingView frame]
                                                        options:(NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect)
                                                          owner:self
                                                       userInfo:nil];
    [containingView addTrackingArea:area];
    [area release];

	[self setFadeOutTimer:[self timerForFadeOut]];
}    

- (void)windowDidLoad
{
	[self setupWindow];
	[self setupTableView];
	[self setupControls];
	[self setupToolbar];
    [self setupTimer];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == kBSIPIDefaultsContext) {
		if ([keyPath isEqualToString:@"alwaysBecomeKey"]) {
			BOOL newFlag = [change boolForKey:NSKeyValueChangeNewKey];
			[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:!newFlag];
			return;
		} else if ([keyPath isEqualToString:@"floating"]) {
			BOOL newFlag = [change boolForKey:NSKeyValueChangeNewKey];
			[(NSPanel *)[self window] setFloatingPanel:newFlag];
			return;
		} else if ([keyPath isEqualToString:@"alphaValue"]) {
			CGFloat newValue = [change floatForKey:NSKeyValueChangeNewKey];
			[[self window] setAlphaValue:newValue];
			return;
		} else if ([keyPath isEqualToString:@"imageViewBgColorData"]) {
			NSColor *newColor = [NSUnarchiver unarchiveObjectWithData:[change objectForKey:NSKeyValueChangeNewKey]];
			[(BSIPIImageView *)[self imageView] setBackgroundColor:newColor];
			return;
		} else if ([keyPath isEqualToString:@"autoCollectImages"]) {
            BOOL autoCollects = [change boolForKey:NSKeyValueChangeNewKey];
            NSToolbar *toolbar = [[self window] toolbar];
            NSArray *items = [toolbar visibleItems];
            for (NSToolbarItem *item in items) {
                if ([item tag] == 575) {
                    if ([item action] == @selector(saveImage:)) {
                        [(NSButton *)[item view] setImage:(autoCollects ? [NSImage imageNamed:NSImageNameRevealFreestandingTemplate] : [self imageResourceWithName:@"IPISaveTemplate"])];
                        [item setLabel:[self localizedStrForKey:(autoCollects ? @"Reveal" : @"Save")]];
                        [item setPaletteLabel:[self localizedStrForKey:(autoCollects ? @"RevealInFinder" : @"Save")]];
                        [item setToolTip:[self localizedStrForKey:(autoCollects ? @"RevealTip" : @"SaveTip")]];
                        break;
                    }
                }
            }
            return;
        }
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (NSTimer *)timerForFadeOut
{
    return [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(startFadeOut:) userInfo:nil repeats:NO];
}

-(void)mouseEntered:(NSEvent *)event
{
	[self setFadeOutTimer:nil];
	[[[self window] animator] setAlphaValue:1.0];
}

-(void)mouseExited:(NSEvent *)event
{
	[self setFadeOutTimer:[self timerForFadeOut]];    
}

-(void)startFadeOut:(NSTimer *)aTimer
{
    CGFloat outValue = [[BSIPIDefaults sharedIPIDefaults] alphaValue];
    if (outValue < 1.0) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[[self window] animator] setAlphaValue:[[BSIPIDefaults sharedIPIDefaults] alphaValue]];
        [NSAnimationContext endGrouping];
	}
	[self setFadeOutTimer:nil];
}

- (void)makeWindowOpaqueWithFade:(NSNotification *)notification
{
    if ([[BSIPIDefaults sharedIPIDefaults] alphaValue] == 1.0) {
        return;
    }
    if ([self isWindowLoaded] && [[self window] isVisible]) {
        [[[self window] animator] setAlphaValue:1.0];
        [self setFadeOutTimer:[self timerForFadeOut]];
    }
}
@end
