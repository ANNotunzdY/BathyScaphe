//
//  CMRThreadsList-DataSource.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/10/04.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadsList_p.h"
#import "CMRThreadSignature.h"
#import "BSQuickLookPanelController.h"
#import "BSQuickLookObject.h"
#import "BSDateFormatter.h"
#import "DatabaseManager.h"


@implementation CMRThreadsList(DataSource)
static id kNewThreadAttrTemplate;
static id kThreadAttrTemplate;
static id kDatOchiThreadAttrTemplate;

static NSMutableDictionary *kThreadCreatedDateAttrTemplate;
static NSMutableDictionary *kThreadModifiedDateAttrTemplate;
static NSMutableDictionary *kThreadLastWrittenDateAttrTemplate;

static NSMutableParagraphStyle *pStyleForDateColumnWithWidth(CGFloat tabWidth)
{
	NSMutableParagraphStyle *style_;
    NSTextTab	*tab_ = [[NSTextTab alloc] initWithType:NSRightTabStopType location:tabWidth];
	
	style_ = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style_ setLineBreakMode:NSLineBreakByClipping];
	[style_ setTabStops:[NSArray array]];
    [style_ addTabStop:tab_];
	[tab_ release];

	return [style_ autorelease];
}

+ (void)resetDataSourceTemplateForDateColumn
{
	if (!kThreadCreatedDateAttrTemplate || !kThreadModifiedDateAttrTemplate || !kThreadLastWrittenDateAttrTemplate) {
		kThreadCreatedDateAttrTemplate = [[NSMutableDictionary alloc] init];
		kThreadModifiedDateAttrTemplate = [[NSMutableDictionary alloc] init];
		kThreadLastWrittenDateAttrTemplate = [[NSMutableDictionary alloc] init];
	}
}

+ (void)resetDataSourceTemplateForColumnIdentifier:(NSString *)identifier width:(CGFloat)loc
{
    static CGFloat cachedLoc1 = 0;
    static CGFloat cachedLoc2 = 0;
	static CGFloat cachedLoc3 = 0;

	[self resetDataSourceTemplateForDateColumn];

    if ([identifier isEqualToString:ThreadPlistIdentifierKey]) {
        if (cachedLoc1 == 0 || loc != cachedLoc1) {
            cachedLoc1 = loc;
			NSParagraphStyle	*ps = pStyleForDateColumnWithWidth(cachedLoc1);

			[kThreadCreatedDateAttrTemplate setObject:ps forKey:NSParagraphStyleAttributeName];
		}
    } else if ([identifier isEqualToString:CMRThreadModifiedDateKey]) {
        if (cachedLoc2 == 0 || loc != cachedLoc2) {
            cachedLoc2 = loc;
			NSParagraphStyle	*ps2 = pStyleForDateColumnWithWidth(cachedLoc2);

			[kThreadModifiedDateAttrTemplate setObject:ps2 forKey:NSParagraphStyleAttributeName];
		}
	} else if ([identifier isEqualToString:LastWrittenDateColumn]) {
        if (cachedLoc3 == 0 || loc != cachedLoc3) {
            cachedLoc3 = loc;
			NSParagraphStyle	*ps3 = pStyleForDateColumnWithWidth(cachedLoc3);
			
			[kThreadLastWrittenDateAttrTemplate setObject:ps3 forKey:NSParagraphStyleAttributeName];
		}
	}
}

+ (void)resetDataSourceTemplates
{
	// default object value:
	kThreadAttrTemplate = [[NSDictionary alloc] initWithObjectsAndKeys:
							[CMRPref threadsListFont], NSFontAttributeName,
							[CMRPref threadsListColor], NSForegroundColorAttributeName,
							NULL];

	// New Arrival thread:
	kNewThreadAttrTemplate = [[NSDictionary alloc] initWithObjectsAndKeys:
								[CMRPref threadsListNewThreadFont], NSFontAttributeName,
								[CMRPref threadsListNewThreadColor], NSForegroundColorAttributeName,
								NULL];

	// Dat Ochi thread:
	kDatOchiThreadAttrTemplate = [[NSDictionary alloc] initWithObjectsAndKeys:
								[CMRPref threadsListDatOchiThreadFont], NSFontAttributeName,
								[CMRPref threadsListDatOchiThreadColor], NSForegroundColorAttributeName,
								NULL];
}

