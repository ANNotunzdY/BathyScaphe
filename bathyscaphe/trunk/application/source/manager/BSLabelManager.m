//
//  BSLabelManager.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/08/15.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLabelManager.h"
#import "CocoMonar_Prefix.h"


NSString *const BSLabelManagerDidUpdateDisplayNamesNotification = @"BSLabelManagerDidUpdateDisplayNamesNotification";
NSString *const BSLabelManagerDidUpdateBackgroundColorsNotification = @"BSLabelManagerDidUpdateBackgroundColorsNotification";

static NSString *const kLabelsSettingFileName = @"Labels.plist";
static NSString *const kDisplayNameKey = @"DisplayName";
static NSString *const kBackgroundColorKey = @"BackgroundColor";

@interface BSLabelManager(Private)
- (NSImage *)drawImageWithName:(NSString *)imageName baseColor:(NSColor *)color highlighted:(BOOL)isHighlighted;
- (void)cacheLabelIconImages;
- (void)restoreFromFilename:(NSString *)filename;
@end


@implementation BSLabelManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (id)init
{
    if (self = [super init]) {
        [self loadFromFile];
    }
    return self;
}

- (void)dealloc
{
    [m_displayNames release];
    [m_backgroundColors release];
    [super dealloc];
}

- (void)loadFromFile
{
    NSBundle    *bundles[] = {
        [NSBundle applicationSpecificBundle], 
        [NSBundle mainBundle],
        nil};
    NSBundle    **p = bundles;
    NSString    *path = nil;
    
    for (; *p != nil; p++) {
        if ((path = [*p pathForResourceWithName:kLabelsSettingFileName])) {
            break;
        }
    }
    
    if (path) {
        NSArray *contents = [NSArray arrayWithContentsOfFile:path];
        m_displayNames = [[contents valueForKey:kDisplayNameKey] retain];
        if ([[contents objectAtIndex:0] objectForKey:kBackgroundColorKey]) { // カラーも記録されているファイル
            if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
                NSLog(@"** USER DEBUG ** Importing Color Data From Labels.plist");
            }
            NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:7];
            for (id obj in contents) {
                NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:[obj objectForKey:kBackgroundColorKey]];
                [colors addObject:color];
            }
            m_backgroundColors = colors;
        } else {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
                NSLog(@"** USER DEBUG ** No Color Data Included In Labels.plist");
            }            
            m_backgroundColors = [[NSArray alloc] initWithObjects:
                                  [NSColor colorWithCalibratedHue:318.0/360.0 saturation:0.47 brightness:0.91 alpha:1.0],
                                  [NSColor colorWithCalibratedHue:200.0/360.0 saturation:0.6 brightness:1.0 alpha:1.0],
                                  [NSColor colorWithCalibratedHue:153.0/360.0 saturation:0.48 brightness:0.97 alpha:1.0],
                                  [NSColor colorWithCalibratedHue:240.0/360.0 saturation:0.6 brightness:1.0 alpha:1.0],
                                  [NSColor colorWithCalibratedHue:40.0/360.0 saturation:0.6 brightness:1.0 alpha:1.0],
                                  [NSColor colorWithCalibratedHue:0.0 saturation:0.6 brightness:1.0 alpha:1.0],
                                  [NSColor colorWithCalibratedHue:80.0/360.0 saturation:0.0 brightness:0.7 alpha:1.0],
                                  nil];
        }
    } else {
        m_displayNames = [[NSArray alloc] initWithObjects:@"Mf", @"Mi", @"Va", @"Ch", @"Ap", @"Ra", @"Wo", nil];
        m_backgroundColors = [[NSArray alloc] initWithObjects:
                              [NSColor colorWithCalibratedHue:318.0/360.0 saturation:0.47 brightness:0.91 alpha:1.0],
                              [NSColor colorWithCalibratedHue:200.0/360.0 saturation:0.6 brightness:1.0 alpha:1.0],
                              [NSColor colorWithCalibratedHue:153.0/360.0 saturation:0.48 brightness:0.97 alpha:1.0],
                              [NSColor colorWithCalibratedHue:240.0/360.0 saturation:0.6 brightness:1.0 alpha:1.0],
                              [NSColor colorWithCalibratedHue:40.0/360.0 saturation:0.6 brightness:1.0 alpha:1.0],
                              [NSColor colorWithCalibratedHue:0.0 saturation:0.6 brightness:1.0 alpha:1.0],
                              [NSColor colorWithCalibratedHue:80.0/360.0 saturation:0.0 brightness:0.7 alpha:1.0],
                              nil];
    }
    [self cacheLabelIconImages];
}

