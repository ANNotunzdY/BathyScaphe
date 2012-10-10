//
//  CMXTextParser.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMXTextParser.h"
#import "CocoMonar_Prefix.h"
#import "CMRThreadMessage.h"
#import <CocoaOniguruma/OnigRegexp.h>

// for debugging only
#define UTIL_DEBUGGING      1
#import "UTILDebugging.h"

static NSString *const CMXTextParserComma                   = @",";
static NSString *const CMXTextParser2chSeparater            = @"<>";

#define kAvailableURLCFEncodingsNSArrayKey      @"System - AvailableURLCFEncodings"

static BOOL _parseDateExtraField(NSString *dateExtra, CMRThreadMessage *aMessage);

#pragma mark -

// teri系以外は'@｀'を','に変換
static NSString *fnc_stringWillConvertToComma(void)
{
    static NSString *st_cnv;
    
    if (!st_cnv) {
        unichar c[] = {'@', 0xff40};    // '@｀'
        st_cnv = [[NSString alloc] initWithCharacters:c length:UTILNumberOfCArray(c)];
    }
    return st_cnv;
}

static void separetedLineByConvertingComma(NSString *theString, NSMutableArray *fields)
{
    NSArray *separated_;
    NSString *replace_;
    
    UTILCAssertNotNil(theString);
    UTILCAssertNotNil(fields);
    
    replace_ = fnc_stringWillConvertToComma();
    separated_ = [theString componentsSeparatedByString:CMXTextParserComma];
    if ([separated_ count] < 2) {
        return;
    }

    for (NSString *string_ in separated_) {
        if ([string_ containsString:replace_]) {
            string_ = [string_ stringByReplaceCharacters:replace_ toString:CMXTextParserComma];
        }
        [fields addObject:string_];
    }
}


@implementation CMXTextParser
+ (NSArray *)separatedLine:(NSString *)theString
{
    NSArray *components_;
    components_ = [theString componentsSeparatedByString:CMXTextParser2chSeparater];

    if ([components_ count] == 1) {
        NSMutableArray  *commaComponents_ = [NSMutableArray arrayWithCapacity:2];
        separetedLineByConvertingComma(theString, commaComponents_);
        if ([commaComponents_ count] == 0) {
            return nil;
        }
        return commaComponents_;
    }

    return components_;
}

/*
レスの本文のうち変換できるものは変換してしまう。
不要なHTMLタグを取り除き、改行タグを変換
*/
+ (NSString *)cachedMessageWithMessageSource:(NSString *)aSource
{
    NSMutableString *tmp;
    NSString *result;
    
    tmp = [aSource mutableCopy];
    [self convertMessageSourceToCachedMessage:tmp];

    result = [[tmp copy] autorelease];
    [tmp release];

    return result;
}

static void htmlConvertBreakLineTag(NSMutableString *theString)
{
    if (!theString || [theString length] == 0) {
        return;
    }
    // 2003-09-18 Takanori Ishikawa <takanori@gd5.so-net.ne.jp>
    // --------------------------------
    // - [NSMutableString strip] だと
    // 現在の実装ではCFStringTrimWhitespace()
    // が使われるため、日本語環境だと全角空白も消去されてしまう。
    [theString stripAtStart];
    [theString stripAtEnd];
    
    // 行頭・行末の半角スペースを同時に削除
    static OnigRegexp *cachedRegexp = nil;
    if (!cachedRegexp) {
        cachedRegexp = [[OnigRegexp compileIgnorecase:@" *<br> *"] retain];
    }
    NSString *temp = [theString replaceAllByRegexp:cachedRegexp with:@"\n"];
    [theString setString:temp];
}

