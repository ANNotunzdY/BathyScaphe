/**
  * $Id: CMRThreadsList-Download.m,v 1.1.1.1.4.5 2006-09-01 13:46:54 masakih Exp $
  * BathyScaphe
  *
  * Copyright 2005 BathyScaphe Project. All rights reserved.
  *
  */

#import "CMRThreadsList_p.h"
#import "ThreadTextDownloader.h"
#import "ThreadsListDownloader.h"
#import "CMRNetRequestQueue.h"

@implementation CMRThreadsList(Download)
- (void) downloadThreadsList
{
	CMRDownloader		*downloader_;
	
	downloader_ = [ThreadsListDownloader threadsListDownloaderWithBBSName : [self boardName]];

	if(nil == downloader_){
		NSLog(@"  Sorry, not supported...");
		return;
	}
	
	[self registerToNotificationCeterWithDownloader : downloader_];
	[[CMRTaskManager defaultManager] addTask : downloader_];
	[downloader_ startLoadInBackground];
}

- (void) postListDidUpdateNotification : (int) mask
{
	id		obj_;
	
	obj_ = [NSNumber numberWithUnsignedInt : mask];
	UTILNotifyInfo3(
		CMRThreadsListDidUpdateNotification,
		obj_,
		ThreadsListUserInfoSelectionHoldingMaskKey);
	UTILNotifyName(CMRThreadsListDidChangeNotification);
	[self writeListToFileNow];
}
@end



@implementation CMRThreadsList(DownLoadPrivate)
- (void) registerToNotificationCeterWithDownloader : (CMRDownloader *) downloader
{
	NSNotificationCenter	*nc_;
	
	if(nil == downloader) return;
	nc_ = [NSNotificationCenter defaultCenter];
	
	[nc_ addObserver : self
			selector : @selector(downloaderFinishedNotified:)
			    name : ThreadListDownloaderUpdatedNotification
			  object : downloader];
	[nc_ addObserver : self
			selector : @selector(downloaderNotFound:)
			    name : CMRDownloaderNotFoundNotification
			  object : downloader];
	[nc_ addObserver : self
			selector : @selector(downloaderTaskStopped:)
				name : CMRTaskDidFinishNotification
			  object : downloader];
}
- (void) removeFromNotificationCeterWithDownloader : (CMRDownloader *) downloader
{
	NSNotificationCenter	*nc_;
	
	if(nil == downloader) return;
	nc_ = [NSNotificationCenter defaultCenter];
	[nc_ removeObserver : self
				   name : ThreadListDownloaderUpdatedNotification
				 object : downloader];
	[nc_ removeObserver : self
				   name : CMRDownloaderNotFoundNotification
				 object : downloader];
}

- (void) downloaderTaskStopped : (NSNotification *) notification
{
	//NSLog(@"TASKSTOPPED");
	/* フェスト・テスタロッサ　チラシの裏
	　ダウンロード完了前に task がストップされるとこのメソッドが呼ばれる。*/
	[[NSNotificationCenter defaultCenter] removeObserver : self
				   name : CMRTaskDidFinishNotification
				 object : [notification object]];

	[self postListDidUpdateNotification : CMRAutoscrollWhenTLUpdate];
}

- (void) downloaderFinishedNotified : (NSNotification *) notification
{
	CMRDownloader		*downloader_;
	NSMutableArray		*newList_;
	//NSLog(@"downloaderFInidhedNotified");
	/* フェイト・テスタロッサ　チラシの裏
	　downloaderFinishedNotified が投げられた時点でまだ task は停止していない。しかしダウンロードが完了したら、
	　もうこの task を捕まえる必要はないので、このメソッド内で通知観察を解除する。よってこのメソッドにたどり着いたら、
	　downloaderTaskStopped: は呼ばれない。*/
	UTILAssertNotificationName(
		notification,
		ThreadListDownloaderUpdatedNotification);
	
	downloader_ = [notification object];
	UTILAssertKindOfClass(downloader_, CMRDownloader);
	UTILAssertNotNil([notification userInfo]);
	
	newList_ = 
		[[notification userInfo] objectForKey : CMRDownloaderUserInfoContentsKey];
	UTILAssertKindOfClass(newList_, NSMutableArray);

	// task の観察を解除
	[[NSNotificationCenter defaultCenter] removeObserver : self
				   name : CMRTaskDidFinishNotification
				 object : [notification object]];
	
	[self donwnloader : [downloader_ retain]
		  didFinished : [newList_ retain]];
}

- (void) donwnloader : (CMRDownloader  *) theDownloader
         didFinished : (NSMutableArray *) newList
{
	SGFileRef   *folder;
	
	folder = [[CMRDocumentFileManager defaultManager]
				ensureDirectoryExistsWithBoardName : [self boardName]];
	UTILAssertNotNil(folder);
	
	[self startUpdateThreadsList:newList update:YES usesWorker:YES];
	[self removeFromNotificationCeterWithDownloader : theDownloader];
	
	[theDownloader release];
	[newList release];
}



- (void) downloaderNotFound : (NSNotification *) notification
{
	CMRDownloader *downloader_;
	NSString      *msg_;
	//NSLog(@"downloaderNotFound");
	/* フェイト・テスタロッサ　チラシの裏
	downloaderNotFound が投げられた時点ではまだ task は終了していない。よってこの時点では taskDidFinish の
	通知観察を解除せず、このメソッド終了後に taskDidFinish を通知してもらう。
	その時点で postListDidUpdateNotification を downloaderTaskStopped: が投げ、一覧は表示される。*/
	UTILAssertNotificationName(
		notification,
		CMRDownloaderNotFoundNotification);
	
	downloader_ = [notification object];
	UTILAssertKindOfClass(downloader_, CMRDownloader);
	[self removeFromNotificationCeterWithDownloader : downloader_];
	
	
	msg_ = [NSString stringWithFormat : 
						[self localizedString : APP_TLIST_NOT_FOUND_MSG_FMT],
						[[downloader_ resourceURL] absoluteString]];
	
	NSBeep();
	NSRunAlertPanel(
		[self localizedString : APP_TLIST_NOT_FOUND_TITLE],
		msg_,
		nil,
		nil,
		nil);
}
@end
