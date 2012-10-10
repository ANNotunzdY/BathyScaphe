//
//  CookieManager.m
//  BathyScaphe
//
//  Created by Takanori Ishikawa on 02/03/25.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CookieManager.h"
#import "Cookie.h"
#import "AppDefaults.h"
#import <AppKit/NSApplication.h>
#import "w2chConnect.h"


@implementation CookieManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

+ (NSString *)defaultFilepath
{
    return [[CMRFileManager defaultManager] supportFilepathWithName:CMRCookiesFile resolvingFileRef:NULL];
}

- (id)init
{
    NSString        *filepath_;
    NSDictionary    *dict_;

    filepath_ = [[self class] defaultFilepath];
    UTILAssertNotNil(filepath_);
        
    dict_ = [NSDictionary dictionaryWithContentsOfFile:filepath_];
    return [self initWithPropertyListRepresentation:dict_];
}

+ (id)objectWithPropertyListRepresentation:(id)rep
{
    return [[[self alloc] initWithPropertyListRepresentation:rep] autorelease];
}

- (id)propertyListRepresentation
{
    return [self dictionaryRepresentation];
}

- (id)initWithPropertyListRepresentation:(id)rep
{
    if (self = [super init]) {
        if (![self initializeFromPropertyListRepresentation:rep]) {
            [self autorelease];
            return nil;
        }

        [[NSNotificationCenter defaultCenter]
                 addObserver:self
                    selector:@selector(applicationWillTerminate:)
                        name:NSApplicationWillTerminateNotification
                      object:NSApp];
    }
    return self;
}

