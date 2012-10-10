//
//  CMRDocumentController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/19.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRDocumentController.h"
#import "CMRThreadDocument.h"
#import "CMRThreadViewer_p.h"
#import "Browser.h"

@implementation CMRDocumentController
- (void)noteNewRecentDocumentURL:(NSURL *)aURL
{
	// ブロックして、アップルメニューの「最近使った項目」への追加を抑制する
}

- (NSUInteger)maximumRecentDocumentCount
{
	// BathyScaphe の「ファイル」＞「最近使った書類」サブメニューの生成を抑制する
	return 0;
}

- (NSDocument *)documentAlreadyOpenForURL:(NSURL *)absoluteDocumentURL
{
	NSArray			*documents;
	NSEnumerator	*iter;
	NSDocument		*document;
	NSString		*fileName;
	NSString		*documentPath;

	if (![absoluteDocumentURL isFileURL]) return nil;
	documentPath = [absoluteDocumentURL path];

	documents = [self documents];
	iter = [documents objectEnumerator];

	while (document = [iter nextObject]) {
		fileName = [[document fileURL] path];
		if (!fileName && [document isKindOfClass:[Browser class]]) {
			fileName = [[(Browser *)document threadAttributes] path];
		}
		if (fileName && [fileName isEqualToString:documentPath]) {
			return document;
		}
	}
	return nil;
}

- (BOOL)showDocumentWithContentOfFile:(NSURL *)fileURL boardInfo:(NSDictionary *)info
{
	NSDocument *document;
	CMRThreadViewer *viewer;
    NSString *filepath;

	if (!fileURL || !info) {
        return NO;
	}

    filepath = [fileURL path];
	document = [self documentAlreadyOpenForURL:fileURL];
	if (document) {
        if ([document isKindOfClass:[Browser class]] && ![(Browser *)document showsThreadDocument]) {
            id wc = [[document windowControllers] objectAtIndex:0];
            [wc cleanUpItemsToBeRemoved:[NSArray arrayWithObject:filepath]];
            document = nil;
        } else {
            [document showWindows];
            return YES;
        }
	}

    NSMutableDictionary *tmp = nil;

	viewer = [[CMRThreadViewer alloc] init];
	document = [[CMRThreadDocument alloc] initWithThreadViewer:viewer];
    [document setFileURL:fileURL];
//	[document setFileName:filepath];
    if ([info objectForKey:@"candidateHost"]) {
        [(CMRThreadDocument *)document setCandidateHost:[info objectForKey:@"candidateHost"]];
        tmp = [[info mutableCopy] autorelease];
        [tmp removeObjectForKey:@"candidateHost"];
    }
	[self addDocument:document];
	[viewer setThreadContentWithFilePath:filepath boardInfo:(tmp ?: info)];
	[viewer release];
	[document release];
	
	return YES;
}

- (BOOL)showDocumentWithHistoryItem:(CMRThreadSignature *)historyItem
{
	NSDictionary	*info_;
	NSString		*path_ = [historyItem threadDocumentPath];
	
	info_ = [NSDictionary dictionaryWithObjectsAndKeys:[historyItem boardName], ThreadPlistBoardNameKey,
													   [historyItem identifier], ThreadPlistIdentifierKey, NULL];
	return [self showDocumentWithContentOfFile:[NSURL fileURLWithPath:path_] boardInfo:info_];	
}

#pragma mark Window Restoration (Lion)
// See NSWindowRestration.h, CMRThreadDocument.m, Browser.m, and CMRBrowser-Delegate.m
+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    NSString *className = [state decodeObjectForKey:@"BS_DocumentClass"];
    if (className && [className isEqualToString:@"CMRThreadDocument"]) {
        id object = [state decodeObjectForKey:@"BS_ThreadSignature"];
        if (object) {
            NSString *path = [(CMRThreadSignature *)object threadDocumentPath];
            NSDictionary *boardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[(CMRThreadSignature *)object boardName], ThreadPlistBoardNameKey,
                         [(CMRThreadSignature *)object identifier], ThreadPlistIdentifierKey,
                         NULL];
            [[self sharedDocumentController] showDocumentWithContentOfFile:[NSURL fileURLWithPath:path] boardInfo:boardInfo];
        }
    }
    [super restoreWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}
@end
