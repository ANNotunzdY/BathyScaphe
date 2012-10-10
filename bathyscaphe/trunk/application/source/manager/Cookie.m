//
//  Cookie.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/04/10.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "Cookie.h"


/* クッキーのオプション名 */
#define kCookieOptionPath           @"path"
#define kCookieOptionDomain         @"domain"
#define kCookieOptionExpires        @"expires"
#define kCookieOptionSecure         @"secure"
/* 内部用 */
#define kCookieOptionEnabled        @"x-application/CocoMonar enabled"
#define kCookieOptionBSEnabled      @"x-application/BathyScaphe enabled" // available in BathyScaphe 1.2.2/1.5 and later.


@implementation Cookie
+ (NSDateFormatter *)cookieDateFormatter
{
    static NSDateFormatter *cachedFormatter = nil;
    if (!cachedFormatter) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        cachedFormatter = [[NSDateFormatter alloc] init];
        [cachedFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // to make the intent clear

        [cachedFormatter setDateStyle:NSDateFormatterNoStyle];
        [cachedFormatter setTimeStyle:NSDateFormatterNoStyle];
        [cachedFormatter setDateFormat:@"EEEE, dd-MMM-yyyy HH:mm:ss 'GMT'"];

        [cachedFormatter setLocale:locale];
        [cachedFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        [locale release];
    }
    return cachedFormatter;
}

#pragma mark init & dealloc
/**
  * 一時オブジェクトの生成。
  * 
  * @return                 一時オブジェクト
  */
+ (id)cookie
{
    return [[[[self class] alloc] init] autorelease];
}

/**
  * 一時オブジェクトの生成。
  * 文字列表現からインスタンスを生成、初期化。
  * 
  * @param      anyCookies  文字列表現
  * @return     一時オブジェクト
  */
+ (id)cookieWithString:(NSString *)anyCookies
{
    return [[[[self class] alloc] initWithString:anyCookies] autorelease];
}

/**
  * 一時オブジェクトの生成。
  * 辞書オブジェクトからインスタンスを生成、初期化。
  * 
  * @param      anyCookies  辞書オブジェクト
  * @return                 一時オブジェクト
  */
+ (id)cookieWithDictionary:(NSDictionary *)anyCookies
{
    return [[[[self class] alloc] initWithDictionary:anyCookies] autorelease];
}

- (id)init
{
    if (self = [super init]) {
        [self setIsEnabled:YES];
    }
    return self;
}

/**
  * 指定イニシャライザ。
  * 文字列表現からインスタンスを生成、初期化。
  * 
  * @param    anyCookies  文字列表現
  * @return               初期化済みのインスタンス
  */
- (id)initWithString:(NSString *)anyCookies
{
    if (self = [self init]) {
        [self setCookieWithString:anyCookies];
    }
    return self;
}

/**
  * 指定イニシャライザ。
  * 辞書オブジェクトからインスタンスを生成、初期化。
  * 
  * @param    anyCookies  辞書オブジェクト
  * @return               初期化済みのインスタンス
  */
- (id)initWithDictionary:(NSDictionary *)dict
{
    
    if (self = [self init]) {
        if (!dict) {
            return self;
        }
        [self setCookieWithDictionary:dict];
    }
    return self;
}

- (void)dealloc
{
    [m_name release];
    [m_value release];
    [m_path release];
    [m_domain release];
    [m_expires release];
    [super dealloc];
}

#pragma mark Accessors
- (NSString *)name
{
    return m_name;
}

- (void)setName:(NSString *)aName
{
    [aName retain];
    [m_name release];
    m_name = aName;
}

- (NSString *)value
{
    return m_value;
}

- (void)setValue:(NSString *)aValue
{
    [aValue retain];
    [m_value release];
    m_value = aValue;
}

- (NSString *)path
{
    return m_path;
}

- (void)setPath:(NSString *)aPath
{
    [aPath retain];
    [m_path release];
    m_path = aPath;
}

- (NSString *)domain
{
    return m_domain;
}

- (void)setDomain:(NSString *)aDomain
{
    [aDomain retain];
    [m_domain release];
    m_domain = aDomain;
}

- (NSString *)expires
{
    return m_expires;
}

- (void)setExpires:(NSString *)anExpires
{
    [anExpires retain];
    [m_expires release];
    m_expires = anExpires;
}

- (BOOL)secure
{
    return m_secure;
}

- (void)setSecure:(BOOL)aSecure
{
    m_secure = aSecure;
}

- (BOOL)isEnabled
{
    return m_isEnabled;
}

- (void)setIsEnabled:(BOOL)anIsEnabled
{
    m_isEnabled = anIsEnabled;
}

#pragma mark Instance Methods
/**
  * レシーバのクッキーが有効なURLならYESを返す。
  * 
  * @param    anURL  対象URL
  * @return          クッキーが有効なURLならYES
  */
- (BOOL)isAvalilableURL:(NSURL *)anURL
{
    if (!anURL) {
        return NO;
    }
    //pathが指定されていれば、マッチするか検査
    if (![self path]) {
        return YES;
    }
    return [[anURL path] hasPrefix:[self path]];
}

/**
  * 期限切れの場合はYESを返す。
  * 終了時に破棄される場合にはwhenTerminate = YES
  *
  * @param   whenTerminate   終了時に破棄される場合はYES
  * @return                  期限切れの場合はYES
  */
- (BOOL)isExpired:(BOOL *)whenTerminate
{
    NSDate *exp_;
    
    exp_ = [self expiresDate];
    if (!exp_) {
        //終了時に破棄
        if (whenTerminate != NULL) {
            *whenTerminate = YES;
        }
        return NO;
    }
    NSComparisonResult compare = [exp_ compare:[NSDate date]];
    return (compare == NSOrderedAscending);
}


/**
  * レシーバのを辞書形式で返す。
  * 
  * @return     辞書オブジェクト
  */
- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict_;
    
    dict_ = [NSMutableDictionary dictionary];
    //オプションを保存
    if ([self path]) {
        [dict_ setObject:[self path] forKey:kCookieOptionPath];
    }
    if ([self domain]) {
        [dict_ setObject:[self domain] forKey:kCookieOptionDomain];
    }
    if ([self expires]) {
        [dict_ setObject:[self expires] forKey:kCookieOptionExpires];
    }
    [dict_ setBool:[self secure] forKey:kCookieOptionSecure];
    [dict_ setBool:[self isEnabled] forKey:kCookieOptionBSEnabled];
    //クッキーを保存
    if ([self name] && [self value]) {
        [dict_ setObject:[self value] forKey:[self name]];
    }
    return dict_;
}

