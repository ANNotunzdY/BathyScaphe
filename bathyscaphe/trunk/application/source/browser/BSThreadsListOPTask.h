//
//  BSThreadsListOPTask.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/06.
//  Copyright 2006-2010,2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

#import "BSDBThreadList.h"

#import "BSThreadListTask.h"

@class BSDownloadTask, BSDBThreadsListDBUpdateTask2;

@interface BSThreadsListOPTask : BSThreadListTask
{
	BSDBThreadList *m_targetList;
	BOOL m_forceDL;
	
	NSURL *targetURL;
	NSString *bbsName;
	BSDownloadTask *dlTask;
	BSDBThreadsListDBUpdateTask2 *dbupTask;
	
	NSData *m_downloadData;
	NSError *m_downloadError;
	BOOL	isRebuilding;
    BOOL isLivedoor;
}
@property (nonatomic, copy) NSString *boardName;

+ (id)taskWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)forceDL;
- (id)initWithThreadList:(BSDBThreadList *)list forceDownload:(BOOL)forceDL rebuild:(BOOL)flag;

@end

extern NSString *const ThreadsListDownloaderShouldRetryUpdateNotification;