/*
2004-02-29 Takanori Ishikawa <takanori@gd5.so-net.ne.jp>
----------------------------------------
朝鮮半島情勢+ 板の名無しさん「<丶｀∀´>（´・ω・｀）（｀ハ´　 ）さん」
が CocoMonar で上手く表示されない。

どうも '<', '>' が実体参照で置き換えられずにそのまま dat に記録されているのが
問題らしい。名無しさんの場合にこのチェックが抜けている。

これに備えて、タグ名は ASCII に限定しておく。

*/
#define ELEM_NAME_BUFSIZE 31
static void htmlConvertDeleteAllTagElements(NSMutableString *theString)
{
    NSUInteger strLen_;
    NSRange result_;
    NSRange searchRange_;

    strLen_ = [theString length];
    if (strLen_ < 2) {
        return;
    }

    searchRange_ = NSMakeRange(0, strLen_);

    while ((result_ = [theString rangeOfString:@"<"
                                       options:NSLiteralSearch
                                         range:searchRange_]).length != 0) {
        NSRange gtRange_;           // ">"
        BOOL    shouldDelete = YES; // 2005-11-16 tsawada2 : shouldDelete はループの先頭に戻るたびに再初期化しないとダメ

        // "<"の次から検索
        searchRange_.location = NSMaxRange(result_);
        searchRange_.length = (strLen_ - searchRange_.location);
        gtRange_ = [theString rangeOfString:@">" options:NSLiteralSearch range:searchRange_];
        if (gtRange_.length == 0) {
            continue;
        }

        result_.length = NSMaxRange(gtRange_) - result_.location;
        searchRange_.location = NSMaxRange(gtRange_);
        searchRange_.length = (strLen_ - searchRange_.location);

        // 削除しない要素
        {
            NSInteger i;
            NSInteger max;
            unichar c = '\0';
            char tagName[ELEM_NAME_BUFSIZE +1];
            NSInteger bufidx = 0;

            i = result_.location +1;
            max = NSMaxRange(result_);
            NSCAssert(result_.length >= 2, @"result_.length >= 2");
            // skip first blank spaces and '/'
            for (; i < max; i++) {
                c = [theString characterAtIndex:i];
                if (!isspace(c & 0x7f) && c != '/') {
                    break;
                }
            }
            if (i >= max) {
                shouldDelete = YES;
                goto FORCE_DELETE;
            }

            // now c points first character of element's tagName
            for (; i < max; i++) {
                c = [theString characterAtIndex:i];

                if (isspace(c & 0x7f) || '/' == c || '>' == c) { 
                    break;
                }
                // tag name must be ASCII characters
                // or must be less than ELEM_NAME_BUFSIZE
                if (c > 0x7f || bufidx >= ELEM_NAME_BUFSIZE) {
                    shouldDelete = NO;
                    break;
                }
                tagName[bufidx++] = (c & 0x7f);

            }
            tagName[bufidx++] = '\0';
            // now tagName buffer contains elements tagName

            // <ul>
            if (0 == nsr_strcasecmp(tagName, "ul")) {
                shouldDelete = NO;
            }
        }

FORCE_DELETE:
        if (!shouldDelete) {
            continue;
        }

        // 削除
        {
            [theString deleteCharactersInRange:result_];
            searchRange_.location -= result_.length;
            strLen_ = [theString length];
        }
    }
}

+ (void)convertMessageSourceToCachedMessage:(NSMutableString *)aSource
{
  @synchronized([CMXTextParser class]) {
    htmlConvertBreakLineTag(aSource);
    [aSource replaceCharacters:[NSString backslash] toString:[NSString yenmark]];
    htmlConvertDeleteAllTagElements(aSource);
    [self replaceEntityReferenceWithString:aSource];
  }
}

+ (NSArray *)messageArrayWithDATContents:(NSString *)DatContents
                               baseIndex:(NSUInteger)baseIndex
                                   title:(NSString **)titlePtr
{
    NSMutableArray  *messageArray_;
    id              contents_;
    NSArray         *lineArray_;
    NSUInteger      index_ = baseIndex;
    
    // Extra Data
    NSString *title_ = nil;
    
    if (!DatContents || [DatContents isEmpty]) {
        return nil;
    }
    if (titlePtr != NULL) *titlePtr = nil;
    
    // 前後の空白を取り除き、行で分割
    messageArray_ = [NSMutableArray array];
    contents_ = SGTemporaryString();
    [contents_ appendString:DatContents];   
    [contents_ strip];
    lineArray_ = [contents_ componentsSeparatedByNewline];
    contents_ = nil;
    
    for (NSString *line_ in lineArray_) {
        CMRThreadMessage *message_;
        NSArray *components_;
        
        components_ = [self separatedLine:line_];
        message_ = [self messageWithDATLineComponentsSeparatedByNewline:components_];
        
        if (!message_) {
            // 解析に失敗
            if (line_ && ![line_ isEmpty]) {
                UTILDebugWrite1(@"ERROR:parseDATFieldWithLine(Index = %lu)", (unsigned long)index_);
            }
            continue;
        }
        [message_ setIndex:index_];
        [messageArray_ addObject:message_];
        index_++;

        // タイトルを探査
        if ([components_ count] > k2chDATTitleIndex && !title_ && titlePtr != NULL) {
            title_ = [components_ objectAtIndex:k2chDATTitleIndex];
            title_ = [title_ stringByReplaceEntityReference];
            *titlePtr = title_;
        }
    }

    return messageArray_;
}

