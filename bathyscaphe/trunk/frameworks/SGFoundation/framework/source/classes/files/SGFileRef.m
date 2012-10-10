//
//  SGFileRef.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGFileRef.h"
#import "PrivateDefines.h"
#import <SGFoundation/SGFileLocation.h>
#import <SGFoundation/NSURL-SGExtensions.h>
// #import "SGFile+AppSupport.h"
#import <SGFoundation/NSBundle-SGExtensions.h>

@implementation SGFileRef
- (BOOL)changeFileSystemReferenceWithFileURL:(NSURL *)anURL
{
	if (anURL && [anURL isFileURL]) {
		return [anURL getFileSystemReference:[self getFSRef]];
	}
	return NO;
}

+ (id)fileRefWithFileURL:(NSURL *)anURL
{
	return [[[self alloc] initWithFileURL:anURL] autorelease];
}

- (id)initWithFileURL:(NSURL *)anURL
{
	if (self = [self init]) {
		if (![self changeFileSystemReferenceWithFileURL:anURL]) {
			[self release];
			return nil;
		}
	}
	return self;
}

+ (id)fileRefWithFSRef:(FSRef *)fsRef
{
	return [[[self alloc] initWithFSRef:fsRef] autorelease];
}

- (id)initWithFSRef:(FSRef *)fsRef
{
	if (NULL == fsRef) {
		[self release];
		return nil;
	}

	if (self = [self init]) {
        m_fsRef = *fsRef;
	}
	return self;
}

+ (id)fileRefWithPath:(NSString *)filepath
{
	return [[[self alloc] initWithPath:filepath] autorelease];
}

- (id)initWithPath:(NSString *)filepath
{
	NSURL *fileURL_;

	if (!filepath || 0 == [filepath length]) {
		[self release];
		return nil;
	}

	fileURL_ = [NSURL fileURLWithPath:filepath];
	return [self initWithFileURL:fileURL_];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)aZone
{
    return [self retain];
}

#pragma mark NSObject
- (BOOL)isEqual:(id)other
{
	if (self == other) {
        return YES;
    }
	if (!other) {
        return NO;
	}
	if ([other isKindOfClass:[self class]]) {
		OSErr result;

		result = FSCompareFSRefs([self getFSRef], [other getFSRef]);
		return (noErr == result);
	}

	return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:
            @"<%@:%p> %@",
            [self className], self,
            [self filepath]];
}

- (NSUInteger)hash
{
    return [[self filepath] hash];
}

- (FSRef *)getFSRef
{
	return &m_fsRef;
}

- (SGFileLocation *)fileLocation
{
    return [SGFileLocation fileLocationWithName:[self filename] directory:[self parentFileReference]];
}

- (NSString *)filepath
{
	OSErr		err;
	UInt8		path_[FRWK_SGFILEREF_PATHSIZE];
	
	if (NULL == [self getFSRef]) {
		return nil;
	}
	err = FSRefMakePath([self getFSRef], path_, FRWK_SGFILEREF_PATHSIZE);
	if (err != noErr) {
		return nil;
	}
	// CFStringCreateWithFileSystemRepresentation() is available for Mac OS X 10.4 and later.
	CFStringRef pathRef = CFStringCreateWithFileSystemRepresentation(kCFAllocatorDefault, (const char *)path_);
	if (pathRef == NULL) {
		return nil;
	}

	return [(NSString *)pathRef autorelease];
}

- (NSString *)filename
{
	HFSUniStr255	uniStr255_;
	OSErr			err;

	err = FSGetCatalogInfo(
				[self getFSRef],
				kFSCatInfoNone,
				NULL,
				&uniStr255_,
				NULL,
				NULL);
	if (err != noErr) {
		return nil;
	}
	return [NSString stringWithCharacters:uniStr255_.unicode length:uniStr255_.length];
}

- (NSString *)pathExtension
{
	return [[self filename] pathExtension];
}

- (NSDate *)modifiedDate
{
    NSString *filepath = [self filepath];
    NSDate *date = nil;
    if (!filepath) {
        return nil;
    }
    NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error:NULL];
    if (!info) {
        return nil;
    }
    date = [info objectForKey:NSFileModificationDate];
    return date;
}

- (NSURL *)fileURL
{
	CFURLRef	URLRef_;

	if (NULL == [self getFSRef]) {
		return nil;
	}
	URLRef_ = CFURLCreateFromFSRef(CFAllocatorGetDefault(), [self getFSRef]);
	return [(NSURL*)URLRef_ autorelease];
}

