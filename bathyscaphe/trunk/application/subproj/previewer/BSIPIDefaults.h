//
//  BSIPIDefaults.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/08/31.
//  Copyright 2008-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class AppDefaults;

@interface BSIPIDefaults : NSObject {
	@private
	AppDefaults	*m_defaults;
}

+ (id)sharedIPIDefaults;

- (AppDefaults *)appDefaults;
- (void)setAppDefaults:(AppDefaults *)appDefaults;

- (BOOL)alwaysBecomeKey;
- (void)setAlwaysBecomeKey:(BOOL)alwaysKey;

- (NSString *)saveDirectory;
- (void)setSaveDirectory:(NSString *)aString;

- (CGFloat)alphaValue;
- (void)setAlphaValue:(CGFloat)newValue;

- (BOOL)resetWhenHide;
- (void)setResetWhenHide:(BOOL)reset;

- (BOOL)floating;
- (void)setFloating:(BOOL)floatOrNot;

- (NSInteger)preferredView;
- (void)setPreferredView:(NSInteger)aType;

- (NSInteger)lastShownViewTag;
- (void)setLastShownViewTag:(NSInteger)aTag;

- (BOOL)leaveFailedToken;
- (void)setLeaveFailedToken:(BOOL)leave;

- (CGFloat)fullScreenWheelAmount;
- (void)setFullScreenWheelAmount:(float)floatValue;

- (BOOL)useIKSlideShowOnLeopard;
- (void)setUseIKSlideShowOnLeopard:(BOOL)flag;

- (NSData *)fullScreenBgColorData;
- (void)setFullScreenBgColorData:(NSData *)aColorData;

- (NSData *)imageViewBgColorData;
- (void)setImageViewBgColorData:(NSData *)aColorData;

- (BOOL)autoCollectImages;
- (void)setAutoCollectImages:(BOOL)flag;

- (BOOL)tidyUpByDate;
- (void)setTidyUpByDate:(BOOL)flag;
@end

// For KVO
extern void *kBSIPIDefaultsContext;
