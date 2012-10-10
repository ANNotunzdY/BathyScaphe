//
//  CMRThreadViewer-Download.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/23.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"
#import "CMRAbstructThreadDocument.h"
#import "CMRDATDownloader.h"
#import "BSLoggedInDATDownloader.h"

@implementation CMRThreadViewer(Download)
#pragma mark Start Downloading
- (void)downloadThread:(CMRThreadSignature *)aSignature title:(NSString *)threadTitle nextIndex:(NSUInteger)aNextIndex
{
	CMRDownloader			*downloader;
	NSNotificationCenter	*nc;
	
	nc = [NSNotificationCenter defaultCenter];
	downloader = [ThreadTextDownloader downloaderWithIdentifier:aSignature threadTitle:threadTitle nextIndex:aNextIndex];

	if (!downloader) return;
	
	/* NotificationCenter */
    [nc addObserver:self 
           selector:@selector(threadTextDownloaderConnectionDidFail:) 
               name:CMRDownloaderConnectionDidFailNotification 
             object:downloader];
	[nc addObserver:self
		   selector:@selector(threadTextDownloaderInvalidPerticalContents:)
			   name:ThreadTextDownloaderInvalidPerticalContentsNotification
			 object:downloader];
	[nc addObserver:self
		   selector:@selector(threadTextDownloaderDidDetectDatOchi:)
			   name:CMRDATDownloaderDidDetectDatOchiNotification
			 object:downloader];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderDidSuspectBBON:)
               name:CMRDATDownloaderDidSuspectBBONNotification
             object:downloader];
	[nc addObserver:self
		   selector:@selector(threadTextDownloaderDidFinishLoading:)
			   name:ThreadTextDownloaderDidFinishLoadingNotification
			 object:downloader];

	/* TaskManager, load */
	[[CMRTaskManager defaultManager] addTask:downloader];
	[downloader loadInBackground];
}

#pragma mark After Download (Success)
- (void)removeFromNotificationCeterWithDownloader:(CMRDownloader *)downloader
{
	NSNotificationCenter	*nc;

	if (!downloader) return;
	nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self
				  name:CMRDownloaderConnectionDidFailNotification
				object:downloader];
	[nc removeObserver:self
				  name:ThreadTextDownloaderInvalidPerticalContentsNotification
				object:downloader];
	[nc removeObserver:self
				  name:CMRDATDownloaderDidDetectDatOchiNotification
				object:downloader];
    [nc removeObserver:self
                  name:CMRDATDownloaderDidSuspectBBONNotification
                object:downloader];
	[nc removeObserver:self
				  name:ThreadTextDownloaderDidFinishLoadingNotification
				object:downloader];
}

- (void)threadTextDownloaderDidFinishLoading:(NSNotification *)notification
{
	ThreadTextDownloader	*downloader;
	NSDictionary			*userInfo;
	NSString				*contents;

	UTILAssertNotificationName(notification, ThreadTextDownloaderDidFinishLoadingNotification);
	
	userInfo = [notification userInfo];
	UTILAssertNotNil(userInfo);

	downloader = [[notification object] retain];
	contents = [userInfo objectForKey:CMRDownloaderUserInfoContentsKey];
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
	UTILAssertKindOfClass(contents, NSString);
	
	[self removeFromNotificationCeterWithDownloader:downloader];

	if (![[self threadIdentifier] isEqual:[downloader identifier]]) {
        [downloader release];
		return;
	}

	[[self threadAttributes] addEntriesFromDictionary:[userInfo objectForKey:CMRDownloaderUserInfoAdditionalInfoKey]];
	[self composeDATContents:contents threadSignature:[downloader identifier] nextIndex:[downloader nextIndex]];
	[downloader autorelease];
}

