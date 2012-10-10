//
//  BathyScapheErrors.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/03/07.
//  Copyright 2008-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


enum {
    // File Read/Write Errors
    BSDocumentReadRequiredAttrNotFoundError = 201, // 書類の内容で必須な部分が欠落
    BSDocumentReadNoDataError = 202, // 書類の内容がまったく無い
    BSDocumentReadTooOldLogFormatError = 203, // ログファイルのフォーマットが古すぎる
    BSDocumentReadCannotCopyLogFileError = 211, // ログファイルを適切な場所にコピーできない

    BSDocumentWriteRequiredAttrNotFoundError = 501, // 書類に書き込むべき必須な内容が欠落
    BSDocumentWriteNoDataError = 502, // 書類に書き込むべき内容がまったく無い

    // Downloader Errors
    BSDATDownloaderThreadNotFoundError = 404, // そんな板orスレッドないです（DAT 落ち？）
    BSLoggedInDATDownloaderThreadNotFoundError = 1404, // ●ログインして "-ERR そんな板orスレッドないです。"
    BSThreadTextDownloaderInvalidPartialContentsError = 416, // ダウンロードしたデータが不完全
    CMRDownloaderConnectionDidFailError = 1401, // （NSURLConnection レベルの）ダウンロードエラー Available in BathyScaphe 2.0 "Final Moratorium" and later.

    // BSSettingTxtDetector Errors: Available in BathyScaphe 1.6.3 "Hinagiku" and later.
    BSSettingTxtDetectorCannotStartDownloadingError = 1001, // SETTINT.TXT のダウンロード開始失敗（ダウンロード場所確保失敗）
    
    // BoardManager Errors: Available in BathyScaphe 2.1.1 "D-FORMATION" and later.
    BoardManagerMovedBoardDetectConnectionDidFailError = 1101, // （NSURLConnection レベルの）エラーで板移転検知処理を実行できなかった
    BoardManagerMovedBoardDetectBBONSuspectionError = 1102, // スレッド一覧更新時にバーボン・ボボン規制ページに飛ばされた
    BoardManagerMovedBoardDetectGeneralError = 1103, // 何らかの理由で板移転検知がうまくできなかった

    // BSRelatedKeywordsCollector Errors: Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
    // Removed in BathyScaphe 2.0.
//    BSRelatedKeywordsCollectorInvalidResponseError = 1501, // 不正な http レスポンス（200 以外）
//    BSRelatedKeywordsCollectorDidFailParsingError = 1502, // キーワードの抽出失敗
    
    // BSTGrepSoulGem Errors: Available in BathyScaphe 2.1.1 "D-FORMATION" and later.
    BSFind2chSoulGemServerCapacityError = 1601, // ２ちゃんねる検索側の高負荷のため、検索結果が 0 件だった場合

    // BSNGExpression Errors: Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
    BSNGExpressionInvalidAsRegexError = 1701, // 文字列を正規表現として評価できない
    BSNGExpressionNilExpressionError = 1702, // 文字列を空に設定しようとしている Available in BathyScaphe 2.0 and later.

    // CMRFavoritesManager Errors: Available in BathyScaphe 2.0 "Final Moratorium" and later.
    CMRFavoritesManagerHEADCheckUnavailableError = 1801, // 更新チェックの利用不可
};

extern NSString *const BSBathyScapheErrorDomain;
