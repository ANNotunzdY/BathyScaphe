//
//  CMRFileManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/04/09.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class SGFileRef;

@interface CMRFileManager : NSObject {
    @private
    SGFileRef *m_dataRootDirectory;
    NSString *m_dataRootDirectoryPath;
}

+ (id)defaultManager;

// CMRDocumentsDirectory
- (NSString *)dataRootDirectoryPath;
- (NSString *)supportFileUnderDataRootDirectoryPathWithName:(NSString *)name;
- (SGFileRef *)dataRootDirectory;

// ~/Library/Application Support/BathyScaphe 
- (SGFileRef *)supportDirectory;

// ~/Library/Application Support/BathyScaphe/<dirName>
- (SGFileRef *)supportDirectoryWithName:(NSString *)dirName;

// ~/Library/Application Support/BathyScaphe/<fileName>
- (NSString *)supportFilepathWithName:(NSString *)aFileName
                     resolvingFileRef:(SGFileRef **)aFileRefPtr;

// ~/Desktop
- (NSString *)userDomainDesktopFolderPath;

// ~/Downloads (on Mac OS X 10.5 and later)
- (NSString *)userDomainDownloadsFolderPath;

// ~/Library/Logs
- (NSString *)userDomainLogsFolderPath;
@end


@interface CMRFileManager(Cache)
- (void)updateDataRootDirectory;
@end
