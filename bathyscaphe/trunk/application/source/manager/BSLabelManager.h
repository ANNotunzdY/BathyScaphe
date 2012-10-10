//
//  BSLabelManager.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/15.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSLabelManager : NSObject {
    @private
    NSArray *m_displayNames;
    NSArray *m_backgroundColors; // Array of NSColor objects
    NSArray *m_colorImages; // Array of NSImage objects
    NSArray *m_disabledColorImages; // Array of NSImage objects
}

+ (id)defaultManager;

- (void)loadFromFile;
- (void)saveToFile;

- (void)restoreGASettings;
- (void)restoreFinderSettings;

- (NSArray *)displayNames;
- (void)setDisplayNames:(NSArray *)array;

- (NSArray *)backgroundColors;
- (void)setBackgroundColors:(NSArray *)array;
@end

extern NSString *const BSLabelManagerDidUpdateDisplayNamesNotification;
extern NSString *const BSLabelManagerDidUpdateBackgroundColorsNotification;
