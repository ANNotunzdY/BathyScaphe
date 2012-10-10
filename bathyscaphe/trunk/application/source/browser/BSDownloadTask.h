//
//  BSDownloadTask.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 06/08/06.
//  Copyright 2006-2009,2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

#import "BSThreadListTask.h"

@interface BSDownloadTask : BSThreadListTask
{
	NSURL *m_targetURL;

	CGFloat	m_contLength;
	CGFloat	m_currentLength;

	NSMutableData *receivedData;
	NSURLConnection *con;
	id _response;

	NSString *method;
    BOOL m_contLengthIsUnknown;
}
@property (retain) NSURL *URL;
@property (readonly, retain) NSData *receivedData;

+ (id)taskWithURL:(NSURL *)url;
- (id)initWithURL:(NSURL *)url;
+ (id)taskWithURL:(NSURL *)url method:(NSString *)method;
- (id)initWithURL:(NSURL *)url method:(NSString *)method;

- (NSData *)receivedData;
- (id)response;

- (void)synchronousDownLoad;
@end


@interface BSDownloadTask(TaskNotification)
- (void)postNotificationWithName:(NSString *)name userInfo:(NSDictionary *)info;
- (void)postNotificaionWithResponse:(NSURLResponse *)response;
- (void)postNotificaionWithResponseDontFinish:(NSURLResponse *)response;
@end


extern NSString *const BSDownloadTaskFinishDownloadNotification;
extern NSString *const BSDownloadTaskCanceledNotification;
extern NSString *const BSDownloadTaskInternalErrorNotification;
extern NSString *const BSDownloadTaskReceiveResponseNotification;
extern NSString *const BSDownloadTaskAbortDownloadNotification;
extern NSString	*const BSDownloadTaskFailDownloadNotification;

extern NSString *const BSDownloadTaskServerResponseKey;	// NSURLResponse
extern NSString	*const BSDownloadTaskStatusCodeKey;	// NSNumber (int)
extern NSString *const BSDownloadTaskErrorObjectKey; // NSError
