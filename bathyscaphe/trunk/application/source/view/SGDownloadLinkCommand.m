//
//  SGDownloadLinkCommand.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/01/16.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGDownloadLinkCommand.h"
#import "CocoMonar_Prefix.h"
#import <SGAppKit/SGAppKit.h>
#import "CMRTaskManager.h"
#import "AppDefaults.h"
#import "BSLinkDownloadManager.h"


NSString *const kRefererURLKey = @"URL";
NSString *const kRefererTitleKey = @"Title";

@implementation SGDownloadLinkCommand
- (id)initWithObject:(id)obj
{
    if (self = [super initWithObject:obj]) {
        m_expectLength = 0;
        m_downloadedLength = 0;
        m_amount = -1.0;
        m_refererThreadInfo = nil;
    }
    return self;
}

- (void)dealloc
{
    [self setRefererThreadInfo:nil];
    [self setMessage:nil];
    [self setCurrentDownload:nil];
    [super dealloc];
}

- (void)execute:(id)sender
{
    NSString *destination = [CMRPref linkDownloaderDestination];
    UTILAssertNotNil(destination);

    BSURLDownload *download = [[BSURLDownload alloc] initWithURL:[self URLValue] delegate:self destination:destination];
    [self setCurrentDownload:download];
    [download release];

    [self setMessage:NSLocalizedStringFromTable(@"Downloading Message", @"CMRTaskDescription", @"")];
    [[CMRTaskManager defaultManager] addTask:self];
    [[CMRTaskManager defaultManager] taskWillStart:self];
}

- (BOOL)bsURLDownload:(BSURLDownload *)download shouldDownloadWithMIMEType:(NSString *)type
{
    return ![[[BSLinkDownloadManager defaultManager] abortMIMETypes] containsObject:type];
}

- (void)bsURLDownloadDidAbortForDenyingResponsedMIMEType:(BSURLDownload *)download
{
    [self cancel:nil];
    [[NSWorkspace sharedWorkspace] openURL:[self URLValue]];
}

- (void)bsURLDownload:(BSURLDownload *)aDownload willDownloadContentOfSize:(NSUInteger)expectedLength
{
    m_expectLength = expectedLength;
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didDownloadContentOfSize:(NSUInteger)downloadedLength
{
    m_downloadedLength = downloadedLength;

    if (m_expectLength > 0) {
        NSString *template;
        double rate;
        double amountValue;
        // 1048576 == 1024*1024
        if (m_expectLength > 1048576) {
            template = NSLocalizedStringFromTable(@"Downloading Message M", @"CMRTaskDescription", @"");
            rate = 1048576;
        } else {
            template = NSLocalizedStringFromTable(@"Downloading Message K", @"CMRTaskDescription", @"");
            rate = 1024;
        }
// #warning 64BIT: Check formatting arguments
// 2010-05-16 tsawada2 検討済
        [self setMessage:[NSString stringWithFormat:template, m_downloadedLength/rate, m_expectLength/rate]];
        amountValue = ((double)m_downloadedLength/(double)m_expectLength*100.0);

        if (amountValue >= 0 && amountValue <= 100.0) {
            [self setAmount:amountValue];
        }
    }
}

- (void)bsURLDownloadDidFinish:(BSURLDownload *)aDownload
{
    NSString *template;
    double rate;

    if ([self refererThreadInfo]) {
        NSArray *array = [NSArray arrayWithObjects:[[self URLValue] absoluteString], [[self refererThreadInfo] objectForKey:kRefererURLKey], nil];
        NSData *data = [NSPropertyListSerialization dataFromPropertyList:array format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
        [UKXattrMetadataStore setData:data forKey:@"com.apple.metadata:kMDItemWhereFroms" atPath:[aDownload downloadedFilePath] traverseLink:NO];
    }
    
    NSString *folderPath = [[aDownload downloadedFilePath] stringByDeletingLastPathComponent];
    if ([folderPath isEqualToString:[[CMRFileManager defaultManager] userDomainDownloadsFolderPath]]) {
        // 「ダウンロード」フォルダにダウンロードした場合で、「ダウンロード」フォルダが Dock に置かれていてスタック表示なら、アイコンがビョンと跳ねる
        // cf. Camino 2.0 のソースコード（から調べた人たち、例えば http://13bold.com/quick-tricks/downloads-stack/ など）
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DownloadFileFinished" object:[aDownload downloadedFilePath]];
    }

    NSString *ext = [[[self stringValue] componentsSeparatedByString:@"."] lastObject];
    NSUInteger hoge = [[CMRPref linkDownloaderExtensionTypes] indexOfObject:ext];
    if (hoge != NSNotFound) {
        BOOL hage = [[[CMRPref linkDownloaderAutoopenTypes] objectAtIndex:hoge] boolValue];
        if (hage) {
            [[NSWorkspace sharedWorkspace] openFile:[aDownload downloadedFilePath]];
        }
    }
    [self setAmount:-1.0];
    [self setCurrentDownload:nil];

    if (m_downloadedLength > 1048576) {
        template = NSLocalizedStringFromTable(@"Download Finished M", @"CMRTaskDescription", @"");
        rate = 1048576;
    } else {
        template = NSLocalizedStringFromTable(@"Download Finished K", @"CMRTaskDescription", @"");
        rate = 1024;
    }

// #warning 64BIT: Check formatting arguments
// 2010-05-16 tsawada2 検証済
    [self setMessage:[NSString stringWithFormat:template, m_downloadedLength/rate]];
    [[CMRTaskManager defaultManager] taskDidFinish:self];
}

- (BOOL)bsURLDownload:(BSURLDownload *)aDownload shouldRedirectToURL:(NSURL *)newURL
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    NSString *message;
// #warning 64BIT: Check formatting arguments
// 2010-05-16 tsawada2 検証済
    message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"RedirectionAlertMessage", @"HTMLView", @""), [newURL absoluteString]];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert setMessageText:NSLocalizedStringFromTable(@"RedirectionAlertTitle", @"HTMLView", @"")];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"RedirectionAlertCancelBtn", @"HTMLView", @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"RedirectionAlertContinueBtn", @"HTMLView", @"")];
    if ([alert runModal] == NSAlertSecondButtonReturn) {
        return YES;
    }
    return NO;
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didAbortRedirectionToURL:(NSURL *)anURL
{
    [self cancel:nil];
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didFailWithError:(NSError *)aError
{
    [self cancel:nil];

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
// #warning 64BIT: Check formatting arguments
// 2010-05-16 tsawada2 検証済
    NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"FailDownloadAlertMessage", @"HTMLView", @""),
        [aError localizedDescription], [self stringValue]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setMessageText:NSLocalizedStringFromTable(@"FailDownloadAlertTitle", @"HTMLView", @"")];
    [alert setInformativeText:message];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"FailDownloadCancelBtn", @"HTMLView", @"")];
    [alert addButtonWithTitle:NSLocalizedStringFromTable(@"FailDownloadPassBtn", @"HTMLView", @"")];
    if ([alert runModal] == NSAlertSecondButtonReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[self URLValue]];
    }
}

