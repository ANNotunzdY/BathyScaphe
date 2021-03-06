//: CMXPopUpWindowManager.h
/**
  * $Id: CMXPopUpWindowManager.h,v 1.1.1.1 2005-05-11 17:51:09 tsawada2 Exp $
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.
  * See the file LICENSE for copying permission.
  */

/*!
 * @header     CMXPopUpWindowManager
 * @discussion ポップアップウィンドウの管理
 */
#import <Cocoa/Cocoa.h>
#import "CMXPopUpWindowController.h"


@class SGBaseCArrayWrapper;

#define CMRPopUpMgr		[CMXPopUpWindowManager defaultManager]

@interface CMXPopUpWindowManager : NSObject
{
	@private
	SGBaseCArrayWrapper		*_controllerArray;
}
/*!
 * @method      defaultManager
 * @abstract    共有オブジェクトを返す。
 * @discussion  共有オブジェクトを返す。
 * @result      共有オブジェクトを返す。
 */
+ (id) defaultManager;

- (BOOL) isPopUpWindowVisible;
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
- (id) showPopUpWindowWithContext : (NSAttributedString *) context
                        forObject : (id                  ) object
                            owner : (id                  ) owner
                     locationHint : (NSPoint             ) point;

- (BOOL) popUpWindowIsVisibleForObject : (id) object;

- (void) closePopUpWindowForOwner : (id) owner;
/*!
 * @method        performClosePopUpWindowForObject:
 * @abstract      ポップアップウィンドウを閉じる
 * @discussion    ポップアップウィンドウを閉じる
 * @param object  関連づけのキーとなるオブジェクト
 * @result		  閉じた場合はYES
 */
- (BOOL) performClosePopUpWindowForObject : (id) object;



- (NSColor *) backgroundColor;
- (BOOL) isSeeThrough;
@end