+ (CMRThreadMessage *)messageWithDATLine:(NSString *)theString
{
    NSArray *components_;

    components_ = [self separatedLine:theString];
    return [self messageWithDATLineComponentsSeparatedByNewline:components_];
}

+ (CMRThreadMessage *)messageWithInvalidDATLineDetected:(NSString *)line
{
    NSArray             *components_;
    NSString            *contents_;
    CMRThreadMessage    *message_;

    components_ = [self separatedLine:line];
    contents_ = [components_ componentsJoinedByString:@"\n"];
    contents_ = [contents_ stringByStriped];
    if (!contents_ || [contents_ isEmpty]) {
        return nil;
    }
    message_ = [[[CMRThreadMessage alloc] init] autorelease];
    [message_ setName:@""];
    [message_ setMail:@""];
    [message_ setIDString:@""];
    [message_ setMessageSource:contents_];
    [message_ setInvalid:YES];

    return message_;
}

#pragma mark Entity Reference
// "&amp" --> "&amp;"
#define kInvalidAmpEntity   @"&amp"
#define kAmpEntity          @"&amp;"
#define kAmpEntityLength    4
static void resolveInvalidAmpEntity(NSMutableString *aSource)
{
    NSMutableString *src_ = aSource;
    NSUInteger      srcLength_;
    NSRange         result;
    NSRange         searchRng;

    srcLength_ = [src_ length];
    searchRng = [src_ range];
    while ((result = [src_ rangeOfString:kInvalidAmpEntity
                                 options:NSLiteralSearch
                                   range:searchRng]).length != 0) {
        NSUInteger nextIndex_;
        char c;

        nextIndex_ = NSMaxRange(result);
        if (nextIndex_ >= srcLength_) {
            break;
        }
        c = ([src_ characterAtIndex:nextIndex_] & 0x7f);
        if (c != ';') {
            [src_ replaceCharactersInRange:result withString:kAmpEntity];
            result.length = kAmpEntityLength;
        }
        srcLength_ = [src_ length];
        searchRng.location = NSMaxRange(result);
        searchRng.length = (srcLength_ - searchRng.location);
    }
}

+ (void)replaceEntityReferenceWithString:(NSMutableString *)aString
{
    resolveInvalidAmpEntity(aString);
    [aString replaceEntityReference];
}

+ (NSString *)stringByReplacingEntityReference:(NSString *)baseString
{
    NSMutableString *ms = SGTemporaryString();
    [ms setString:baseString];
    [self replaceEntityReferenceWithString:ms];
    return [NSString stringWithString:ms];
}

