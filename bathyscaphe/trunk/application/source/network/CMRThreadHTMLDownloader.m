//
//  CMRThreadHTMLDownloader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/22.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadHTMLDownloader.h"
#import "ThreadTextDownloader_p.h"
#import "CMRHostHandler.h"
#import "CMRHostHTMLHandler.h"
#import "DatabaseManager.h"


@implementation CMRThreadHTMLDownloader
+ (NSMutableDictionary *)defaultRequestHeaders
{
	return [NSMutableDictionary dictionaryWithObjectsAndKeys :
				@"no-cache",				HTTP_CACHE_CONTROL_KEY,
				@"no-cache",				HTTP_PRAGMA_KEY,
				@"Close",					HTTP_CONNECTION_KEY,
				[NSBundle monazillaUserAgent],	HTTP_USER_AGENT_KEY,
				@"text/html",				HTTP_ACCEPT_KEY,
				@"ja",						HTTP_ACCEPT_LANGUAGE_KEY,
				nil];
}

+ (BOOL)canInitWithURL:(NSURL *)url
{
	CMRHostHandler	*handler_;
	
	handler_ = [CMRHostHandler hostHandlerForURL:url];
	return handler_ ? (NO == [handler_ canReadDATFile]) : NO;
}

- (NSURL *)threadURL
{
	NSURL				*boardURL_;
	NSURL				*threadURL_;
	CMRHostHandler		*handler_;
	NSUInteger			nextIndex;
	
	boardURL_ = [self boardURL];
	UTILAssertNotNil(boardURL_);
	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
    UTILAssertKindOfClass(handler_, CMRHostHTMLHandler);
	nextIndex = ([self nextIndex] != NSNotFound) ? [self nextIndex] : 0;

	threadURL_ = [(CMRHostHTMLHandler *)handler_ rawmodeURLWithBoard:boardURL_
									   datName:[[self threadSignature] identifier]
										 start:nextIndex +1
										   end:NSNotFound
									   nofirst:(nextIndex != 0)];

	return threadURL_;
}

- (NSURL *)resourceURL
{
	return [self threadURL];
}

- (NSString *)contentsWithData:(NSData *)theData
{
	CFStringEncoding	enc;
	NSString			*src = nil;
	enc = [self CFEncodingForLoadedData];
    if (enc != kCFStringEncodingEUC_JP) {
        return [super contentsWithData:theData];
    }
	
	if (!theData || [theData length] == 0) {
        return nil;
	}
    // EUC-JP（したらば）のみ常に TEC 使用     
    src = [[NSString alloc] initWithDataUsingTEC:theData encoding:CF2TextEncoding(enc)];
    return [src autorelease];
}

- (BOOL)dataProcess:(NSData *)resourceData withConnector:(NSURLConnection *)connector
{
	NSString *inputSource_;
	id thread_;
	CMRHostHandler *handler_;
    BOOL showsDebugLog = [[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey];
	
	if (!resourceData) {
		return YES;
	}
	
	handler_ = [CMRHostHandler hostHandlerForURL:[self boardURL]];
    UTILAssertKindOfClass(handler_, CMRHostHTMLHandler);
	inputSource_ = [self contentsWithData:resourceData];
	thread_ = [[[NSMutableString alloc] init] autorelease];

	if (!inputSource_) {
        if (showsDebugLog) {
		NSLog(@"\n"
			@"*** WARNING ***\n\t"
			@"Can't convert the bytes into Unicode characters\n\t"
			@"so can't convert string to thread.");
        }
        return NO;
	}
	NSUInteger datNumOfAll;
	thread_ = [(CMRHostHTMLHandler *)handler_ parseHTML:inputSource_ with:thread_ count:[self nextIndex] lastReadedCount:&datNumOfAll];
	if (!thread_ || [thread_ isEmpty]) {
		return YES;
	}

    NSArray *boardIDs = [[DatabaseManager defaultManager] boardIDsForName:[[self threadSignature] boardName]];
    if (!boardIDs || [boardIDs count] == 0) {
        return [self synchronizeLocalDataWithContents:thread_ dataLength:0];
    }

    // スレッド一覧の「レス数」カラムの数値と、実際に取得された内容の最終レス番を比較し、足りなければ
    // 最終レスがあぼーんされていると見なし、末尾にダミー行を追加する
    NSUInteger boardID;
    boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];    
    id tListNumOfAllObj = [[DatabaseManager defaultManager] valueForKey:NumberOfAllColumn
                                                                boardID:boardID
                                                               threadID:[[self threadSignature] identifier]];

    NSUInteger tListNumOfAll = [tListNumOfAllObj unsignedIntegerValue];
    if (showsDebugLog) {
        NSLog(@"** USER DEBUG ** Downloaded contents last res number: %lu / Threads list last res number: %lu",
              (unsigned long)datNumOfAll, (unsigned long)tListNumOfAll);
    }
    NSInteger delta = (tListNumOfAll - datNumOfAll);
    if (showsDebugLog) {
        NSLog(@"** USER DEBUG ** Delta: %li", (long)delta);
    }
    if (delta > 0) {
        NSInteger i;
        for (i = 0; i < delta; i++) {
            if (showsDebugLog) {
                NSLog(@"** USER DEBUG ** Appending dummy dat line...");
            }
            // ダミー行の追加
            [thread_ appendString:@"<><><><>\n"];
        }
    } else {
        if (showsDebugLog) {
            NSLog(@"** USER DEBUG ** No need to append dummy dat line.");
        }
    }

	return [self synchronizeLocalDataWithContents:thread_ dataLength:0];
}
@end
