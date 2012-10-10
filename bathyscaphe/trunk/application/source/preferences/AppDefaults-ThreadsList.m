//
// AppDefaults-ThreadsList.m
// BathyScaphe
//
// Updated by Tsutomu Sawada on 08/06/28.
// Copyright 2005-2009 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "AppDefaults_p.h"

static NSString *const AppDefaultsThreadsListSettingsKey = @"Preferences - ThreadsListSettings";
static NSString *const AppDefaultsThreadsListAutoscrollMaskKey = @"Selection Holding Mask";

static NSString *const AppDefaultsTLAutoReloadWhenWakeKey = @"Reload When Wake";

//static NSString *const AppDefaultsTLLastHEADCheckedDateKey = @"Last HEADCheck";
//static NSString *const AppDefaultsTLHEADCheckIntervalKey = @"HEADCheck Interval"; // Deprecated in Tenori Tiger.

static NSString *const AppDefaultsTLViewModeKey = @"View Mode";
static NSString *const AppDefaultsTLInvalidDescFixedKey = @"Invalid SortDescriptor Fixed"; // Available in BathyScaphe 1.6.3 "Hinagiku" and later.
static NSString *const AppDefaultsTLSortImmediatelyKey = @"Sort Immediately"; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.
static NSString *const AppDefaultsTLNextUpdatedContainsNewKey = @"NextUpdatedContainsNew";

// 以下は User Defaults 直下に作成される key
static NSString *const AppDefaultsUseIncrementalSearchKey = @"UseIncrementalSearch";
//static NSString *const AppDefaultsTRViewTextUsesBlackColorKey = @"ThreadTitleBarTextUsesBlackColor";
static NSString *const AppDefaultsTLTableColumnStateKey = @"ThreadsListTable Columns Manualsave";
static NSString *const AppDefaultsUsesLevelIndicatorKey = @"UsesLevelIndicator";
static NSString *const AppDefaultsDrawsLabelColorKey = @"DrawsLabelColors";
//static NSString *const AppDefaultsUsesThinDividerKey = @"UsesThinDivider";


@implementation AppDefaults(ThreadsListSettings)
- (NSMutableDictionary *)threadsListSettingsDictionary
{
	if (!m_threadsListDictionary) {
		NSDictionary	*dict_;

		dict_ = [[self defaults] dictionaryForKey:AppDefaultsThreadsListSettingsKey];
		m_threadsListDictionary = [dict_ mutableCopy];
		// Clean-up deprecated key (if exists)
//		[m_threadsListDictionary removeObjectForKey:AppDefaultsTLHEADCheckIntervalKey];
	}
	
	if (!m_threadsListDictionary) {
		m_threadsListDictionary = [[NSMutableDictionary alloc] init];
	}
	return m_threadsListDictionary;
}

- (CMRAutoscrollCondition)threadsListAutoscrollMask
{
	return [[self threadsListSettingsDictionary] unsignedIntegerForKey:AppDefaultsThreadsListAutoscrollMaskKey defaultValue:DEFAULT_TLSEL_HOLDING_MASK];
}

- (void)setThreadsListAutoscrollMask:(CMRAutoscrollCondition)mask
{
	[[self threadsListSettingsDictionary] setUnsignedInteger:mask forKey:AppDefaultsThreadsListAutoscrollMaskKey];
}

- (BOOL)useIncrementalSearch
{
	return [[self defaults] boolForKey:AppDefaultsUseIncrementalSearchKey defaultValue:DEFAULT_TL_INCREMENTAL_SEARCH];
}

- (void)setUseIncrementalSearch:(BOOL)TorF
{
	[[self defaults] setBool:TorF forKey:AppDefaultsUseIncrementalSearchKey];
}

static id AppDefaults_defaultBrowserListColumns(void)
{
	static NSArray *cachedDefaultArray = nil;
	if (!cachedDefaultArray) {
		cachedDefaultArray = [[NSArray alloc] initWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:@"Status",@"Identifier",[NSNumber numberWithFloat:18.0],@"Width",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Number",@"Identifier",[NSNumber numberWithFloat:40.0],@"Width",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Title",@"Identifier",[NSNumber numberWithFloat:251.0],@"Width",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Count",@"Identifier",[NSNumber numberWithFloat:60.0],@"Width",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"NewCount",@"Identifier",[NSNumber numberWithFloat:60.0],@"Width",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"Updated Count",@"Identifier",[NSNumber numberWithFloat:60.0],@"Width",nil],
			[NSDictionary dictionaryWithObjectsAndKeys:@"ModifiedDate",@"Identifier",[NSNumber numberWithFloat:100.0],@"Width",nil],
			nil];
	}
	return cachedDefaultArray;
}

