//
//  CMRAttributedMessageComposer.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/11/03.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAttributedMessageComposer_p.h"
#import "CMRThreadLinkProcessor.h"
#import <AppKit/NSTextStorage.h>

// for debugging only
#define UTIL_DEBUGGING      1
#import "UTILDebugging.h"

#define kLocalizedFilename          @"MessageComposer"

// KeyValueTemplate.plist
#define kThreadIndexFormatKey       @"Thread - IndexFormat"
#define kThreadFieldSeparaterKey    @"Thread - FieldSeparater"
#define kThreadHostFormatKey        @"Thread - Host Format"

static NSString *dateStringFromObject(id theDate, NSString *prefix);
static void appendFieldTitle(NSMutableAttributedString *buffer, NSUInteger tag);
static void appendWhiteSpaceSeparator(NSMutableAttributedString *buffer);

enum {
    kFieldName = 0,
    kFieldMail = 1,
    kFieldDate = 2,
    kFieldID = 3,
};

#define LOCALIZED_STR(aKey) NSLocalizedStringFromTable(aKey, kLocalizedFilename, nil)
#define FIELD_NAME              LOCALIZED_STR(@"Name")
#define FIELD_MAIL              LOCALIZED_STR(@"Mail")
#define FIELD_DATE              LOCALIZED_STR(@"Date")
#define FIELD_ID                LOCALIZED_STR(@"ID")
#define FIELD_HOST              LOCALIZED_STR(@"Host")


#pragma mark -

@implementation CMRAttributedMessageComposer

static NSAttributedString   *wSS = nil;

+ (void)initialize 
{
    UTIL_DEBUG_METHOD;
}

+ (id)composerWithContentsStorage:(NSMutableAttributedString *)storage
{
    return [[[self alloc] initWithContentsStorage:storage] autorelease];
}

- (id)initWithContentsStorage:(NSMutableAttributedString *)storage
{
    if (self = [self init]) {
        [self setContentsStorage:storage];
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        [self setComposingMask:CMRInvisibleMask compose:NO];
        bs_targetIndex = NSNotFound;
    }
    return self;
}

- (void)dealloc
{
    [_contentsStorage release];
    [_nameCache release];
    [super dealloc];
}

/* Accessor for _contentsStorage */
- (NSMutableAttributedString *)contentsStorage
{
    if (!_contentsStorage) {
        _contentsStorage = [[NSTextStorage alloc] init];
    }
    return _contentsStorage;
}

- (void)setContentsStorage:(NSMutableAttributedString *)aContentsStorage
{
    id tmp;

    tmp = _contentsStorage;
    _contentsStorage = [aContentsStorage retain];
    [tmp release];
}

/* mask で指定された属性を無視する */
- (UInt32)attributesMask
{
    return _mask;
}

- (void)setAttributesMask:(UInt32)mask
{
    _mask = mask;
}

/* flag: mask に一致する属性をもつレスを生成するかどうか */
- (void)setComposingMask:(UInt32)mask compose:(BOOL)flag
{
    _CCFlags.mask = mask;
    _CCFlags.compose = flag ? 1 : 0;
}

- (void)setComposingTargetIndex:(NSUInteger)index
{
    bs_targetIndex = index;
}

- (BOOL)shouldComposeMsgsOnlyForWhichContainsAnchorForTheIdx
{
    return (bs_targetIndex != NSNotFound);
}

#pragma mark Instance Methods
static BOOL messageIsLocalAboned_(CMRThreadMessage *aMessage) 
{
    return ([aMessage isLocalAboned] || ([aMessage isSpam] && kSpamFilterLocalAbonedBehavior == [CMRPref spamFilterBehavior]));
}

