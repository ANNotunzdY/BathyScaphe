/**
  * $Id: CMRAttributedMessageComposer.h,v 1.1.1.1.4.1 2006-01-28 16:06:42 masakih Exp $
  * 
  * CMRAttributedMessageComposer.h
  *
  * Copyright (c) 2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  */
#import <Cocoa/Cocoa.h>
#import "CMRMessageComposer.h"



@interface CMRAttributedMessageComposer : CMRMessageComposer
{
	@private
	NSMutableAttributedString	*_contentsStorage;
	NSMutableAttributedString	*_nameCache;
	
	//NSDictionary				*_localeDict;
	
	UInt32			_mask;
	struct {
		unsigned int mask:31;
		unsigned int compose:1;
		unsigned int :0;
	} _CCFlags;
}
+ (id) composerWithContentsStorage : (NSMutableAttributedString *) storage;
- (id) initWithContentsStorage : (NSMutableAttributedString *) storage;

//- (NSDictionary *) localeDict;

/* mask で指定された属性を無視する */
- (UInt32) attributesMask;
- (void) setAttributesMask : (UInt32) mask;

/* flag: mask に一致する属性をもつレスを生成するかどうか */
- (void) setComposingMask : (UInt32) mask
				  compose : (BOOL  ) flag;

- (NSMutableAttributedString *) contentsStorage;
- (void) setContentsStorage : (NSMutableAttributedString *) aContentsStorage;
@end
