//
//  CMRExports.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/28.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//


#ifndef CMREXPORTS_H_INCLUDED
#define CMREXPORTS_H_INCLUDED

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

@class CMRBrowser;
// main browser
extern CMRBrowser			*CMRMainBrowser;

/*!
    @defined    CMXFavoritesDirectoryName
    @abstract   「お気に入り」項目
    @discussion 「お気に入り」項目の名前
*/
#define CMXFavoritesDirectoryName	NSLocalizedString(@"Favorites", @"")

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6
/*!
    @defined    NSAppKitVersionNumber10_6
    @abstract   Mac OS X v10.6 の AppKit バージョン番号
    @discussion Mac OS X v10.6 SDK では、この番号は定義されていないので、
                ここで定義しておく。
*/
#define NSAppKitVersionNumber10_6 1038
#endif

/*!
    @defined    BSUserDebugEnabledKey
    @abstract   ユーザ側でデバッグログ出力の可否を切り替えるための defaults キー
    @discussion ユーザに defaults データベースのこのキーを YES にしてもらうことで、
                デバッグログを取得してもらい、問題発生時の調査・解決に役立てる。
*/
#define BSUserDebugEnabledKey @"BSUserDebugEnabled"

    
#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_6
enum {
    NSTableViewRowSizeStyleDefault = -1, 
    NSTableViewRowSizeStyleCustom = 0,
    NSTableViewRowSizeStyleSmall = 1,  
    NSTableViewRowSizeStyleMedium = 2,
    NSTableViewRowSizeStyleLarge = 3,
};
typedef NSInteger NSTableViewRowSizeStyle;

enum {
    NSScrollerStyleLegacy       = 0,
    NSScrollerStyleOverlay      = 1
};
typedef NSInteger NSScrollerStyle;

enum {
    NSScrollerKnobStyleDefault  = 0,
    NSScrollerKnobStyleDark     = 1,
    NSScrollerKnobStyleLight    = 2
};
typedef NSInteger NSScrollerKnobStyle;

enum {
    NSScrollElasticityAutomatic = 0, // automatically determine whether to allow elasticity on this axis
    NSScrollElasticityNone      = 1, // disallow scrolling beyond document bounds on this axis
    NSScrollElasticityAllowed   = 2, // allow content to be scrolled past its bounds on this axis in an elastic fashion
};
typedef NSInteger NSScrollElasticity; 
    
@interface NSScroller(LionStub)
+ (NSScrollerStyle)preferredScrollerStyle;
- (void)setKnobStyle:(NSScrollerKnobStyle)newKnobStyle;
@end
    
@interface NSScrollView(LionStub)
- (void)setScrollerKnobStyle:(NSScrollerKnobStyle)newKnobStyle;
- (void)flashScrollers;
- (void)setVerticalScrollElasticity:(NSScrollElasticity)elasticity;
@end

@interface NSTableView(LionStub)
- (void)setRowSizeStyle:(NSTableViewRowSizeStyle)rowSizeStyle;
- (NSTableViewRowSizeStyle)rowSizeStyle;
@end
#endif

@interface NSObject(MountainLionStub)
- (id)initWithItems:(NSArray *)items;
- (void)showRelativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)preferredEdge;
@end


#ifdef __cplusplus
}  /* End of the 'extern "C"' block */
#endif
#endif /* CMREXPORTS_H_INCLUDED */