- (BOOL)isPackage
{
	return ((kLSItemInfoIsPackage & [self itemInfoFlags]) != 0);
}

- (BOOL)bs_isDirectory:(Boolean *)flag
{
	OSErr	err;

    FSCatalogInfoBitmap whichInfo = kFSCatInfoNone;
    if (NULL != flag) {
        whichInfo |= kFSCatInfoNodeFlags;
    }

    FSCatalogInfo catalogInfo;
    err = FSGetCatalogInfo([self getFSRef], whichInfo, &catalogInfo, NULL, NULL, NULL);
	if (noErr != err) {
        return NO;
    }

    if (NULL != flag) {
        *flag = (0 != (kFSNodeIsDirectoryMask & catalogInfo.nodeFlags));
    }

    return YES;
}

- (BOOL)isDirectory
{
	Boolean		isDir_;
	
	if ([self bs_isDirectory:&isDir_]) {
		return isDir_ ? YES : NO;
	}
	return NO;
}
@end


@implementation SGFileRef(AllocateOtherRef)
+ (id)searchDirectoryInDomain:(FSVolumeRefNum)vRefNum folderType:(OSType)folderType willCreate:(BOOL)willCreate
{
	OSErr error_;
	FSRef spFolder_;
	
	error_ = FSFindFolder(
					vRefNum, 
					folderType,
					willCreate,
					&spFolder_);
	if (error_ != noErr) {
        return nil;
	}
	return [self fileRefWithFSRef:&spFolder_];
}

+ (id)homeDirectory
{
	return [self searchDirectoryInDomain:kUserDomain folderType:kDomainTopLevelFolderType willCreate:YES];
}

+ (id)desktopFolder
{
	return [self searchDirectoryInDomain:kUserDomain folderType:kDesktopFolderType willCreate:NO];
}

+ (id)downloadsFolder
{
	id tmp = [self searchDirectoryInDomain:kUserDomain folderType:kDownloadsFolderType willCreate:NO];
	if (tmp) {
		return tmp;
	} else {
		return [self desktopFolder];
	}
}

+ (id)logsFolder
{
	return [self searchDirectoryInDomain:kUserDomain folderType:kLogsFolderType willCreate:NO];
}

- (id)parentFileReference
{
	FSRef		parent_;
	OSErr		error_;
	
	error_ = FSGetCatalogInfo([self getFSRef], kFSCatInfoNodeID, NULL, NULL, NULL, &parent_);
	require_noerr(error_, ErrFSGetParentRef);
	// maybe root.
    error_ = FSGetCatalogInfo(&parent_, kFSCatInfoNone, NULL, NULL, NULL, NULL);
	require_noerr(error_, ErrFSGetParentRef);
	
	return [[self class] fileRefWithFSRef:&parent_];
	
ErrFSGetParentRef:

	return nil;
}

- (id)fileRefOfResolvedAliasFile
{
	FSRef			fileSystemRef_;
	Boolean			isTargetFolder_;
	Boolean			wasAliased_;
	OSErr			error_;
	
	if (![self isAliasFile]) {
        return nil;
	}
	fileSystemRef_ = *[self getFSRef];

	error_ = FSResolveAliasFile(
				&fileSystemRef_,
				YES,
				&isTargetFolder_,
				&wasAliased_);
	if (noErr == error_) {
		return [[self class] fileRefWithFSRef:&fileSystemRef_];
	}
	return nil;
}

- (id)fileRefCreateChildWithName:(NSString *)aName whichInfo:(FSCatalogInfoBitmap)whichInfo catalogInfo:(const FSCatalogInfo *)catalogInfo
{
	OSErr			err = noErr;

	UniCharCount	length_ = [aName length];
	const UniChar	*name_;
	UniChar			*nameBuffer_ = NULL;

	FSRef			childRef_;
	id				child_ = nil;

	if (!aName || 0 == length_ || kHFSPlusMaxFileNameChars < length_) {
		return nil;
	}
	name_ = CFStringGetCharactersPtr((CFStringRef)aName);
	if (NULL == name_) {
		nameBuffer_ = malloc(sizeof(UniChar) * length_);
		if (NULL == nameBuffer_) {
			UTILDebugWrite1(
				@"***ERROR*** %@ fail malloc()",
				UTIL_HANDLE_FAILURE_IN_METHOD);

			return nil;
		}

		[aName getCharacters:nameBuffer_];
		name_ = nameBuffer_;
	}

	err = FSCreateFileUnicode(
			[self getFSRef],
			length_,
			name_,
			whichInfo,
			catalogInfo,
			&childRef_,
			NULL);
	
	if (noErr == err) {
		child_ = [[self class] fileRefWithFSRef:&childRef_];
	}

	free(nameBuffer_);
	return child_;
}

