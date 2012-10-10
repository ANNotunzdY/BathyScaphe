//
//  CMRThreadViewer-ConfirmAction.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 09/12/23.
//  Copyright 2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"
#import "CMRReplyDocumentFileManager.h"
#import "CMRThreadLayout.h"

enum {
    CMRThreadViewerDeletionAlertType = 1,
    CMRThreadViewerRetrieveAlertType = 2,
};
typedef NSUInteger CMRThreadViewerAlertType;

#define kDeletionMessageTextFormatKey @"Deletion Msg"
#define kBrowserDeletionMessageTextKey @"Browser Deletion Msg"
#define kRetrieveMessageTextFormatKey @"Retrieve Msg"
#define kBrowserRetrieveMessageTextKey @"Browser Retrieve Msg"

#define kDeletionInformativeTextKey @"Deletion Info"
#define kRetrieveInformativeTextKey @"Retrieve Info"

#define kDeletionOKButtonLabelKey @"Deletion OK"
#define kRetrieveOKButtonLabelKey @"Retrieve OK"


@implementation CMRThreadViewer(DeletionAndRetrieving)
- (void)closeWindowIfNeededAtPath:(NSString *)path
{
    if ([path isEqualToString:[self path]]) {
        [[self window] performClose:self];
    }
}

- (BOOL)forceDeleteThreads:(NSArray *)threads
{
	NSMutableArray	*array_ = [NSMutableArray arrayWithCapacity:[threads count]];
	NSArray			*arrayWithReplyFiles_;
	NSEnumerator	*iter_ = [threads objectEnumerator];
	NSFileManager	*fm = [NSFileManager defaultManager];
	id				eachItem_;
	NSString		*path_;

	while (eachItem_ = [iter_ nextObject]) {
		path_ = [CMRThreadAttributes pathFromDictionary:eachItem_];
		if ([fm fileExistsAtPath:path_]) {
            [self closeWindowIfNeededAtPath:path_];
			[array_ addObject:path_];
		} else {
			NSLog(@"File does not exist (although we're going to remove it!)\n%@", path_);
		}
	}

	arrayWithReplyFiles_ = [[CMRReplyDocumentFileManager defaultManager] replyDocumentFilesArrayWithLogsArray:array_];
	return [[CMRTrashbox trash] performWithFiles:arrayWithReplyFiles_];
}

- (void)showAlert:(CMRThreadViewerAlertType)type targetThreads:(NSArray *)threads
{
	NSAlert		*alert_;
    NSString *title_;

    NSString *titleFormatKey;
	NSString *titleKey;
	NSString *infoTextKey;
    NSString *okBtnKey;
    SEL didEndSelector;

    if (type == CMRThreadViewerDeletionAlertType) {
        titleFormatKey = kDeletionMessageTextFormatKey;
        titleKey = kBrowserDeletionMessageTextKey;
        infoTextKey = kDeletionInformativeTextKey;
        okBtnKey = kDeletionOKButtonLabelKey;
        didEndSelector = @selector(_threadDeletionSheetDidEnd:returnCode:contextInfo:);
    } else {
        titleFormatKey = kRetrieveMessageTextFormatKey;
        titleKey = kBrowserRetrieveMessageTextKey;
        infoTextKey = kRetrieveInformativeTextKey;
        okBtnKey = kRetrieveOKButtonLabelKey;
        didEndSelector = @selector(retrieveAlertDidEnd:returnCode:contextInfo:);
    }

	alert_ = [[[NSAlert alloc] init] autorelease];

    if (!threads || [threads count] < 1) {
        return;
	} else if ([threads count] == 1) {
		NSString *tmp_ = [self localizedString:titleFormatKey];
		NSString *threadTitle_ = [CMRThreadAttributes threadTitleFromDictionary:[threads lastObject]];
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 検証済
		title_ = [NSString stringWithFormat:tmp_, threadTitle_];
	} else {
		title_ = [self localizedString:titleKey];
	}
	
	[alert_ setMessageText:title_];
	[alert_ setInformativeText:[self localizedString:infoTextKey]];
	[alert_ addButtonWithTitle:[self localizedString:okBtnKey]];
	[alert_ addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];

	[alert_ beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:didEndSelector contextInfo:[threads retain]];
}

- (IBAction)retrieveThread:(id)sender
{
	NSArray			*targets_ = [self targetThreadsForAction:_cmd sender:sender];
	NSInteger				numOfSelected_ = [targets_ count];

	if (numOfSelected_ == 0) return;
	
    [self showAlert:CMRThreadViewerRetrieveAlertType targetThreads:targets_];
}

