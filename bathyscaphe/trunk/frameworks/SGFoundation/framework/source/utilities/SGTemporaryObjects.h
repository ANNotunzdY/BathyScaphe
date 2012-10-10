//
//  SGTemporaryObjects.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#ifndef SGTEMPOBJECTS_H_INCLUDED
#define SGTEMPOBJECTS_H_INCLUDED

/*!
 * @header     CMXObjectRecycle.h
 * @discussion Recyclable Object Service -- Public API
 */
#import <Foundation/Foundation.h>
#import <SGFoundation/SGFoundationBase.h>
#import <SGFoundation/SGBase.h>


SG_DECL_BEGIN



/*!
 * @abstract   一時可変オブジェクト
 * @discussion 
 * 
 * ***スレッドごとに***割り当てられる可変オブジェクト。
 * 次の呼び出し時に内容はクリアされる。
 * 
 */
SG_EXPORT
NSMutableArray *SGTemporaryArray(void);
SG_EXPORT
NSMutableDictionary *SGTemporaryDictionary(void);
SG_EXPORT
NSMutableAttributedString *SGTemporaryAttributedString(void);
SG_EXPORT
NSMutableString *SGTemporaryString(void);
SG_EXPORT
NSMutableSet *SGTemporarySet(void);
SG_EXPORT
NSMutableData *SGTemporaryData(void);
SG_EXPORT
SGBaseRangeArray *SGTemporaryRangeArray(void);




SG_DECL_END

#endif /* SGTEMPOBJECTS_H_INCLUDED */