- (id)fileRefCreateChildWithName:(NSString *)aName fileType:(OSType)fileHFSTypeCode creatorType:(OSType)fileHFSCreatorCode
{
/*	FileInfo		*fileInfo_;
	FSCatalogInfo	catalogInfo_;
	
	fileInfo_ = (FileInfo*)&catalogInfo_.finderInfo[0];
// #warning 64BIT: Inspect use of sizeof
// 2010-03-20 tsawada2 検討済
	BlockZero(fileInfo_, sizeof(FileInfo));
	
	fileInfo_->fileType = fileHFSTypeCode;
	fileInfo_->fileCreator = fileHFSCreatorCode;
	
	return [self fileRefCreateChildWithName:aName whichInfo:kFSCatInfoFinderInfo catalogInfo:&catalogInfo_];*/
    return nil;
}

- (id)fileRefWithChildName:(NSString *)aName createDirectory:(BOOL)willCreateDir
{
	OSErr			error_;
	const UniChar	*name_;
	
	UniCharCount	length_      = [aName length];
	UniChar			*unicBuffer_ = NULL;
	id				instance_    = nil;
	FSRef			childRef_;
	
	if (!aName || kHFSPlusMaxFileNameChars < length_) {
		return nil;
	}
	name_ = CFStringGetCharactersPtr((CFStringRef)aName);
	if (NULL == name_) {
		unicBuffer_ = malloc(sizeof(UniChar) * length_);
		if (NULL == unicBuffer_) {
			UTILDebugWrite1(
				@"***ERROR*** %@ fail malloc()",
				UTIL_HANDLE_FAILURE_IN_METHOD);

			return nil;
		}

		[aName getCharacters:unicBuffer_];
		name_ = unicBuffer_;
	}


	error_ = FSMakeFSRefUnicode(
				[self getFSRef],
				length_,
				name_,
				kTextEncodingUnknown,
				&childRef_);

	// create Directory
	if ((fnfErr == error_) && willCreateDir) {
		error_ = FSCreateDirectoryUnicode(
					[self getFSRef], 
					[aName length], 
					name_, 
					kFSCatInfoNone,
					NULL, 
					&childRef_, 
					NULL, 
					NULL);
	}

	if (noErr == error_) {
		instance_ = [[self class] fileRefWithFSRef:&childRef_];
	}

	free(unicBuffer_);
	return instance_;
}

- (id)fileRefWithChildName:(NSString *)aName
{
	return [self fileRefWithChildName:aName createDirectory:NO];
}
@end


@implementation SGFileRef(AliasManagerSupport)
- (BOOL)isAliasFile:(Boolean *)isDirectoryFlag
{
	Boolean		aliasFileFlag_;
	OSErr		error_;
	
	error_ = FSIsAliasFile(
				[self getFSRef],
				&aliasFileFlag_,
				isDirectoryFlag);
	if (error_ != noErr) {
		return NO;
	}

	return aliasFileFlag_;
}

- (BOOL)isAliasFile
{
	Boolean isDirectoryFlag;
	return [self isAliasFile:&isDirectoryFlag];
}

- (BOOL)isSymbolicLink
{
	NSDictionary *fileAttributes_;
    fileAttributes_ = [[NSFileManager defaultManager] attributesOfItemAtPath:[self filepath] error:NULL];

	return [NSFileTypeSymbolicLink isEqualToString:[fileAttributes_ fileType]];
}

- (NSString *)pathContentOfResolvedAliasFile
{
	SGFileRef		*resolved_;
	
	if (![self isAliasFile]) {
        return nil;
	}
	resolved_ = [self fileRefOfResolvedAliasFile];
	return [resolved_ filepath];
}

- (NSString *)pathContentResolvingLinkIfNeeded
{
	return [[self fileRefResolvingLinkIfNeeded] filepath];
}