- (id)threadsListTableColumnState
{
	id storedValue = [[self defaults] objectForKey:AppDefaultsTLTableColumnStateKey];
	if (storedValue) {
		return storedValue;
	} else {
		return AppDefaults_defaultBrowserListColumns();
	}
}

- (void)setThreadsListTableColumnState:(id)aColumnState
{
	[[self defaults] setObject:aColumnState forKey:AppDefaultsTLTableColumnStateKey];
}

- (BOOL)autoReloadListWhenWake
{
	return [[self threadsListSettingsDictionary] boolForKey:AppDefaultsTLAutoReloadWhenWakeKey defaultValue:DEFAULT_TL_AUTORELOAD_WHEN_WAKE];
}

- (void)setAutoReloadListWhenWake:(BOOL)doReload
{
	[[self threadsListSettingsDictionary] setBool:doReload forKey:AppDefaultsTLAutoReloadWhenWakeKey];
}

- (BSThreadsListViewModeType)threadsListViewMode
{
	return [[self threadsListSettingsDictionary] integerForKey:AppDefaultsTLViewModeKey defaultValue:DEFAULT_TL_VIEW_MODE];
}

- (void)setThreadsListViewMode:(BSThreadsListViewModeType)type
{
	[[self threadsListSettingsDictionary] setInteger:type forKey:AppDefaultsTLViewModeKey];
}

- (BOOL)energyUsesLevelIndicator
{
	return (PFlags.usesLevelIndicator != 0);
}

- (void)setEnergyUsesLevelIndicator:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:AppDefaultsUsesLevelIndicatorKey];
	PFlags.usesLevelIndicator = flag ? 1 : 0;
	[self postLayoutSettingsUpdateNotification];
}

- (BOOL)invalidSortDescriptorFixed
{
	return [[self threadsListSettingsDictionary] boolForKey:AppDefaultsTLInvalidDescFixedKey defaultValue:DEFAULT_TL_INVALID_DESC_FIXED];
}

- (void)setInvalidSortDescriptorFixed:(BOOL)flag
{
	[[self threadsListSettingsDictionary] setBool:flag forKey:AppDefaultsTLInvalidDescFixedKey];
}

- (BOOL)sortsImmediately
{
    return [[self threadsListSettingsDictionary] boolForKey:AppDefaultsTLSortImmediatelyKey defaultValue:DEFAULT_TL_SORT_IMMEDIATELY];
}

- (void)setSortsImmediately:(BOOL)flag
{
    [[self threadsListSettingsDictionary] setBool:flag forKey:AppDefaultsTLSortImmediatelyKey];
}

- (BOOL)drawsLabelColorOnRowBackground
{
    return [[self defaults] boolForKey:AppDefaultsDrawsLabelColorKey defaultValue:DEFAULT_TL_DRAWS_LABELCOLOR]; 
}

- (void)setDrawsLabelColorOnRowBackground:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:AppDefaultsDrawsLabelColorKey];
}

- (BOOL)nextUpdatedThreadContainsNewThread
{
    return [[self threadsListSettingsDictionary] boolForKey:AppDefaultsTLNextUpdatedContainsNewKey defaultValue:DEFAULT_TL_NEXT_UPDATED_CONTAINS_NEW];
}

- (void)setNextUpdatedThreadContainsNewThread:(BOOL)flag
{
    [[self threadsListSettingsDictionary] setBool:flag forKey:AppDefaultsTLNextUpdatedContainsNewKey];
}
/*
- (BOOL)threadsListSplitViewUsesThinDivider
{
    return [[self defaults] boolForKey:AppDefaultsUsesThinDividerKey defaultValue:DEFAULT_TL_SPLITVIEW_USES_THIN_DIVIDER];
}

- (void)setThreadsListSplitViewUsesThinDivider:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:AppDefaultsUsesThinDividerKey];
}
*/
#pragma mark -
- (void)_loadThreadsListSettings
{
	BOOL	flag_;
	
	flag_ = [[self defaults] boolForKey:AppDefaultsUsesLevelIndicatorKey defaultValue:true];//DEFAULT_IKIOI_USES_LEVELINDICATOR];
	[self setEnergyUsesLevelIndicator:flag_];
}

- (BOOL)_saveThreadsListSettings
{
	NSDictionary			*dict_;
	
	dict_ = [self threadsListSettingsDictionary];
	
	UTILAssertNotNil(dict_);
	[[self defaults] setObject:dict_ forKey:AppDefaultsThreadsListSettingsKey];
	return YES;
}
@end
