//
//  CMRThreadViewer_p.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/08/14.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer.h"
#import <SGAppKit/BSTitleRulerView.h>
#import "CMRStatusLineWindowController.h"
#import "AppDefaults.h"

#import "CMRThreadSignature.h"
#import "CMRThreadAttributes.h"
#import "CMRThreadDocument.h"
#import "CMRThreadMessageBuffer.h"
#import "CMRThreadMessage.h"

#import "CMRTrashbox.h"
#import "CMRTaskManager.h"
#import "CMRDocumentFileManager.h"
#import "CMRDocumentController.h"
#import "CMRHostHandler.h"

@class CMRReplyMessenger;


#define APP_TVIEW_LOCALIZABLE_FILE			@"ThreadViewer"
#define APP_TVIEW_STATUSLINE_IDENTIFIER		@"ThreadViewer"
#define APP_TVIEWER_INVALID_PERT_TITLE		@"Invalid Pertical Contents Title"
#define APP_TVIEWER_INVALID_PERT_MSG_FMT	@"Invalid Pertical Contents Message"
#define APP_TVIEWER_DELETE_LABEL			@"Delete Button Label"
#define APP_TVIEWER_NOT_DELETE_LABEL		@"Do Not Delete Button Label"
#define APP_TVIEWER_DEL_AND_RETRY_LABEL		@"Delete And Retry Button Label"
#define APP_TVIEWER_INVALID_THREAD_TITLE	@"Invalidated Thread Contents Title"
#define APP_TVIEWER_INVALID_THREAD_MSG_FMT	@"Invalidated Thread Contents Message"
#define APP_TVIEWER_DO_RELOAD_LABEL			@"Reload From File Button Label"
#define APP_TVIEWER_NOT_RELOAD_LABEL		@"Do Not Reload Button Label"

#define kNotFoundTitleKey				@"Not Found Title"
#define kNotFoundMessageFormatKey		@"Not Found Message"
#define kNotFoundMessageFormat2Key		@"Not Found Message 2"
#define kNotFoundMaruLabelKey			@"Not Found Maru Button Label"
#define kNotFoundHelpKeywordKey			@"NotFoundSheet Help Anchor"
#define kInvalidPerticalContentsHelpKeywordKey	@"InvalidPerticalSheet Help Anchor"
#define kNotFoundCancelLabelKey			@"Do Not Reload Button Label"



@interface CMRThreadViewer(NotificationPrivate)
- (void)cleanUpItemsToBeRemoved:(NSArray *)files;
- (void)appDefaultsLayoutSettingsUpdated:(NSNotification *)notification;
- (void)trashDidPerformNotification:(NSNotification *)notification;
@end


@interface CMRThreadViewer(ThreadContents)
- (BOOL)shouldShowContents;
- (BOOL)shouldLoadWindowFrameUsingCache;
- (BOOL)shouldSaveThreadDataAttributes;
- (BOOL)canGenarateContents;
- (BOOL)checkCanGenarateContents;

- (void)setThreadAttributes:(CMRThreadAttributes *) aThreadData;
- (void)disposeThreadAttributes;
- (void)registerThreadAttributes:(CMRThreadAttributes *) newThread;

- (void)addThreadTitleToHistory;
@end


@interface CMRThreadViewer(MoveActionValidation)
- (BOOL)canScrollFirstMessage;
- (BOOL)canScrollLastMessage;
- (BOOL)canScrollPrevMessage;
- (BOOL)canScrollNextMessage;
- (BOOL)canScrollToMessage;
- (BOOL)canScrollToLastReadedMessage;
- (BOOL)canScrollToLastUpdatedMessage;
@end


@interface CMRThreadViewer(ThreadAttributesNotification)
- (void)synchronizeAttributes;
- (void)synchronizeLayoutAttributes;
@end


@interface CMRThreadViewer(ActionSupport)
- (CMRReplyMessenger *)replyMessenger;
- (void)addMessenger:(CMRReplyMessenger *)aMessenger;
- (void)replyMessengerDidFinishPosting:(NSNotification *)aNotification;
- (void)removeMessenger:(CMRReplyMessenger *)aMessenger;
- (void)openThreadsInThreadWindow:(NSArray *)threads;
@end


@interface CMRThreadViewer(SaveAttributes)
- (void)threadWillClose;

- (BOOL)synchronize;

- (void)saveWindowFrame;
- (void)saveLastIndex;
@end

//:CMRThreadViewer-Download.m
@interface CMRThreadViewer(Download)
- (void)downloadThread:(CMRThreadSignature *)aSignature title:(NSString *)threadTitle nextIndex:(NSUInteger)aNextIndex;

// Available in Twincam Angel.
- (void)downloadThreadUsingMaru:(CMRThreadSignature *)aSignature title:(NSString *)threadTitle;
@end

//:CMRThreadViewer-ViewAccessor.m
@interface CMRThreadViewer(ViewAccessor)
- (NSTextView *)textView;
- (void)setTextView:(NSTextView *)aTextView;
- (NSScrollView *)scrollView;

- (BSIndexPanelController *)indexPanelController;
- (BSAddNGExWindowController *)addNGExWindowController;
- (BSThreadLinkerCorePasser *)threadLinkerCorePasser;
@end


@interface CMRThreadViewer(NSTextViewDelegate)
- (IBAction)runSpamFilter:(id)sender;
@end


@interface CMRThreadViewer(UIComponents)
- (BOOL)loadComponents;
- (NSView *)containerView;
- (void)setupLoadedComponents;
@end


@interface CMRThreadViewer(ViewInitializer)
+ (NSMenu *)loadContextualMenuForTextView;

- (void)setupScrollView;
- (void)setupTextView;
- (void)updateLayoutSettings;
- (void)setupTextViewBackground;
- (void)setWindowFrameUsingCache;

+ (BOOL)shouldShowTitleRulerView;
+ (BSTitleRulerModeType)rulerModeForInformDatOchi;
- (void)cleanUpTitleRuler:(NSTimer *)aTimer;
@end