/**
  * 有効期限を返す。
  * 
  * @return     有効期限
  */
- (NSDate *)expiresDate
{
    if (![self expires]) {
        return nil;
    }
    return [[[self class] cookieDateFormatter] dateFromString:[self expires]];
}

/**
  * クッキーを設定。
  * 
  * @param    aValue  値
  * @param    aName   名前
  */
- (void)setCookie:(id)aValue forName:(NSString *)aName
{
    if (!aValue || !aName) {
        return;
    }
    //オプション指定の場合はインスタンス変数に保持
    if ([aName isEqualToString:kCookieOptionSecure]) {
        if (![aValue respondsToSelector:@selector(boolValue)]) {
            [self setSecure:NO];
        } else {
            [self setSecure:[aValue boolValue]];
        }
    } else if ([aName isEqualToString:kCookieOptionEnabled] || [aName isEqualToString:kCookieOptionBSEnabled]) {
        if (![aValue respondsToSelector:@selector(boolValue)]) {
            [self setIsEnabled:YES];
        } else {
            [self setIsEnabled:[aValue boolValue]];
        }
    } else if ([aName isEqualToString:kCookieOptionPath]) {
        [self setPath:aValue];
    } else if ([aName isEqualToString:kCookieOptionDomain]) {
        [self setDomain:aValue];
    } else if ([aName isEqualToString:kCookieOptionExpires]) {
        [self setExpires:aValue];
    } else {
        [self setName:aName];
        [self setValue:aValue];
    }
}

