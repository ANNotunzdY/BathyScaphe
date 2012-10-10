//
//  NSMutableString-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/NSMutableString-SGExtensions_p.h>



@implementation NSMutableString(SGExtensions)
- (void)bs_replaceCharacters:(id)searchObject
                    toString:(NSString *)toString
                     options:(NSUInteger)options
                       range:(NSRange)aRange
{
    NSRange     foundRange;
    NSRange     inRange = aRange;
    NSUInteger  replaceLength = [toString length];

    BOOL fromSet = [searchObject isKindOfClass:[NSCharacterSet class]];
    BOOL toDelete = (nil == toString || 0 == replaceLength);

    if (!searchObject) {
        return;
    }
    // 後方検索は必要ない
    if (options & NSBackwardsSearch) {
        options &= ~NSBackwardsSearch;
    }

    while (1) {
        foundRange = fromSet 
            ? [self rangeOfCharacterFromSet:searchObject options:options range:inRange]
            : [self rangeOfString:searchObject options:options range:inRange];

        if (NSNotFound == foundRange.location || 0 == foundRange.length) {
            break;
        }
        if (toDelete) {
            [self deleteCharactersInRange:foundRange];
        } else {
            [self replaceCharactersInRange:foundRange withString:toString];
        }
        inRange.location = foundRange.location + replaceLength;
        inRange.length = ([self length] - inRange.location);
    }
}

- (void)replaceCharacters:(NSString *)chars
                 toString:(NSString *)replacement
{
    [self replaceCharacters:chars
                   toString:replacement
                    options:NSLiteralSearch];
}

- (void)replaceCharacters:(NSString *)chars
                 toString:(NSString *)replacement
                  options:(NSUInteger)options
{
    [self replaceCharacters:chars
                   toString:replacement
                    options:options
                      range:NSMakeRange(0, [self length])];
}

- (void)replaceCharacters:(NSString *)theString
                 toString:(NSString *)replacement
                  options:(NSUInteger)options
                    range:(NSRange)aRange
{
    [self bs_replaceCharacters:theString toString:replacement options:options range:aRange];
}

- (void)deleteCharacters:(NSString *)theString
{
    [self deleteCharacters:theString options:NSLiteralSearch];
}

- (void)deleteCharacters:(NSString *)theString
                 options:(NSUInteger)options
{
    [self deleteCharacters:theString
                   options:options
                     range:NSMakeRange(0, [self length])];
}

- (void)deleteCharacters:(NSString *)theString
                 options:(NSUInteger)options
                   range:(NSRange)aRange
{
    [self bs_replaceCharacters:theString toString:nil options:options range:aRange];
}

- (void)replaceCharactersInSet:(NSCharacterSet *)theSet
                      toString:(NSString *)replacement
                       options:(NSUInteger)options
                         range:(NSRange)aRange
{
    [self bs_replaceCharacters:theSet toString:replacement options:options range:aRange];
}

- (void)replaceCharactersInSet:(NSCharacterSet *)theSet
                      toString:(NSString *)replacement
                       options:(NSUInteger)options
{
    [self replaceCharactersInSet:theSet
                        toString:replacement
                         options:options
                           range:NSMakeRange(0, [self length])];
}

- (void)replaceCharactersInSet:(NSCharacterSet *)theSet
                      toString:(NSString *)replacement
{
    [self replaceCharactersInSet:theSet
                       toString:replacement
                        options:NSLiteralSearch];
}

- (void)deleteCharactersInSet:(NSCharacterSet *)charSet
{
    [self deleteCharactersInSet:charSet
                        options:0];
}

- (void)deleteCharactersInSet:(NSCharacterSet *)charSet
                      options:(NSUInteger)options
{
    [self deleteCharactersInSet:charSet
                        options:options
                          range:NSMakeRange(0, [self length])];
}

- (void)deleteCharactersInSet:(NSCharacterSet *)theSet
                      options:(NSUInteger)options
                        range:(NSRange)aRange
{
    [self bs_replaceCharacters:theSet toString:nil options:options range:aRange];
}

- (void)deleteAll
{
    [self deleteCharactersInRange:NSMakeRange(0, [self length])];
}

- (void)strip
{
    CFStringTrimWhitespace((CFMutableStringRef)self);
}

