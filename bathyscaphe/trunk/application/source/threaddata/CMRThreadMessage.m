//: CMRThreadMessage.m
/**
  * $Id: CMRThreadMessage.m,v 1.8 2008-07-21 09:04:13 tsawada2 Exp $
  * 
  * Copyright (c)2001-2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  * encoding="UTF-8"
  */

#import "CMRThreadMessage.h"
#import "UTILKit.h"
#import "CMXTextParser.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"

/*!
 * @function    CMRThreadMessageNameCache
 * @abstract    名前欄のキャッシュ
 * @discussion  
 * 
 * 各レスの内容はファイルやストリームからの読み込みによって
 * 生成されるため、そのままではそれらが各メッセージで共有さ
 * れることはなく、各々に別メモリ上のインスタンスを保持した
 * 状態である。
 * しかし、名前欄はほとんどの場合で同一のレスが多いため、レ
 * ス間で共有することができる。
 * 
 * この関数は引数として渡された名前を必要ならばキャッシュし、
 * それ自身か、あるいは以前にキャッシュされ同等のインスタン
 * スを返す。
 * 
 * @param    theName 名前欄
 * @result           名前欄
 */
static NSString *CMRThreadMessageNameCache(NSString *theName);

// 同上：メール欄はsageであることが多いはず。。
static NSString *CMRThreadMessageMailCache(NSString *theMail);

static NSString *const kEmptyString = @"";

//////////////////////////////////////////////////////////////////////
////////////////////// [ 定数やマクロ置換 ] //////////////////////////
//////////////////////////////////////////////////////////////////////
// Notification
NSString *const CMRThreadMessageDidChangeAttributeNotification = @"CMRThreadMessageDidChangeAttributeNotification";

// age / sage
NSString *const CMRThreadMessage_AGE_String		= @"age";
NSString *const CMRThreadMessage_SAGE_String	= @"sage";

#pragma mark -

@implementation CMRThreadMessage
- (void)dealloc
{
	[_name release];
	[_mail release];
	[_date release];
	[_beProfile release];
	[_dateRepresentation release];
	[_IDString release];
	[_hostString release];
	[_messageSource release];
	[bs_cachedMessage release];
	[_messageAttributes release];

	[super dealloc];
}
#pragma mark CMRPropertyListCoding
- (BOOL)initializeWithPropertyListRepresentation:(id)rep
{
	if (![rep isKindOfClass:[NSDictionary class]]) {
		return NO;
	}

	[self setIndex:[rep unsignedIntegerForKey:ThreadPlistContentsIndexKey]];
	[self setName:[rep stringForKey:ThreadPlistContentsNameKey]];
	[self setMail:[rep stringForKey:ThreadPlistContentsMailKey]];
	[self setDate:[rep objectForKey:ThreadPlistContentsDateKey]];
	[self setDateRepresentation:[rep objectForKey:ThreadPlistContentsDateRepKey]];
	[self setIDString:[rep stringForKey:ThreadPlistContentsIDKey]];
	[self setBeProfile:[rep objectForKey:ThreadPlistContentsBeProfileKey]];
	[self setMessageSource:[rep stringForKey:ThreadPlistContentsMessageKey]];
	[self setHost:[rep stringForKey:CMRThreadContentsHostKey]];
	
	[self setMessageAttributes:[CMRThreadMessageAttributes objectWithPropertyListRepresentation:[rep objectForKey:CMRThreadContentsStatusKey]]];
	
	return YES;
}

- (id)initWithPropertyListRepresentation:(id)rep
{
	if (self = [self init]) {
		if (![self initializeWithPropertyListRepresentation:rep]) {
			[self release];
			return nil;
		}
	}
	return self;
}

+ (id)objectWithPropertyListRepresentation:(id)rep
{
	return [[[self alloc] initWithPropertyListRepresentation:rep] autorelease];
}

