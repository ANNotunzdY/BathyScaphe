//
//  CMRThreadViewer.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/01.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CMRStatusLineWindowController.h"
#import "CMRFavoritesManager.h"
#import "CMRThreadView.h"
#import "BSMessageSampleRegistrant.h"

@class CMRThreadLayout;
@class CMRThreadAttributes;
@class CMRThreadSignature;
@class CMRReplyMessenger;
@class BSIndexPanelController;
@class BSAddNGExWindowController;
@class BSThreadLinkerCorePasser;

@interface CMRThreadViewer : CMRStatusLineWindowController<NSTextViewDelegate, CMRThreadViewDelegate, BSMessageSampleRegistrantDelegate>
{	
	// History
	NSUInteger					_historyIndex;
	NSMutableArray				*_history;

    int m_scaleCount;
	
	// Helper
	CMRThreadLayout             *_layout;
	NSUndoManager               *m_undo;
    BSIndexPanelController      *m_indexPanelController;
    BSAddNGExWindowController   *m_addNGExWindowController;
    BSThreadLinkerCorePasser    *m_passer;

	// Interface
	IBOutlet NSView				*m_componentsView;
	IBOutlet NSView				*m_containerView;
	IBOutlet NSView				*m_windowContentView;	// dummy
	IBOutlet NSScrollView		*m_scrollView;
	IBOutlet NSTextView			*m_textView;
	
	struct {
		unsigned int invalidate:1; // invalid contents
		unsigned int themechangeing:1; // change theme task is in progress
        unsigned int retrieving:1; // 再取得作業中→オフライン時でもリロード必須
		unsigned int reserved:29;
	} _flags;
}

/* Register history list if relativeIndex == 0 */
- (void)setThreadContentWithThreadIdentifier:(id)aThreadIdentifier noteHistoryList:(NSInteger)relativeIndex;
- (void)setThreadContentWithFilePath:(NSString *)filepath boardInfo:(NSDictionary *)boardInfo noteHistoryList:(NSInteger)relativeIndex;
- (void)setThreadContentWithThreadIdentifier:(id)aThreadIdentifier;
- (void)setThreadContentWithFilePath:(NSString *)filepath boardInfo:(NSDictionary *)boardInfo;

- (void)loadFromContentsOfFile:(NSString *)filepath;
- (void)composeDATContents:(NSString *)datContents threadSignature:(CMRThreadSignature *)aSignature nextIndex:(NSUInteger)aNextIndex;

/*** auxiliary ***/
- (BOOL)isInvalidate;
- (void)setInvalidate:(BOOL)flag;
- (BOOL)changeThemeTaskIsInProgress;
- (void)setChangeThemeTaskIsInProgress:(BOOL)flag;
- (BOOL)isRetrieving;
- (void)setRetrieving:(BOOL)flag;

- (CMRThreadLayout *)threadLayout;
- (CMRThreadAttributes *)threadAttributes;

- (NSString *)titleForTitleBar;

/* called when thread did be changed */
- (void)didChangeThread;

- (void)closeWindowOfAlert:(NSAlert *)alert;

/*** NO_NAME properties ***/
- (NSString *)detectDefaultNoName;
- (void)setupDefaultNoNameIfNeeded;

- (NSString *)path;
- (NSString *)title;
- (NSString *)boardName;
- (NSURL *)boardURL;
- (NSURL *)threadURL;
- (NSString *)datIdentifier;
- (NSString *)bbsIdentifier;
//- (NSArray *)cachedKeywords;
//- (void)setCachedKeywords:(NSArray *)array;
@end


@interface CMRThreadViewer(Action)
- (NSPoint)locationForInformationPopUp;

// NOTE: CMRBrowser overrides this method.
- (NSArray *)targetThreadsForAction:(SEL)action sender:(id)sender;
- (NSArray *)targetBoardsForAction:(SEL)action sender:(id)sender;

- (void)quoteWithMessenger:(CMRReplyMessenger *)aMessenger;
- (CMRReplyMessenger *)plainReply:(id)sender;

- (void)checkIfUsesCorpusOptionOn;

// KeyBinding...
- (IBAction)reloadThread:(id)sender;
- (IBAction)reply:(id)sender;

- (IBAction)copyThreadAttributes:(id)sender;

- (IBAction)copySelectedResURL:(id)sender;
- (IBAction)reloadIfOnlineMode:(id)sender;
- (IBAction)addFavorites:(id)sender;

- (IBAction)openBBSInBrowser:(id)sender;
- (IBAction)showBoardInspectorPanel:(id)sender;
- (IBAction)showLocalRules:(id)sender;

