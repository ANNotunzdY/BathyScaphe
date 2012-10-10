//
//  CMRThreadLinkProcessor.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/11/19.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class CMRThreadSignature;

@interface CMRThreadLinkProcessor : NSObject
+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL filepath:(NSString **)pFilepath;
+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL filepath:(NSString **)pFilepath parsedHost:(NSString **)pH;
+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName threadSignature:(CMRThreadSignature **)pSignature; // Available in BathyScaphe 2.3 and later.
+ (BOOL)parseBoardLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL;

+ (BOOL)isMessageLinkUsingLocalScheme:(id)aLink messageIndexes:(NSIndexSet **)indexSetPtr;
+ (BOOL)isBeProfileLinkUsingLocalScheme:(id)aLink linkParam:(NSString **)aParam;
@end
