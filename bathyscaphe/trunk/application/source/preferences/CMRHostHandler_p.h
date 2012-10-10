//
//  CMRHostHandler_p.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/27.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRHostHandler.h"
#import "CocoMonar_Prefix.h"
#import "CMXTextParser.h"

#define kHostPropertiesFile     @"HostProperties.plist"


#define kHostNameKey                @"name"
#define kHostIdentifierKey          @"identifier"
#define kReadCGIPropertiesKey       @"CGI - Read"
    #define kRelativePathKey        @"relativePath"
    #define kRelativePathRawModeKey @"relativePath(raw)" // Available in BathyScaphe 2.0 and later.
    #define kAbsolutePathKey        @"absolutePath"
    // [[NSURL path] pathComponents] での directory のindex
    #define kReadCGIDirectoryIndexKey   @"directoryIndex"
    #define kReadCGINameKey             @"name" // BathyScaphe 1.6.5 以降では NSArray かもしれない
    #define kReadCGIDirectoryKey        @"directory"
    #define kReadCGIParamBBSKey         @"bbs"
    #define kReadCGIParamIDKey          @"key"
    #define kReadCGIParamStartKey       @"start"
    #define kReadCGIParamEndKey         @"end"
    #define kReadCGIParamNoFirstKey     @"nofirst"
    #define kReadCGIParamTrueKey        @"true"

// DAT
#define kCanReadDATFileKey          @"DAT - Readable"
#define kRelativeDATDirectoryKey    @"DAT - RelativeDirectory"

// @see readURLWithBoard:datName:
#define READ_URL_FORMAT_DEF     @"%@?%@=%@&%@=%@"
#define READ_URL_FORMAT_2CH     @"%@/%s/%@/"
#define READ_URL_FORMAT_2CH_2       @"%@/%@/%@/"


extern NSDictionary *CMRHostPropertiesForKey(NSString *aKey);
