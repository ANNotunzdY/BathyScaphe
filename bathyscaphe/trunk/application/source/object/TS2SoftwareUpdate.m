//
//  TS2SoftwareUpdate.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/03.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "TS2SoftwareUpdate.h"
#import <Carbon/Carbon.h>

NSString *const TS2SoftwareUpdateCheckKey = @"TS2SoftwareUpdateCheck";
NSString *const TS2SoftwareUpdateCheckIntervalKey = @"TS2SoftwareUpdateCheckInterval";
NSString *const TS2SoftwareUpdateNotifyOnNextLaunchKey = @"TS2SoftwareUpdateNotifyOnNextLaunch";
static NSString *const TS2SoftwareUpdateLastCheckedDateKey = @"TS2SoftwareUpdateLastCheckedDate";

@implementation TS2SoftwareUpdate
static id sharedTS2SUInstance = nil;
static BOOL g_showsLog = NO;

#pragma mark Overrides 
+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (!sharedTS2SUInstance) {
            sharedTS2SUInstance = [super allocWithZone:zone];
            return sharedTS2SUInstance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
// #warning 64BIT: Inspect use of MAX/MIN constant; consider one of LONG_MAX/LONG_MIN/ULONG_MAX/DBL_MAX/DBL_MIN, or better yet, NSIntegerMax/Min, NSUIntegerMax, CGFLOAT_MAX/MIN
// 2010-03-21 tsawada2 修正済
    return NSUIntegerMax;
}

- (oneway void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

- (void)dealloc
{
    [ts2su_connection release];
    [ts2su_receivedData release];
    [ts2su_infoURL release];
    [super dealloc];
}

+ (NSInteger)version
{
    return 4;
}

#pragma mark Accessors
- (NSURLConnection *)connection
{
    return ts2su_connection;
}

- (void)setConnection:(NSURLConnection *)aConnection
{
    [aConnection retain];
    [ts2su_connection release];
    ts2su_connection = aConnection;
}
/*
- (SEL)openPrefsSelector
{
    return ts2su_openPrefsSelector;
}

- (void)setOpenPrefsSelector:(SEL)selector
{
    ts2su_openPrefsSelector = selector;
}
*/
- (SEL)updateNowSelector
{
    return ts2su_updateNowSelector;
}

- (void)setUpdateNowSelector:(SEL)selector
{
    ts2su_updateNowSelector = selector;
}

+ (BOOL)showsDebugLog
{
    return g_showsLog;
}

+ (void)setShowsDebugLog:(BOOL)showsLog
{
    g_showsLog = showsLog;
}

- (NSMutableData *)receivedData
{
    if (!ts2su_receivedData) {
        ts2su_receivedData = [[NSMutableData alloc] init];
    }
    return ts2su_receivedData;
}

- (NSURL *)updateInfoURL
{
    return ts2su_infoURL;
}

- (void)setUpdateInfoURL:(NSURL *)anURL
{
    [anURL retain];
    [ts2su_infoURL release];
    ts2su_infoURL = anURL;
}

- (BOOL)isChecking
{
    return ts2su_isChecking;
}

- (void)setIsChecking:(BOOL)boolValue
{
    ts2su_isChecking = boolValue;
}

#pragma mark Private Methods
- (NSString *)applicationName
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
}

- (NSString *)userAgentString
{
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 修正済
    return [NSString stringWithFormat:@"TS2SoftwareUpdate/%ld %@/%@", (long)[[self class] version], [self applicationName], appVersion];
}

- (void)showUpdateIsAvailableAlert
{
    NSString *appName = [self applicationName];
    NSString *updateBtnName = NSLocalizedStringFromTable(@"Update Now", @"SoftwareUpdate", @"");
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle: NSCriticalAlertStyle];

// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 検証済
    NSString *msg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"NewVerIsAvailableAlertMsg", @"SoftwareUpdate", @""), appName];
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 検証済
    NSString *info = [NSString stringWithFormat:NSLocalizedStringFromTable(@"NewVerIsAvailableAlertInfo", @"SoftwareUpdate", @""), updateBtnName];
    [alert setMessageText:msg];
    [alert setInformativeText:info];
    [alert addButtonWithTitle:updateBtnName];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ask Again Later", @"SoftwareUpdate", @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Skip Update", @"SoftwareUpdate", @"")];

    NSInteger returnCode = [alert runModal];
    
    if (returnCode == NSAlertFirstButtonReturn) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:TS2SoftwareUpdateNotifyOnNextLaunchKey];
        [NSApp sendAction:[self updateNowSelector] to:nil from:self];
    } else if (returnCode == NSAlertThirdButtonReturn) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:TS2SoftwareUpdateNotifyOnNextLaunchKey];
//      [NSApp sendAction:[self openPrefsSelector] to:nil from:self];
    }
}

- (void)showErrorAlert
{
    NSAlert *alert_ = [[[NSAlert alloc] init] autorelease];
    [alert_ setAlertStyle:NSWarningAlertStyle];
    [alert_ setMessageText:NSLocalizedStringFromTable(@"FailedToCheckAlertMsg", @"SoftwareUpdate", @"")];
    [alert_ setInformativeText:NSLocalizedStringFromTable(@"FailedToCheckAlertInfo", @"SoftwareUpdate", @"")];
    [alert_ addButtonWithTitle:NSLocalizedStringFromTable(@"OK", @"SoftwareUpdate", @"")];
    [alert_ runModal];
}

- (void)showThisIsUpToDateAlert
{
    NSInteger majorVersion, minorVersion, bugFixVersion;
    NSString *appName = [self applicationName];
    NSString *info;
    if ([self getSystemVersionMajor:&majorVersion minor:&minorVersion bugFix:&bugFixVersion]) {
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 修正済
        info = [NSString stringWithFormat:NSLocalizedStringFromTable(@"UpToDateAlertInfo", @"SoftwareUpdate", @""),
                (long)majorVersion, (long)minorVersion, (long)bugFixVersion, appName];
    } else {
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 検証済
        info = [NSString stringWithFormat:NSLocalizedStringFromTable(@"UpToDateAlertInfo2", @"SoftwareUpdate", @""), appName];
    }
    NSAlert *alert_ = [[[NSAlert alloc] init] autorelease];
    [alert_ setAlertStyle:NSInformationalAlertStyle];
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 検証済
    [alert_ setMessageText:[NSString stringWithFormat:NSLocalizedStringFromTable(@"UpToDateAlertMsg", @"SoftwareUpdate", @""), appName]];
    [alert_ setInformativeText:info];
    [alert_ addButtonWithTitle:NSLocalizedStringFromTable(@"OK", @"SoftwareUpdate", @"")];
    [alert_ runModal];
}

- (BOOL)shouldCheck:(id)sender
{
    if ([self isChecking]) {
        return NO;
    }
    NSUserDefaults *defaults_ = [NSUserDefaults standardUserDefaults];
    NSNumber *readyNum = [defaults_ objectForKey:TS2SoftwareUpdateNotifyOnNextLaunchKey];
    if (readyNum && [readyNum boolValue]) {
        [self showUpdateIsAvailableAlert];
        return NO;
    }
    
    if (sender) {
        return YES; // 自動チェックの場合は設定による（以下で判定）が、手動チェックはいつでも出来る
    }
    NSNumber *autoCheckNum = [defaults_ objectForKey:TS2SoftwareUpdateCheckKey];
    if (!autoCheckNum || ![autoCheckNum boolValue]) {
        return NO;
    }
    
    NSNumber *intervalNum = [defaults_ objectForKey:TS2SoftwareUpdateCheckIntervalKey];
    NSInteger interval = [intervalNum integerValue];
    NSDate *lastDate = [defaults_ objectForKey:TS2SoftwareUpdateLastCheckedDateKey];
    if (!lastDate) {
        return YES;
    } else {
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:lastDate];
        NSTimeInterval value_;
        switch (interval) {
        case TS2SUCheckDaily:
            value_ = 60*60*24;
            break;
        case TS2SUCheckWeekly:
            value_ = 60*60*24*7;
            break;
        case TS2SUCheckMonthly:
            value_ = 60*60*24*30;
            break;
        default:
            value_ = 60*60*24*7;
            break;
        }
        return (timeInterval > value_);
    }
    return NO;
}

