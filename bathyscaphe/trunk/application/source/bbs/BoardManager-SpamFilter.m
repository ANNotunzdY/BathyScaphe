//
//  BoardManager-SpamFilter.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/05/22.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BoardManager_p.h"
#import "CMRDocumentFileManager.h"
#import "CMRSpamFilter.h"
#import "BSBoardInfoInspector.h"

@implementation BoardManager(SpamFilter)
- (NSString *)corpusFilePathForBoard:(NSString *)boardName
{
    NSString *folderPath = [[CMRDocumentFileManager defaultManager] directoryWithBoardName:boardName];
	return [folderPath stringByAppendingPathComponent:BSNGExpressionsFile];
}

- (NSMutableDictionary *)corpusCache
{
    if (!m_corpusCache) {
        m_corpusCache = [[NSMutableDictionary alloc] init];
        [[NSTimer scheduledTimerWithTimeInterval:600 // 10 minutes
                                          target:self
                                        selector:@selector(saveSpamCorpusIfNeeded:)
                                        userInfo:nil
                                         repeats:YES] retain];
    }
    return m_corpusCache;
}

- (NSSet *)spamHostSymbolsForBoard:(NSString *)boardName
{
    id obj = [self valueForKey:@"SpamHostSymbols" atBoard:boardName defaultValue:nil];
    if (obj && [obj isKindOfClass:[NSArray class]]) {
        return [NSSet setWithArray:obj];
    }
    return [CMRPref spamHostSymbols];
}

- (void)setSpamHostSymbols:(NSSet *)set forBoard:(NSString *)boardName
{
    if (!set) {// || [set count] < 1) {
        [self removeValueForKey:@"SpamHostSymbols" atBoard:boardName];
    } else {
        if ([set isEqualToSet:[CMRPref spamHostSymbols]]) {
            [self removeValueForKey:@"SpamHostSymbols" atBoard:boardName];
        } else {
            [self setValue:[set allObjects] forKey:@"SpamHostSymbols" atBoard:boardName];
        }
    }
}

- (BOOL)treatsNoSageAsSpamAtBoard:(NSString *)boardName
{
    return [self boolValueForKey:@"TreatsNoSageAsSpam" atBoard:boardName defaultValue:[CMRPref treatsNoSageAsSpam]];
}

- (void)setTreatsNoSageAsSpam:(BOOL)flag atBoard:(NSString *)boardName
{
    [self setBoolValue:flag forKey:@"TreatsNoSageAsSpam" atBoard:boardName];
}

- (BOOL)treatsAsciiArtAsSpamAtBoard:(NSString *)boardName
{
    return [self boolValueForKey:@"TreatsAsciiArtAsSpam" atBoard:boardName defaultValue:[CMRPref treatsAsciiArtAsSpam]];
}

- (void)setTreatsAsciiArtAsSpam:(BOOL)flag atBoard:(NSString *)boardName
{
    [self setBoolValue:flag forKey:@"TreatsAsciiArtAsSpam" atBoard:boardName];
}

- (BOOL)registrantShouldConsiderNameAtBoard:(NSString *)boardName
{
    return [self boolValueForKey:@"RegistrantConsidersName" atBoard:boardName defaultValue:[CMRPref registrantShouldConsiderName]];
}

- (void)setRegistrantShouldConsiderName:(BOOL)flag atBoard:(NSString *)boardName
{
    [self setBoolValue:flag forKey:@"RegistrantConsidersName" atBoard:boardName];
}

- (NSMutableArray *)spamMessageCorpusForBoard:(NSString *)boardName
{
    id cachedCorpus = [[self corpusCache] objectForKey:boardName];
    if (cachedCorpus) {
        return cachedCorpus;
    }

    CMRSpamFilter *sf = [CMRSpamFilter sharedInstance];
    NSArray *plist = [sf readFromContentsOfPropertyListFile:[self corpusFilePathForBoard:boardName]];
    if (!plist) {
        [[self corpusCache] setObject:[NSMutableArray array] forKey:boardName];
    } else {
        [[self corpusCache] setObject:[sf restoreFromPlistToCorpus:plist] forKey:boardName];
    }
    return [[self corpusCache] objectForKey:boardName];
}

- (void)setSpamMessageCorpus:(NSMutableArray *)mutableArray forBoard:(NSString *)boardName
{
    [[self corpusCache] setObject:mutableArray forKey:boardName];
}

- (void)saveSpamCorpusIfNeeded:(NSTimer *)timer
{
    if (!m_corpusCache) {
        return;
    }
    NSArray *boards = [[self corpusCache] allKeys];
    CMRSpamFilter *sf = [CMRSpamFilter sharedInstance];
    for (NSString *boardName in boards) {
        id rep = [sf propertyListRepresentation:[[self corpusCache] objectForKey:boardName]];
        if (rep) {
            [sf saveRepresentation:rep toFile:[self corpusFilePathForBoard:boardName]];
        }
    }
}

- (void)addNGExpression:(BSNGExpression *)expression forBoard:(NSString *)boardName
{
	[[BSBoardInfoInspector sharedInstance] willChangeValueForKey:@"spamCorpusForTargetBoard"];
	[[self spamMessageCorpusForBoard:boardName] addObject:expression];
	[[BSBoardInfoInspector sharedInstance] didChangeValueForKey:@"spamCorpusForTargetBoard"];
}
@end
