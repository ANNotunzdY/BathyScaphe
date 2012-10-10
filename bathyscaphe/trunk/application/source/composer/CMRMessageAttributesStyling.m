//:CMRMessageAttributesStyling.m
// encoding="UTF-8"
#import "CMRMessageAttributesStyling.h"

NSString *const CMRAttributeInnerLinkScheme = @"cmonar";
NSString *const CMRAttributesBeProfileLinkScheme = @"cmbe";

/*** Application Specific Attribute Name ***/
NSString *const CMRMessageIndexAttributeName = @"CMRIndex";

/* These attributes are for text attachements. */
NSString *const CMRMessageLastUpdatedHeaderAttributeName = @"CMRLastUpdated";
NSString *const CMRMessageProxyAttributeName = @"CMRMessageProxy";
NSString *const CMRMessageBeProfileLinkAttributeName = @"CMRBeProfileLink";

// Available in TestaRossa and later.
NSString *const BSMessageIDAttributeName = @"BSID";

// Available in Starlight Breaker.
NSString *const BSMessageKeyAttributeName = @"BSKey";

// Available in BathyScaphe 2.3 "Bright Stream" and later.
NSString *const BSMessageReferencedCountAttributeName = @"BSRefCount";

// 内部リンクのアドレス文字列を生成。
NSString *CMRLocalResLinkWithString(NSString *address)
{
	return [NSString stringWithFormat: @"%@:%@",
		CMRAttributeInnerLinkScheme,
		address];
}
/* 0-based */
NSString *CMRLocalResLinkWithIndex(NSUInteger anIndex)
{
// #warning 64BIT: Check formatting arguments
// 2011-08-27 tsawada2 修正済
	return [NSString stringWithFormat: @"%@:%lu",
		CMRAttributeInnerLinkScheme,
		(unsigned long)anIndex +1];
}
// be プロフィールリンクの内部表現用アドレス文字列を生成。
NSString *CMRLocalBeProfileLinkWithString(NSString *beProfile)
{
	return [NSString stringWithFormat: @"%@:%@",
		CMRAttributesBeProfileLinkScheme,
		beProfile];
}
