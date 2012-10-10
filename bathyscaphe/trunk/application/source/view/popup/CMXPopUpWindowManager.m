//
//  CMXPopUpWindowManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/12/25.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMXPopUpWindowManager.h"
#import "CocoMonar_Prefix.h"
#import "CMXPopUpWindowController.h"
#import "AppDefaults.h"
#import "CMRPopUpTemplateKeys.h"



@implementation CMXPopUpWindowManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (void)dealloc
{
	[bs_controllersArray release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (NSMutableArray *)controllerArray
{
	if (!bs_controllersArray) {
		CFArrayCallBacks arrayCallBacks = kCFTypeArrayCallBacks;
		arrayCallBacks.retain = NULL;
		arrayCallBacks.release = NULL;
		bs_controllersArray = (NSMutableArray *)CFArrayCreateMutable(NULL, 0, &arrayCallBacks);
	}
	return bs_controllersArray;
}

- (CMXPopUpWindowController *)availableController
{
	CMXPopUpWindowController *controller_ = nil;
	NSMutableArray *array_= [self controllerArray];
	NSEnumerator *iter_ = [array_ objectEnumerator];
	
	while (controller_ = [iter_ nextObject]) {
		if ([controller_ canPopUpWindow]) {
			break;
		}
	}
	
	if (!controller_ || ![controller_ canPopUpWindow]) {
		// 
		// すべて使用中
		// 
		controller_ = [[CMXPopUpWindowController alloc] init];
		[controller_ window];

		[array_ addObject:controller_];
//        [controller_ release];
	}
	return controller_;
}

- (BOOL)isPopUpWindowVisible
{
    NSMutableArray *array = [self controllerArray];
    for (CMXPopUpWindowController *controller in array) {
        if (![controller canPopUpWindow]) {
            return YES;
        }
    }
	return NO;
}

- (CMXPopUpWindowController *)controllerForObject:(id)object
{
    NSMutableArray *array = [self controllerArray];
    for (CMXPopUpWindowController *controller in array) {
        if ([[controller object] isEqual:object]) {
            return controller;
        }
    }
	return nil;
}

- (NSWindow *)windowForObject:(id)object
{
	return [[self controllerForObject:object] window];
}

- (BOOL)popUpWindowIsVisibleForObject:(id)object
{
	return [[self windowForObject:object] isVisible];
}

#pragma mark PopUp or Close PopUp
- (id)showPopUpWindowWithContext:(NSAttributedString *)context
                       forObject:(id)object
                           owner:(id)owner
                    locationHint:(NSPoint)point
{
	CMXPopUpWindowController	*controller_;
	
	UTILAssertNotNilArgument(context, @"context");
    CMXPopUpWindowController *openedPopup = [self controllerForObject:object];
    if (openedPopup) {
        // 既に同一内容のポップアップが表示されていて、かつ、ロックされていないポップアップの場合は、ここで処理を終了する（重複ポップアップの発生を抑制）
        if (![openedPopup canPopUpWindow] && [openedPopup isClosable]) {
            if ([[openedPopup contextAsString] isEqualToString:[context string]]) {
                return nil;
            }
        }
    }
	controller_ = [self availableController];
	[controller_ setObject:object];

	// setup UI
	[controller_ setUsesSmallScroller:[self popUpUsesSmallScroller]];	
	[controller_ setShouldAntialias:[self popUpShouldAntialias]];
	[controller_ setLinkTextHasUnderline:[self popUpLinkTextHasUnderline]];
	[controller_ setTheme:[self theme]];

	[controller_ showPopUpWindowWithContext:context
					                  owner:owner
							   locationHint:point];
	return controller_;
}

- (void)closePopUpWindowForOwner:(id)owner
{
    NSMutableArray *array = [self controllerArray];
    for (CMXPopUpWindowController *controller in array) {
        if ([(id)[controller owner] isEqual:owner]) {
            [controller performClose];
        }
    }
}

- (BOOL)performClosePopUpWindowForObject:(id)object
{
	CGFloat insetWidth_;
	CMXPopUpWindowController *controller_;

	controller_ = [self controllerForObject:object];
	if (!controller_) {
		return NO;
	}
	insetWidth_ = [[controller_ class] popUpTrackingInsetWidth];
	if (![controller_ mouseInWindowFrameInset:-insetWidth_]) {
		[controller_ performClose];
		return YES;
	}
	return NO;
}

#pragma mark CMRPref Accessors
- (BOOL)popUpUsesSmallScroller
{
	return [CMRPref popUpWindowVerticalScrollerIsSmall];
}

- (BOOL)popUpShouldAntialias
{
	return [CMRPref shouldThreadAntialias];
}

- (BOOL)popUpLinkTextHasUnderline
{
	return [CMRPref hasMessageAnchorUnderline];
}

- (BSThreadViewTheme *)theme
{
	return [CMRPref threadViewTheme];
}
@end