- (BOOL)satisfyOSVersion:(NSArray *)requiredVersionInfo
{
    if (!requiredVersionInfo) {
        if (g_showsLog) {
            NSLog(@"(TS2SoftwareUpdate) No MinimumSystemVersion entry.");
        }
        return YES;
    }

    NSInteger majorVersion, minorVersion, bugFixVersion;
    if ([self getSystemVersionMajor:&majorVersion minor:&minorVersion bugFix:&bugFixVersion]) {
        if (g_showsLog) {
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 修正済
            NSLog(@"(TS2SoftwareUpdate) Mac OS X Version: %ld.%ld.%ld", (long)majorVersion, (long)minorVersion, (long)bugFixVersion);
        }
        NSInteger requiredMajor, requiredMinor, requiredBugFix;
        requiredMajor = [(NSNumber *)[requiredVersionInfo objectAtIndex:0] integerValue];
        requiredMinor = [(NSNumber *)[requiredVersionInfo objectAtIndex:1] integerValue];
        requiredBugFix = [(NSNumber *)[requiredVersionInfo objectAtIndex:2] integerValue];
        if (g_showsLog) {
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 修正済
            NSLog(@"(TS2SoftwareUpdate) Required Version: %ld.%ld.%ld", (long)requiredMajor, (long)requiredMinor, (long)requiredBugFix);
        }
        if (majorVersion < requiredMajor) {
            return NO;
        }
        if (minorVersion < requiredMinor) {
            return NO;
        }
        if (bugFixVersion < requiredBugFix) {
            return NO;
        }
    } else {
        if (g_showsLog) {
            NSLog(@"(TS2SoftwareUpdate) Mac OS X version is less than 10.4.0, or some error.");
        }
    }
    return YES;
}

#pragma mark Public Methods
+ (id)sharedInstance
{
    @synchronized(self) {
        if (!sharedTS2SUInstance) {
            [[self alloc] init];
        }
    }
    return sharedTS2SUInstance;
}

- (BOOL)getSystemVersionMajor:(NSInteger *)major minor:(NSInteger *)minor bugFix:(NSInteger *)bugFix
{
    OSErr err;
    SInt32 systemVersion, versionMajor, versionMinor, versionBugFix;
    if ((err = Gestalt(gestaltSystemVersion, &systemVersion)) != noErr) return NO;
    if (systemVersion < 0x1040) {
        // Too old system. (10.3.9 or earlier)
        return NO;
    } else {
        if ((err = Gestalt(gestaltSystemVersionMajor, &versionMajor)) != noErr) return NO;
        if ((err = Gestalt(gestaltSystemVersionMinor, &versionMinor)) != noErr) return NO;
        if ((err = Gestalt(gestaltSystemVersionBugFix, &versionBugFix)) != noErr) return NO;
        if (major) *major = versionMajor;
        if (minor) *minor = versionMinor;
        if (bugFix) *bugFix = versionBugFix;
    }

    return YES;
}