#pragma mark CES (Code Encoding Scheme)
+ (NSString *)stringWithData:(NSData *)aData CFEncoding:(CFStringEncoding)enc
{
    CFStringEncoding ShiftJISFamily[] = {
        kCFStringEncodingDOSJapanese,   /* CP932 (Windows) */
        kCFStringEncodingMacJapanese,   /* X-MAC-JAPANESE (Mac) */
        kCFStringEncodingShiftJIS,      /* SHIFT_JIS (JIS) */
    };
    
    NSInteger i;
    NSInteger cnt;
    NSString *result = nil;

    UTIL_DEBUG_METHOD;

    cnt = UTILNumberOfCArray(ShiftJISFamily);
    // ShiftJIS か？
    for (i = 0; i < cnt; i++) {
        if (ShiftJISFamily[i] == enc) {
            ShiftJISFamily[i] = ShiftJISFamily[0];
            ShiftJISFamily[0] = enc;

            goto SHIFT_JIS;
        }
    }
    goto OTHER_ENCODINGS;
    
SHIFT_JIS:
    UTIL_DEBUG_WRITE2(@"Encoding(0x%X):%@ is ShiftJIS", enc, (NSString *)CFStringConvertEncodingToIANACharSetName(enc));
    
    for (i = 0; i < cnt; i++) {
        CFStringEncoding SJISEnc = ShiftJISFamily[i];
        
        UTIL_DEBUG_WRITE2(@"  Using CES (0x%X):%@", SJISEnc, (NSString *)CFStringConvertEncodingToIANACharSetName(SJISEnc));
        
        result = (NSString *)CFStringCreateWithBytes(NULL, (const UInt8 *)[aData bytes], (CFIndex)[aData length], SJISEnc, false);
        if (result) {
            UTIL_DEBUG_WRITE1(@"Success -- text length:%lu", (unsigned long)[result length]);
            break;
        }
    }
    goto RET_RESULT;
    
OTHER_ENCODINGS:
    UTIL_DEBUG_WRITE2(@"  Using CES (0x%X):%@", enc, (NSString*)CFStringConvertEncodingToIANACharSetName(enc));
    result = (NSString*) CFStringCreateWithBytes(NULL, (const UInt8 *)[aData bytes], (CFIndex)[aData length], enc, false);

RET_RESULT:
    if (!result) {
        UTIL_DEBUG_WRITE2(@"We can't convert bytes into unicode characters, \n"
        @"but we can use TEC instead of CFStringCreateWithBytes()\n"
        @"  Using CES (0x%X):%@",
        enc, (NSString*)CFStringConvertEncodingToIANACharSetName(enc));

        result = [[NSString alloc] initWithDataUsingTEC:aData encoding:CF2TextEncoding(enc)];
    }
    return [result autorelease];
}

#pragma mark Low Level APIs
static BOOL divideField(NSString *field, NSString **datePart, NSString **milliSecPart, NSString **extraPart, CMRThreadMessage *aMessage)
{
    static OnigRegexp *regExpForPrefix2;
    static OnigRegexp *regExp2;

    if (!regExpForPrefix2) {
        regExpForPrefix2 = [[OnigRegexp compile:@"^(.*),\\d{2,4}"] retain];
    }
    if (!regExp2) {
        regExp2 = [[OnigRegexp compile:@"^(.*\\d{2}:\\d{2})(\\.\\d{2})? ?( <a href=\"http://2ch.se/\">.*</a>)? ?(.*)"] retain];
    }

    // 
    // まずは暦区切りの","を探し、
    // 「エロゲ暦24年,2005/04/02...」 -> 「2005/04/02...」のように変な表記をカット
    //
    OnigResult *prefixMatch2 = [regExpForPrefix2 search:field];
    NSString *tmpPrefix = nil;

    if (prefixMatch2) {
        tmpPrefix = [prefixMatch2 stringAt:1];
        NSRange cutRange2 = [prefixMatch2 rangeAt:1];
        field = [field substringFromIndex:NSMaxRange(cutRange2)+1];
    }

    //
    // 日時とそれ以外を分割
    // あぼーんなどの場合に注意しなければならない
    //
    OnigResult *match2 = [regExp2 search:field];

    if (match2) {
        NSString *tmpDate, *tmpMilliSec, *tmpStock, *tmpExtra, *dateRep;
        tmpDate = [match2 stringAt:1];
        tmpMilliSec = [match2 stringAt:2];
        tmpStock = [match2 stringAt:3];
        tmpExtra = [match2 stringAt:4];

        if (datePart != NULL) {
            *datePart = tmpDate;
        }
        if (extraPart != NULL) {
            *extraPart = tmpExtra;
        }

        if (tmpStock) {
            if (tmpMilliSec) {
                dateRep = [NSString stringWithFormat:@"%@%@ %@", tmpDate, tmpMilliSec, tmpStock];
                if (milliSecPart != NULL) {
                    *milliSecPart = tmpMilliSec;
                }
            } else {
                dateRep = [NSString stringWithFormat:@"%@ %@", tmpDate, tmpStock];
            }
        } else {
            if (tmpMilliSec) {
                dateRep = [NSString stringWithFormat:@"%@%@", tmpDate, tmpMilliSec];
                if (milliSecPart != NULL) {
                    *milliSecPart = tmpMilliSec;
                }
            } else {
                dateRep = tmpDate;
            }
        }
        [aMessage setDateRepresentation:(tmpPrefix == nil) ? dateRep : [NSString stringWithFormat:@"%@,%@", tmpPrefix, dateRep]];
    } else { // あぼーんなどの場合こちらに回る
        NSArray *array = [field componentsSeparatedByString:@" "];

        if ([array count] > 1 && extraPart != NULL) {
            *extraPart = [array objectAtIndex:1];
        }
    }

    return YES;
}

