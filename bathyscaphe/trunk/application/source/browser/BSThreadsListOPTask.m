//
//  BSThreadsListOPTask.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/06.
//  Copyright 2006-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadsListOPTask.h"

#import "CMRThreadsList_p.h"

#import "BSDownloadTask.h"
#import "BSDBThreadsListDBUpdateTask2.h"

#import "AppDefaults.h"
#import "BoardManager.h"
#import "CMRHostHandler.h"

NSString *const ThreadsListDownloaderShouldRetryUpdateNotification = @"ThreadsListDownloaderShouldRetryUpdateNotification";


@interface BSThreadsListOPTask ()
@property (retain) NSURL *URL;
@property (assign) BSDBThreadList *targetList;
@end

@implementation BSThreadsListOPTask
@synthesize URL = targetURL;
@synthesize targetList = m_targetList;

+ (id)taskWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)forceDownload
{
	return [[[[self class] alloc] initWithThreadList:list forceDownload:forceDownload rebuild:NO] autorelease];
}

- (id)initWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)forceDownload rebuild:(BOOL)flag
{
	if (self = [super init]) {
		self.targetList = list;
		m_forceDL = forceDownload;
		isRebuilding = flag;
		self.boardName = [list boardName];

		if (!self.boardName) goto fail;
	}
	
	return self;
fail:
	[self release];
	return nil;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[targetURL release];
	[dlTask release];
	[dbupTask release];
	[m_downloadData release];
	[m_downloadError release];
	[bbsName release];
	
	[super dealloc];
}

#pragma mark-

- (void)setBoardName:(NSString *)name
{
	id u = [[BoardManager defaultManager] URLForBoardName:name];
	u = [NSURL URLWithString:CMRAppSubjectTextFileName relativeToURL:u];
	if (!u) return;

    const char *host = NULL;
    CMRGetHostCStringFromBoardURL((NSURL *)u, &host);
    isLivedoor = host ? is_jbbs_livedoor(host) : NO;

	id temp = bbsName;
	bbsName = [name copy];
	[temp release];
	
	self.URL = u;
}

- (NSString *)boardName
{
	return bbsName;
}

#pragma mark-
- (id)makeDownloadTask
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	dlTask = [[BSDownloadTask alloc] initWithURL:self.URL];

	[nc addObserver:self
		   selector:@selector(dlDidFinishDownloadNotification:)
			   name:BSDownloadTaskFinishDownloadNotification
			 object:dlTask];
	[nc addObserver:self
		   selector:@selector(dlAbortDownloadNotification:)
			   name:BSDownloadTaskInternalErrorNotification
			 object:dlTask];
	[nc addObserver:self
		   selector:@selector(dlAbortDownloadNotification:)
			   name:BSDownloadTaskAbortDownloadNotification
			 object:dlTask];
	[nc addObserver:self
		   selector:@selector(dlDidFailDownloadNotification:)
			   name:BSDownloadTaskFailDownloadNotification
			 object:dlTask];
	[nc addObserver:self
		   selector:@selector(dlCancelDownloadNotification:)
			   name:BSDownloadTaskCanceledNotification
			 object:dlTask];
	
	return dlTask;
}

- (void)tryToDetectMovedBoardOnMainThread:(id)dummy
{
	BoardManager *bm = [BoardManager defaultManager];
    NSError *error;
	if ([bm tryToDetectMovedBoard:self.boardName error:&error]) {
		UTILNotifyName(ThreadsListDownloaderShouldRetryUpdateNotification);
	} else {
        NSAlert *alert = [NSAlert alertWithError:error];
        NSBeep();
        if ([alert runModal] == NSAlertSecondButtonReturn) {
            NSString *urlString = SGTemplateResource(@"System - BBON Info URL");
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
        }
	}
}

- (void)tryToDetectMovedBoard
{
	[self performSelectorOnMainThread:@selector(tryToDetectMovedBoardOnMainThread:)
						   withObject:nil
						waitUntilDone:NO];
}

- (void)showDownloadErrorAlert
{
	[self performSelectorOnMainThread:@selector(showDownloadErrorAlertOnMainThread) withObject:nil waitUntilDone:NO];
}

- (void)showDownloadErrorAlertOnMainThread
{
	UTILAssertNotNil(m_downloadError);

	NSString *message = [NSString stringWithFormat:
		NSLocalizedStringFromTable(APP_TLIST_NOT_FOUND_MSG_FMT, @"ThreadsList", nil),
		[self.URL absoluteString]];

	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:[m_downloadError localizedDescription]];
	[alert setInformativeText:message];
	
	[alert addButtonWithTitle:NSLocalizedStringFromTable(@"TLDownloadErrorButton1", @"ThreadsList", @"OK")];
    NSButton *button2 = [alert addButtonWithTitle:NSLocalizedStringFromTable(@"TLDownloadErrorButton2", @"ThreadsList", @"Try Again")];
    [button2 setKeyEquivalent:@"r"];

	NSBeep();
	if ([alert runModal] == NSAlertSecondButtonReturn) {
        UTILNotifyName(ThreadsListDownloaderShouldRetryUpdateNotification);
    }
}

#pragma mark-
- (void)excute
{
	if(self.isInterrupted) goto abort;
	if ([CMRPref isOnlineMode] || m_forceDL) {
		dlTask = [self makeDownloadTask];
		[dlTask run];
		id temp = dlTask;
		dlTask = nil;
		[temp release];
		
		if(self.isInterrupted) goto abort;
		if (m_downloadData && [m_downloadData length] != 0) {
			dbupTask = [[BSDBThreadsListDBUpdateTask2 taskWithBBSName:bbsName data:m_downloadData livedoor:isLivedoor rebuilding:isRebuilding] retain];
			[dbupTask run];
            if (isRebuilding && [dbupTask lastErrorWhileRebuilding]) {
                self.targetList.rebuildError = [dbupTask lastErrorWhileRebuilding];
            }

            id temp2 = dbupTask;
            dbupTask = nil;
            [temp2 release];
			
			if(self.isInterrupted) goto abort;
		} else if (m_downloadError) {
			[self showDownloadErrorAlert];
		} else {
			[self tryToDetectMovedBoard];
		}
	}
	
	if(self.isInterrupted) goto abort;
	[self.targetList updateCursor];
	
abort:
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

	
- (void)dlDidFinishDownloadNotification:(NSNotification *)notification
{
	m_downloadData = [[[notification object] receivedData] retain];
}

- (void)dlDidFailDownloadNotification:(NSNotification *)notification
{
	UTILAssertNotNil([notification userInfo]);

	m_downloadError = [[[notification userInfo] objectForKey:BSDownloadTaskErrorObjectKey] retain];
}

-(void)dlCancelDownloadNotification:(NSNotification *)notification
{
	self.isInterrupted = YES;
}
-(void)dlAbortDownloadNotification:(NSNotification *)notification
{
	m_downloadData = nil;
}

#pragma mark -
- (NSString *)title
{
	return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Update threads list. %@", @"ThreadsList", @""),
		self.boardName];
}
- (NSString *)message
{
	return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Update threads list. %@", @"ThreadsList", @""),
		self.boardName];
}

-(IBAction)cancel:(id)sender
{
	[dlTask cancel:self];
	self.targetList = nil;
	
	[super cancel:sender];
}
@end