- (IBAction)deleteThread:(id)sender
{
	NSArray			*targets_ = [self targetThreadsForAction:_cmd sender:sender];
	NSInteger				numOfSelected_ = [targets_ count];

	if (numOfSelected_ == 0) return;
	
    if ([CMRPref quietDeletion]) {
        if (![self forceDeleteThreads:targets_]) {
            NSBeep();
            NSLog(@"CMRTrashbox returns some error.");
        }			
    } else {
        [self showAlert:CMRThreadViewerDeletionAlertType targetThreads:targets_];
    }
}

- (void)_threadDeletionSheetDidEnd:(NSAlert *)alert
						returnCode:(NSInteger)returnCode
					   contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn) {
        [[alert window] orderOut:nil];
		if (![self forceDeleteThreads:(NSArray *)contextInfo]) {
			NSBeep();
			NSLog(@"CMRTrashbox returns some error.");
		}
	}
}

- (BOOL)restoreFromRetrieving:(NSString *)path error:(NSError **)error
{
    NSMutableDictionary *mDict;
    
	mDict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
	if (!mDict) {
        return NO;
    }
    
    [mDict setObject:[mDict objectForKey:@"BackupLength"] forKey:ThreadPlistLengthKey];
    [mDict setObject:[mDict objectForKey:@"BackupContents"] forKey:ThreadPlistContentsKey];
    
	[mDict removeObjectForKey:@"BackupLength"];
	[mDict removeObjectForKey:@"BackupContents"];
    
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:mDict format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
    if (!data) {
        return NO;
    }
    
    if (![data writeToFile:path options:NSAtomicWrite error:error]) {
        return NO;
    }

    CMRThreadSignature *signature = [CMRThreadSignature threadSignatureFromFilepath:path];
    if ([signature isEqual:[self threadIdentifier]]) {
        [[self threadLayout] setMessagesEdited:NO];
        [self setRetrieving:NO];
        [self setThreadContentWithFilePath:path
                                 boardInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [self boardName], ThreadPlistBoardNameKey, [signature identifier], ThreadPlistIdentifierKey, NULL]];
    }
    return YES;
}


- (BOOL)prepareRetrieving:(NSString *)logFilePath error:(NSError **)error
{
    NSMutableDictionary *mDict;

	mDict = [NSMutableDictionary dictionaryWithContentsOfFile:logFilePath];
	if (!mDict) {
        return NO;
    }

    [mDict setObject:[mDict objectForKey:ThreadPlistLengthKey] forKey:@"BackupLength"];
    [mDict setObject:[mDict objectForKey:ThreadPlistContentsKey] forKey:@"BackupContents"];

	[mDict removeObjectForKey:ThreadPlistLengthKey];
	[mDict removeObjectForKey:ThreadPlistContentsKey];

    NSData *data = [NSPropertyListSerialization dataFromPropertyList:mDict format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
    if (!data) {
        return NO;
    }

    return [data writeToFile:logFilePath options:NSAtomicWrite error:error];
}

- (BOOL)retrieveThreadAtPath:(NSString *)filepath title:(NSString *)title
{
    NSError *error = nil;

    if (![self prepareRetrieving:filepath error:&error]) {
        NSBeep();
        NSString *messageText = [NSString stringWithFormat:[self localizedString:@"Prepare Retrieving Error Msg"], title];
        NSString *infoText;
        if (error) {
//            NSAlert *alert = [NSAlert alertWithError:error];
//            [alert runModal];
            infoText = [error localizedDescription];
        } else {
            infoText = [self localizedString:@"Prepare Retrieving Error Info"];
        }
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:messageText];
        [alert setInformativeText:infoText];
        [alert runModal];

        return NO;
    }

    CMRThreadSignature *aSignature = [CMRThreadSignature threadSignatureFromFilepath:filepath];
    if ([aSignature isEqual:[self threadIdentifier]]) {
        [[self threadLayout] setMessagesEdited:NO];
        [self setRetrieving:YES];
        [self setThreadContentWithFilePath:filepath
                                 boardInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [self boardName], ThreadPlistBoardNameKey, [aSignature identifier], ThreadPlistIdentifierKey, NULL]];
    } else {
        [self downloadThread:aSignature title:title nextIndex:NSNotFound];
    }
    return YES;
}

- (void)retrieveAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)code contextInfo:(void *)contextInfo
{
    if (code != NSAlertFirstButtonReturn) {
        return;
    }

    [[alert window] orderOut:nil];

    NSEnumerator *iter = [(NSArray *)contextInfo objectEnumerator];
    id obj;
    NSString *path;
    NSString *title;
    while (obj = [iter nextObject]) {
        path = [CMRThreadAttributes pathFromDictionary:obj];
        title = [CMRThreadAttributes threadTitleFromDictionary:obj];
        [self retrieveThreadAtPath:path title:title];
    }
}
@end
