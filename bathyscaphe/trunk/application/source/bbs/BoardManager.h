//
//  BoardManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/31.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "SmartBoardList.h"

@class BSLocalRulesPanelController, BSNGExpression;

@interface BoardManager : NSObject<NSWindowDelegate> // LocalRulesPanel の Delegate になるため
{
    @private
	SmartBoardList			*_defaultList;
	SmartBoardList			*_userList;

	NSMutableDictionary		*_noNameDict;
	NSMutableArray			*m_localRulesPanelControllers;
    NSMutableDictionary     *m_corpusCache;
    NSArray                 *m_invalidBoardURLs; // Array of NSString
    BOOL                    m_syncInProgress;
}
+ (id)defaultManager;

- (SmartBoardList *)defaultList;
- (SmartBoardList *)userList;

// Available in CometBlaster and later.
- (SmartBoardList *)filteredListWithString:(NSString *)keyword;

- (NSString *)defaultBoardListPath;
- (NSString *)userBoardListPath;

+ (NSString *)NNDFilepath; // BoardProperties.plist

- (NSURL *)URLForBoardName:(NSString *)boardName;
- (NSURL *)URLForBoardID:(NSUInteger)boardID;
- (NSString *)boardNameForURL:(NSURL *)anURL;

- (void)updateURL:(NSURL *)anURL forBoardName:(NSString *)aName;

/*!
 * @method        tryToDetectMovedBoard:
 * @abstract      Detect moved BBS as possible.
 * @discussion    Detect moved BBS from HTML contents server has
 *                returned. It may be unexpected contents (expected
 *                index.html), but it can contain information about 
 *                new location of BBS.
 *
 * @param boardName BBS Name
 * @result        Returns YES if BoardManager change old location.
 */
- (BOOL)tryToDetectMovedBoard:(NSString *)boardName error:(NSError **)errorPtr;

/*!
 * @method        detectMovedBoardWithResponseHTML:
 * @abstract      Detect moved BBS as possible.
 * @discussion    Detect moved BBS from HTML contents server has
 *                returned. It may be unexpected contents (expected
 *                index.html), but it can contain information about 
 *                new location of BBS.
 *
 * @param aHTML     HTML contents, NSString
 * @param boardName BBS Name
 * @result          Returns YES if BoardManager change old location.
 */
- (BOOL)detectMovedBoardWithResponseHTML:(NSString *)htmlContents boardName:(NSString *)boardName;

- (void)reloadBoardFilesIfNeeded;
@end

@interface BoardManager(BoardProperties)
- (NSMutableDictionary *)noNameDict;

- (BOOL)saveNoNameDict;

// Available in Starlight Breaker and later.
- (void)passPropertiesOfBoardName:(NSString *)boardName toBoardName:(NSString *)newBoardName;

- (NSDate *)lastDetectedDateForBoard:(NSString *)boardName;
- (void)setLastDetectedDate:(NSDate *)date forBoard:(NSString *)boardName;

#pragma mark Nanashi-san
// Available in MeteorSweeper and later.
- (NSArray*)defaultNoNameArrayForBoard:(NSString *)boardName;
- (void)setDefaultNoNameArray:(NSArray *)array forBoard:(NSString *)boardName;
- (void)addNoName:(NSString *)additionalNoName forBoard:(NSString *)boardName;

/*!
    @method     askUserAboutDefaultNoNameForBoard:presetValue:
    @abstract   Shows input dialog for user to specify nanashisan.
    @discussion Shows input dialog, and User can directly enter the nanashisan.
				BoardManager will serve presetValue as assumed nanashisan.
	@result		Input string. If User canceled, returns nil.
*/
- (NSString *)askUserAboutDefaultNoNameForBoard:(NSString *)boardName presetValue:(NSString *)aValue;

// Available in BathyScaphe 2.0.5 "Homuhomu" and later.
- (BOOL)needToDetectNoNameForBoard:(NSString *)boardName shouldInputManually:(BOOL *)boolPtr;

// Available in ReinforceII and later.
- (BOOL)allowsNanashiAtBoard:(NSString *)boardName;
- (void)setAllowsNanashi:(BOOL)allows atBoard:(NSString *)boardName;

#pragma mark Sorting
// Available in Starlight Breaker and later.
- (NSArray *)sortDescriptorsForBoard:(NSString *)boardName;
- (void)setSortDescriptors:(NSArray *)sortDescriptors forBoard:(NSString *)boardName;

