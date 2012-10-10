//: CMRThreadMessage.h
/**
  * $Id: CMRThreadMessage.h,v 1.5 2008-02-18 23:17:36 tsawada2 Exp $
  * 
  * Copyright (c)2001-2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  * encoding="UTF-8"
  */

#import <Foundation/Foundation.h>
#import <SGFoundation/SGFoundation.h>

@interface CMRThreadMessage : NSObject<NSCopying, CMRPropertyListCoding>
{
	@private
	NSUInteger		_index;		/* 0-base */
	NSString		*_name;
	NSString		*_mail;
	
	id				_date;
	NSString		*_dateRepresentation; // may be nil in old log
	
	NSArray			*_beProfile;
	NSString		*_messageSource;
    NSString        *bs_cachedMessage;

	NSString		*_IDString;
	NSString		*_hostString;

	/* Application Difined Attributes*/
	CMRThreadMessageAttributes *_messageAttributes;
}
/* 0-base */
- (NSUInteger)index;
- (void)setIndex:(NSUInteger)anIndex;

- (NSString *)name;
- (void)setName:(NSString *)aName;
- (NSString *)mail;
- (void)setMail:(NSString *)aMail;
- (id)date;
- (void)setDate:(id)aDate;

- (NSString *)dateRepresentation;
- (void)setDateRepresentation:(NSString *)aRep;

// Plain Text
- (NSString *)cachedMessage;

// HTML Source
- (NSString *)messageSource;
- (void)setMessageSource:(NSString *)aMessageSource;

// Extra Headers
- (NSString *)IDString;
- (void)setIDString:(NSString *)anIDString;
- (NSString *)host;
- (void)setHost:(NSString *)aHost;
- (NSArray *)beProfile;
- (void)setBeProfile:(NSArray *)aBeProfile;
@end


@interface CMRThreadMessage(MessageAttributes)
- (CMRThreadMessageAttributes *)messageAttributes;
- (void)setMessageAttributes:(CMRThreadMessageAttributes *)attrs;

- (UInt32)status;
- (UInt32)flags;
- (void)setFlags:(UInt32)v;

// User defined property: 6 bit
- (NSUInteger)property;
- (void)setProperty:(NSUInteger)aProperty;

// NO == isInvisibleAboned  && NO == isTemporaryInvisible
- (BOOL)isVisible;

// あぼーん
- (BOOL)isAboned;
- (void)setAboned:(BOOL)flag;

// ローカルあぼーん
- (BOOL)isLocalAboned;
- (void)setLocalAboned:(BOOL)flag;

// 透明あぼーん
- (BOOL)isInvisibleAboned;
- (void)setInvisibleAboned:(BOOL)flag;

// AA
- (BOOL)isAsciiArt;
- (void)setAsciiArt:(BOOL)flag;

// ブックマーク
// Finder like label, 3bit unsigned integer value.
- (BOOL)hasBookmark;
// set bookmark 1 if none.
- (void)setHasBookmark:(BOOL)aBookmark;

- (NSUInteger)bookmark;
- (void)setBookmark:(NSUInteger)aBookmark;

// このレスは壊れています
- (BOOL)isInvalid;
- (void)setInvalid:(BOOL)flag;

// 迷惑レス
- (BOOL)isSpam;
- (void)setSpam:(BOOL)flag;

// temporary attributes
- (void)clearTemporaryAttributes;

// The NONE temporary attributes changes can result in notification posting:
- (BOOL)postsAttributeChangedNotifications;
- (void)setPostsAttributeChangedNotifications:(BOOL)flag;

// Visible Range
- (BOOL)isTemporaryInvisible;
- (void)setTemporaryInvisible:(BOOL)flag;
@end


@interface CMRThreadMessage(UndoSupport)
- (void)setLocalAboned:(BOOL)flag undoManager:(NSUndoManager *)um;
- (void)setInvisibleAboned:(BOOL)flag undoManager:(NSUndoManager *)um;
- (void)setAsciiArt:(BOOL)flag undoManager:(NSUndoManager *)um;
- (void)setHasBookmark:(BOOL)flag undoManager:(NSUndoManager *)um;
- (void)setSpam:(BOOL)flag undoManager:(NSUndoManager *)um;
@end


@interface CMRThreadMessage(Private)
- (void)setMessageAttributeFlag:(UInt32)flag on:(BOOL)isSet;
- (void)postDidChangeAttributeNotification;
@end


// Notification
extern NSString *const CMRThreadMessageDidChangeAttributeNotification;


// age / sage
extern NSString *const CMRThreadMessage_AGE_String;
extern NSString *const CMRThreadMessage_SAGE_String;