- (id)propertyListRepresentation
{
	NSMutableDictionary		*rep;
	id						date_ = [self date];
	rep = [NSMutableDictionary dictionary];
	
	[rep setUnsignedInteger:[self index] forKey:ThreadPlistContentsIndexKey];
	[rep setNoneNil:[self name] forKey:ThreadPlistContentsNameKey];
	[rep setNoneNil:[self mail] forKey:ThreadPlistContentsMailKey];

	if (date_) {
		[rep setObject:date_ forKey:ThreadPlistContentsDateKey];
	}

	[rep setNoneNil:[self IDString] forKey:ThreadPlistContentsIDKey];
	[rep setNoneNil:[self dateRepresentation] forKey:ThreadPlistContentsDateRepKey];
	[rep setNoneNil:[self beProfile] forKey:ThreadPlistContentsBeProfileKey];
	[rep setNoneNil:[self messageSource] forKey:ThreadPlistContentsMessageKey];
	[rep setNoneNil:[self host] forKey:CMRThreadContentsHostKey];
	[rep setNoneNil:[[self messageAttributes] propertyListRepresentation] forKey:CMRThreadContentsStatusKey];
	
	return rep;
}

#pragma mark NSObject
- (NSString *)description
{
// #warning 64BIT: Check formatting arguments
// 2010-03-31 tsawada2 修正済
	return [NSString stringWithFormat: 
				@"<%@ %p> index=%lu Abone?=%@ date=%@\n"
				@"  name=%@ mail=%@\n"
				@"  id=%@ host=%@\n"
				@"  %@",
				
				[self className],
				self,
				(unsigned long)[self index],
				UTILBOOLString([self isAboned]),
				[self date],
				[self name],
				[self mail],
				[self IDString],
				[self host],
				[self messageSource]];
}

- (id)copyWithZone:(NSZone *)aZone
{
	CMRThreadMessage	*tmp;
	id					v;
	
	tmp = [[[self class] allocWithZone:aZone] init];
	
	[tmp setIndex:[self index]];
	
	v = [[self name] copyWithZone:aZone];
	[tmp setName:v];
	[v release];
	
	v = [[self mail] copyWithZone:aZone];
	[tmp setMail:v];
	[v release];
	
	v = [[self date] copyWithZone:aZone];
	[tmp setDate:v];
	[v release];

	v = [[self beProfile] copyWithZone:aZone];
	[tmp setBeProfile:v];
	[v release];

	v = [[self messageSource] copyWithZone:aZone];
	[tmp setMessageSource:v];
	[v release];
	
	v = [[self messageAttributes] copyWithZone:aZone];
	[tmp setMessageAttributes:v];
	[v release];
	
	v = [[self IDString] copyWithZone:aZone];
	[tmp setIDString:v];
	[v release];
	
	v = [[self host] copyWithZone:aZone];
	[tmp setHost:v];
	[v release];
	
	v = [[self dateRepresentation] copyWithZone:aZone];
	[tmp setDateRepresentation:v];
	[v release];

	return tmp;
}

#pragma mark Accessors
- (NSUInteger)index
{
	return _index;
}

- (void)setIndex:(NSUInteger)anIndex
{
	_index = anIndex;
}

- (NSString *)name
{
	return _name;
}

- (void)setName:(NSString *)aName
{
	id		tmp;
	id		theName_;
	
	theName_ = CMRThreadMessageNameCache(aName);
	
	tmp = _name;
	_name = [theName_ retain];
	[tmp release];
}

- (NSString *)mail
{
	return _mail;
}

- (void)setMail:(NSString *)aMail
{
	id		tmp;
	id		mcache_;
	
	mcache_ = CMRThreadMessageMailCache(aMail);
	
	tmp = _mail;
	_mail = [mcache_ retain];
	[tmp release];
}

- (id)date
{
	return _date;
}

- (void)setDate:(id)aDate
{
	id		tmp;
	
	tmp = _date;
	_date = [aDate retain];
	[tmp release];
	
	// いまのところ、「あぼーん」されたレスかどうかは
	// 日付けがあることに依存
	[self setAboned:(nil == _date)];
}