- (void)startUpdateCheck:(id)sender
{
    if (![self shouldCheck:sender]) {
        return;
    }
    NSMutableURLRequest *req;
    NSURLConnection     *tmpConnection;
    NSString            *uaStr;

    req = [NSMutableURLRequest requestWithURL:[self updateInfoURL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
    uaStr = [self userAgentString];
    [req setValue:uaStr forHTTPHeaderField:@"User-Agent"];
    if (g_showsLog) {
        NSLog(@"(TS2SoftwareUpdate) User-Agent: %@", uaStr);
    }
    tmpConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    [self setConnection:tmpConnection];
    [tmpConnection release];
    [self setIsChecking:YES];
    shouldShowsResult = (sender != nil);
}

- (void)abortChecking
{
    if (![self isChecking]) {
        return;
    }
    if ([self connection]) {
        [[self connection] cancel];
        [self setConnection:nil];
    }

    [ts2su_receivedData release];
    ts2su_receivedData = nil;

    [self setIsChecking:NO];
    NSBeep();
}

#pragma mark NSURLConnection Delegates
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)resp
{
    NSHTTPURLResponse *http = (NSHTTPURLResponse *)resp;
    NSInteger status = [http statusCode];
    if (g_showsLog) {
// #warning 64BIT: Check formatting arguments
// 2010-03-21 tsawada2 修正済
        NSLog(@"(TS2SoftwareUpdate) HTTP Status: %ld", (long)status);
    }

    switch (status) {
    case 200:
        break;
    default:
        [connection cancel];
        [self setConnection:nil];
        [self setIsChecking:NO];

        [self showErrorAlert];
        break;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self receivedData] appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [ts2su_receivedData release];
    ts2su_receivedData = nil;

    [self setConnection:nil];
    [self setIsChecking:NO];

    if (!shouldShowsResult && [[error domain] isEqualToString:NSURLErrorDomain] && ([error code] == NSURLErrorNotConnectedToInternet)) {
        if (g_showsLog) {
            NSLog(@"(TS2SoftwareUpdate) %@", [error localizedDescription]);
        }
    } else {
        [self showErrorAlert];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *errorStr = nil;
    id plist_ = [NSPropertyListSerialization propertyListFromData:[self receivedData]
                                                 mutabilityOption:NSPropertyListImmutable
                                                           format:NULL
                                                 errorDescription:&errorStr];
    if (!plist_) { // Error
        if (g_showsLog) {
            NSLog(@"(TS2SoftWareUpdate) Error: Failed to convert received data to property list.");
        }
        [self showErrorAlert];
    } else {
        if (g_showsLog) {
            NSLog(@"(TS2SoftWareUpdate) ConnectionDidFinishLoading: Successfully Converted To Plist Object.");
        }
        NSUserDefaults *defaults_ = [NSUserDefaults standardUserDefaults];
        NSString *identifier_ = [plist_ objectForKey:@"BundleIdentifier"];
        NSDate *releasedDate_ = [plist_ objectForKey:@"ReleasedDate"];
        NSArray *requiredVersionInfo = [plist_ objectForKey:@"MinimumSystemVersion"];

        NSBundle *myself = [NSBundle mainBundle];
//        NSDictionary *fileAttr = [[NSFileManager defaultManager] fileAttributesAtPath:[myself executablePath] traverseLink:YES];
        NSDictionary *fileAttr = [[NSFileManager defaultManager] attributesOfItemAtPath:[myself executablePath] error:NULL];
        NSDate *createdDate = [fileAttr objectForKey:@"NSFileCreationDate"];

        if ([identifier_ isEqualToString:[myself bundleIdentifier]]) {
            if ([releasedDate_ compare:createdDate] == NSOrderedDescending) {
                if ([self satisfyOSVersion:requiredVersionInfo]) {
                    [defaults_ setObject:[NSNumber numberWithBool:YES] forKey:TS2SoftwareUpdateNotifyOnNextLaunchKey];
                    if (shouldShowsResult) {
                        [self showUpdateIsAvailableAlert];
                    }
                } else {
                    [defaults_ removeObjectForKey:TS2SoftwareUpdateNotifyOnNextLaunchKey];
                    if (shouldShowsResult) {
                        [self showThisIsUpToDateAlert];
                    }
                }
            } else {
                [defaults_ removeObjectForKey:TS2SoftwareUpdateNotifyOnNextLaunchKey];
                if (shouldShowsResult) {
                    [self showThisIsUpToDateAlert];
                }
            }
        } else {
            [self showErrorAlert];
        }
        [defaults_ setObject:[NSDate date] forKey:TS2SoftwareUpdateLastCheckedDateKey];
    }

    [self setConnection:nil];

    [ts2su_receivedData release];
    ts2su_receivedData = nil;

    [self setIsChecking:NO];
}
@end
