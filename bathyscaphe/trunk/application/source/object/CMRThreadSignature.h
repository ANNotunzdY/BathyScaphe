//
//  CMRThreadSignature.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/09.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//
  
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "CMRHistoryObject.h"

@interface CMRThreadSignature : NSObject<NSCopying, NSCoding, NSPasteboardReading, NSPasteboardWriting, CMRHistoryObject, CMRPropertyListCoding>
{
	NSString	*m_identifier;
	NSString	*m_boardName;
}

+ (id)threadSignatureFromFilepath:(NSString *)filepath;
- (id)initFromFilepath:(NSString *)filepath;

+ (id)threadSignatureWithIdentifier:(NSString *)identifier boardName:(NSString *)boardName;
- (id)initWithIdentifier:(NSString *)identifier boardName:(NSString *)boardName;

- (NSString *)identifier;
- (NSString *)boardName;

- (NSString *)datFilename;
- (NSString *)idxFileName;

- (NSString *)threadDocumentPath;
- (NSURL *)threadDocumentURL;
@end

extern NSString *const BSPasteboardTypeThreadSignature;