- (void)composeThreadMessage:(CMRThreadMessage *)aMessage
{
    NSMutableAttributedString   *ms = [self contentsStorage];
    NSRange                     mRange_;
    UInt32                      flags_ = [aMessage flags];
    
    if (!aMessage) {
        return;
    }
    if ((0 == _CCFlags.compose) != (0 == (_CCFlags.mask & flags_))) {
        return;
    }
    
    if (flags_ & _mask) {
        UInt32      newFlags_;
        
        newFlags_ = (flags_ & (~_mask));
        [aMessage setFlags:newFlags_];
    }

    BOOL    isSpam_ = [aMessage isSpam];
    // 「迷惑レス」：表示しない場合
    if (isSpam_ && kSpamFilterInvisibleAbonedBehavior == [CMRPref spamFilterBehavior]) {
        return;
    }
    mRange_.location = [ms length];
    [super composeThreadMessage:aMessage];
    mRange_.length = [ms length] - mRange_.location;

    if ([self shouldComposeMsgsOnlyForWhichContainsAnchorForTheIdx]) {
        if (![self attributedString:[ms attributedSubstringFromRange:mRange_] containsAnchorForMessageIndex:bs_targetIndex]) {
            [ms deleteCharactersInRange:mRange_];
            [aMessage setFlags:flags_];
            return;
        }
    }
    
    if (isSpam_ && (mRange_.length != 0)) {
        //「迷惑レス」は色を変更する
        [ms addAttribute:NSForegroundColorAttributeName value:[[CMRPref threadViewTheme] messageFilteredColor] range:mRange_];
    }
    
    // 属性を元に戻す
    [aMessage setFlags:flags_];
}

- (void)composeIndex:(CMRThreadMessage *)aMessage
{
    static NSString             *indexFormat = nil;
    NSMutableAttributedString   *ms = [self contentsStorage];
    NSMutableString             *label_;
    NSRange                     mRange_;
    NSUInteger              index;
    
    if (!indexFormat) {
        indexFormat = SGTemplateResource(kThreadIndexFormatKey);
        if (!indexFormat) {
            indexFormat = @"%lu";
        }
    }
    
    index = [aMessage index];
    label_ = SGTemporaryString();
// #warning 64BIT: Check formatting arguments
// 2010-11-03 tsawada2 修正済
    [label_ appendFormat:indexFormat, (unsigned long)(index + 1)];
    
    mRange_.location = [ms length];
    [ms appendString:label_ withAttributes:[ATTR_TEMPLATE attributesForText]];
    mRange_.length = [ms length] - mRange_.location;
    
    [ms addAttribute:CMRMessageIndexAttributeName value:[NSNumber numberWithUnsignedInteger:index] range:mRange_];

    /* ブックマークはフォントと色を変更 */
    if ([aMessage hasBookmark]) {
        [ms applyFontTraits:(NSBoldFontMask|NSItalicFontMask) range:mRange_];
        [ms addAttribute:NSForegroundColorAttributeName value:[[CMRPref threadViewTheme] bookmarkColor] range: mRange_];
    }
/*
2004-01-22 Takanori Ishikawa <takanori@gd5.so-net.ne.jp>
レス番号にリンクをはると、ポップアップしたレスの内容が大きすぎる場合、
番号が隠れてしまい、メニューを表示できなくなる。
*/
    appendWhiteSpaceSeparator(ms);
}

- (void)composeName:(CMRThreadMessage *)aMessage
{
    NSString                    *name = [aMessage name];
    NSMutableAttributedString   *ms;
    
    if (!_nameCache) {
        _nameCache = [[NSMutableAttributedString alloc] init];
    }
    if (messageIsLocalAboned_(aMessage)) {
        name = LOCALIZED_STR(@"Abone");
    }
    
    ms = [self contentsStorage];
    appendFieldTitle(ms, kFieldName);
    
    if (name && ![name isEmpty]) {
        if (![[_nameCache string] isEqualToString:name]) {
            [_nameCache deleteAll];
            [self convertName:name with:_nameCache];
        }

        [ms appendAttributedString:_nameCache];
    }

    appendWhiteSpaceSeparator(ms);
}

- (void)composeMail:(CMRThreadMessage *)aMessage
{   
    if (messageIsLocalAboned_(aMessage)) {
        return;
    }
    NSString *mail = [aMessage mail];
    NSString *convertedMail;
    if (!mail) {
        return;
    }
    // assume entity reference length > 4,
    // because in the most case, mail is "sage" or empty string
    if ([mail length] > 4) {
        convertedMail = [CMXTextParser stringByReplacingEntityReference:mail];
    } else {
        convertedMail = mail;
    }

    [self appendMailAttachmentWithAddress:convertedMail];
    [self appendMailAddressWithAddress:convertedMail];

    appendWhiteSpaceSeparator([self contentsStorage]);
}

static void simpleAppendFieldItem(NSMutableAttributedString *ms, NSString *item)
{
    if (!item || [item length] == 0) {
        return;
    }
    appendFieldTitle(ms, kFieldDate);
    [ms appendString:item withAttributes:[ATTR_TEMPLATE attributesForText]];

    appendWhiteSpaceSeparator(ms);
}