static NSDate *dateWith2chDateString(NSString *theString)
{
    static CFDateFormatterRef kDateFormatterStd = NULL;
    static CFDateFormatterRef kDateFormatterAlt = NULL;
    static OnigRegexp *regExp2 = nil;

    NSDate *date_;
    NSMutableString *dateString_;

    if (!theString || [theString length] < 1) {
        return nil;
    }

    if (kDateFormatterStd == NULL) {
        CFLocaleRef locale = CFLocaleGetSystem();
        CFRetain(locale);
        kDateFormatterStd = CFDateFormatterCreate(NULL, locale, kCFDateFormatterNoStyle, kCFDateFormatterNoStyle);
        kDateFormatterAlt = CFDateFormatterCreate(NULL, locale, kCFDateFormatterNoStyle, kCFDateFormatterNoStyle);
        CFRelease(locale);

        // 片方のフォーマッタはフォーマットを「最もありそうなもの」に固定。
        CFDateFormatterSetFormat(kDateFormatterStd, CFSTR("yyyy/MM/dd HH:mm:ss"));
        // もう片方のフォーマッタは「残りの可能性」に合わせて随時フォーマットを再指定する
    }

    // 曜日欄をカッコを含めて除去する。
    dateString_ = SGTemporaryString();
    [dateString_ setString:theString];

    if (!regExp2) {
        regExp2 = [[OnigRegexp compile:@"\\(.*\\)"] retain];
    }

    OnigResult *match2 = [regExp2 search:dateString_];
    if (match2) {
        [dateString_ deleteCharactersInRange:[match2 bodyRange]];
    }
    // 総当たり戦開始 
    date_ = (NSDate *)CFDateFormatterCreateDateFromString(NULL, kDateFormatterStd, (CFStringRef)dateString_, NULL);
    if (date_) {
        return [date_ autorelease];
    }

    // ダメだった場合
    CFDateFormatterSetFormat(kDateFormatterAlt, CFSTR("yy/MM/dd HH:mm:ss"));
    date_ = (NSDate *)CFDateFormatterCreateDateFromString(NULL, kDateFormatterAlt, (CFStringRef)dateString_, NULL);
    if (date_) {
        return [date_ autorelease];
    }

    // やっぱりダメだった場合
    CFDateFormatterSetFormat(kDateFormatterAlt, CFSTR("yy/MM/dd HH:mm"));
    date_ = (NSDate *)CFDateFormatterCreateDateFromString(NULL, kDateFormatterAlt, (CFStringRef)dateString_, NULL);
    if (date_) {
        return [date_ autorelease];
    }

    // 諦め
    return nil;
}

+ (CMRThreadMessage *)messageWithDATLineComponentsSeparatedByNewline:(NSArray *)aComponents
{
    CMRThreadMessage *message_ = nil;
    NSString *dateExtra_;
    
    if (!aComponents) {
        return nil;
    }
    if ([aComponents count] <= k2chDATMessageIndex) {
        UTILDebugWrite2(@"Array count must be at least %i or more, but was %lu",
                k2chDATMessageIndex, (unsigned long)[aComponents count]);
        return nil;
    }

    message_ = [[CMRThreadMessage alloc] init];
    dateExtra_ = [aComponents objectAtIndex:k2chDATDateExtraFieldIndex];

    if (!_parseDateExtraField(dateExtra_, message_)) {
        [message_ release];
        return nil;
    }
    [message_ setName:[aComponents objectAtIndex:k2chDATNameIndex]];

    // ときどきメール欄が"0"のときがある
    // read.cgiはこれを表示しないので無視するかどうか。。。
    [message_ setMail:[aComponents objectAtIndex:k2chDATMailIndex]];
    [message_ setMessageSource:[aComponents objectAtIndex:k2chDATMessageIndex]];

    return [message_ autorelease];
}

