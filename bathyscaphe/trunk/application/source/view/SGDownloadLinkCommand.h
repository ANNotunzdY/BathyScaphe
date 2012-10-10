//
//  SGDownloadLinkCommand.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/01/16.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGLinkCommand.h"
#import "CMRTask.h"

@class BSURLDownload;

@interface SGDownloadLinkCommand : SGLinkCommand<CMRTask> {
    BSURLDownload *m_currentDownload;
    NSUInteger m_expectLength;
    NSUInteger m_downloadedLength;
    NSString *m_message;
    double m_amount;

    NSDictionary *m_refererThreadInfo;
}

- (BSURLDownload *)currentDownload;
- (void)setCurrentDownload:(BSURLDownload *)download;

- (NSDictionary *)refererThreadInfo;
- (void)setRefererThreadInfo:(NSDictionary *)dict;
@end

extern NSString *const kRefererTitleKey;
extern NSString *const kRefererURLKey;