- (void)composeDate:(CMRThreadMessage *)aMessage
{
    NSMutableString     *tmp;
    NSString            *dateRep;
    NSString        *anchorStr = nil;

    if (messageIsLocalAboned_(aMessage)) {
        return;
    }
    // message date is nil, if message was aboned.
    if (![aMessage date]) {
        return;
    }
    tmp = SGTemporaryString();
    dateRep = [aMessage dateRepresentation];

    if (dateRep) {
        NSRange anchor_ = [dateRep rangeOfString:@"<a href=\"http://2ch.se/\">" options:(NSCaseInsensitiveSearch|NSLiteralSearch)];
        if (anchor_.length != 0) {
            NSRange anchorEnd_;
            NSRange foo;
            anchorEnd_ = [dateRep rangeOfString:@"</a>" options:(NSCaseInsensitiveSearch|NSLiteralSearch|NSBackwardsSearch)];
            foo.location = NSMaxRange(anchor_);
            foo.length = anchorEnd_.location - NSMaxRange(anchor_);
            anchorStr = [dateRep substringWithRange:foo];
            [tmp setString:[dateRep substringToIndex:anchor_.location]];
        } else {
            [tmp setString:dateRep];
        }
    } else {
        [tmp setString:dateStringFromObject([aMessage date], nil)];
    }

    simpleAppendFieldItem([self contentsStorage], tmp);

    if (anchorStr) {
        NSMutableAttributedString *result_ = [[NSMutableAttributedString alloc] initWithString:anchorStr];

        NSRange anchorRange = NSMakeRange(0, [result_ length]);
        NSMutableAttributedString   *contentsStorage_ = [self contentsStorage];

        [result_ addAttribute:NSLinkAttributeName value:[NSURL URLWithString:@"http://2ch.se/"]];
        [result_ addAttributes:[ATTR_TEMPLATE attributesForText] range:anchorRange];

        [contentsStorage_ insertAttributedString:result_ atIndex:([contentsStorage_ length] - 1)];
        [result_ release];
    }
}

- (void)composeID:(CMRThreadMessage *)aMessage
{
    if (messageIsLocalAboned_(aMessage)) {
        return;
    }
    NSString    *idStr = [aMessage IDString];
    if (!idStr || [idStr length] == 0) {
        return;
    }
    NSMutableAttributedString   *ms = [self contentsStorage];
    NSRange                     idRange;
    
    appendFieldTitle(ms, kFieldID);
    
    idRange.location = [ms length];
    [ms appendString:idStr withAttributes:[ATTR_TEMPLATE attributesForText]];
    
    if (![idStr hasPrefix:@"???"] && ![idStr isEqualToString:@"DELETED"]) {
        idRange.length = [ms length] - idRange.location;
        
        [ms addAttribute:BSMessageIDAttributeName value:idStr range:idRange];
        // TODO ??? ID でも BSMessageKeyAttributeName は仕込んだ方が良い
        [ms addAttribute:BSMessageKeyAttributeName value:@"IDString" range:idRange];
    }
    appendWhiteSpaceSeparator(ms);
}

- (void)composeBeProfile:(CMRThreadMessage *)aMessage
{
    NSMutableAttributedString   *mas_;
    NSArray                     *tmpAry_ = nil;
    NSString                    *beStr_;
    NSMutableAttributedString   *format_;
    NSInteger                           count_;
    BOOL                        makeLink = YES;

    if (messageIsLocalAboned_(aMessage)) {
        return;
    }
    tmpAry_ = [aMessage beProfile];
    if (!tmpAry_) {
        return;
    }
    count_ = [tmpAry_ count];
    if (count_ == 0 || count_ > 2) {
        return;
    }
    if (count_ == 1) {
        // kabunushi yutai
        beStr_ = [tmpAry_ objectAtIndex:0];
        makeLink = NO;
    } else {
        NSMutableString *beRep_;
        beRep_ = [[tmpAry_ objectAtIndex:1] mutableCopy];

        NSRange fontTag = [beRep_ rangeOfString:@"<font color=" options:(NSCaseInsensitiveSearch|NSLiteralSearch)];
        if (fontTag.length != 0) {
            NSRange fontTagEnd;
            fontTagEnd = [beRep_ rangeOfString:@"</font>" options:(NSCaseInsensitiveSearch|NSLiteralSearch|NSBackwardsSearch)];
            
            if (fontTagEnd.length != 0) {
                fontTag.length = fontTagEnd.location - fontTag.location + fontTagEnd.length;
                [beRep_ replaceCharactersInRange:fontTag withString:LOCALIZED_STR(@"BE_Solitaire")];
            }
        }

        beStr_ = [NSString stringWithFormat:@"?%@", beRep_];
        [beRep_ release];
    }

    format_   = SGTemporaryAttributedString();

    [[format_ mutableString] appendString:beStr_];
    [format_ addAttributes:[ATTR_TEMPLATE attributesForBeProfileLink] range:[format_ range]];

    if (makeLink) {
        [format_ addAttribute:NSLinkAttributeName
                        value:CMRLocalBeProfileLinkWithString([tmpAry_ objectAtIndex:0])
                        range:[format_ range]];
    }

    mas_ = [self contentsStorage];

    [mas_ appendAttributedString:format_];

    appendWhiteSpaceSeparator(mas_);
}