/* TODO その場しのぎ。本来はNSMutableDictionaryをNSDictionaryに変換して返すべきだが、速度的に現実的ではない。*/
+ (NSDictionary *)threadCreatedDateAttrTemplate
{
	return kThreadCreatedDateAttrTemplate;
}

+ (NSDictionary *)threadModifiedDateAttrTemplate
{
	return kThreadModifiedDateAttrTemplate;
}

+ (NSDictionary *)threadLastWrittenDateAttrTemplate
{
	return kThreadLastWrittenDateAttrTemplate;
}

+ (id)objectValueTemplate:(id)aValue forType:(NSInteger)aType
{
	id		temp = nil;
	NSRange	range;
	
	if (!aValue || [aValue isKindOfClass:[NSImage class]]) {
		return aValue;
	}
	if ([aValue isKindOfClass:[NSAttributedString class]]) {
		if([aValue respondsToSelector:@selector(addAttributes:range:)]) {
			temp = [aValue retain];
		} else {
			temp = [aValue mutableCopy];
		}
	} else {
		temp = [[NSMutableAttributedString alloc] initWithString:[aValue stringValue]];
	}
	
	if (!kNewThreadAttrTemplate || !kThreadAttrTemplate || !kDatOchiThreadAttrTemplate) {
		[self resetDataSourceTemplates];
	}

	range = NSMakeRange(0,[temp length]);
	switch (aType) {
	case kValueTemplateDefaultType:
		[temp addAttributes:kThreadAttrTemplate range:range];
		break;
	case kValueTemplateNewArrivalType:
		[temp addAttributes:kNewThreadAttrTemplate range:range];
		break;
	case kValueTemplateDatOchiType:
		[temp addAttributes:kDatOchiThreadAttrTemplate range:range];
		break;
	default :
		UTILUnknownSwitchCase(aType);
		break;
	}
	
	return [temp autorelease];	
}

#pragma mark Getting Thread Attributes
- (NSString *)threadFilePathAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView status:(ThreadStatus *)status
{
	NSString		*path_;
	NSDictionary	*thread_;
	
	thread_ = [self threadAttributesAtRowIndex:rowIndex inTableView:tableView];
	if (!thread_) return nil;
	if (status != NULL) {
		NSNumber *stNum_;
		
		stNum_ = [thread_ objectForKey:CMRThreadStatusKey];
		
		UTILAssertNotNil(stNum_);
		*status = [stNum_ unsignedIntegerValue];
	}

	path_ = [CMRThreadAttributes pathFromDictionary:thread_];
	UTILAssertNotNil(path_);

	return path_;
}

- (NSString *)threadTitleAtRowIndex:(NSInteger)rowIndex inTableView:(NSTableView *)tableView
{
	NSString		*title_;
	NSDictionary	*thread_;
	
	thread_ = [self threadAttributesAtRowIndex:rowIndex inTableView:tableView];
	if (!thread_) return nil;
	title_ = [CMRThreadAttributes threadTitleFromDictionary:thread_];
	UTILAssertNotNil(title_);

	return title_;
}

- (NSArray *)tableView:(NSTableView *)aTableView threadAttibutesArrayAtRowIndexes:(NSIndexSet *)rowIndexes exceptingPath:(NSString *)filepath
{
	NSUInteger	count = [rowIndexes count];
	if (count == 0) return nil;

	NSMutableArray	*mutableArray = [[NSMutableArray alloc] initWithCapacity:count];
	NSArray			*resultArray;

	NSUInteger	element;
	NSDictionary	*dict;
	NSString		*threadPath;
	NSInteger				size = [rowIndexes lastIndex]+1;
	NSRange			e = NSMakeRange(0, size);

	while ([rowIndexes getIndexes:&element maxCount:1 inIndexRange:&e] > 0) {
		dict = [self threadAttributesAtRowIndex:element inTableView:aTableView];
		threadPath = [CMRThreadAttributes pathFromDictionary:dict];
		if (!filepath || ![threadPath isEqualToString:filepath]) [mutableArray addObject:dict];
	}

	resultArray = [[NSArray alloc] initWithArray:mutableArray];
	[mutableArray release];
	return [resultArray autorelease];
}

- (NSArray *)tableView:(NSTableView *)aTableView threadFilePathsArrayAtRowIndexes:(NSIndexSet *)rowIndexes
{
	NSMutableArray	*pathArray_ = [NSMutableArray arrayWithCapacity:[rowIndexes count]];
	NSUInteger	arrayElement;
	NSInteger				size = [rowIndexes lastIndex]+1;
	NSRange			e = NSMakeRange(0, size);

	while ([rowIndexes getIndexes:&arrayElement maxCount:1 inIndexRange:&e] > 0) {
		NSString	*path_;
		path_ = [self threadFilePathAtRowIndex:arrayElement inTableView:aTableView status:NULL];
		[pathArray_ addObject:path_];
	}

	return pathArray_;
}