- (void)saveToFile
{
    NSString *path = [[NSBundle applicationSpecificBundle] pathForResourceWithName:kLabelsSettingFileName];
    if (!path) {
        path = [[CMRFileManager defaultManager] supportFilepathWithName:kLabelsSettingFileName resolvingFileRef:NULL];
        if (!path) {
            return;
        }
    }

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:7];
    NSInteger i;
    for (i = 0; i < 7; i++) {
        NSString *name = [m_displayNames objectAtIndex:i];
        NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:[m_backgroundColors objectAtIndex:i]];
        [array addObject:[NSDictionary dictionaryWithObjectsAndKeys:name, kDisplayNameKey, colorData, kBackgroundColorKey, NULL]];
    }
    [array writeToFile:path atomically:YES];
}

- (void)restoreFinderSettings
{
    [self restoreFromFilename:@"Labels_Finder.plist"];
}

- (void)restoreGASettings
{
    [self restoreFromFilename:kLabelsSettingFileName];
}

- (NSArray *)displayNames
{
    return m_displayNames;
}

- (void)setDisplayNames:(NSArray *)array
{
  @synchronized(self) {
    [array retain];
    [m_displayNames release];
    m_displayNames = array;
    UTILNotifyName(BSLabelManagerDidUpdateDisplayNamesNotification);
  }
}

- (NSArray *)backgroundColors
{
    return m_backgroundColors;
}

- (void)setBackgroundColors:(NSArray *)array
{
  @synchronized(self) {
    [array retain];
    [m_backgroundColors release];
    m_backgroundColors = array;
    [self cacheLabelIconImages];
    UTILNotifyName(BSLabelManagerDidUpdateBackgroundColorsNotification);
  }
}
@end


@implementation BSLabelManager(Private)
- (NSImage *)drawImageWithName:(NSString *)imageName baseColor:(NSColor *)color highlighted:(BOOL)isHighlighted
{
    NSImage *currentImage = [NSImage imageNamed:imageName];
    if (currentImage) {
        [currentImage setName:nil];
    }
    NSImage *img = [[NSImage alloc] initWithSize:NSMakeSize(12, 12)];
    [img lockFocus];
    NSColor *iconColor = isHighlighted ? [color highlightWithLevel:0.5] : color;
    [iconColor set];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0, 0, 12, 12)] fill];
    [img unlockFocus];
    if (![img setName:imageName]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** Fail Registering Image Name");
        }
    }
    return [img autorelease];
}

- (void)cacheLabelIconImages
{
    NSInteger i;
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:7];
    NSMutableArray *arrayDisabled = [NSMutableArray arrayWithCapacity:7];

    [NSGraphicsContext saveGraphicsState];
    for (i = 0; i < 7; i++) {
        NSString *name = [NSString stringWithFormat:@"LabelIcon%ld", (long)(i + 1)];
        NSString *disabledName = [NSString stringWithFormat:@"LabelIconDisabled%ld", (long)(i + 1)];
        NSColor *color = [m_backgroundColors objectAtIndex:i];
        [array addObject:[self drawImageWithName:name baseColor:color highlighted:NO]];
        [arrayDisabled addObject:[self drawImageWithName:disabledName baseColor:color highlighted:YES]];
    }
    [NSGraphicsContext restoreGraphicsState];
    
    [array retain];
    [m_colorImages release];
    m_colorImages = array;
    
    [arrayDisabled retain];
    [m_disabledColorImages release];
    m_disabledColorImages = arrayDisabled;
}

- (void)restoreFromFilename:(NSString *)filename
{
    NSString *path = [[NSBundle mainBundle] pathForResourceWithName:filename];
    if (!path) {
        return;
    }
    NSArray *contents = [NSArray arrayWithContentsOfFile:path];
    [self setDisplayNames:[contents valueForKey:kDisplayNameKey]];
    NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:7];
    for (id obj in contents) {
        NSColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:[obj objectForKey:kBackgroundColorKey]];
        [colors addObject:color];
    }
    [self setBackgroundColors:colors];
    [colors release];
}
@end
