//
//  CMRAppTypes.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/07/19.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


enum {
    ThreadStandardStatus        = 0,
    ThreadNoCacheStatus         = 1,
    ThreadLogCachedStatus       = 1 << 1,
    ThreadUpdatedStatus         = (1 << 2) | ThreadLogCachedStatus,
    ThreadNewCreatedStatus      = (1 << 3) | ThreadNoCacheStatus,
    ThreadHeadModifiedStatus    = (1 << 4) | ThreadLogCachedStatus // Available in BathyScaphe 1.2 and later.
};
typedef NSUInteger ThreadStatus;


enum {
    ThreadViewerMoveToIndexLinkType,
    ThreadViewerOpenBrowserLinkType,
    ThreadViewerResPopUpLinkType,
};
typedef NSUInteger ThreadViewerLinkType;


enum {
    CMRAutoscrollNone             = 0,
    CMRAutoscrollWhenTLUpdate     = 1,
    CMRAutoscrollWhenTLSort       = 1 << 1,
    CMRAutoscrollWhenThreadUpdate = 1 << 2,
    CMRAutoscrollWhenTLVMChange   = 1 << 3, // Available in Tenori Tiger.
    CMRAutoscrollWhenThreadDelete = 1 << 4, // Available in BathyScaphe 1.6.3 "Hinagiku" and later.
    CMRAutoscrollAny              = 0xffffffffU,
    CMRAutoscrollStandard         = CMRAutoscrollAny ^ CMRAutoscrollWhenThreadDelete, // Available in BathyScaphe 1.6.3 "Hinagiku" and later.
};
typedef NSUInteger CMRAutoscrollCondition; // Available in BathyScaphe 1.6.3 "Hinagiku" and later.


enum {
    kSpamFilterChangeTextColorBehavior = 1,
    kSpamFilterLocalAbonedBehavior,
    kSpamFilterInvisibleAbonedBehavior
};
typedef NSUInteger BSSpamFilterBehavior; // Available in BathyScaphe 2.0 and later.


enum {
    BSAddNGExAllScopeType = 0,
    BSAddNGExBoardScopeType = 1,
    BSAddNGExThreadScopeType = 2, // reserved
};
typedef NSInteger BSAddNGExpressionScopeType; // Available in BathyScaphe 2.0 "Final Moratorium" and later.


enum {
    CMRSearchOptionNone                  = 0,
    CMRSearchOptionCaseInsensitive       = 1,
    CMRSearchOptionBackwards             = 1 << 1,
    CMRSearchOptionZenHankakuInsensitive = 1 << 2,
    CMRSearchOptionIgnoreSpecified       = 1 << 3,
    CMRSearchOptionLinkOnly              = 1 << 4,
    CMRSearchOptionUseRegularExpression  = 1 << 5 // Available in Starlight Breaker.
};
typedef NSUInteger CMRSearchMask;


enum {
    BSOpenInBrowserAll          = 2,
    BSOpenInBrowserLatestFifty  = 0,
    BSOpenInBrowserFirstHundred = 1
};
typedef NSUInteger BSOpenInBrowserType;


enum {
    BSBeLoginTriviallyNeeded = 0, // Be ログイン必須
    BSBeLoginTriviallyOFF    = 1, // Be ログインは無意味（2chではない掲示板など）
    BSBeLoginDecidedByUser   = 2, // Be ログインするかどうかはユーザの設定を参照する
    BSBeLoginNoAccountOFF    = 3  // 環境設定で Be アカウントが設定されていない
};
typedef NSUInteger BSBeLoginPolicyType;


enum {
    BSThreadsListShowsLiveThreads = 0, // 0x00
    BSThreadsListShowsStoredLogFiles = 1, // 0x01
    BSThreadsListShowsSmartList = 2, // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later. 0x10
    BSThreadsListShowsFavorites = 3, // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later. 0x11
}; // Available in Twincam Angel and later.
typedef NSUInteger BSThreadsListViewModeType;


enum {
    BSTGrepSearchByNew = 0, // tGrep only.
    BSTGrepSearchByFast = 1, // tGrep only.
    BSTGrepSearchByLast = 2, // find.2ch.net only. Available in BathyScaphe 2.0.4 and later.
    BSTGrepSearchByCount = 3, // find.2ch.net only. Available in BathyScaphe 2.0.4 and later.
}; // Available in BathyScaphe 2.0 "Final Moratorium" and later.
typedef NSUInteger BSTGrepSearchOptionType;


enum {
    BSAppResetNone = 0,
    BSAppResetHistory = 1,
    BSAppResetCookie = 1 << 1,
    BSAppResetCache = 1 << 2,
    BSAppResetWindow = 1 << 3,
    BSAppResetPreviewer = 1 << 4,
    BSAppResetAll = 0xffffffffU,
}; // Available in BathyScaphe 2.0.5 and later.
typedef NSUInteger BSAppResetMask;
