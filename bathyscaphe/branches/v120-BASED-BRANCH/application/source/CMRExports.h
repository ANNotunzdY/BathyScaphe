/**
  * $Id: CMRExports.h,v 1.7 2006-03-07 15:17:40 tsawada2 Exp $
  * 
  * CMRExports.h
  *
  * Copyright (c) 2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  */




#ifndef CMREXPORTS_H_INCLUDED
#define CMREXPORTS_H_INCLUDED

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif


@class SGInternalMessenger;
@class CMRBrowser;
// main browser
extern CMRBrowser			*CMRMainBrowser;

// main thread & runLoop...
extern NSThread				*CMRMainThread;
extern NSRunLoop			*CMRMainRunLoop;
extern SGInternalMessenger	*CMRMainMessenger;

extern void CMRApplicationReset(id sender);

/*!
 * @function    CMXInit
 * @discussion  各サービスの初期化
 */
extern void CMXServicesInit(void);

/*!
 * @abstract    ログ出力オブジェクト
 * @discussion  アプリケーション全体で使用するログ出力オブジェクト
 */
extern SGUtilLogger *CMRLogger;

/*!
 * @category    CMXFavoritesDirectoryName
 * @discussion  Version 1 との互換性のためだけの機能
 */
#define CMXFavoritesDirectoryName	NSLocalizedString(@"Favorites", nil)

extern BOOL shouldCascadeBrowser;


#ifdef __cplusplus
}  /* End of the 'extern "C"' block */
#endif
#endif /* CMREXPORTS_H_INCLUDED */
