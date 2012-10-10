//
//  CMRFileManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/04/09.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRFileManager.h"

#import <AppKit/NSApplication.h>
#import <SGFoundation/SGFoundation.h>
#import <CocoMonar/CocoMonar.h>

#import "UTILKit.h"

@implementation CMRFileManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager)

- (id)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(applicationDidBecomeActive:)
                   name:NSApplicationDidBecomeActiveNotification
                 object:NSApp];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [m_dataRootDirectory release];
    [m_dataRootDirectoryPath release];
    
    [super dealloc];
}

- (NSString *)dataRootDirectoryPath
{
    if (!m_dataRootDirectoryPath) {
        [self updateDataRootDirectory];
    }
    return m_dataRootDirectoryPath;
}

- (NSString *)supportFileUnderDataRootDirectoryPathWithName:(NSString *)name
{
    return [[self dataRootDirectoryPath] stringByAppendingPathComponent:name];
}

- (SGFileRef *)dataRootDirectory
{
    if (!m_dataRootDirectory) {
        [self updateDataRootDirectory];
    }
    return m_dataRootDirectory;
}

- (SGFileRef *)supportDirectory
{
    return [SGFileRef applicationSpecificFolderRef];
}

- (SGFileRef *)supportDirectoryWithName:(NSString *)dirName
{
    SGFileRef *parent_;
    SGFileRef *directory_;
    
    parent_ = [self supportDirectory];
    directory_ = [parent_ fileRefWithChildName:dirName createDirectory:YES];
    directory_ = [directory_ fileRefResolvingLinkIfNeeded];

    if (!directory_ || ![directory_ isDirectory]) {
        NSLog(@"Can't create special folder at %@",
            [[parent_ filepath] stringByAppendingPathComponent:dirName]);
        return nil;
    }

    return directory_;
}

// ~/Library/Application Support/BathyScaphe/<fileName>
- (NSString *)supportFilepathWithName:(NSString *)aFileName resolvingFileRef:(SGFileRef **)aFileRefPtr
{
    SGFileRef *support_;
    SGFileRef *fileRef_;

    if (!aFileName || ([aFileName length] == 0)){
        [NSException raise:NSInvalidArgumentException
                    format:@"Invalid (empty) file name was passed."];
    }

    support_ = [self supportDirectory];

    if (!support_) {
        NSBeep();
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert setMessageText:NSLocalizedString(@"cannotRunTitle", @"cannnotRunTitle")];
        [alert setInformativeText:NSLocalizedString(@"cannotRun", @"We can't resolve/create application support folder.")];
        [alert addButtonWithTitle:NSLocalizedString(@"Terminate", @"Quit")];
        [alert runModal];
        [NSApp terminate:self];
        return nil;
    }

    fileRef_ = [support_ fileRefWithChildName:aFileName];
    fileRef_ = [fileRef_ fileRefResolvingLinkIfNeeded];

    if (aFileRefPtr != NULL) {
        *aFileRefPtr = fileRef_;
    }

    return fileRef_ ? [fileRef_ filepath] : [[support_ filepath] stringByAppendingPathComponent:aFileName];
}

- (NSString *)userDomainDesktopFolderPath
{
    return [[SGFileRef desktopFolder] filepath];
}

- (NSString *)userDomainDownloadsFolderPath
{
    return [[SGFileRef downloadsFolder] filepath];
}

- (NSString *)userDomainLogsFolderPath
{
    return [[SGFileRef logsFolder] filepath];
}
@end


@implementation CMRFileManager(Cache)
- (void)updateDataRootDirectory
{
    [m_dataRootDirectory autorelease];
    [m_dataRootDirectoryPath autorelease];
    m_dataRootDirectory = nil;
    m_dataRootDirectoryPath = nil;
    
    m_dataRootDirectory = [[self supportDirectoryWithName:CMRDocumentsDirectory] retain];
    m_dataRootDirectoryPath = [[m_dataRootDirectory filepath] retain];
}

- (void)applicationDidBecomeActive:(NSNotification *)theNotification
{
    UTILAssertNotificationName(theNotification, NSApplicationDidBecomeActiveNotification);
    UTILAssertNotificationObject(theNotification, NSApp);

    [self updateDataRootDirectory];
}
@end
