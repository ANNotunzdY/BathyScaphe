//
//  BSMachiBBSHEADChecker.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/07/18.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSHTMLHEADChecker : NSObject {
    NSURL *m_url;
    BOOL m_isChecking;
    NSError *m_lastError; // チェック成功の場合：nil チェック失敗の場合：理由を表す NSError オブジェクト
    BOOL m_isUpdated; // YES：新着有り NO：新着無し、エラー、または未チェック
}

- (id)initWithBoardID:(NSUInteger)boardID threadID:(NSString *)threadID count:(NSUInteger)count;
- (void)startChecking;

@property(readonly, assign) BOOL isChecking;
@property(readonly, retain) NSError *lastError;
@property(readonly, assign) BOOL isUpdated; // チェックが終わるまではこの値を信じないこと

@end

extern NSString *const BSHEADCheckerErrorDomain;