- (void)stripAtStart
{
    NSRange wsRange_;
    NSInteger index_;
    NSInteger length_;

    wsRange_.location = 0;
    length_ = [self length];
    for (index_ = 0; index_ < length_; index_++){
        if (!isspace([self characterAtIndex:index_])) {
            break;
        }
    }
    wsRange_.length = index_;
    [self deleteCharactersInRange:wsRange_];
}

- (void)stripAtEnd
{
    NSRange wsRange_;
    NSInteger index_;
    NSInteger length_;

    for (index_ = ([self length] -1); index_ >= 0; index_--) {
        if (!isspace([self characterAtIndex:index_])) {
            break;
        }
    }
    length_ = [self length];
    wsRange_.location = (index_ +1);
    if (wsRange_.location == length_) {
        return;
    }
    wsRange_.length = length_ - wsRange_.location;
    [self deleteCharactersInRange:wsRange_];
}

// HTML
- (void)deleteAllTagElements
{
    static NSString *s_lt = @"<";
    static NSString *s_gt = @">";

    NSUInteger length_;
    NSRange result_;
    NSRange searchRng_;

    if ((length_ = [self length])< 2) {
        return;
    }
    searchRng_ = NSMakeRange(0, length_);

    while ((result_ = [self rangeOfString:s_lt
                                  options:NSLiteralSearch
                                    range:searchRng_]).length != 0) {
        NSRange gtRng_;     //@"<"を検索

        //"<"の次から検索
        searchRng_.location = NSMaxRange(result_);
        searchRng_.length = (length_ - searchRng_.location);
        if ((gtRng_ = [self rangeOfString:s_gt
                                  options:NSLiteralSearch
                                    range:searchRng_]).length == 0) {
            continue;
        }

        result_.length = NSMaxRange(gtRng_)- result_.location;

        //見つかった範囲は削除される
        searchRng_.location = NSMaxRange(gtRng_);
        searchRng_.length = (length_ - searchRng_.location);
        [self deleteCharactersInRange:result_];
        searchRng_.location -= result_.length;
        length_ = [self length];
    }
}

// @return 置換したあとの長さの変化
- (NSInteger)resolveEntityWithEntityRange:(NSRange)entityRange
{
    NSString *entity;
    NSString *newStr;

    // エンティティ参照を解決
    entity = [self substringWithRange:entityRange];
    newStr = [(NSString *)SGXMLCreateStringForEntityReference((CFStringRef)entity) autorelease];

    if (newStr) {
        entityRange.location--;
        entityRange.length += 2;
        [self replaceCharactersInRange:entityRange withString:newStr];
        return [newStr length] - entityRange.length;
    }
    return 0;
}

static inline NSRange SGUtilEntityRangeWithAmpSemicologne(NSUInteger amp, NSUInteger semicologne)
{
    NSRange entityRng;

    NSCAssert(
        amp < semicologne,
        @"F: must be amp location < semicologne location");
    //エンティティ参照の範囲"&(---);"
    entityRng.location = amp +1;
    entityRng.length = semicologne - entityRng.location;

    return entityRng;
}

- (void)replaceEntityReference
{
    NSRange ampRng_;
    NSRange searchRng;

    searchRng = NSMakeRange(0, [self length]);
    while ((ampRng_ = [self rangeOfString:@"&" 
                                  options:NSLiteralSearch
                                    range:searchRng]).length != 0) {
        NSRange semicologneRng_;
        NSUInteger location_;

        location_ = NSMaxRange(ampRng_);
        searchRng = NSMakeRange(location_, [self length] - location_);

        if ((semicologneRng_ = [self rangeOfString:@";" 
                                           options:NSLiteralSearch
                                             range:searchRng]).length != 0) {
            NSRange entityRng_;

            entityRng_ = SGUtilEntityRangeWithAmpSemicologne(ampRng_.location, semicologneRng_.location);

            // 置換しなかった場合は"&"の次から検索するので、検索範囲は変わらない
            NSInteger changeInLength_;

            changeInLength_ = [self resolveEntityWithEntityRange:entityRng_];
            if (changeInLength_ != 0) {
                searchRng.location = NSMaxRange(entityRng_)+1;
                searchRng.location += changeInLength_;
                searchRng.length = ([self length] - searchRng.location);
            }
        }
    }
}
@end
