//
//  BSLoggedInDATDownloader.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/10/15.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRDATDownloader.h"

@interface BSLoggedInDATDownloader : CMRDATDownloader {
    NSString *m_sessionID;
    NSString *m_downloadingHost;
    NSString *m_candidateHost;
    BOOL    m_reuse;
}

+ (id)downloaderWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host;

- (BOOL)updateSessionID;
- (NSString *)sessionID;

- (NSString *)downloadingHost;
- (void)setDownloadingHost:(NSString *)host;

- (NSString *)candidateHost;
- (void)setCandidateHost:(NSString *)host;
@end
