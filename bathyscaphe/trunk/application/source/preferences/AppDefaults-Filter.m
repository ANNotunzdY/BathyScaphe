//
// AppDefaults-Filter.m
// BathyScaphe
//
// Updated by Tsutomu Sawada on 08/02/08.
// Copyright 2006-2011 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "AppDefaults_p.h"
#import "CMRSpamFilter.h"

static NSString *const kPrefFilterDictKey = @"Preferences - Filter";
static NSString *const kPrefSpamFilterEnabledKey = @"Spam Filter Enabled";
static NSString *const kPrefUsesSpamMessageCorpusKey = @"Uses Spam Message Corpus";
static NSString *const kPrefSpamFilterBehaviorKey = @"Spam Filter Behavior";
static NSString	*const kPrefAADEnabledKey = @"AA Detector Enabled";
static NSString *const kPrefOldNGWordsImportedKey = @"Old Format Corpus Imported";
static NSString *const kPrefTreatsAAAsSpamKey = @"Treats AA as Spam";
static NSString *const kPrefSpamHostSymbolsKey = @"Spam Host Symbols";
static NSString *const kPrefTreatsNoSageAsSpamKey = @"Treats non-sage as Spam";
static NSString *const kPrefRunSpamFilterAfterAddingKey = @"Run after Adding";
static NSString *const kPrefNGExAddingScopeKey = @"Default Scope for Adding";
static NSString *const kPrefRegistrantConsidersNameKey = @"Registrant considers name";

@implementation AppDefaults(Filter)
- (NSMutableDictionary *)filterPrefs
{
	if (!_dictFilter) {
		NSDictionary	*dict_;
		
		dict_ = [[self defaults] dictionaryForKey:kPrefFilterDictKey];
		_dictFilter = [dict_ mutableCopy];
		if (!_dictFilter) {
			_dictFilter = [[NSMutableDictionary alloc] init];
		}
	}
	
	return _dictFilter;
}

- (BOOL)spamFilterEnabled
{
	return [[self filterPrefs] boolForKey:kPrefSpamFilterEnabledKey defaultValue:DEFAULT_SPAMFILTER_ENABLED];
}

- (void)setSpamFilterEnabled:(BOOL)flag
{
	[[self filterPrefs] setBool:flag forKey:kPrefSpamFilterEnabledKey];
}
/*
- (BOOL)usesSpamMessageCorpus
{
	return [[self filterPrefs] boolForKey:kPrefUsesSpamMessageCorpusKey defaultValue:DEFAULT_SPAMFILTER_USE_MSG_CORPUS];
}

- (void)setUsesSpamMessageCorpus:(BOOL)flag
{
	[[self filterPrefs] setBool:flag forKey:kPrefUsesSpamMessageCorpusKey];
}
*/
- (NSMutableArray *)spamMessageCorpus
{
	return [[CMRSpamFilter sharedInstance] ngExpressions];
}

- (void)setSpamMessageCorpus:(NSMutableArray *)mutableArray
{
	[[CMRSpamFilter sharedInstance] setNgExpressions:mutableArray];
}
/*
- (BOOL)oldNGWordsImported
{
	return [[self filterPrefs] boolForKey:kPrefOldNGWordsImportedKey defaultValue:DEFAULT_SPAMFILTER_OLD_NG_IMPORTED];
}

- (void)setOldNGWordsImported:(BOOL)imported
{
	[[self filterPrefs] setBool:imported forKey:kPrefOldNGWordsImportedKey];
}
*/
- (BSSpamFilterBehavior)spamFilterBehavior
{
	return [[self filterPrefs] integerForKey:kPrefSpamFilterBehaviorKey defaultValue:DEFAULT_SPAMFILTER_BEHAVIOR];
}

- (void)setSpamFilterBehavior:(BSSpamFilterBehavior)mask
{
	[[self filterPrefs] setInteger:mask forKey:kPrefSpamFilterBehaviorKey];
}

