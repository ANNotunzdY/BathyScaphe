//
//  ThreadTextDownloader_p.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/27.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "ThreadTextDownloader.h"
#import "CMRDownloader_p.h"

#import "CocoMonar_Prefix.h"

#import "AppDefaults.h"
#import "CMRDocumentFileManager.h"

#import "CMRThreadPlistComposer.h"
#import "CMR2chDATReader.h"
#import "CMRThreadSignature.h"
#import "CMRHostHandler.h"

#import "BoardManager.h"




@interface ThreadTextDownloader(ThreadDataArchiver)
- (BOOL)synchronizeLocalDataWithContents:(NSString *)datContents dataLength:(NSUInteger)dataLength;
- (NSDictionary *)dictionaryByAppendingContents:(NSString *)datContents dataLength:(NSUInteger)dataLength;
@end