- (void)composeHost:(CMRThreadMessage *)aMessage
{
    static NSString                     *format_;
    static NSMutableAttributedString    *template_;
    auto   NSMutableAttributedString    *ms;
    auto   NSString                     *host = [aMessage host];
    
    UTILRequireCondition(host && [host length], ErrComposeHost);
    UTILRequireCondition(
        NO == messageIsLocalAboned_(aMessage), 
        ErrComposeHost);
    
    format_   = SGTemplateResource(kThreadHostFormatKey);

    ms = [self contentsStorage];
    template_ = SGTemporaryAttributedString();
// #warning 64BIT: Check formatting arguments
// 2010-11-03 tsawada2 確認済
    [[template_ mutableString] appendFormat:format_, host];
    [template_ addAttributes:[ATTR_TEMPLATE attributesForHost] range:NSMakeRange(0,[[template_ mutableString] length])];
    [template_ addAttribute:BSMessageKeyAttributeName value:@"host" range:[[template_ mutableString] rangeOfString:host]];

    [ms appendAttributedString:template_];

ErrComposeHost:
    return;
}

- (void)composeMessage:(CMRThreadMessage *)aMessage
{
    NSMutableAttributedString   *ms;
    NSMutableAttributedString   *tmp;
    id                          source;
    NSRange                     mRange_;
    BOOL                        isLocalAboned = messageIsLocalAboned_(aMessage);
    BOOL                        isBookmarked = [aMessage hasBookmark];
    
    ms = [self contentsStorage];
    tmp = SGTemporaryAttributedString();
    
    // 「ローカルあぼーん」
    if (isLocalAboned) {
        source = [aMessage isSpam] ? LOCALIZED_STR(@"SpamLocalAbone") : LOCALIZED_STR(@"LocalAbone");
    } else {
        source = [aMessage cachedMessage];
    }
    
    mRange_.location = [tmp length];

    [tmp replaceCharactersInRange:[tmp range] withString:source];
    [tmp setAttributes:[ATTR_TEMPLATE attributesForMessage] range:[tmp range]];
    [self convertMessage:nil with:tmp];
    if (isLocalAboned) {
        NSRange     linkRange_;
        
        // 「ローカルあぼーん」では内容をポップアップするリンクを追加     
        linkRange_.location = [tmp length];
        [[tmp mutableString] appendString:LOCALIZED_STR(@"ShowLocalAbone")];
        linkRange_.length = [tmp length] - linkRange_.location;

        [tmp addAttribute:NSLinkAttributeName value:CMRLocalResLinkWithIndex([aMessage index]) range:linkRange_];
    }
    mRange_.length = [tmp length] - mRange_.location;
    if ([aMessage isAsciiArt]) {
        // AA
        NSFont *font = [CMRPref firstAvailableAAFont];
        if (font) {
            [tmp addAttribute:NSFontAttributeName value:font range:mRange_];
        }
        if (isBookmarked) {
            [tmp addAttribute:NSForegroundColorAttributeName value:[[CMRPref threadViewTheme] bookmarkColor] range:mRange_];
        }
    } else if (isBookmarked) {
        BSThreadViewTheme *theme = [CMRPref threadViewTheme];
        NSDictionary *bmattr = [NSDictionary dictionaryWithObjectsAndKeys:[theme bookmarkFont], NSFontAttributeName,
                                    [theme bookmarkColor], NSForegroundColorAttributeName, NULL];
        [tmp addAttributes:bmattr range:mRange_];
    }
    if (!isLocalAboned) {
        // For Searching
        [tmp addAttribute:BSMessageKeyAttributeName value:@"cachedMessage" range:mRange_];
    }
    
    // 
    // 順番通りに書式つき文字列を挿入すると、つづく文字列にまで
    // 本文の書式が適用されてしまうため、まず、改行を挿入し、
    // そのあとで、本文の書式つき文字列を挿入する。
    source = [ms mutableString];
    [source appendString:@"\n\n"];
    [ms insertAttributedString:tmp atIndex:([ms length] - 1)];
    
    [tmp deleteAll];
}

