//
//  CMRReplyDocumentFileManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/22.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class CMRThreadSignature;

@interface CMRReplyDocumentFileManager : NSObject {

}
+ (id)defaultManager;

+ (NSArray *)documentAttributeKeys;

- (BOOL)replyDocumentFileExistsAtPath:(NSString *)path;
- (BOOL)createDocumentFileIfNeededAtPath:(NSString *)filepath contentInfo:(NSDictionary *)contentInfo;

- (BOOL)replyDocumentFileExistsAtURL:(NSURL *)absoluteURL;
- (BOOL)createReplyDocumentFileAtURL:(NSURL *)absoluteURL documentAttributes:(NSDictionary *)attributesDict;

- (NSString *)replyDocumentFileExtention;
- (NSString *)replyDocumentDirectoryWithBoardName:(NSString *)boardName createIfNeeded:(BOOL)flag;
- (NSString *)replyDocumentFilepathWithLogPath:(NSString *)filepath createIfNeeded:(BOOL)flag;

- (NSURL *)replyDocumentFileURLWithLogURL:(NSURL *)logFileURL createIfNeeded:(BOOL)flag;

- (NSArray *)replyDocumentFilesArrayWithLogsArray:(NSArray *)logfiles;
@end
