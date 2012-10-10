//
//  CMRDATDownloader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRDATDownloader.h"
#import "ThreadTextDownloader_p.h"
#import "CMRServerClock.h"
#import "CMRHostHandler.h"
#import "DatabaseManager.h"
#import "missing.h"


// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"

NSString *const CMRDATDownloaderDidDetectDatOchiNotification = @"CMRDATDownloaderDidDetectDatOchiNotification";
NSString *const CMRDATDownloaderDidSuspectBBONNotification = @"CMRDATDownloaderDidSuspectBBONNotification";
NSString *const CMRDATDownloaderDidDetectInvalidHEADUpdatedNotification = @"CMRDATDownloaderDidDitectIHUNotification";


@implementation CMRDATDownloader
+ (BOOL)canInitWithURL:(NSURL *)url
{
	CMRHostHandler	*handler_;

	handler_ = [CMRHostHandler hostHandlerForURL:url];
	return handler_ ? [handler_ canReadDATFile] : NO;
}

- (NSURL *)threadURL
{
	CMRHostHandler	*handler_;
	NSURL			*boardURL_ = [self boardURL];

	UTILAssertNotNil([self threadSignature]);

	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
	return [handler_ readURLWithBoard:boardURL_ datName:[[self threadSignature] identifier]];
}

- (NSURL *)resourceURL
{
	CMRHostHandler	*handler_;
	NSURL			*boardURL_ = [self boardURL];

	UTILAssertNotNil([self threadSignature]);

	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
	return [handler_ datURLWithBoard:boardURL_ datName:[[self threadSignature] datFilename]];
}

- (void)cancelDownloadWithDetectingDatOchi
{
	NSArray			*recoveryOptions;
	NSDictionary	*dict;
	NSError			*error;
    NSString *description;
    NSString *suggestion;
    if ([self threadTitle]) {
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 検討済
        description = [NSString stringWithFormat:[self localizedString:@"DatOchiDescription"], [self threadTitle]];
        suggestion = [self localizedString:@"DatOchiSuggestion"];
    } else {
        NSString *tmp;
        description = [self localizedString:@"DatOchiDescription2"];
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 検討済
        tmp = [NSString stringWithFormat:[self localizedString:@"DatOchiSuggestion2"], [[self threadURL] absoluteString]];
        suggestion = [tmp stringByAppendingString:[self localizedString:@"DatOchiSuggestion"]];
    }

	recoveryOptions = [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], [self localizedString:@"DatOchiRetry"], nil];
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
				recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
				description, NSLocalizedDescriptionKey,
				suggestion, NSLocalizedRecoverySuggestionErrorKey,
                [self localizedString:@"DatOchiHelpAnchor"], NSHelpAnchorErrorKey,
				NULL];
	error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSDATDownloaderThreadNotFoundError userInfo:dict];
	UTILNotifyInfo3(CMRDATDownloaderDidDetectDatOchiNotification, error, @"Error");
}

- (void)cancelDownloadWithSuspectingBBON
{
    NSArray *recoveryOptions;
    NSDictionary *dict;
    NSError *error;

    recoveryOptions = [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], [self localizedString:@"BBONInfo"], nil];
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
                recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
                [self localizedString:@"BBONDescription"], NSLocalizedDescriptionKey,
                [self localizedString:@"BBONSuggestion"], NSLocalizedRecoverySuggestionErrorKey,
                NULL];
    error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:403 userInfo:dict];
    UTILNotifyInfo3(CMRDATDownloaderDidSuspectBBONNotification, error, @"Error");
}
@end


@implementation CMRDATDownloader(PrivateAccessor)
- (void)setupRequestHeaders:(NSMutableDictionary *)mdict
{
	[super setupRequestHeaders:mdict];

	if ([self partialContentsRequested]) {
		NSNumber *byteLenNum_;
		NSDate *lastDate_;
		NSInteger bytelen;
		NSString *rangeString;
		
		byteLenNum_ = [[self localThreadsDict] objectForKey:ThreadPlistLengthKey];
		UTILAssertNotNil(byteLenNum_);
		lastDate_ = [[self localThreadsDict] objectForKey:CMRThreadModifiedDateKey];

		[mdict setObject:@"identity" forKey:HTTP_ACCEPT_ENCODING_KEY];

		bytelen = [byteLenNum_ integerValue];
		bytelen -= 1; // Get Extra 1 byte, then check received data. if 1st byte is not \n, it's error.
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 修正済
		rangeString = [NSString stringWithFormat:@"bytes=%ld-", (long)bytelen];
		[mdict setNoneNil:rangeString forKey:HTTP_RANGE_KEY];

        NSString *rfc1123dateString = [[BSHTTPDateFormatter sharedHTTPDateFormatter] stringFromDate:lastDate_];
        [mdict setNoneNil:rfc1123dateString forKey:HTTP_IF_MODIFIED_SINCE_KEY];
	}
}
@end


@implementation CMRDATDownloader(ResourceManagement)
// 2ch の場合 Last-Modified がレスポンスヘッダに存在するので、それを解析
- (void)synchronizeServerClock:(NSHTTPURLResponse *)response
{
	[super synchronizeServerClock:response];
	NSString *dateString2;
	NSDate *date2;

	dateString2 = [[response allHeaderFields] stringForKey:HTTP_LAST_MODIFIED_KEY];
	if (!dateString2) {
		return;
	} else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** synchronizeServerClock: OK.");
        }
	}
	date2 = [[BSHTTPDateFormatter sharedHTTPDateFormatter] dateFromString:dateString2];
	if (!date2) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** ERROR - Why? failed to convert. String: %@", dateString2);
        }
	} else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** dateString2 -> date2: OK.");
        }
	}

	[self setLastDate:date2];
}
@end


@implementation CMRDATDownloader(LoadingResourceData)
- (void)fixDatabaseStatus:(ThreadStatus)validStatus
{
    CMRThreadSignature *signature = [self threadSignature];
    DatabaseManager *dbm = [DatabaseManager defaultManager];
    
    [dbm updateStatus:validStatus modifiedDate:[self lastDate] forThreadSignature:signature];
}

- (BOOL)dataProcess:(NSData *)resourceData withConnector:(NSURLConnection *)connector
{
	NSString			*datContents_;

	if (!resourceData || [resourceData length] == 0) {
		return NO;
	}

	if ([self partialContentsRequested]) {
		const char		*p = NULL;
		p = (const char *)[resourceData bytes];
		if (*p != '\n') {
			[self cancelDownloadWithInvalidPartial];
			return NO;
		}
	}
	
	datContents_ = [self contentsWithData:resourceData];
    if ([datContents_ length] == 1) {
        // データが「\n」のみ＝実際には新着レスが無い
        [self setAmount:-1];
        [self fixDatabaseStatus:ThreadLogCachedStatus];
        return NO;
    }

    if ([self useMaru]) {
        if ([datContents_ hasPrefix:[self localizedString:@"maruNotExists"]]) {
            [self cancelDownloadWithDetectingDatOchi];
            return NO;
        } else if ([datContents_ hasPrefix:@"+OK"]) {
            // 最初の行を切り取る
            NSRange firstLineRange = [datContents_ lineRangeForRange:NSMakeRange(0, 1)];
            NSUInteger secondLineHead = NSMaxRange(firstLineRange);
            NSAssert(secondLineHead < [datContents_ length], @"Invalid maru downloaded content?");
            datContents_ = [datContents_ substringFromIndex:secondLineHead];
        }
    }

	return [self synchronizeLocalDataWithContents:datContents_ dataLength:[resourceData length]];
}
@end