- (NSArray *)beProfile
{
	return _beProfile;
}

- (void)setBeProfile:(NSArray *)aBeProfile
{
	id		tmp;

	tmp = _beProfile;
	_beProfile = [aBeProfile retain];
	[tmp release];
}


- (NSString *)cachedMessage
{
//	return [CMXTextParser cachedMessageWithMessageSource:[self messageSource]];
    if (!bs_cachedMessage) {
        bs_cachedMessage = [[CMXTextParser cachedMessageWithMessageSource:[self messageSource]] retain];
    }
    return bs_cachedMessage;
}

- (NSString *)messageSource
{
	return _messageSource;
}

- (void)setMessageSource:(NSString *)aMessageSource
{
	id		tmp;
	
	tmp = _messageSource;
	_messageSource = [aMessageSource retain];
	[tmp release];

    // 殆どの場合 _messageSource は一度セットされたら不変だが…
    // 一応 bs_cachedMessage の再キャッシュを促す
    if (bs_cachedMessage) {
        [bs_cachedMessage release];
        bs_cachedMessage = nil;
    }
}

- (NSString *)dateRepresentation
{
	return _dateRepresentation;
}

- (void)setDateRepresentation:(NSString *)aRep
{
	id		tmp;
	
	tmp = _dateRepresentation;
	_dateRepresentation = [aRep retain];
	[tmp release];
}

// Extra Headers
- (NSString *)IDString
{
	return _IDString;
}

- (void)setIDString:(NSString *)anIDString
{
	id		tmp;
	
	tmp = _IDString;
	_IDString = [anIDString retain];
	[tmp release];
}

- (NSString *)host
{
	return _hostString;
}

- (void)setHost:(NSString *)aHost
{
	id		tmp;
	
	tmp = _hostString;
	_hostString = [aHost retain];
	[tmp release];
}
@end


@implementation CMRThreadMessage(AdditionalAttributes)
- (CMRThreadMessageAttributes *)messageAttributes
{
	if (!_messageAttributes) {
		_messageAttributes = [[CMRThreadMessageAttributes alloc] init];
	}
	return _messageAttributes;
}

- (void)setMessageAttributes:(CMRThreadMessageAttributes *)attrs
{
	id		tmp;
	
	tmp = _messageAttributes;
	_messageAttributes = [attrs retain];
	[tmp release];
}

- (UInt32)status
{
	return [[self messageAttributes] status];
}

- (UInt32)flags
{
	return [[self messageAttributes] flags];
}

- (void)setFlags:(UInt32)v
{
	[[self messageAttributes] setFlags:v];
}

// 6 bit
- (NSUInteger)property
{
	UInt32	v;
	
	v = [self flags];
	return (NSUInteger)(v & MA_FL_USER_USED_MASK);
}

- (void)setProperty:(NSUInteger)aProperty
{
	UInt32	v;
	
	v = [self flags];
	aProperty &= MA_FL_USER_USED_MASK;
	v &= ~MA_FL_USER_USED_MASK;
	v |= aProperty;
	
	[self setFlags:v];
}

// Notification
- (BOOL)postsAttributeChangedNotifications
{
	return [[self messageAttributes] flagAt:TEMP_POST1_FLAG];
}

- (void)setPostsAttributeChangedNotifications:(BOOL)flag
{
	[self setMessageAttributeFlag:TEMP_POST1_FLAG on:flag];
}

- (BOOL)isVisible
{
	return [[self messageAttributes] isVisible];
}

// あぼーん
- (BOOL)isAboned
{
	return [[self messageAttributes] isAboned];
}

- (void)setAboned:(BOOL)flag
{
	[self setMessageAttributeFlag:ABONED_FLAG on:flag];
}

// ローカルあぼーん
- (BOOL)isLocalAboned
{
	return [[self messageAttributes] isLocalAboned];
}

- (void)setLocalAboned:(BOOL)flag
{
	[self setMessageAttributeFlag:LOCAL_ABONED_FLAG on:flag];
}