#pragma mark Accessors
- (BSURLDownload *)currentDownload
{
    return m_currentDownload;
}

- (void)setCurrentDownload:(BSURLDownload *)download
{
    [self willChangeValueForKey:@"isInProgress"];
    [download retain];
    [m_currentDownload release];
    m_currentDownload = download;
    [self didChangeValueForKey:@"isInProgress"];
}

- (NSDictionary *)refererThreadInfo
{
    return m_refererThreadInfo;
}

- (void)setRefererThreadInfo:(NSDictionary *)dict
{
    [dict retain];
    [m_refererThreadInfo release];
    m_refererThreadInfo = dict;
}

- (void)setMessage:(NSString *)string
{
    [string retain];
    [m_message release];
    m_message = string;
}

#pragma mark CMRTask
- (id)identifier
{
    return [self stringValue];
}

- (NSString *)title
{
    NSString *linkFileName = [[[self stringValue] componentsSeparatedByString:@"/"] lastObject];
// #warning 64BIT: Check formatting arguments
// 2010-05-16 tsawada2 検討済
    return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Downloading Link", @"CMRTaskDescription", @""), linkFileName];
}

- (NSString *)message
{
    return m_message;
}

- (BOOL)isInProgress
{
    return ([self currentDownload] != nil);
}

- (double)amount
{
    return m_amount;
}

- (void)setAmount:(double)doubleValue
{
    m_amount = doubleValue;
}

- (IBAction)cancel:(id)sender
{
    NSString *toBeRemoved;
    [[self currentDownload] cancel];

    toBeRemoved = [[self currentDownload] downloadedFilePath];
    if (toBeRemoved && [[NSFileManager defaultManager] fileExistsAtPath:toBeRemoved]) {
        [[NSFileManager defaultManager] removeItemAtPath:toBeRemoved error:NULL];
    }

    [self setAmount:-1.0];
    [self setCurrentDownload:nil];
    [self setMessage:NSLocalizedStringFromTable(@"Task Canceled", @"CMRTaskDescription", @"Task Canceled")];
    [[CMRTaskManager defaultManager] taskDidFinish:self];
}
@end
