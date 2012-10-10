//
//  CMRHostTypes.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#ifndef HOSTTYPES_INCLUDED
#define HOSTTYPES_INCLUDED
#ifdef  __cplusplus
extern "C" {
#endif

#import <Foundation/Foundation.h>

/*
  2channel.brd compatibility
--------------------------------
  http://jbbs.shitaraba.com/business/767/
    -->
  (host) jbbs.shitaraba.com
  (path) jbbs.shitaraba.com/business
  (directory) 767
*/

// return temporary cstring
extern const char *CMRGetHostCStringFromBoardURL(NSURL *anURL, const char **bbs);
// return copied string
extern NSString *CMRGetHostStringFromBoardURL(NSURL *anURL, NSString **bbs);
/*
  Deprecated in BathyScaphe 1.6 and later.
*/
// return temporary string
//extern NSString *CMRGetHostStringFromBoardURLNoCopy(NSURL *anURL, NSString **bbs);




extern bool can_readcgi(const char *host);

// 2channel互換
extern bool is_2channel(const char *host);

// 純粋な２ちゃんねる（pink も除く） Available in BathyScaphe 2.0.3 and later.
extern bool is_2ch_except_pink(const char *host);
/*
  Deprecated in BathyScaphe 2.0 and later.
*/
//extern bool is_be2ch(const char *host);	// EUC エンコーディングが必要かどうかを判定する際に使う

// 書き込みに Be ログインが必須かどうかを判定する際に使う
extern bool is_2ch_belogin_needed(const char *host);

/*
  Deprecated in BathyScaphe 2.0 and later.
  Use is_jbbs_livedoor(const char *host) instead.
*/
extern bool is_jbbs_shita(const char *host);

/*
  Available in BathyScaphe 1.6 and later.
*/
extern bool is_jbbs_livedoor(const char *host);
extern bool is_machi(const char *host);

/*
  Deprecated in BathyScaphe 1.6 and later.
  These BBSs has no longer been available recent years.
*/
//extern bool is_jbbs(const char *host);
//extern bool is_shitaraba(const char *host);
//extern bool is_tanteifile(const char *host);

//extern bool can_offlaw(const char *host);
//extern bool kako_salad(const char *host, const char *bbs);
//extern bool bbs_qb(const char *host);





#ifdef  __cplusplus
}
#endif

#endif	/* HOSTTYPES_INCLUDED */
