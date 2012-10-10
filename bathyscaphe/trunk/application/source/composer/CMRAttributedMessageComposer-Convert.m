//
//  CMRAttributedMessageComposer-Convert.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/08/16.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAttributedMessageComposer_p.h"
#import <CocoaOniguruma/OnigRegexp.h>

static void convertMessageOrNameWith(NSMutableAttributedString *ms, NSString *str, NSDictionary *attributes)
{	
	if (!ms) {
        return;
    }
	[ms replaceCharactersInRange:[ms range] withString:str];
	[ms setAttributes:attributes range:[ms range]];

	[CMXTextParser convertMessageSourceToCachedMessage:[ms mutableString]];
}

static void convertMessageWith(NSMutableAttributedString *ms)
{
	if (!ms || [ms length] == 0) {
		return;
    }
    static OnigRegexp *regExp = nil;

	if (!regExp) {
		regExp = [[OnigRegexp compile:@"ID:\\s?([[[:ascii:]]&&[^\\s]]{8,11})"] retain];
	}

    NSRange sakuRange = [[ms string] rangeOfString:NSLocalizedStringFromTable(@"saku saku", @"MessageComposer", @"") options:NSLiteralSearch];
    if (sakuRange.location != NSNotFound) {
        sakuRange.length -= 6;
        [ms addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:sakuRange];
        NSRange foo;
        foo.location = NSMaxRange(sakuRange);
        foo.length = [[ms string] length] - NSMaxRange(sakuRange);
        [[ms mutableString] replaceOccurrencesOfString:@" <ul> " withString:@"\n" options:NSLiteralSearch range:foo];

        NSRange bar = [[ms string] rangeOfString:@"</ul> " options:NSLiteralSearch];
        if (bar.location != NSNotFound) {
            [[ms mutableString] deleteCharactersInRange:bar];
        }
        NSRange hoge = [[ms string] rangeOfString:@" </ul>" options:NSLiteralSearch|NSBackwardsSearch];
        if (hoge.location != NSNotFound) {
            [[ms mutableString] deleteCharactersInRange:hoge];
        }
    }
	// 本文中の「ID: xxxxxxxxxx」という文字列にも Attribute を仕込んで、長押しによる ID ポップアップを可能にする
    OnigResult *match;
    NSInteger start = 0;
    NSInteger length = [ms length];
    NSString *value;
    NSRange IDRange;
    while (start < length) {
        match = [regExp search:[ms string] start:start];
        if (match) {
            value = [match stringAt:1];
            IDRange = [match rangeAt:1];
            [ms addAttribute:BSMessageIDAttributeName value:value range:IDRange];
            start = NSMaxRange([match bodyRange]);
        } else {
            break;
        }
    }
}

@implementation CMRAttributedMessageComposer(Convert)
- (void)convertMessage:(NSString *)message with:(NSMutableAttributedString *)buffer
{
//	convertMessageOrNameWith(buffer, message, [ATTR_TEMPLATE attributesForMessage]);
	convertMessageWith(buffer);
	[self convertLinkAnchor:buffer];
}

- (void)convertName:(NSString *)name with:(NSMutableAttributedString *)buffer
{
	convertMessageOrNameWith(buffer, name, [ATTR_TEMPLATE attributesForName]);
	[self makeInnerLinkAnchorInNameField:buffer];
}
@end
