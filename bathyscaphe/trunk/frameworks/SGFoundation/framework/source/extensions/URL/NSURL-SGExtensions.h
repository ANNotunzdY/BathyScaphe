//
//  NSURL-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>


@interface NSURL(SGExtensions)
+ (id)URLWithLink:(id)aLink;
+ (id)URLWithLink:(id)anLink baseURL:(NSURL *)baseURL;
+ (id)URLWithScheme:(NSString *)scheme host:(NSString *)host path:(NSString *)path;

- (NSString *)stringValue;
- (NSDictionary *)queryDictionary;

- (NSURL *)URLByAppendingPathComponent:(NSString *)pathComponent;
- (NSURL *)URLByDeletingLastPathComponent;

// Carbon FSRef/Alias
+ (id)fileURLWithFileSystemReference:(const FSRef *)fileSystemRef;
- (BOOL)getFileSystemReference:(FSRef *)fileSystemRef;

- (NSURL *)resolveAliasFile;
@end