// make text area to be first responder
- (IBAction)focus:(id)sender;
// NOTE: It is a history item's action.
- (IBAction)showThreadFromHistoryMenu:(id)sender; // Overrides CMRAppDelegate's one.

- (IBAction)biggerText:(id)sender;
- (IBAction)smallerText:(id)sender;
- (IBAction)actualSizeText:(id)sender;

- (IBAction)testPasser:(id)sender; // テスト用
@end


@interface CMRThreadViewer(DeletionAndRetrieving)
- (void)closeWindowIfNeededAtPath:(NSString *)path;

- (BOOL)forceDeleteThreads:(NSArray *)threads;
- (BOOL)prepareRetrieving:(NSString *)logFilePath error:(NSError **)error;
- (BOOL)retrieveThreadAtPath:(NSString *)filepath title:(NSString *)title;
- (BOOL)restoreFromRetrieving:(NSString *)path error:(NSError **)error;

- (IBAction)deleteThread:(id)sender;
- (IBAction)retrieveThread:(id)sender;
@end


@interface CMRThreadViewer(History)
// History: ThreadSignature...
- (NSUInteger)historyIndex;
- (void)setHistoryIndex:(NSUInteger)aHistoryIndex;
- (NSMutableArray *)threadHistoryArray;

- (id)threadIdentifierFromHistoryWithRelativeIndex:(NSInteger)relativeIndex;
- (void)noteHistoryThreadChanged:(NSInteger)relativeIndex;
- (void)clearThreadHistories;

- (IBAction)historyMenuPerformForward:(id)sender;
- (IBAction)historyMenuPerformBack:(id)sender;
@end


@interface CMRThreadViewer(MoveAction)
/* 最初／最後のレス */
- (IBAction)scrollFirstMessage:(id)sender;
- (IBAction)scrollLastMessage:(id)sender;

/* 次／前のレス */
- (IBAction)scrollPrevMessage:(id)sender;
- (IBAction)scrollPreviousMessage:(id)sender;
- (IBAction)scrollNextMessage:(id)sender;

/* 次／前のブックマーク */
- (IBAction)scrollPreviousBookmark:(id)sender;
- (IBAction)scrollNextBookmark:(id)sender;

- (IBAction)scrollToLastReadedIndex:(id)sender;
- (IBAction)scrollToLastUpdatedIndex:(id)sender;

/* 今日のレス (available in Starlight Breaker.) */
- (IBAction)scrollToFirstTodayMessage:(id)sender;

/* 最後から 50 レス手前 (Available in Final Moratorium.) */
- (IBAction)scrollToLatest50FirstIndex:(id)sender;

- (IBAction)showIndexPanel:(id)sender;

- (IBAction)scrollFromNavigator:(id)sender;
@end


@interface CMRThreadViewer(MoveActionSupport)
- (void)validateIndexingNavigator;
- (void)scrollMessageAtIndex:(NSInteger)index;
@end


@interface CMRThreadViewer(TextViewSupport)
- (IBAction)findNextText:(id)sender;
- (IBAction)findPreviousText:(id)sender;
- (IBAction)findFirstText:(id)sender;
- (IBAction)findAll:(id)sender;
- (IBAction)findAllByFilter:(id)sender;
- (void) findTextByFilter: (NSString *) aString
			   searchMask: (CMRSearchMask) searchOption
			   targetKeys: (NSArray *) keysArray
			 locationHint: (NSPoint) location;
// Available in Starlight Breaker. For ID Popup.
- (void)extractMessagesWithIDString:(NSString *)IDString popUpLocation:(NSPoint)location;
@end


@interface CMRThreadViewer(Validation)
- (BOOL)validateDeleteThreadItemEnabling:(NSString *)threadPath;
- (void)validateDeleteThreadItemTitle:(id)theItem;
- (void)validateShowBoardInspectorPanelItemTitle:(id)item;
- (CMRFavoritesOperation)favoritesOperationForThreads:(NSArray *)threadsArray;
- (BOOL)validateAddFavoritesItem:(id)theItem forOperation:(CMRFavoritesOperation)operation;
@end


@interface CMRThreadViewer(SelectingThreads)
- (NSUInteger)numberOfSelectedThreads;
- (NSDictionary *)selectedThread;
- (NSArray *)selectedThreads;
@end


extern NSString *const CMRThreadViewerDidChangeThreadNotification;

/**
  * userInfo:
  * 	@"Count"	-- number of found items (NSNumber, as an unsigned int)
  *
  */
#define kAppThreadViewerFindInfoKey	@"Count"

extern NSString *const BSThreadViewerWillStartFindingNotification;
extern NSString *const BSThreadViewerDidEndFindingNotification;
extern NSString *const CMRThreadViewerRunSpamFilterNotification;
