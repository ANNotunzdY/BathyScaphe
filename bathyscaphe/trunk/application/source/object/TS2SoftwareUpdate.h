//
//  TS2SoftwareUpdate.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/03.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

enum {
    TS2SUCheckDaily = 1,
    TS2SUCheckWeekly,
    TS2SUCheckMonthly,
};
typedef NSUInteger TS2SoftwareUpdateIntervalType;

@interface TS2SoftwareUpdate : NSObject {
    NSURL           *ts2su_infoURL;
//    SEL             ts2su_openPrefsSelector;
    SEL             ts2su_updateNowSelector;

@private
    NSURLConnection *ts2su_connection;
    NSMutableData   *ts2su_receivedData;
    BOOL            ts2su_isChecking;
    BOOL            shouldShowsResult;
}
+ (id)sharedInstance;

+ (BOOL)showsDebugLog;
+ (void)setShowsDebugLog:(BOOL)showsLog;

- (NSURL *)updateInfoURL;
- (void)setUpdateInfoURL: (NSURL *) anURL;
//- (SEL)openPrefsSelector;
//- (void)setOpenPrefsSelector:(SEL)selector;
- (SEL)updateNowSelector;
- (void)setUpdateNowSelector:(SEL)selector;

- (BOOL)getSystemVersionMajor:(NSInteger *)major minor:(NSInteger *)minor bugFix:(NSInteger *)bugFix;

- (void)startUpdateCheck:(id)sender;
- (void)abortChecking;

- (BOOL)isChecking;
@end

// User Defaults Keys
extern NSString *const TS2SoftwareUpdateCheckKey;
extern NSString *const TS2SoftwareUpdateCheckIntervalKey;
extern NSString *const TS2SoftwareUpdateNotifyOnNextLaunchKey;
