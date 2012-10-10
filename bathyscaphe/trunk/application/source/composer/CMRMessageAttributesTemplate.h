//:CMRMessageAttributesTemplate.h
/**
  *
  * スレッドの標準的な書式を管理するオブジェクト
  *
  * @author Takanori Ishikawa
  * encoding="UTF-8"
  * @version 1.0.0d1 (02/04/21  0:12:41 AM)
  *
  */
#import <Cocoa/Cocoa.h>
#import "CMRMessageAttributesStyling.h"



@interface CMRMessageAttributesTemplate : NSObject<CMRMessageAttributesStyling>
{
	NSMutableDictionary *_messageAttributesForAnchor;	//リンクの書式
	NSMutableDictionary *_messageAttributesForName;	//名前の書式
	NSMutableDictionary *_messageAttributesForTitle;	//項目のタイトル書式
	NSMutableDictionary *_messageAttributesForText;	//標準の書式
	NSMutableDictionary *_messageAttributes;			//メッセージの書式
	
	NSMutableDictionary *_messageAttributesForBeProfileLink;	//Be プロフィールリンクの書式
	NSMutableDictionary *_messageAttributesForHost;	//Hostの書式
}
+ (NSDictionary *) defaultAttributes;
+ (id) sharedTemplate;

- (NSAttributedString *)referencedMarkerStringForMessageIndex:(NSNumber *)messageIndex referencedCount:(NSUInteger)count;
@end




@interface CMRMessageAttributesTemplate(Attributes)
- (void) setMessageHeadIndent : (CGFloat) anIndent;
- (void) setHasAnchorUnderline : (BOOL) flag;

- (void) setMessageIdxSpacingBefore : (CGFloat) beforeValue
					andSpacingAfter : (CGFloat) afterValue;
@end
