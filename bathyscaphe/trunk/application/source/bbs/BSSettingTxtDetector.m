//
// BSSettingTxtDetector.m
// BathyScaphe
//
// Written by Tsutomu Sawada on 06/08/15.
// Copyright 2006-2011 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import "BSSettingTxtDetector.h"
#import "UTILKit.h"
#import <CocoMonar/CMRAppTypes.h>


NSString *const BSSettingTxtDetectorDidFinishNotification = @"BSSTDDidFinishNotification";
NSString *const BSSettingTxtDetectorDidFailNotification = @"BSSTDDidFailNotification";

NSString *const kBSSTDBoardNameKey = @"boardName";
NSString *const kBSSTDNoNameValueKey = @"defaultNoName";
NSString *const kBSSTDBeLoginPolicyTypeValueKey = @"beLoginPolicyType";
NSString *const kBSSTDAllowsNanashiBoolValueKey = @"allowsNanashi";
NSString *const kBSSTDAllowsCharRefBoolValueKey = @"allowsCharacterReference";
NSString *const kBSSTDShowsPrefectureBoolValueKey = @"showsPrefecture";
NSString *const kBSSTDDetectedDateKey = @"DetectedDate";
NSString *const kBSSTDErrorKey = @"Error";

@implementation BSSettingTxtDetector
- (id)initWithBoardName:(NSString *)boardName settingTxtURL:(NSURL *)anURL
{
    if (self = [super init]) {
        [self setBoardName:boardName];
        [self setSettingTxtURL:anURL];
    }

    return self;
}

- (void)dealloc
{
    [self setBoardName:nil];
    [self setSettingTxtURL:nil];
    [super dealloc];
}

- (NSString *)boardName
{
    return bsSTD_boardName;
}

- (void)setBoardName:(NSString *)newBoardName
{
    [newBoardName retain];
    [bsSTD_boardName release];
    bsSTD_boardName = newBoardName;
}

- (NSURL *)settingTxtURL
{
    return bsSTD_settingTxtURL;
}

- (void)setSettingTxtURL:(NSURL *)newURL
{
    [newURL retain];
    [bsSTD_settingTxtURL release];
    bsSTD_settingTxtURL = newURL;
}

- (void)startDownloadingSettingTxt
{
    BSURLDownload *newDownload_;

	NSString *tmpDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"BSSTD-XXXXXX"];    
	char *cTmpDir = strdup([tmpDir fileSystemRepresentation]);
	mkdtemp(cTmpDir);
	NSString *tmpDirPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:cTmpDir length:strlen(cTmpDir)];
	free(cTmpDir);

    newDownload_ = [[BSURLDownload alloc] initWithURL:[self settingTxtURL] delegate:self destination:tmpDirPath];
    if (!newDownload_) {
        NSError *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSSettingTxtDetectorCannotStartDownloadingError userInfo:nil];
        UTILNotifyInfo3(BSSettingTxtDetectorDidFailNotification, error, kBSSTDErrorKey);
        return;
    }

    [newDownload_ setAllowsOverwriteDownloadedFile:YES];
}

- (void)detectBoardPropertiesFromSettingTxtFile:(NSString *)filePath
{
    NSString *settingTxt;
    NSError *error = nil;
    settingTxt = [NSString stringWithContentsOfFile:filePath encoding:NSShiftJISStringEncoding error:&error];
    if (!settingTxt) {
        UTILNotifyInfo3(BSSettingTxtDetectorDidFailNotification, error, kBSSTDErrorKey);
        return;
    }

    NSArray *array_ = [settingTxt componentsSeparatedByNewline];

    NSEnumerator *iter_ = [array_ objectEnumerator];
    id eachItem;
    NSString *noNameValue = @"";
    BSBeLoginPolicyType typeValue = BSBeLoginDecidedByUser;
    BOOL nanashiOK = YES;
    BOOL charRefAllowed = NO;
    BOOL showsPrefecture = NO;

    while (eachItem = [iter_ nextObject]) {
        NSArray *ary2;
        ary2 = [eachItem componentsSeparatedByString:@"="];

        if ([ary2 count] != 2) {
            continue;
        }

        if ([ary2 containsObject:@"BBS_NONAME_NAME"]) {
            noNameValue = [ary2 objectAtIndex:1];
        } else if ([ary2 containsObject:@"BBS_BE_ID"]) {
            if (![[ary2 objectAtIndex:1] isEqualToString:@""]) {
                typeValue = BSBeLoginTriviallyNeeded;
            }
        } else if ([ary2 containsObject:@"BBS_UNICODE"]) {
            if ([[ary2 objectAtIndex:1] isEqualToString:@"pass"]) {
                charRefAllowed = YES;
            }
        } else if ([ary2 containsObject:@"NANASHI_CHECK"]) {
            if (![[ary2 objectAtIndex:1] isEqualToString:@""]) {
                nanashiOK = NO;
            }
        } else if ([ary2 containsObject:@"BBS_JP_CHECK"]) {
            if (![[ary2 objectAtIndex:1] isEqualToString:@""]) {
                showsPrefecture = YES;
            }
        }
    }

    NSDictionary *returnDict;
    returnDict = [NSDictionary dictionaryWithObjectsAndKeys:
                  [noNameValue stringByReplaceEntityReference], kBSSTDNoNameValueKey,
                  [NSNumber numberWithUnsignedInteger:typeValue], kBSSTDBeLoginPolicyTypeValueKey,
                  [NSNumber numberWithBool:nanashiOK], kBSSTDAllowsNanashiBoolValueKey,
                  [NSNumber numberWithBool:charRefAllowed], kBSSTDAllowsCharRefBoolValueKey,
                  [NSNumber numberWithBool:showsPrefecture], kBSSTDShowsPrefectureBoolValueKey,
                  [NSDate date], kBSSTDDetectedDateKey,
                  [self boardName], kBSSTDBoardNameKey,
                   NULL];

    UTILNotifyInfo(BSSettingTxtDetectorDidFinishNotification, returnDict);
}

#pragma mark BSURLDownload delegate
- (void)bsURLDownloadDidFinish:(BSURLDownload *)aDownload
{
    NSString *downloadedFilePath_;
    downloadedFilePath_ = [aDownload downloadedFilePath];
    [aDownload release];

    [self detectBoardPropertiesFromSettingTxtFile:downloadedFilePath_];

    // Delete downloaded SETTING.TXT (and its parent directory)
    [[NSFileManager defaultManager] removeItemAtPath:[downloadedFilePath_ stringByDeletingLastPathComponent] error:NULL];
}

- (BOOL)bsURLDownload:(BSURLDownload *)aDownload didRedirectToURL:(NSURL *)newURL
{
    return NO;
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didAbortRedirectionToURL:(NSURL *)anURL
{
    UTILNotifyName(BSSettingTxtDetectorDidFailNotification);
    [aDownload release];
}

- (void)bsURLDownload:(BSURLDownload *)aDownload didFailWithError:(NSError *)aError
{
    UTILNotifyInfo3(BSSettingTxtDetectorDidFailNotification, aError, kBSSTDErrorKey);
    [aDownload release];
}
@end