- (void)resetSpamFilter
{
	[[CMRSpamFilter sharedInstance] resetSpamFilter];
}

- (void)setSpamFilterNeedsSaveToFiles:(BOOL)flag
{
	[[CMRSpamFilter sharedInstance] setNeedsSaveToFiles:flag];
}

- (BOOL)asciiArtDetectorEnabled
{
	return [[self filterPrefs] boolForKey:kPrefAADEnabledKey defaultValue:DEFAULT_AAD_ENABLED];
}

- (void)setAsciiArtDetectorEnabled:(BOOL)flag
{
	[[self filterPrefs] setBool:flag forKey:kPrefAADEnabledKey];
}

- (BOOL)treatsAsciiArtAsSpam
{
	return [[self filterPrefs] boolForKey:kPrefTreatsAAAsSpamKey defaultValue:DEFAULT_AAD_TRAET_AA_AS_SPAM];
}

- (void)setTreatsAsciiArtAsSpam:(BOOL)flag
{
	[[self filterPrefs] setBool:flag forKey:kPrefTreatsAAAsSpamKey];
}

- (BOOL)registrantShouldConsiderName
{
    return [[self filterPrefs] boolForKey:kPrefRegistrantConsidersNameKey defaultValue:DEFAULT_REGISTRANT_CONSIDER_NAME];
}

- (void)setRegistrantShouldConsiderName:(BOOL)flag
{
    [[self filterPrefs] setBool:flag forKey:kPrefRegistrantConsidersNameKey];
}

- (NSSet *)spamHostSymbols
{
    if (!m_spamHostSymbolsSet) {
        NSArray *array = [[self filterPrefs] arrayForKey:kPrefSpamHostSymbolsKey];
        if (array) {
            m_spamHostSymbolsSet = [[NSSet alloc] initWithArray:array];
        } else {
            m_spamHostSymbolsSet = [[NSSet alloc] init];
        }
    }
    return m_spamHostSymbolsSet;
}

- (void)setSpamHostSymbols:(NSSet *)set
{
    [set retain];
    [m_spamHostSymbolsSet release];
    m_spamHostSymbolsSet = set;
}

- (BOOL)treatsNoSageAsSpam
{
    return [[self filterPrefs] boolForKey:kPrefTreatsNoSageAsSpamKey defaultValue:DEFAULT_TREAT_NO_SAGE_AS_SPAM];
}

- (void)setTreatsNoSageAsSpam:(BOOL)flag
{
    [[self filterPrefs] setBool:flag forKey:kPrefTreatsNoSageAsSpamKey];
}

- (BSAddNGExpressionScopeType)ngExpressionAddingScope
{
    return [[self filterPrefs] integerForKey:kPrefNGExAddingScopeKey defaultValue:DEFAULT_SCOPE_FOR_ADDING];
}

- (void)setNgExpressionAddingScope:(BSAddNGExpressionScopeType)scope
{
    [[self filterPrefs] setInteger:scope forKey:kPrefNGExAddingScopeKey];
}

- (BOOL)runSpamFilterAfterAddingNGExpression
{
    return [[self filterPrefs] boolForKey:kPrefRunSpamFilterAfterAddingKey defaultValue:DEFAULT_RUN_AFTER_ADDING];
}

- (void)setRunSpamFilterAfterAddingNGExpression:(BOOL)flag
{
    [[self filterPrefs] setBool:flag forKey:kPrefRunSpamFilterAfterAddingKey];
}

- (void)_loadFilter
{

}

- (BOOL)_saveFilter
{
    if ([[self spamHostSymbols] count] > 0) {
        [[self filterPrefs] setObject:[[self spamHostSymbols] allObjects] forKey:kPrefSpamHostSymbolsKey];
    } else {
        [[self filterPrefs] removeObjectForKey:kPrefSpamHostSymbolsKey];
    }
	[[self defaults] setObject:[self filterPrefs] forKey:kPrefFilterDictKey];
	return YES;
}
@end
