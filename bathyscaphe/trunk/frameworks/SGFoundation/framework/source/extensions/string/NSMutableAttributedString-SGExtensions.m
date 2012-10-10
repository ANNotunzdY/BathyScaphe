//
//  NSMutableAttributedString-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSMutableAttributedString-SGExtensions.h"
#import <Foundation/NSString.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>


@implementation NSMutableAttributedString(SGExtentions)
- (void)addAttribute:(NSString *)name value:(id)value
{
	NSRange rng_;

	if (!name) {
        return;
    }
	rng_ = NSMakeRange(0, [self length]);
	if (!value) {
		[self removeAttribute:name range:rng_];
	} else {
		[self addAttribute:name value:value range:rng_];
	}
}

- (void)deleteAll
{
	[self deleteCharactersInRange:NSMakeRange(0, [self length])];
}

- (void)appendString:(NSString *)str withAttributes:(NSDictionary *)dict
{
	NSAttributedString *attributedString_;

	attributedString_ = [[NSAttributedString allocWithZone:[self zone]] initWithString:str attributes:dict];
	[self appendAttributedString:attributedString_];
	[attributedString_ release];
}

- (void)appendString:(NSString *)str withAttribute:(NSString *)attrsName value:(id)value
{
	NSRange rng_;
	NSMutableString *mstr_;
	
	if (!attrsName) {
        return;
    }
	rng_.length = [str length];
	if (!str || 0 == rng_.length) {
        return;
    }
	mstr_ = [self mutableString];
	rng_.location = [mstr_ length];
	[mstr_ appendString:str];
	[self addAttribute:attrsName value:value range:rng_];
}
@end