- (BOOL)initializeFromPropertyListRepresentation:(id)rep
{
    NSDictionary        *tmp_;

    if (!rep) {
        return YES;
    }
    if (![rep isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    tmp_ = [self dictionaryByDeletingExpiredCookies:rep];
    [self setCookies:tmp_];
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [m_beCookies release];
    [_cookies release];
    [super dealloc];
}

- (NSDictionary *)cookies
{
    if (!_cookies) {
        _cookies = [[NSDictionary empty] copy];
    }
    return _cookies;
}

- (void)setCookies:(NSDictionary *)aCookies
{
    [aCookies retain];
    [_cookies release];
    _cookies = aCookies;
}

- (NSArray *)beCookies
{
    return m_beCookies;
}

- (void)setBeCookies:(NSArray *)obj
{
    [obj retain];
    [m_beCookies release];
    m_beCookies = obj;
}

- (void)setCookiesArray:(NSArray *)aCookiesArray forHost:(NSString *)aHost
{
    NSMutableDictionary     *tmp;
    NSDictionary            *newDict_;

    if (!aCookiesArray || !aHost) { 
        return;
    }
    tmp = [[self cookies] mutableCopy];
    [tmp setObject:aCookiesArray forKey:aHost];

    newDict_ = [tmp copy];
    [self setCookies:newDict_];

    [newDict_ release];
    [tmp release];
}

- (void)removeAllCookies
{
    [self setCookies:nil];
    [self setBeCookies:nil];
}

//////////////////////////////////////////////////////////////////////
//////////////////// [ インスタンスメソッド ] ////////////////////////
//////////////////////////////////////////////////////////////////////
/**
  * 単一、または複数のクッキー設定をまとめた@"Set-Cookie"ヘッダを
  * 解析し、適切な数のCookieを生成し、配列に格納して返す。
  * 
  * @param    header  ヘッダ
  * @return           Cookieの配列(失敗時にはnil)
  */
- (NSArray *)scanSetCookieHeader:(NSString *)header
{
    static NSString *const st_sep_ = @",";
    static NSString *const st_expsep_ = @"day,";
    static NSString *const st_expsep2_ = @"day.";
    // 付け焼き刃…
    static NSString *const st_expsep3_ = @"Sun,";
    static NSString *const st_expsep4_ = @"Sunday.";
    static NSString *const st_expsep5_ = @"Mon,";
    static NSString *const st_expsep6_ = @"Monday.";
    static NSString *const st_expsep7_ = @"Tue,";
    static NSString *const st_expsep8_ = @"Tuesday.";
    static NSString *const st_expsep9_ = @"Wed,";
    static NSString *const st_expsepA_ = @"Wednesday.";
    static NSString *const st_expsepB_ = @"Thu,";
    static NSString *const st_expsepC_ = @"Thursday.";
    static NSString *const st_expsepD_ = @"Fri,";
    static NSString *const st_expsepE_ = @"Friday.";
    static NSString *const st_expsepF_ = @"Sat,";
    static NSString *const st_expsepG_ = @"Saturday.";

    NSMutableArray  *marray_;
    NSMutableString *mstr_;
    
    if (!header || [header length] == 0) {
        return nil;
    }
    marray_ = [NSMutableArray array];
    // カンマで区切られているが、有効期限のフォーマットにもカンマ
    // が含まれているため、単純に切り分けることはできない。
    // ex. expires=Wednesday, 24-Apr-2002 00:00:00 GMT 
    mstr_ = [NSMutableString stringWithString:header];
    //expiresの曜日の後のカンマをひとまず、他の文字に(*)
    [mstr_ replaceCharacters:st_expsep3_ toString:st_expsep4_];
    [mstr_ replaceCharacters:st_expsep5_ toString:st_expsep6_];
    [mstr_ replaceCharacters:st_expsep7_ toString:st_expsep8_];
    [mstr_ replaceCharacters:st_expsep9_ toString:st_expsepA_];
    [mstr_ replaceCharacters:st_expsepB_ toString:st_expsepC_];
    [mstr_ replaceCharacters:st_expsepD_ toString:st_expsepE_];
    [mstr_ replaceCharacters:st_expsepF_ toString:st_expsepG_];

    [mstr_ replaceCharacters:st_expsep_ toString:st_expsep2_];
    //解析部
    {
        NSArray      *comps_;       //区切り文字で切り分け
        NSEnumerator *iter_;        //順次探索
        NSString     *item_;        //各単位
        
        comps_ = [mstr_ componentsSeparatedByString:st_sep_];
        iter_ = [comps_ objectEnumerator];
        while (item_ = [iter_ nextObject]) {
            Cookie *cookie_;
            
            item_ = [item_ stringByStriped];
            //(*)の置換を戻しておく。
            item_ = [item_ stringByReplaceCharacters:st_expsep2_ toString:st_expsep_];
            cookie_ = [Cookie cookieWithString:item_];
            if (!cookie_) {
                continue;
            }
            [marray_ addObject:cookie_];
        }
    }
    if ([marray_ count] == 0) {
        return nil;
    }
    return marray_;
}

/**
  * @"Set-Cookie"で要求されたクッキーを保持。
  * 
  * @param    header    @"Set-Cookie"ヘッダ
  * @param    hostName  要求元のホスト名
  */
- (void)addCookies:(NSString *)header fromServer:(NSString *)hostName
{
    NSMutableArray *oldCookies_;        //前回までのクッキー
    NSArray        *newCookies_;        //新しく追加するクッキー
    
    if (!header || !hostName) {
        return;
    }
    oldCookies_ = [[self cookies] objectForKey:hostName];
    // 新規作成
    if (!oldCookies_) {
        oldCookies_ = [NSMutableArray array];
    }
    UTILAssertKindOfClass(oldCookies_, NSMutableArray);

    newCookies_ = [self scanSetCookieHeader:header];
    if (newCookies_) {
        NSEnumerator *iter_;        //順次探索
        Cookie       *cookie_;      //各クッキー

        iter_ = [newCookies_ reverseObjectEnumerator];
        while (cookie_ = [iter_ nextObject]) {
            // domainが省略されたクッキーは、そのクッキーを生成したサーバのドメイン名が指定されたとみなされます。
            NSString *cookieDomain = [cookie_ domain];
            if (cookieDomain && ![cookieDomain isEqualToString:hostName]) {
                NSMutableArray *cookieForSomeDomain = [[self cookies] objectForKey:cookieDomain];
                if (!cookieForSomeDomain) {
                    cookieForSomeDomain = [NSMutableArray array];
                } else {
                    if ([cookieForSomeDomain containsObject:cookie_]) {
                        // 重複するクッキーは取り除く。
                        [cookieForSomeDomain removeObject:cookie_];
                    }
                }                
                [cookieForSomeDomain addObject:cookie_];
                [self setCookiesArray:cookieForSomeDomain forHost:cookieDomain];
            } else {
                //重複するクッキーは取り除く。
                [oldCookies_ removeObject:cookie_];
                [oldCookies_ addObject:cookie_];
            }
        }
    }
    [self setCookiesArray:oldCookies_ forHost:hostName];
}

- (void)addBeCookiesFromHeader:(NSString *)header
{
    NSArray *newCookies_;
    
    if (!header) {
        return;
    }
    
    newCookies_ = [self scanSetCookieHeader:header];
    [self setBeCookies:newCookies_];
}

/**
  * 送信先に送るべきクッキーがある場合はクッキー文字列を返す。
  * 
  * @param    anURL  送信先URL
  * @param    withBe  Be ログイン用のクッキーが必要かどうか
  * @return          クッキー（クッキーが無い場合は空の文字列）
  */
- (NSString *)cookiesForRequestURL:(NSURL *)anURL withBeCookie:(BOOL)withBe
{
    NSString *host;
    NSMutableArray *availableCookies; //送るべきクッキー
    NSDictionary *allCookies;
    NSArray *domains;
    
    if (!anURL) {
        return nil;
    }

    host = [anURL host];
    if (!host) {
        return nil;
    }

    allCookies = [self cookies];
    domains = [allCookies allKeys];
    if (!domains) {
        return nil;
    }

    availableCookies = [NSMutableArray array];

    for (NSString *domain in domains) {
        if ([host hasSuffix:domain]) { // 後方一致
            NSArray *cookies = [allCookies objectForKey:domain];
            if (cookies && ([cookies count] > 0)) {
                for (Cookie *cookie in cookies) {
                    if (![cookie isAvalilableURL:anURL]) {
                        continue;
                    }
                    if (![cookie isEnabled]) {
                        continue;
                    }
                    if ([cookie isExpired:NULL]) {
                        continue;
                    }
                    [availableCookies addObject:cookie];
                }
            }
        }
    }

    //名前が同じで、パスの違うクッキーがある場合は
    //より深くマッチするものを送る。
    //いまのところ未実装

    // be ログイン
    if (withBe) {
        [self fillBeCookies:availableCookies];
    }

    return [availableCookies componentsJoinedByString:@"; "];
}

- (BOOL)fillBeCookies:(NSMutableArray *)buffer
{
    if ([self beCookies]) {
        [buffer addObjectsFromArray:[self beCookies]];
    } else {
        // 新規クッキー取得
        id<be2chAuthenticationStatus> authenticator_;
        authenticator_ = [CMRPref sharedBe2chAuthenticator];

        if ([authenticator_ invalidate]) {
            [self addBeCookiesFromHeader:[authenticator_ cookieHeader]];
            [buffer addObjectsFromArray:[self beCookies]];
        } else {
            NSError *error = [authenticator_ lastError];
            NSString *message;
            NSString *informative;
            switch ([error code]) {
                case BS2chConnectLoginUserCanceledError:
                {
                    message = NSLocalizedStringFromTable(@"beCookie canceled message text", @"CookieManager", nil);
                    informative = NSLocalizedStringFromTable(@"beCookie canceled info text", @"CookieManager", nil);
                }
                    break;
                case BSBe2chLoginServerFailedError:
                {
                    message = [NSString stringWithFormat:NSLocalizedStringFromTable(@"beCookie error message text format", @"CookieManager", nil),
                               [error localizedDescription]];
                    informative = [NSString stringWithFormat:NSLocalizedStringFromTable(@"beCookie error info text format", @"CookieManager", nil),
                                   (unsigned long)[error code]];
                }
                    break;
                default:
                {
                    message = NSLocalizedStringFromTable(@"beCookie canceled message text", @"CookieManager", nil);
                    informative = [NSString stringWithFormat:NSLocalizedStringFromTable(@"beCookie error info text format", @"CookieManager", nil),
                                   (unsigned long)[error code]];
                }
                    break;
            }
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:message];
            [alert setInformativeText:informative];
            [alert runModal];
            return NO;
        }
    }
    return YES;
}

/**
  * 期限切れのクッキーを削除する。
  */
- (void)deleteExpiredCookies
{
    [self setCookies:[self dictionaryByDeletingExpiredCookies:[self cookies]]];
}

/**
  * 期限切れのクッキーを削除し、可変辞書で返す。
  * 
  * @param    dict  辞書
  * @return         期限切れのクッキーを削除した辞書
  */
- (NSMutableDictionary *)dictionaryByDeletingExpiredCookies:(NSDictionary *)dict
{
    NSMutableDictionary *tmp_;      //作業用
    NSEnumerator        *kiter_;    //すべてのキー
    NSString            *host_;     //各キー

    tmp_ = [NSMutableDictionary dictionary];
    if (!dict || [dict count] == 0) {
        return tmp_;
    }
    kiter_ = [dict keyEnumerator];
    while (host_ = [kiter_ nextObject]) {
        NSMutableArray      *tmparray_; //作業用
        NSArray             *cookies_;      //すべてのクッキー
        NSEnumerator        *citer_;        //順次探索
        id                   cookie_;       //各クッキー

        cookies_ = [dict objectForKey:host_];
        if (!cookies_ || [cookies_ count] == 0) {
            continue;
        }
        tmparray_ = [NSMutableArray array];
        citer_ = [cookies_ reverseObjectEnumerator];
        while (cookie_ = [citer_ nextObject]) {
            // 辞書の場合はCookieに変換
            if ([cookie_ isKindOfClass:[NSDictionary class]]) {
                cookie_ = [Cookie cookieWithDictionary:cookie_];
            }
            if ([cookie_ isExpired:NULL]) {
                continue;
            }
            // 期限切れでない場合は移す
            [tmparray_ addObject:cookie_];
        }
        [tmp_ setObject:tmparray_ forKey:host_];
    }
    return [[tmp_ copy] autorelease];
}

/**
  * ファイルとして保存。
  * 
  * @param    path  保存場所のパス
  * @param    flag  NOなら直接、書き込む。
  * @return         成功時にYES
  */
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag
{
    NSData *binaryPlist;
    NSString *errorStr;
    binaryPlist = [NSPropertyListSerialization dataFromPropertyList:[self dictionaryRepresentation]
                                                             format:NSPropertyListBinaryFormat_v1_0
                                                   errorDescription:&errorStr];
    if (errorStr) {
        NSLog(@"CookieManager failed to convert cookies dictionary to binary data.");
        [errorStr autorelease];
        return NO;
    }
    return [binaryPlist writeToFile:path options:(flag ? NSAtomicWrite : 0) error:NULL];
}

/**
  * レシーバを保存可能な辞書で返す。
  * 
  * @return     辞書
  */
- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary     *tmp_;
    NSEnumerator            *kiter_;
    NSString                *host_;
    
    tmp_ = [NSMutableDictionary dictionary];
    kiter_ = [[self cookies] keyEnumerator];
    while (host_ = [kiter_ nextObject]) {
        NSMutableArray      *tmparray_;     //作業用
        NSArray             *cookies_;      //すべてのクッキー
        NSEnumerator        *citer_;        //順次探索
        Cookie              *cookie_;       //各クッキー

        cookies_ = [[self cookies] objectForKey:host_];
        if (!cookies_ || [cookies_ count] == 0) {
            continue;
        }
        tmparray_ = [NSMutableArray array];
        citer_ = [cookies_ reverseObjectEnumerator];
        while (cookie_ = [citer_ nextObject]) {
            BOOL whenTerminate_ = NO;
            // 期限切れか、終了時に破棄する場合は追加しない
            if ([cookie_ isExpired:&whenTerminate_] || whenTerminate_) {
                continue;
            }
            //期限切れでない場合は
            //辞書形式で追加
            [tmparray_ addObject:[cookie_ dictionaryRepresentation]];
        }
        [tmp_ setObject:tmparray_ forKey:host_];
    }
    return tmp_;
}

- (void)applicationWillTerminate:(NSNotification *)theNotification
{
    UTILAssertNotificationName(
        theNotification,
        NSApplicationWillTerminateNotification);

    [self writeToFile:[[self class] defaultFilepath] atomically:YES];
}
@end