// 透明あぼーん
- (BOOL)isInvisibleAboned
{
	return [[self messageAttributes] isInvisibleAboned];
}

- (void)setInvisibleAboned:(BOOL)flag
{
	[self setMessageAttributeFlag:INVISIBLE_ABONED_FLAG on:flag];
}

// AA
- (BOOL)isAsciiArt
{
	return [[self messageAttributes] isAsciiArt];
}

- (void)setAsciiArt:(BOOL)flag
{
	[self setMessageAttributeFlag:ASCII_ART_FLAG on:flag];
}

// ブックマーク
// Finder like label, 3bit unsigned integer value.
- (BOOL)hasBookmark
{
    return ([self bookmark] != 0);
}

- (void)setHasBookmark:(BOOL)aBookmark
{
	if (!aBookmark) {
		[self setBookmark:0];
	} else if (![self hasBookmark]) {
		[self setBookmark:1];
	}
}

- (NSUInteger)bookmark
{
    return [[self messageAttributes] bookmark];
}

- (void)setBookmark:(NSUInteger)aBookmark
{
	UInt32		flags_ = [self flags];

	flags_ &=  ~BOOKMARK_FLAG;
	flags_ |= INT2BOOKMARK(aBookmark);

	[self setFlags:flags_];
	[self postDidChangeAttributeNotification];
}

// このレスは壊れています
- (BOOL)isInvalid
{
	return [[self messageAttributes] isInvalid];
}

- (void)setInvalid:(BOOL)flag
{
	[self setMessageAttributeFlag:INVALID_FLAG on:flag];
}

// 迷惑レス
- (BOOL)isSpam
{
	return [[self messageAttributes] isSpam];
}

- (void)setSpam:(BOOL)flag
{
	[self setMessageAttributeFlag:SPAM_FLAG on:flag];
}

// Visible Range
- (void)clearTemporaryAttributes
{
	[self setFlags:[self status]];
}

- (BOOL)isTemporaryInvisible
{
	return [[self messageAttributes] isTemporaryInvisible];
}

- (void)setTemporaryInvisible:(BOOL)flag
{
	[self setMessageAttributeFlag:TEMP_INVISIBLE_FLAG on:flag];
}
@end


@implementation CMRThreadMessage(Private)
- (void)postDidChangeAttributeNotification
{
	NSNotification *notification;
	
	notification = [NSNotification notificationWithName:CMRThreadMessageDidChangeAttributeNotification object:self];
	
	[[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostASAP coalesceMask:NSNotificationCoalescingOnSender forModes:nil];
}

- (void)setMessageAttributeFlag:(UInt32)flag on:(BOOL)isSet
{
	UInt32				oldFlags;
	
	oldFlags = [[self messageAttributes] flags];
	[[self messageAttributes] setFlag:flag on:isSet];
	
	if ((oldFlags == [[self messageAttributes] flags]) || (![self postsAttributeChangedNotifications]) ||
        ((flag & MA_FL_NOT_TEMP_MASK) <= MA_FL_USER_USED_MASK)) {
        return;
    }

	[self postDidChangeAttributeNotification];
}
@end


static NSString *CMRThreadMessageNameCache(NSString *theName)
{
	static NSString *kCachedName_;
	auto   id        tmp;
	
	if (!theName) {
        return nil;
    }
	if (0 == [theName length]) {
        return kEmptyString;
	}
	if ([theName isEqualToString:kCachedName_]) {
		return kCachedName_;
	}
	
	tmp = kCachedName_;
	kCachedName_ = [theName copy];
	[tmp release];
	
	tmp = nil;
	return kCachedName_;
}

static NSString *CMRThreadMessageMailCache(NSString *theMail)
{
	if (!theMail) {
        return nil;
    }
	if (0 == [theMail length]) {
        return kEmptyString;
	}
	if ([theMail isEqualToString:CMRThreadMessage_SAGE_String]){
		return CMRThreadMessage_SAGE_String;
	}

	return theMail;
}
