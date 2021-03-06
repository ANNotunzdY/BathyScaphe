//: CMRAppTypes.h
/**
  * $Id: CMRAppTypes.h,v 1.1.1.1.4.2 2006-01-29 12:58:10 masakih Exp $
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.
  * See the file LICENSE for copying permission.
  */

#import <Foundation/Foundation.h>


typedef enum _ThreadStatus {
	ThreadStandardStatus    = 0,		
	ThreadNoCacheStatus     = 1,		
	ThreadLogCachedStatus   = 1 << 1,	
	
	ThreadUpdatedStatus     = (1 << 2) | ThreadLogCachedStatus,	
	
	ThreadNewCreatedStatus  = (1 << 3) | ThreadNoCacheStatus,
	
	ThreadHeadModifiedStatus = (1 << 4) | ThreadLogCachedStatus // available in BathyScaphe 1.2 and later
} ThreadStatus;

typedef enum _ThreadViewerLinkType{
	ThreadViewerMoveToIndexLinkType,
	ThreadViewerOpenBrowserLinkType,
	ThreadViewerResPopUpLinkType,
} ThreadViewerLinkType;


enum {
	CMRAutoscrollNone             = 0,
	CMRAutoscrollWhenTLUpdate     = 1,
	CMRAutoscrollWhenTLSort       = 1 << 1,
	CMRAutoscrollWhenThreadUpdate = 1 << 2,
	CMRAutoscrollAny			  = 0xffffffffU
};

enum {
	kSpamFilterChangeTextColorBehavior = 1,
	kSpamFilterLocalAbonedBehavior,
	kSpamFilterInvisibleAbonedBehavior
};

typedef enum _CMRSearchMask{
	CMRSearchOptionNone						= 0,
	CMRSearchOptionCaseInsensitive			= 1,
	CMRSearchOptionBackwards				= 1 << 1,
	CMRSearchOptionZenHankakuInsensitive	= 1 << 2,
	CMRSearchOptionIgnoreSpecified			= 1 << 3,
	CMRSearchOptionLinkOnly					= 1 << 4
} CMRSearchMask;

typedef enum _BSOpenInBrowserType {
	BSOpenInBrowserAll			= 2,
	BSOpenInBrowserLatestFifty	= 0,
	BSOpenInBrowserFirstHundred	= 1
} BSOpenInBrowserType;


typedef enum _BSBeLoginPolicyType {
	BSBeLoginTriviallyNeeded	= 0, // Be ログイン必須
	BSBeLoginTriviallyOFF		= 1, // Be ログインは無意味（2chではない掲示板など）
	BSBeLoginDecidedByUser		= 2, // Be ログインするかどうかはユーザの設定を参照する
	BSBeLoginNoAccountOFF		= 3  // 環境設定で Be アカウントが設定されていない
} BSBeLoginPolicyType;

