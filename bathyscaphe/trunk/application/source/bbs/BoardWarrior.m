//
//  BoardWarrior.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/08/06.
//  Copyright 2006-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BoardWarrior.h"
#import "CocoMonar_Prefix.h"
#import "AppDefaults.h"
#import "BSDateFormatter.h"
#import "BoardManager.h"
#import <SGAppKit/NSAppleScript-SGExtensions.h>
#import <AudioToolbox/AudioToolbox.h>

#import "BSModalStatusWindowController.h"

NSString *const kBoardWarriorErrorDomain	= @"BoardWarriorErrorDomain";

static NSString *const kBWLocalizedStringsTableName = @"BoardWarrior";

static NSString *const kBWLogFolderName	= @"Logs";
static NSString *const kBWLogFileName	= @"BathyScaphe BoardWarrior.log";

static NSString *const kBWTaskTitleKey			= @"BW_task title";
static NSString *const kBWTaskMsgKey			= @"BW_task message";
static NSString *const kBWTaskMsgFailedKey		= @"BW_task fail";
static NSString *const kBWTaskMsgFinishedKey	= @"BW_task finish";
static NSString *const kBWTaskInformativeKey    = @"BW_task modal info";

@interface BoardWarrior(Private)
- (NSString *)bbsMenuPath;
- (void)setBbsMenuPath:(NSString *)filePath;

- (NSData *)encodedLocalizedStringForKey:(NSString *)key format:(NSString *)format;
- (BOOL)writeLogsToFileWithUTF8Data:(NSData *)encodedData;

- (NSInteger)runSession;
- (void)closeAndEndSession;
@end


@implementation BoardWarrior
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(warrior);

- (id)delegate
{
	return m_delegate;
}

- (void)setDelegate:(id)aDelegate
{
	m_delegate = aDelegate;
}

- (BOOL)syncBoardLists
{
	BSURLDownload	*newDownload_;
	NSString		*tmpDir_ = NSTemporaryDirectory();

	if ([self isInProgress] || !tmpDir_) {
		return NO;
	}

    [[m_statusWindowController infoTextField] setStringValue:[self localizedString:kBWTaskInformativeKey]];
    [[m_statusWindowController messageTextField] setStringValue:[self localizedString:kBWTaskMsgKey]];
    [[m_statusWindowController progressIndicator] startAnimation:nil];

    m_session = [NSApp beginModalSessionForWindow:[m_statusWindowController window]];

	newDownload_ = [[BSURLDownload alloc] initWithURL:[CMRPref BBSMenuURL] delegate:self destination:tmpDir_];
	if (newDownload_) {
		NSData *logMsg;
		m_currentDownload = newDownload_;

		logMsg = [self encodedLocalizedStringForKey:@"BW_start at date %@" format:[[NSDate date] description]];
		[self writeLogsToFileWithUTF8Data:logMsg];
    } else {
        [self closeAndEndSession];
		return NO;
	}

	return YES;
}

- (NSString *)logFilePath
{
	NSString *logsPath = [[CMRFileManager defaultManager] userDomainLogsFolderPath];
	if (!logsPath) {
        return nil;
    }
	return [logsPath stringByAppendingPathComponent:kBWLogFileName];
}

#pragma mark Overrides
- (id)init
{
	if (self = [super init]) {
        m_statusWindowController = [[BSModalStatusWindowController alloc] init];
        [[m_statusWindowController progressIndicator] setIndeterminate:YES];
	}
	return self;
}

- (void)dealloc
{
    [m_statusWindowController release];
	[m_bbsMenuPath release];
	m_currentDownload = nil;
	m_delegate = nil;
    m_session = nil;
	[super dealloc];
}

+ (NSString *)localizableStringsTableName
{
	return kBWLocalizedStringsTableName;
}

- (BOOL)isInProgress
{
    return (m_session != nil);
}
@end


@implementation BoardWarrior(Private)
- (NSString *)bbsMenuPath
{
	return m_bbsMenuPath;
}

- (void)setBbsMenuPath:(NSString *)filePath
{
	[filePath retain];
	[m_bbsMenuPath release];
	m_bbsMenuPath = filePath;
}

