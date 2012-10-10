//
//  BSIPILeopardSlideshowHelper.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/12.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPILeopardSlideshowHelper.h"
#import <CocoMonar/CMRSingletonObject.h>


@implementation BSIPILeopardSlideshowHelper
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance)

- (void)dealloc
{
	m_cube = nil;
	[super dealloc];
}

#pragma mark Accessors
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

#pragma mark Public Method
- (void)startSlideshow
{
	NSUInteger selectionIdx = [[self arrayController] selectionIndex];
	if (selectionIdx == NSNotFound) {
		[[self arrayController] setSelectionIndex:0];
		selectionIdx = 0;
	}

	NSNumber *no = [NSNumber numberWithBool:NO];
	NSNumber *yes = [NSNumber numberWithBool:YES];
	NSNumber *idx = [NSNumber numberWithUnsignedInteger:selectionIdx];

	IKSlideshow	*slideshow = [IKSlideshow sharedSlideshow];

	slideshow.autoPlayDelay = 5.0;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:yes, IKSlideshowWrapAround,
																	    no, IKSlideshowStartPaused,
																	   idx, IKSlideshowStartIndex,
																	   NULL];

	[slideshow runSlideshowWithDataSource:self inMode:IKSlideshowModeImages options:options];
}

#pragma mark IKSlideshowDataSource Protocol
- (NSUInteger)numberOfSlideshowItems
{
	return [[[self arrayController] arrangedObjects] count];
}

- (id)slideshowItemAtIndex:(NSUInteger)index
{
	return [[[[self arrayController] arrangedObjects] objectAtIndex:index] valueForKey:@"downloadedFilePath"];
}

- (void)slideshowDidChangeCurrentIndex:(NSUInteger)newIndex
{
	[[self arrayController] setSelectionIndex:newIndex];
}
@end
