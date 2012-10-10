//
//  SGTemplatesManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/08/11.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#ifndef SGTEMPLATE_MGR_INCLUDED
#define SGTEMPLATE_MGR_INCLUDED

#import <Cocoa/Cocoa.h>
#import <SGFoundation/SGBase.h>

SG_DECL_BEGIN



/*!
 * @define      kSGAttributesTemplateFile
 * @discussion  書式付き文字列のテンプレートファイル
 */
//#define kSGAttributesTemplateFile		@"StyleTemplates"
/*!
 * @define      kSGPropertyListTemplateFile
 * @discussion  Property List形式のテンプレートファイル
 */
#define kSGPropertyListTemplateFile		@"KeyValueTemplates"



//@interface NSMutableAttributedString(SGTemplateResourcesManagerPrivate)
//- (id) setStringAndReturnSelf : (NSString *) aString;
//@end



/*

[Attributed String Template]
RTF, RTFDファイルに記述した識別子を取り出し、
NSMutableAttributedStringのインスタンスとして管理できます。

たとえば、%%%ExampleIdentifier%%%と記述したRTFファイルを
用意してそれを取り込むと、アプリケーションからは
- resourceForKey:で@"ExampleIdentifier"の
NSMutableAttributedStringインスタンスを得ることができます。

*/

@interface SGTemplatesManager : NSObject {
    @private
    NSMutableDictionary *_resources;
}
/*!
 * @method      sharedInstance
 * @abstract    共有インスタンス
 * @discussion  
 * 
 * アプリケーションのApplecation Supportディレクトリと
 * + [NSBundle mainBundle]からリソースを探索するインスタンス
 * 
 * @result      共有インスタンス
 */
+ (SGTemplatesManager *)sharedInstance;

- (id)resourceForKey:(id)aKey;
- (void)addResourcesFromContentsOfFile:(NSString *)filepath;

- (void)resetAllResources;
@end


#define SGTemplateResource(aKey)	[[SGTemplatesManager sharedInstance] resourceForKey : (aKey)]

// Property List
#define SGTemplateSize(aKey)	NSSizeFromString(SGTemplateResource(aKey))
#define SGTemplatePoint(aKey)	NSPointFromString(SGTemplateResource(aKey))
#define SGTemplateRect(aKey)	NSRectFromString(SGTemplateResource(aKey))

#define SGTemplateSelector(aKey)	NSSelectorFromString(SGTemplateResource(aKey))
#define SGTemplateClass(aKey)	NSClassFromString(SGTemplateResource(aKey))


// プリミティブ
#define SGTemplateBool(aKey)	[SGTemplateResource(aKey) boolValue]


// 書式付き文字列
//#define SGTemplateAttrString(aKey, aString)	[SGTemplateResource(aKey) setStringAndReturnSelf : (aString)]

//#define SGTemplateAttribute(aKey, aName)	[SGTemplateResource(aKey) attribute:(aName) atIndex:0 effectiveRange:NULL]

// NSDictionary
//#define SGTemplateAttributes(aKey)	[SGTemplateResource(aKey) attributesAtIndex:0 effectiveRange:NULL]

//#define SGTemplateColor(aKey)	SGTemplateAttribute(aKey, NSForegroundColorAttributeName)

//#define SGTemplateFont(aKey)	SGTemplateAttribute(aKey, NSFontAttributeName)



SG_DECL_END


#endif /* SGTEMPLATE_MGR_INCLUDED*/
