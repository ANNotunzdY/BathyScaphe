//
//  BSLinkDownloadManager.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/08/07.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@protocol CMRPropertyListCoding;

@interface BSLinkDownloadTicket : NSObject<CMRPropertyListCoding> {
    NSString    *m_extension;
    BOOL        m_autoopen;
}
- (NSString *)extension;
- (void)setExtension:(NSString *)extensionString;
- (BOOL)autoopen;
- (void)setAutoopen:(BOOL)isAutoopen;
@end

@interface BSLinkDownloadManager : NSObject {
    NSMutableArray *m_downloadableTypes;
    NSMutableArray *m_abortMIMETypes;
}

+ (id)defaultManager;

- (NSMutableArray *)downloadableTypes;
- (void)setDownloadableTypes:(NSMutableArray *)array;

- (NSMutableArray *)abortMIMETypes;
- (void)setAbortMIMETypes:(NSMutableArray *)array;

- (void)writeToFileNow;
@end