#pragma mark Replying
// Available in SledgeHammer and later.
- (BOOL)alwaysBeLoginAtBoard:(NSString *)boardName;
- (void)setAlwaysBeLogin:(BOOL)alwaysLogin atBoard:(NSString *)boardName;
- (NSString *)defaultKotehanForBoard:(NSString *)boardName;
- (void)setDefaultKotehan:(NSString *)aName forBoard:(NSString *)boardName;
- (NSString *)defaultMailForBoard:(NSString *)boardName;
- (void)setDefaultMail:(NSString *)aString forBoard:(NSString *)boardName;

// Available in LittleWish and later.
- (BSBeLoginPolicyType)typeOfBeLoginPolicyForBoard:(NSString *)boardName;

// Available in MeteorSweeper and later.
- (void)setTypeOfBeLoginPolicy:(BSBeLoginPolicyType)aType forBoard:(NSString *)boardName;

// Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
- (BOOL)hasAllowsCharRefEntryAtBoard:(NSString *)boardName;
- (BOOL)allowsCharRefAtBoard:(NSString *)boardName;
- (void)setAllowsCharRef:(BOOL)flag atBoard:(NSString *)boardName;

#pragma mark Other Board Properties
// Available in BathyScaphe 1.2 and later.
//- (BOOL)allThreadsShouldAAThreadAtBoard:(NSString *)boardName;
//- (void)setAllThreadsShouldAAThread:(BOOL)shouldAAThread atBoard:(NSString *)boardName;

- (id)itemForName:(NSString *)boardName;
@end

// Available in MeteorSweeper and later.
@interface BoardManager(SettingTxtDetector)
- (BOOL)startDownloadSettingTxtForBoard:(NSString *)boardName askIfOffline:(BOOL)flag allowToInputManually:(BOOL)manualFlag;
@end

@interface BoardManager(UserListEditorCore)
- (BOOL)addCategoryOfName:(NSString *)name;
- (BOOL)editBoardItem:(id)item newURLString:(NSString *)newURLString;
- (BOOL)editCategoryItem:(id)item newName:(NSString *)newName;
- (BOOL)removeBoardItems:(NSArray *)boardItemsForRemoval;
@end

// Available in SilverGull and later.
@interface BoardManager(LocalRules)
- (NSMutableArray *)localRulesPanelControllers;
- (BSLocalRulesPanelController *)localRulesPanelControllerForBoardName:(NSString *)boardName;
- (BOOL)isKeyWindowForBoardName:(NSString *)boardName;
@end

@interface BoardManager(SortDescriptorRepairing)
- (NSArray *)sortDescriptorsForBoard:(NSString *)boardName useDefaultDescs:(BOOL)flag;

- (void)repairInvalidDescriptorForBoard:(NSString *)boardName;
- (void)fixUnconvertedNoNameEntityReferenceForBoard:(NSString *)boardName;
@end


@interface BoardManager(SpamFilter)
- (NSSet *)spamHostSymbolsForBoard:(NSString *)boardName;
- (void)setSpamHostSymbols:(NSSet *)set forBoard:(NSString *)boardName;

- (BOOL)treatsNoSageAsSpamAtBoard:(NSString *)boardName;
- (void)setTreatsNoSageAsSpam:(BOOL)flag atBoard:(NSString *)boardName;

- (BOOL)treatsAsciiArtAsSpamAtBoard:(NSString *)boardName;
- (void)setTreatsAsciiArtAsSpam:(BOOL)flag atBoard:(NSString *)boardName;

- (BOOL)registrantShouldConsiderNameAtBoard:(NSString *)boardName; // Available in BathyScaphe 2.0.5 "Homuhomu" and later.
- (void)setRegistrantShouldConsiderName:(BOOL)flag atBoard:(NSString *)boardName; // Available in BathyScaphe 2.0.5 "Homuhomu" and later.

- (NSMutableArray *)spamMessageCorpusForBoard:(NSString *)boardName;
- (void)setSpamMessageCorpus:(NSMutableArray *)mutableArray forBoard:(NSString *)boardName;

- (void)saveSpamCorpusIfNeeded:(NSTimer *)timer;

- (void)addNGExpression:(BSNGExpression *)expression forBoard:(NSString *)boardName;
@end


@interface BoardManager(BoardListRepairing)
- (NSArray *)invalidBoardURLsToBeRemoved;
- (void)repairInvalidBoardData;
- (BOOL)shouldRepairInvalidBoardData;
@end


extern NSString *const CMRBBSManagerUserListDidChangeNotification;
extern NSString *const CMRBBSManagerDefaultListDidChangeNotification;

// Available in ReinforceII and later.
extern NSString *const BoardManagerDidFinishDetectingSettingTxtNotification;