- (NSData *)encodedLocalizedStringForKey:(NSString *)key format:(NSString *)format
{
	NSString *str = [self localizedString:key];

	return [[NSString stringWithFormat:str, format] dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)delegateRespondsToSelector:(SEL)selector
{
	id delegate = [self delegate];
	return (delegate && [delegate respondsToSelector:selector]);
}

- (void)didFailSyncing:(NSError *)error
{
    [self closeAndEndSession];
    NSBeep();
    if (error) {
        [[NSAlert alertWithError:error] runModal];
    }
}

- (NSArray *)parametersForHandler:(NSString *)handlerName
{
	NSBundle *bathyscaphe = [NSBundle mainBundle];
	NSString *logFolderPath_ = [[CMRFileManager defaultManager] dataRootDirectoryPath];

	if ([handlerName isEqualToString:@"make_default_list"]) {
		NSString *soraToolPath_ = [bathyscaphe pathForResource:@"sora" ofType:@"pl"];
		NSString *convertToolPath_ = [bathyscaphe pathForResource:@"SJIS2UTF8" ofType:@""];
		return [NSArray arrayWithObjects:soraToolPath_, convertToolPath_, logFolderPath_, [self bbsMenuPath], nil];
	} else {
		NSString *rosettaToolPath_ = [bathyscaphe pathForResource:@"rosetta" ofType:@"pl"];
		return [NSArray arrayWithObjects:rosettaToolPath_, logFolderPath_, [self bbsMenuPath], nil];
	}
}

- (BOOL)doHandler:(NSString *)handlerName inScript:(NSAppleScript *)script
{
	NSDictionary *errors_ = [NSDictionary dictionary];
	NSArray *params_ = [self parametersForHandler:handlerName];

	if (![script doHandler:handlerName withParameters:params_ error:&errors_]) {
		NSString *errDescription_ = [errors_ objectForKey:NSAppleScriptErrorMessage];
        if (!errDescription_) {
            errDescription_ = @"Unknown AppleScript Exec Error";
        }
		[self writeLogsToFileWithUTF8Data:[self encodedLocalizedStringForKey:@"BW_sub_error %@" format:errDescription_]];

        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errDescription_ forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kBoardWarriorErrorDomain code:BWDidFailExecuteAppleScriptHandler userInfo:userInfo];

		[self didFailSyncing:error];

		if ([self delegateRespondsToSelector:@selector(warrior:didFailSync:)]) {
			[[self delegate] warrior:self didFailSync:error];
		}
		return NO;
	}

	[self writeLogsToFileWithUTF8Data:[self encodedLocalizedStringForKey:@"BW_run %@" format:handlerName]];
	return YES;
}

- (NSURL *)fileURLWithResource:(NSString *)name ofType:(NSString *)extension
{
	NSBundle *bundle_ = [NSBundle mainBundle];
	NSString *path_ = [bundle_ pathForResource:name ofType:extension];
	if (!path_) {
        return nil;
    }
	return [NSURL fileURLWithPath:path_];
}

- (void)startAppleScriptTask
{
    [self runSession];

	BoardManager *bm = [BoardManager defaultManager];

	/* まず NSAppleScript インスタンスを生成 */
	NSURL *url_ = [self fileURLWithResource:@"BoardWarrior" ofType:@"scpt"];
	if (!url_) {
		[self writeLogsToFileWithUTF8Data:[self encodedLocalizedStringForKey:@"BW_fail_script1" format:@"BoardWarrior"]];

        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[self localizedString:@"BW_fail_init"] forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kBoardWarriorErrorDomain code:BWDidFailInitializeAppleScript userInfo:userInfo];

		[self didFailSyncing:error];

		if ([self delegateRespondsToSelector:@selector(warrior:didFailSync:)]) {
			[[self delegate] warrior:self didFailSync:error];
		}
		return;
	}

    [self runSession];

	NSAppleScript *script_ = [[NSAppleScript alloc] initWithContentsOfURL:url_ error:NULL];
	if (!script_) {
		[self writeLogsToFileWithUTF8Data:[self encodedLocalizedStringForKey:@"BW_fail_script2" format:@"BoardWarrior"]];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[self localizedString:@"BW_fail_init"] forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:kBoardWarriorErrorDomain code:BWDidFailInitializeAppleScript userInfo:userInfo];

		[self didFailSyncing:error];

		if ([self delegateRespondsToSelector:@selector(warrior:didFailSync:)]) {
			[[self delegate] warrior:self didFailSync:error];
		}
		return;
	}

	/* make_default_list */
    [self runSession];

    if (![self doHandler:@"make_default_list" inScript:script_]) {
		[script_ release];
		// delete bbsmenu.html
        [[NSFileManager defaultManager] removeItemAtPath:[self bbsMenuPath] error:NULL];
		[self setBbsMenuPath:nil];

		return;
	}

	/* update_user_list */
    [self runSession];

    BOOL success = [self doHandler:@"update_user_list" inScript:script_];

	[script_ release];

	// delete bbsmenu.html
    [[NSFileManager defaultManager] removeItemAtPath:[self bbsMenuPath] error:NULL];
	[self setBbsMenuPath:nil];

	if (!success) {
        return;
    }
