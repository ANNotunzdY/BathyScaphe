//
//  AppDefaults-BoardWarrior.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/06/06.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "AppDefaults_p.h"
#import "UTILKit.h"

static NSString *const AppDefaultsBWSettingsKey = @"Preferences - BoardWarrior";

//static NSString *const kBWBBSMenuURLKey = @"BoardWarrior:bbsmenu URL";
static NSString *const kBWAutoSyncBoardListKey = @"BoardWarrior:Auto Sync";
//static NSString *const kBWAutoSyncIntervalKey = @"BoardWarrior:Auto Sync Interval";
static NSString *const kBWLastSyncDateKey = @"BoardWarrior:Last Sync Date";

@implementation AppDefaults(BoardWarriorSupport)
- (NSMutableDictionary *)boardWarriorSettingsDictionary
{
	if (!m_boardWarriorDictionary) {
		NSDictionary *dict_;

		dict_ = [[self defaults] dictionaryForKey:AppDefaultsBWSettingsKey];
		m_boardWarriorDictionary = [dict_ mutableCopy];
	}

	if (!m_boardWarriorDictionary) {
		m_boardWarriorDictionary = [[NSMutableDictionary alloc] init];
	}
	return m_boardWarriorDictionary;
}

- (NSURL *)BBSMenuURL
{
    return [NSURL URLWithString:DEFAULT_BW_BBSMENU_URL];
}

- (void)setBBSMenuURL:(NSURL *)anURL
{
    [self doesNotRecognizeSelector:_cmd];
}

- (BOOL)autoSyncBoardList
{
	return [[self boardWarriorSettingsDictionary] boolForKey:kBWAutoSyncBoardListKey defaultValue:DEFAULT_BW_AUTOSYNC];
}

- (void)setAutoSyncBoardList:(BOOL)autoSync
{
	[[self boardWarriorSettingsDictionary] setBool:autoSync forKey:kBWAutoSyncBoardListKey];
}

- (BSAutoSyncIntervalType)autoSyncIntervalTag
{
    return DEFAULT_BW_SYNC_INTERVAL;
}

- (void)setAutoSyncIntervalTag:(BSAutoSyncIntervalType)aType
{
	[self doesNotRecognizeSelector:_cmd];
}

- (NSTimeInterval)timeIntervalForAutoSyncPrefs
{
	NSTimeInterval interval_;

	switch ([self autoSyncIntervalTag]) {
	case BSAutoSyncByWeek:
		interval_ = 604800.0;
		break;
	case BSAutoSyncBy2weeks:
		interval_ = 1209600.0;
		break;
	case BSAutoSyncByMonth:
		interval_ = 2592000.0;
		break;
	default:
		interval_ = 0.0;
		break;
	}
	return interval_;
}

- (NSDate *)lastSyncDate
{
	return [[self boardWarriorSettingsDictionary] objectForKey:kBWLastSyncDateKey];
}

- (void)setLastSyncDate:(NSDate *)finishedDate
{
	[[self boardWarriorSettingsDictionary] setObject:finishedDate forKey:kBWLastSyncDateKey];
}

- (BOOL)shouldAutoSyncBoardListImmediately
{
    if (![self autoSyncBoardList] || ![self isOnlineMode]) {
        return NO;
    }

    if (![self invalidBoardDataRemoved]) {
        // これから掲示板リストを修理しようとするならば、リスクを低減させるため掲示板リストの自動同期はしない。
        return NO;
    }

    NSDate *lastDate = [self lastSyncDate];
    if (!lastDate) {
        return YES;
    }
    NSDate *currentDate = [NSDate date];
    NSTimeInterval interval = [currentDate timeIntervalSinceDate:lastDate];
    return (interval > [self timeIntervalForAutoSyncPrefs]);
}

- (void)_loadBWSettings
{
}

- (BOOL)_saveBWSettings
{
	NSDictionary *dict_;

	dict_ = [self boardWarriorSettingsDictionary];

	UTILAssertNotNil(dict_);
	[[self defaults] setObject:dict_ forKey:AppDefaultsBWSettingsKey];
	return YES;
}
@end