- (id)fileRefResolvingLinkIfNeeded
{
	if ([self isSymbolicLink]) {
		NSString *actualPath_;

        actualPath_ = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath:[self filepath] error:NULL];
		if (!actualPath_) {
			return self;
		}
		if (![actualPath_ hasPrefix:@"/"]) { //2005-12-04
			NSString *parent_;
			parent_ = [[self filepath] stringByDeletingLastPathComponent];
			actualPath_ = [parent_ stringByAppendingPathComponent:actualPath_];
		}

		return [[self class] fileRefWithPath:actualPath_];
	}
	if ([self isAliasFile]) {
		return [self fileRefOfResolvedAliasFile];
	}
	return self;
}
@end


@implementation SGFileRef(LaunchServicesSupport)
- (NSString *)displayName
{
	NSString	*displayName_;
	OSStatus	error_;

	error_ = LSCopyDisplayNameForRef(
				[self getFSRef],
				(CFStringRef*)(&displayName_));
	require_noerr(error_, ErrLSCopyDisplayNameForRef);

	return [displayName_ autorelease];

ErrLSCopyDisplayNameForRef:
	return [[self filepath] lastPathComponent];
}

- (NSString *)kindString
{
	NSString	*kindString_;
	OSStatus	error_;

	error_ = LSCopyKindStringForRef(
				[self getFSRef],
				(CFStringRef*)(&kindString_));
	require_noerr(error_, err_LSCopyKindStringForRef);

	return [kindString_ autorelease];

err_LSCopyKindStringForRef:
	return nil;
}

- (OSStatus)copyItemInfo:(LSRequestedInfo)inWhichInfo itemInfo:(LSItemInfoRecord *)outItemInfo
{
	return LSCopyItemInfoForRef(
				[self getFSRef],
				inWhichInfo,
				outItemInfo);
}

- (BOOL)fileHFSCreatorCode:(OSTypePtr)creator fileType:(OSTypePtr)type
{
	LSItemInfoRecord	record_;
	OSStatus			error_;
	
	error_ = [self copyItemInfo:kLSRequestTypeCreator itemInfo:&record_];
	require_noerr(error_, err_copyItemInfo);

	if (creator != NULL) {
        *creator = record_.creator;
    }
	if (type != NULL) {
        *type = record_.filetype;
    }
	return YES;

err_copyItemInfo:
    return NO;
}

- (OSType)fileHFSCreatorCode
{
	OSType		creator_;
	
	if (![self fileHFSCreatorCode:&creator_ fileType:NULL]) {
		return 0;
    }
	return creator_;
}

- (OSType)fileHFSTypeCode
{
	OSType		filetype_;
	
	if (![self fileHFSCreatorCode:NULL fileType:&filetype_]) {
		return 0;
    }
	return filetype_;
}

- (LSItemInfoFlags)itemInfoFlags
{
	LSItemInfoRecord	record_;
	OSStatus			error_;
	
	error_ = [self copyItemInfo:kLSRequestBasicFlagsOnly itemInfo:&record_];
	if (noErr == error_) {
		return record_.flags;
    }
	return kLSItemInfoIsPlainFile;
}
@end


@implementation SGFileRef(SGApplicationSupport)
// ~/Library/Application Support
+ (SGFileRef *)applicationSupportFolderRef
{
	SGFileRef	*f;

	f = [self searchDirectoryInDomain:kUserDomain folderType:kApplicationSupportFolderType willCreate:YES];
	if (!f) {
		NSLog(@"%@ Can't locate special folder <Application Support>",
			UTIL_HANDLE_FAILURE_IN_METHOD);
	}
	return f;
}
// ~/Library/Application Support/(ExecutableName)
+ (SGFileRef *)applicationSpecificFolderRef
{
	static SGFileRef *supportDirRef_;
	
	if (!supportDirRef_) {
		SGFileRef	*f;
		NSString	*executableName_;

		executableName_ = [NSBundle applicationName];
		if (!executableName_) {
			NSLog(@"%@ No Executable.", UTIL_HANDLE_FAILURE_IN_METHOD);
			return nil;
		}

		f = [self applicationSupportFolderRef];
		if (!f) {
            return nil;
		}

		f = [f fileRefWithChildName:executableName_ createDirectory:YES];
		f = [f fileRefResolvingLinkIfNeeded];

		if (!f || ![f isDirectory]) {
			NSLog(@"%@ Can't locate special folder <Application Support/%@>",
					executableName_,
					UTIL_HANDLE_FAILURE_IN_METHOD);
			return nil;
		}

		supportDirRef_ = [f retain];
	}
	return supportDirRef_;
}
@end
