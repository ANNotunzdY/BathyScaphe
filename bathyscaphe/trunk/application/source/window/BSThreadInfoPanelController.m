//
//  BSThreadInfoPanelController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/01/20.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadInfoPanelController.h"
#import "CMRThreadViewer.h"
#import <CocoMonar/CocoMonar.h>
#import "BSLabelManager.h"

@implementation BSThreadInfoPanelController
static BOOL	g_isNonActivatingPanel = NO;

APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance);

+ (BOOL) nonActivatingPanel
{
	return g_isNonActivatingPanel;
}

+ (void) setNonActivatingPanel: (BOOL) nonActivating
{
	g_isNonActivatingPanel = nonActivating;
}

#pragma mark Override
- (id)init
{
	if (self = [super initWithWindowNibName:@"BSThreadInfoPanel"]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(mainWindowChanged:) name:NSWindowDidBecomeMainNotification object:nil];
        [nc addObserver:self selector:@selector(labelColorChanged:) name:BSLabelManagerDidUpdateBackgroundColorsNotification object:[BSLabelManager defaultManager]];
	}
	return self;
}

- (void)awakeFromNib
{
	[[self window] setFrameAutosaveName:@"BathyScaphe:Thread Info Panel Autosave"];
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:g_isNonActivatingPanel];
}

- (void)showWindow:(id)sender
{
	if ([self isWindowLoaded] && [[self window] isVisible] && [[self window] isKeyWindow]) {
		[[self window] orderOut:sender];
	} else {
		[super showWindow:sender];
		id winController_ = [[NSApp mainWindow] windowController];

		if (winController_ && [winController_ respondsToSelector:@selector(threadAttributes)]) {
			[m_greenCube bind:@"contentObject" toObject:winController_ withKeyPath:@"threadAttributes" options:nil];
		}
	}
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

#pragma mark Delegate and Notification
- (void)mainWindowChanged:(NSNotification *)aNotification
{
	if (![self isWindowLoaded] || ![[self window] isVisible]) {
        return;
    }
	id winController_ = [[aNotification object] windowController];

	if ([winController_ respondsToSelector:@selector(threadAttributes)]) {
		[m_greenCube unbind:@"contentObject"];
		[m_greenCube bind:@"contentObject" toObject:winController_ withKeyPath:@"threadAttributes" options:nil];
	}
}

- (void)labelColorChanged:(NSNotification *)aNotification
{
    NSInteger i;
    for (i = 1; i < 8; i++) {
        [m_labelChooser setImage:[NSImage imageNamed:[NSString stringWithFormat:@"LabelIcon%ld", (long)i]] forSegment:i];
    }
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[m_greenCube unbind:@"contentObject"];
}
@end