- (void)tableView:(NSTableView *)aTableView revealFilesAtRowIndexes:(NSIndexSet *)rowIndexes
{
	NSArray *filePaths = [self tableView:aTableView threadFilePathsArrayAtRowIndexes:rowIndexes];
	[[NSWorkspace sharedWorkspace] revealFilesInFinder:filePaths];
}

- (void)tableView:(NSTableView *)aTableView quickLookAtRowIndexes:(NSIndexSet *)rowIndexes
{
	[self tableView:aTableView quickLookAtRowIndexes:rowIndexes keepLook:NO];
}

- (void)tableView:(NSTableView *)aTableView quickLookAtRowIndexes:(NSIndexSet *)rowIndexes keepLook:(BOOL)flag
{
	BSQuickLookPanelController *qlc = [BSQuickLookPanelController sharedInstance];
	if (![qlc isLooking] || !flag) {
		[qlc showWindow:self];
	}

	if ([[qlc window] isVisible]) {
		NSUInteger rowIndex = [rowIndexes firstIndex];
		[qlc setQlPanelParent:[aTableView window]];
		NSString *path = [self threadFilePathAtRowIndex:rowIndex inTableView:aTableView status:NULL];
		NSString *title = [self threadTitleAtRowIndex:rowIndex inTableView:aTableView];

		CMRThreadSignature *foo = [CMRThreadSignature threadSignatureFromFilepath:path];
		// TODO ミョーに増える retainCount = release阻害 = メモリリーク
		BSQuickLookObject	*bar = [[BSQuickLookObject alloc] initWithThreadTitle:title signature:foo];
		[[qlc objectController] setContent:bar];
		[bar release];
	}
}

- (void)tableView:(NSTableView *)aTableView openURLsAtRowIndexes:(NSIndexSet *)rowIndexes
{
	NSMutableArray	*urls = [NSMutableArray arrayWithCapacity:[rowIndexes count]];

	NSUInteger	element;
	NSDictionary	*dict;
	NSURL			*url;
	NSInteger				size = [rowIndexes lastIndex]+1;
	NSRange			e = NSMakeRange(0, size);

	while ([rowIndexes getIndexes:&element maxCount:1 inIndexRange:&e] > 0) {
		dict = [self threadAttributesAtRowIndex:element inTableView:aTableView];
		url = [CMRThreadAttributes threadURLWithDefaultParameterFromDictionary:dict];
		if (url) [urls addObject:url];
	}

	[[NSWorkspace sharedWorkspace] openURLs:urls inBackground:[CMRPref openInBg]];
}

#pragma mark NSDraggingSource
- (BOOL)userWantsToMoveToTrash
{
	if (![self isFavorites]) return YES;

	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:[self localizedString:@"DragDropTrashAlert"]];
	[alert setInformativeText:[self localizedString:@"DragDropTrashMessage"]];
	[alert addButtonWithTitle:[self localizedString:@"DragDropTrashOK"]];
	[alert addButtonWithTitle:[self localizedString:@"DragDropTrashCancel"]];
	return ([alert runModal] == NSAlertFirstButtonReturn);
}

- (void)tableView:(NSTableView *)aTableView draggingEnded:(NSDragOperation)operation
{
	NSPasteboard	*pboard_;

	// 「ゴミ箱」への移動でなければ終わり
	if (!(NSDragOperationDelete & operation)) {
		return;
	}

	pboard_ = [NSPasteboard pasteboardWithName:NSDragPboard];
    NSArray *classesArray = [NSArray arrayWithObject:[NSURL class]];
    NSDictionary *optionDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey];

    if ([pboard_ canReadObjectForClasses:classesArray options:optionDict]) {
        if ([self userWantsToMoveToTrash]) {
            NSArray *fileURLs = [pboard_ readObjectsForClasses:classesArray options:optionDict];
            // URL をファイルパスに変換
            NSMutableArray *array = [NSMutableArray arrayWithCapacity:[fileURLs count]];
            for (NSURL *fileURL in fileURLs) {
                [array addObject:[fileURL path]];
            }
            [self tableView:aTableView removeFiles:array];
        }
    }
}
@end
