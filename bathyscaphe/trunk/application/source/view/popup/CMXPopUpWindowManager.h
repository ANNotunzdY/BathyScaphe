//
//  CMXPopUpWindowManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/12/25.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

/*!
 * @header     CMXPopUpWindowManager
 * @discussion ポップアップウィンドウの管理
 */
#import <Cocoa/Cocoa.h>
#import "CMXPopUpWindowController.h"

@class BSThreadViewTheme;

#define CMRPopUpMgr		[CMXPopUpWindowManager defaultManager]

@interface CMXPopUpWindowManager : NSObject {
	@private
	NSMutableArray *bs_controllersArray;
}
/*!
 * @method      defaultManager
 * @abstract    共有オブジェクトを返す。
 * @discussion  共有オブジェクトを返す。
 * @result      共有オブジェクトを返す。
 */
+ (id)defaultManager;

- (BOOL)isPopUpWindowVisible;

/*!
 * @method         showPopUpWindowWithContext:forObject:owner:locationHint:
 * @abstract       ポップアップウィンドウを表示する
 * @discussion     ポップアップウィンドウを表示する
 * @param context  表示する内容
 * @param object   関連づけのキーとなるオブジェクト
 * @param owner    delegate
 * @param point    表示位置
 * 
 * @result         CMXPopUpWindowController
 */
- (id)showPopUpWindowWithContext:(NSAttributedString *)context
                       forObject:(id)object
                           owner:(id)owner
                    locationHint:(NSPoint)point;

- (BOOL)popUpWindowIsVisibleForObject:(id)object;

- (void)closePopUpWindowForOwner:(id)owner;

/*!
 * @method        performClosePopUpWindowForObject:
 * @abstract      ポップアップウィンドウを閉じる
 * @discussion    ポップアップウィンドウを閉じる
 * @param object  関連づけのキーとなるオブジェクト
 * @result		  閉じた場合はYES
 */
- (BOOL)performClosePopUpWindowForObject:(id)object;

// CMRPref Accessors
- (BOOL)popUpUsesSmallScroller;
- (BOOL)popUpShouldAntialias;
- (BOOL)popUpLinkTextHasUnderline;
- (BSThreadViewTheme *)theme;
@end