static BOOL _parseExtraField(NSString *extraField, CMRThreadMessage *aMessage)
{
    /*
     2007-03-07 tsawada2<ben-sawa@td5.so-net.ne.jp>
     目標の確認：この関数内では Host, ID, BE を extraField から探して、aMessage の該当属性をセットする。
     - Host の例外：「発信元」@シベリア／発信元記号のみ
    */
    NSUInteger  length_;

    if (!extraField) {
        return YES;
    }
    length_ = [extraField length];
    if (length_ < 1) {
        return YES;
    }

    static NSSet *clientCodeSet;
    static OnigRegexp *regExpForHOST = nil;
    static OnigRegexp *regExpForBE = nil;
    static OnigRegexp *regExpForID = nil;

    OnigResult *matchOfHOST;
    OnigResult *matchOfBE;
    OnigResult *matchOfID;

    /*
     2005-02-03 tsawada2<ben-sawa@td5.so-net.ne.jp>
     extraField が 0 または O 一文字の場合は、携帯・PCの区別記号と見なして直接処理
     ログファイルのフォーマットの互換性などを考慮して、Host の値として処理することにする。
     2005-06-18 追加：公式p2 からの投稿区別記号「P」が加わった。
     2005-07-31 追加：「o」もあるのか。知らなかった。
     2006-03-22 追加：「Q」も加わったらしい。
     2008-07-15 追加：「i」で iPhone 3G からの投稿らしい。
     2008-07-17 追加：「I」で iPhone Wi-Fi からの投稿？
     2ch特化型サーバ・ロケーション構築作戦 Part29
     http://qb5.2ch.net/test/read.cgi/operate/1212665493/ とか。
    */
    if (length_ == 1) {
        if (!clientCodeSet) {
            clientCodeSet = [[NSSet alloc] initWithObjects:@"0", @"O", @"P", @"o", @"Q", @"i", @"I", nil];
        }
        if ([clientCodeSet containsObject:extraField]) {
            [aMessage setHost:extraField];
            return YES;
        }
    }

    if (!regExpForHOST) {
        NSString *string = [NSString stringWithFormat:@"(HOST:|%@:)\\s?(.*)", NSLocalizedString(@"siberia IP field", @"")];
        regExpForHOST = [[OnigRegexp compile:string] retain];
    }
    
    if (!regExpForBE) {
        regExpForBE = [[OnigRegexp compile:@"BE:\\s?(.*)\\s?"] retain];
    }

    if (!regExpForID) {
        regExpForID = [[OnigRegexp compile:@"ID:\\s?(\\S*)\\s?"] retain];
    }

    // HOST
    matchOfHOST = [regExpForHOST search:extraField];
    if (matchOfHOST) {
        NSRange matchedRange = [matchOfHOST bodyRange];
        NSString *hostString = [matchOfHOST stringAt:2];
        [aMessage setHost:hostString];
        if (matchedRange.location == 0) {
            return YES;
        }
        extraField = [extraField substringToIndex:matchedRange.location-1]; // HOST から先を刈り取ってしまう
    }

    // Be
    matchOfBE = [regExpForBE search:extraField];
    if (matchOfBE) {
        NSRange matchedBERange = [matchOfBE bodyRange];
        NSString *beStr_ = [matchOfBE stringAt:1];
        [aMessage setBeProfile:[beStr_ componentsSeparatedByString:@"-"]];
        if (matchedBERange.location == 0) { // extraField の先頭でマッチ＝ID が無い（IDが有れば BE より前に書かれている）
            return YES;
        }
    }

    // ID
    matchOfID = [regExpForID search:extraField];
    if (matchOfID) {
        NSString *idString = [matchOfID stringAt:1];
        [aMessage setIDString:idString];
    }

    return YES;
}

static BOOL _parseDateExtraField(NSString *dateExtra, CMRThreadMessage *aMessage)
{
    NSString *datePart_ = nil;
    NSString *extraPart_ = nil;

    if (!dateExtra || [dateExtra length] == 0) {
        return YES;
    }
    divideField(dateExtra, &datePart_, NULL, &extraPart_, aMessage);

    if (datePart_) {
        NSDate *date_ = dateWith2chDateString(datePart_);

        if (!date_) {
            NSLog(@"Can't convert '%@' to NSDate.", datePart_);
            return NO;
        }
        [aMessage setDate:date_];
    }

    return _parseExtraField(extraPart_, aMessage);
}
@end
