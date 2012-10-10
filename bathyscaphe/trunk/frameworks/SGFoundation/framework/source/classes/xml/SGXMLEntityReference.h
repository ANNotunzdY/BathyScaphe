//
//  SGXMLEntityReference.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/17.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#ifndef SGXMLENTITYREFERENCE_INCLUDED
#define SGXMLENTITYREFERENCE_INCLUDED

#include <CoreFoundation/CoreFoundation.h>
#include <SGFoundation/SGBase.h>

SG_DECL_BEGIN



/*!
 * @function      SGXMLCharacterForEntityReference
 * @abstract      XML実体参照の解決
 * @discussion    

実体参照の名前、または文字参照に対応したUnicode文字を返す。
任意のUnicode文字。ただし，サロゲートブロック，FFFE及びFFFFは除く。
サポートしているのはスタンダード、Latin1、Special、Symbolである。

 * @param  theEntity  名前 or 文字参照 ("#123" "#xAA")
 * @param  theUniChar 対応するUnicode文字
 * @result            成功時にtrue
 */

SG_EXPORT
Boolean SGXMLCharacterForEntityReference(
                CFStringRef         theEntityReference,
                UniChar             *theUniChar);

SG_EXPORT
CFStringRef SGXMLCreateStringForEntityReference(
                CFStringRef         theEntityReference);



SG_DECL_END

#endif /* SGXMLENTITYREFERENCE_INCLUDED */