- (id)getMessages
{
    return [self contentsStorage];
}

- (BOOL)attributedString:(NSAttributedString *)substring containsAnchorForMessageIndex:(NSUInteger)index
{
    NSRange range;
    NSInteger i;
    NSInteger cnt = [substring length];
    NSRange rangeLimit = NSMakeRange(0, cnt);

    for (i = 0; i < cnt; i += range.length) {
        id aURLString = [substring attribute:NSLinkAttributeName atIndex:i longestEffectiveRange:&range inRange:rangeLimit];

        if (range.length <= 0) {
            break;
        }
        if (aURLString) {
            NSMutableIndexSet *indexes = nil;
            if ([CMRThreadLinkProcessor isMessageLinkUsingLocalScheme:aURLString messageIndexes:&indexes] && indexes) {
                if ([indexes containsIndex:index]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}
@end


@implementation CMRAttributedMessageComposer(Mail)
- (void)appendMailAttachmentWithAddress:(NSString *)address
{
    NSAttributedString  *attachment_;

    if (![CMRPref mailAttachmentShown] || !address) {
        return;
    }
    attachment_ = [ATTR_TEMPLATE mailAttachmentStringWithMail:address];
    if (!attachment_ || [attachment_ length] == 0) {
        return;
    }
    [[self contentsStorage] appendAttributedString:attachment_];
}

- (void)appendMailAddressWithAddress:(NSString *)address
{
    NSMutableAttributedString *ms;
    NSMutableAttributedString *mail;

    if (![CMRPref mailAddressShown] || !address) {
        return;
    }
    ms = [self contentsStorage];

    appendWhiteSpaceSeparator(ms);

    appendFieldTitle(ms, kFieldMail);

    mail = [[NSMutableAttributedString alloc] initWithString:address attributes:[ATTR_TEMPLATE attributesForText]];
    [mail addAttribute:BSMessageKeyAttributeName value:@"mail" range:NSMakeRange(0, [address length])];
    [ms appendAttributedString:mail];
    [mail release];
}
@end

#pragma mark -

static NSString *dateStringFromObject(id theDate, NSString *prefix)
{
    static CFDateFormatterRef   formatterRef = NULL;

    if ([theDate isKindOfClass:[NSString class]]) {
        return theDate;
    }
    if ([theDate isKindOfClass:[NSDate class]]) {
        UTILDebugWrite(@"NSDate -> NSString");
        CFStringRef         dayStrRef;

        if (formatterRef == NULL) {
            CFLocaleRef localeRef = CFLocaleCopyCurrent();
            formatterRef = CFDateFormatterCreate(kCFAllocatorDefault, localeRef, kCFDateFormatterShortStyle, kCFDateFormatterMediumStyle);
            CFRelease(localeRef);
        }

        dayStrRef = CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, formatterRef, (CFDateRef)theDate);

        if (dayStrRef != NULL) {
            NSString *dayStr_ = [NSString stringWithString:(NSString *)dayStrRef];
            CFRelease(dayStrRef);
            if (!prefix) {
                return dayStr_;
            } else {
                return [NSString stringWithFormat:@"%@ %@", prefix, dayStr_];
            }
        }
    }
    return @"";
}

static void appendWhiteSpaceSeparator(NSMutableAttributedString *buffer)
{
    if (!wSS) {
        wSS = [[NSAttributedString alloc] initWithString:@" "];
    }
    [buffer appendAttributedString:wSS];
}

static void appendFieldTitle(NSMutableAttributedString *buffer, NSUInteger tag)
{
    static NSArray *cache = nil;

    if (!cache) {
        NSString *fieldSeparator = SGTemplateResource(kThreadFieldSeparaterKey);
        if (!fieldSeparator) {
            fieldSeparator = @": ";
        }
        cache = [[NSArray alloc] initWithObjects:
            [FIELD_NAME stringByAppendingString:fieldSeparator],
            [FIELD_MAIL stringByAppendingString:fieldSeparator],
            [FIELD_DATE stringByAppendingString:fieldSeparator],
            [FIELD_ID stringByAppendingString:fieldSeparator],
            nil];
    }
    [buffer appendString:[cache objectAtIndex:tag] withAttributes:[ATTR_TEMPLATE attributesForItemName]];
}
