//
//  BSThemePreView.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 09/01/11.
//  Copyright 2009-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
@class BSThreadViewTheme;
@protocol PreferencesController;

@interface BSThemePreView : NSView {
	BSThreadViewTheme	*m_theme;
    id<PreferencesController> m_delegate;
}

- (BSThreadViewTheme *)theme;
- (void)setTheme:(BSThreadViewTheme *)aTheme;
- (void)setThemeWithoutNeedingDisplay:(BSThreadViewTheme *)aTheme;

@property(readwrite, assign) IBOutlet id<PreferencesController> delegate;
@end