/**
  * 文字列から変換。
  * オプションを指定した場合は、それらも反映される。
  * 
  * ex:@"SPID=XWDtLhNY; expires=1016920836 GMT; path=/"
  * 
  * @param    anyCookies  文字列表現
  */
- (void)setCookieWithString:(NSString *)anyCookies
{
    NSArray      *comps_;       //組毎を配列オブジェクトに
    NSEnumerator *iter_;        //順次検査
    NSString     *item_;        //各組
    
    if (!anyCookies) {
        return;
    }
    comps_ = [anyCookies componentsSeparatedByString:@";"];
    if (!comps_ || [comps_ count] == 0) {
        return;
    }
    iter_ = [comps_ objectEnumerator];
    while (item_ = [iter_ nextObject]) {
        NSArray         *pair_; //名前、値
        NSMutableString *name_;
        NSMutableString *value_;

        pair_ = [item_ componentsSeparatedByString:@"="];
        if (!pair_) {
            continue;
        }
        //Secure
        if ([pair_ count] == 1) {
            NSMutableString *cstr_;

            cstr_ = [NSMutableString stringWithString:[pair_ objectAtIndex:0]];
            [cstr_ strip];

            if ([cstr_ isEqualToString:kCookieOptionSecure]) {
                [self setSecure:YES];
            }
            continue;
        }
        if ([pair_ count] != 2) {
            continue;
        }
        name_ = [NSMutableString stringWithString:[pair_ objectAtIndex:0]];
        value_ = [NSMutableString stringWithString:[pair_ objectAtIndex:1]];
        //先頭、末尾の空白を削除
        [name_ strip];
        [value_ strip];

        [self setCookie:value_ forName:name_];
    }
}

/**
  * 辞書オブジェクトから変換。
  * オプションを指定した場合は、それらも反映される。
  * 
  * 
  * @param    anyCookies  辞書オブジェクト
  */
- (void)setCookieWithDictionary:(NSDictionary *)anyCookies
{
    NSEnumerator    *iter_;     //キーを順次検査
    NSString        *key_;      //キー
    
    if (!anyCookies) {
        return;
    }
    iter_ = [anyCookies keyEnumerator];
    while (key_ = [iter_ nextObject]) {
        id value_;

        value_ = [anyCookies objectForKey:key_];
        if (!value_) {
            continue;
        }
        [self setCookie:value_ forName:key_];
    }
}

/**
  * クッキーを文字列で表現したものを返す。
  * 
  * @return     文字列表現
  */
- (NSString *)stringValue
{
    if (![self name] || ![self value]) {
        return @"";
    }
    return [NSString stringWithFormat:@"%@=%@", [self name], [self value]];
}

#pragma mark NSObject
- (NSString *)description
{
    return [self stringValue];
}

- (BOOL)isEqual:(id)obj
{
    if ([super isEqual:obj]) {
        return YES;
    }
    if (![obj isKindOfClass:[self class]]) {
        return NO;
    }
    if (![[obj name] isEqualToString:[self name]]) {
        return NO;
    }
    if (![[obj path] isEqualToString:[self path]]) {
        return NO;
    }
    return YES;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    Cookie *tmpcopy;
    
    tmpcopy = [[[self class] allocWithZone:zone] init];
    [tmpcopy setName:[self name]];
    [tmpcopy setValue:[self value]];
    [tmpcopy setPath:[self path]];
    [tmpcopy setDomain:[self domain]];
    [tmpcopy setExpires:[self expires]];
    [tmpcopy setSecure:[self secure]];
    [tmpcopy setIsEnabled:[self isEnabled]];

    return tmpcopy;
}
@end