#pragma mark After Download (Some Error)
- (void)threadTextDownloaderConnectionDidFail:(NSNotification *)notification
{
	ThreadTextDownloader	*downloader;
	
	UTILAssertNotificationName(notification, CMRDownloaderConnectionDidFailNotification);
    
	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
    
	[self removeFromNotificationCeterWithDownloader:downloader];

	NSAlert *alert = [NSAlert alertWithError:[[notification userInfo] objectForKey:@"Error"]];
    if ([self isRetrieving]) {
        NSString *tmp = [(NSError *)[[notification userInfo] objectForKey:@"Error"] localizedRecoverySuggestion];
        [alert setInformativeText:[tmp stringByAppendingString:NSLocalizedStringFromTable(@"ConnectionFailedSuggestionRetrieving", @"Downloader", @"")]];
    }

	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(threadConnectionFailedSheetDidEnd:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)threadTextDownloaderInvalidPerticalContents:(NSNotification *)notification
{
	ThreadTextDownloader	*downloader;
	
	UTILAssertNotificationName(notification, ThreadTextDownloaderInvalidPerticalContentsNotification);

	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);

	[self removeFromNotificationCeterWithDownloader:downloader];

	NSAlert *alert = [NSAlert alertWithError:[[notification userInfo] objectForKey:@"Error"]];
	[alert setShowsHelp:YES];
	[alert setDelegate:[NSApp delegate]];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(threadInvalidParticalContentsSheetDidEnd:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)informDatOchiWithTitleRulerIfNeeded
{
	if ([CMRPref informWhenDetectDatOchi]) {
		BSTitleRulerView *ruler = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];

		[ruler setCurrentMode:[[self class] rulerModeForInformDatOchi]];
		[ruler setInfoStr:[self localizedString:@"titleRuler info auto-detected title"]];
		[[self scrollView] setRulersVisible:YES];

		[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(cleanUpTitleRuler:) userInfo:nil repeats:NO];
	}
}

- (void)beginNotFoundAlertSheetWithDownloader:(ThreadTextDownloader *)downloader error:(NSError *)error
{
	NSString	*filePath;
	filePath = [downloader filePathToWrite];

	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if (![self isRetrieving]) {
            if ([[self threadIdentifier] isEqual:[downloader identifier]]) {
                [(CMRAbstructThreadDocument *)[self document] setIsDatOchiThread:YES];
                [self informDatOchiWithTitleRulerIfNeeded];
            }
            [downloader autorelease];
            return;
        }
	}

	NSAlert *alert = [NSAlert alertWithError:error];

    if ([self isRetrieving]) {
        [alert setInformativeText:NSLocalizedStringFromTable(@"DatOchiSuggestionRetrieving", @"Downloader", @"")];
    }
	[alert setShowsHelp:YES];
	[alert setDelegate:[NSApp delegate]];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(threadNotFoundSheetDidEnd:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)validateWhetherDatOchiWithDownloader:(ThreadTextDownloader *)downloader error:(NSError *)error
{
	NSUInteger	resCount;
	resCount = [downloader nextIndex];

	if ((resCount < 1001) || [self isRetrieving]) {
		[self beginNotFoundAlertSheetWithDownloader:downloader error:error];
	} else {
		if ([[self threadIdentifier] isEqual:[downloader identifier]]) {
			[(CMRAbstructThreadDocument *)[self document] setIsDatOchiThread:YES];
			[self informDatOchiWithTitleRulerIfNeeded];
			[downloader autorelease];
		}
	}
}

- (void)threadTextDownloaderDidDetectDatOchi:(NSNotification *)notification
{
	CMRDATDownloader	*downloader;
	
	UTILAssertNotificationName(notification, CMRDATDownloaderDidDetectDatOchiNotification);
		
	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, CMRDATDownloader);

	[self removeFromNotificationCeterWithDownloader:downloader];

	[self validateWhetherDatOchiWithDownloader:downloader error:[[notification userInfo] objectForKey:@"Error"]];
//    [downloader autorelease]; // 禁止！
}

- (void)threadConnectionFailedSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
    
	if (returnCode == NSAlertFirstButtonReturn) {
        if ([self isRetrieving]) {
            [self restoreFromRetrieving:[downloader filePathToWrite] error:NULL];
        }
	}
	[downloader autorelease];
}

- (void)threadInvalidParticalContentsSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSString				*path;
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
	path = [downloader filePathToWrite];

	switch (returnCode) {
	case NSAlertFirstButtonReturn: // Delete and try again
	{
		if (![self retrieveThreadAtPath:path title:[downloader threadTitle]]) {
			NSBeep();
			NSLog(@"Deletion failed : %@\n...So reloading operation has been canceled.", path);
		}
		break;
	}
	case NSAlertSecondButtonReturn: // Cancel
		break;
	default:
		UTILUnknownSwitchCase(returnCode);
		break;
	}
	[downloader autorelease];
}

- (void)threadNotFoundSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);

	switch (returnCode) {
	case NSAlertFirstButtonReturn:
        {
            if ([self isRetrieving]) {
                [self restoreFromRetrieving:[downloader filePathToWrite] error:NULL];
            } else {
                [self closeWindowOfAlert:sheet];
            }
        }
		break;
	case NSAlertSecondButtonReturn:
		[self downloadThreadUsingMaru:[downloader threadSignature] title:[downloader threadTitle]];
		break;
	default:
		UTILUnknownSwitchCase(returnCode);
		break;
	}
	[downloader autorelease];
}