//    [self runSession];

	NSDate *date_ = [NSDate date];
	[CMRPref setLastSyncDate:date_];
	[self writeLogsToFileWithUTF8Data:[self encodedLocalizedStringForKey:@"BW_finish at date %@" format:[date_ description]]];

//    [self runSession];
//	[[bm defaultList] reloadBoardFile:[bm defaultBoardListPath]];

//    [self runSession];
//    [[bm userList] reloadBoardFile:[bm userBoardListPath]];
    [bm reloadBoardFilesIfNeeded];

    [self closeAndEndSession];

	AudioServicesPlaySystemSound(22); // Disc Burned

	if ([self delegateRespondsToSelector:@selector(warriorDidFinishSyncing:)]) {
		[[self delegate] warriorDidFinishSyncing:self];
	}
}

- (BOOL)createLogFileIfNeededAtPath:(NSString *)filePath
{
	BOOL isDir;
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
		return YES;
	} else {
		return [fm createFileAtPath:filePath contents:[NSData data] attributes:nil];
	}
}

- (BOOL)writeLogsToFileWithUTF8Data:(NSData *)encodedData
{
	if (!encodedData) return NO;
	NSString *logFilePath = [self logFilePath];

	if (logFilePath && [self createLogFileIfNeededAtPath:logFilePath]) {
		NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
		
		[fileHandle seekToEndOfFile];
		[fileHandle writeData:encodedData];
		[fileHandle closeFile];
		return YES;
	}
	
	return NO;
}

- (NSInteger)runSession
{
    return [NSApp runModalSession:m_session];
}

- (void)closeAndEndSession
{
    [[m_statusWindowController progressIndicator] stopAnimation:nil];
    [m_statusWindowController close];
    [NSApp endModalSession:m_session];
    m_session = nil;
}

#pragma mark BSIPIDownload Delegate
- (void)bsURLDownload:(BSURLDownload *)aDownload willDownloadContentOfSize:(NSUInteger)expectedLength
{
    NSData *data = [self encodedLocalizedStringForKey:@"BW_download from %@" format:[[aDownload URL] absoluteString]];
	[self writeLogsToFileWithUTF8Data:data];	
}

- (void)bsURLDownloadDidFinish:(BSURLDownload *)aDownload
{
	[self setBbsMenuPath:[aDownload downloadedFilePath]];
	[self writeLogsToFileWithUTF8Data:[[self localizedString:@"BW_download finish"] dataUsingEncoding:NSUTF8StringEncoding]];

	[aDownload release];
	m_currentDownload = nil;
	[self startAppleScriptTask];
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didFailWithError:(NSError *)aError
{
	[self writeLogsToFileWithUTF8Data:[self encodedLocalizedStringForKey:@"BW_download fail %@" format:[aError description]]];

	[self didFailSyncing:aError];

	if ([self delegateRespondsToSelector:@selector(warrior:didFailSync:)]) {
		[[self delegate] warrior:self didFailSync:aError];
	}

	[aDownload release];
	m_currentDownload = nil;
}
@end