- (void)threadTextDownloaderDidSuspectBBON:(NSNotification *)notification
{
	CMRDATDownloader	*downloader;
	
	UTILAssertNotificationName(notification, CMRDATDownloaderDidSuspectBBONNotification);
		
	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, CMRDATDownloader);

	[self removeFromNotificationCeterWithDownloader:downloader];

	NSAlert *alert = [NSAlert alertWithError:[[notification userInfo] objectForKey:@"Error"]];

	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(suspectingBBONSheetDidEnd:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)suspectingBBONSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);

	switch (returnCode) {
	case NSAlertFirstButtonReturn: // Cancel
		break;
	case NSAlertSecondButtonReturn: // Info
    {
        NSString *urlString = SGTemplateResource(@"System - BBON Info URL");
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
		break;
    }
	default:
		UTILUnknownSwitchCase(returnCode);
		break;
	}
	[downloader autorelease];
}

#pragma mark Start Maru-Login Downloading
- (void)downloadThreadUsingMaru:(CMRThreadSignature *)aSignature title:(NSString *)threadTitle
{
	BSLoggedInDATDownloader *downloader;

	downloader = [BSLoggedInDATDownloader downloaderWithIdentifier:aSignature
                                                       threadTitle:threadTitle
                                                     candidateHost:[[self document] candidateHost]];
	if (!downloader) {
        return;
    }

	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loggedInDATDownloaderDidFinishLoading:)
                                                 name:ThreadTextDownloaderDidFinishLoadingNotification
                                               object:downloader];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loggedInDATDownloaderDidFail:)
                                                 name:CMRDATDownloaderDidDetectDatOchiNotification
                                               object:downloader];

	// TaskManager, load
	[[CMRTaskManager defaultManager] addTask:downloader];
	[downloader loadInBackground];
}

- (void)loggedInDATDownloaderDidFinishLoading:(NSNotification *)notification
{
	BSLoggedInDATDownloader	*downloader;
	NSDictionary			*userInfo;
	NSString				*contents;

	UTILAssertNotificationName(notification, ThreadTextDownloaderDidFinishLoadingNotification);
	
	userInfo = [notification userInfo];
	UTILAssertNotNil(userInfo);

	downloader = [[notification object] retain];
	contents = [userInfo objectForKey:CMRDownloaderUserInfoContentsKey];
	UTILAssertKindOfClass(downloader, BSLoggedInDATDownloader);
	UTILAssertKindOfClass(contents, NSString);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ThreadTextDownloaderDidFinishLoadingNotification
                                                  object:downloader];
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CMRDATDownloaderDidDetectDatOchiNotification
                                                  object:downloader];
    
	if (![[self threadIdentifier] isEqual:[downloader identifier]]) {
        [downloader release];
		return;
	}

	[[self threadAttributes] addEntriesFromDictionary:[userInfo objectForKey:CMRDownloaderUserInfoAdditionalInfoKey]];
	[(CMRAbstructThreadDocument *)[self document] setIsDatOchiThread:YES];
	[self composeDATContents:contents threadSignature:[downloader identifier] nextIndex:[downloader nextIndex]];
	[downloader autorelease];
}

- (void)loggedInDATDownloaderDidFail:(NSNotification *)notification
{
	BSLoggedInDATDownloader *downloader;
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
	UTILAssertNotificationName(notification, CMRDATDownloaderDidDetectDatOchiNotification);
    
	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, BSLoggedInDATDownloader);
    
	[nc removeObserver:self
				  name:CMRDATDownloaderDidDetectDatOchiNotification
				object:downloader];
	[nc removeObserver:self
				  name:ThreadTextDownloaderDidFinishLoadingNotification
				object:downloader];
    
	NSAlert *alert = [NSAlert alertWithError:[[notification userInfo] objectForKey:@"Error"]];

    if ([self isRetrieving]) {
        [alert setInformativeText:NSLocalizedStringFromTable(@"MaruFailSuggestionRetrieving", @"Downloader", @"")];
    }
    
//	[alert setShowsHelp:YES];
//	[alert setDelegate:[NSApp delegate]];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(maruDownloadDidFail:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)maruDownloadDidFail:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, BSLoggedInDATDownloader);
    
	if (returnCode == NSAlertFirstButtonReturn) {
        if ([self isRetrieving]) {
            [self restoreFromRetrieving:[downloader filePathToWrite] error:NULL];
        } else {
            [self closeWindowOfAlert:sheet];
        }
	}
	[downloader autorelease];
}
@end
