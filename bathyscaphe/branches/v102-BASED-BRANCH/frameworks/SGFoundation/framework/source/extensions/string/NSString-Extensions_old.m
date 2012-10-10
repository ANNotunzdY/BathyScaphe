//: NSString-Extensions_old.m/**  * $Id: NSString-Extensions_old.m,v 1.1.1.1 2005-05-11 17:51:45 tsawada2 Exp $  *   * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.  * See the file LICENSE for copying permission.  */#import <SGFoundation/NSString-SGExtensions.h>#import <SGFoundation/NSMutableString-SGExtensions.h>#import <SGFoundation/NSCharacterSet-SGExtensions.h>#import <SGFoundation/PublicDefines.h>#import <string.h>//////////////////////////////////////////////////////////////////////////////////////////// [ 定数やマクロ置換 ] ////////////////////////////////////////////////////////////////////////////////////////////////// URLEncodestatic CFStringEncoding st_default_urlEncoding = kCFStringEncodingUTF8;/*static const char st_nonEscapeASCIICharacters[] = "-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";static inline char hex(int i){	static const char *hexchars = "0123456789ABCDEF";		return hexchars[i];}*///URLEncodeする文字セットを返す。/*static NSCharacterSet *fnc_escapeCharacterSet(void){	static NSCharacterSet *st_escapeCharacterSet;		if(nil == st_escapeCharacterSet){		NSMutableCharacterSet *escape_cset_;		NSString *nonEscapeASCIICharacters;				escape_cset_ = [[NSMutableCharacterSet alloc] init];		nonEscapeASCIICharacters = [NSString stringWithCString : st_nonEscapeASCIICharacters];		[escape_cset_ addCharactersInString : nonEscapeASCIICharacters];		[escape_cset_ invert];		st_escapeCharacterSet = [escape_cset_ copy];		[escape_cset_ release];	}	return st_escapeCharacterSet;}*/@implementation NSString(SGExtensions)///////////////////////////////////////////////////////////////////////////////////////////// [ 初期化・後始末 ] /////////////////////////////////////////////////////////////////////////////////////////////////+ (id) stringWithData : (NSData         *) data		   CFEncoding : (CFStringEncoding) encoding{	return [[[self alloc] initWithData : data							CFEncoding : encoding] autorelease];}- (id) initWithData : (NSData         *) data		 CFEncoding : (CFStringEncoding) encoding{	NSStringEncoding	encoding_;		encoding_ = CFStringConvertEncodingToNSStringEncoding(encoding);	if(kCFStringEncodingInvalidId == encoding_){		[self release];		return nil;	}	return [self initWithData : data encoding : encoding_];}/**  * 与えられたデータから一時的なオブジェクトを生成し、返す。  * 引数encodingに、そのとき用いるエンコードを指定。  *   * @param    data      データ  * @param    encoding  エンコード方式  * @return             一時的なオブジェクト  */+ (id) stringWithData : (NSData         *) data             encoding : (NSStringEncoding) encoding{	return [[[self alloc] initWithData : data 	                          encoding : encoding] autorelease];}/**  * 一文字を表す文字コードを与えて、一時的なオブジェクトを生成し、返す。  *   * @param    aCharacter  一文字を表す文字コード  * @return               一時的なオブジェクト  */+ (id) stringWithCharacter : (unichar) aCharacter{	return [[[self alloc] initWithCharacter : aCharacter] autorelease];}/**  * 一文字を表す文字コードを与えて、初期化。  *   * @param    aCharacter  一文字を表す文字コード  * @return               初期化済みのインスタンス  */- (id) initWithCharacter : (unichar) aCharacter{	return [self initWithCharacters : &aCharacter length : 1];}////////////////////////////////////////////////////////////////////////////////////////// [ インスタンスメソッド ] //////////////////////////////////////////////////////////////////////////////////////////////- (BOOL) isEmpty{	return (0 == [self length]);}//Check whether contains character/**  * レシーバが引数aStringに指定した文字列を含む場合にYESを返す。  *   * @param    aString  探索文字列  * @return            レシーバが引数aStringに指定した文字列を含む場合にYES  */- (BOOL) containsString : (NSString *) aString{	return ([self rangeOfString : aString].length != 0);}/**  * レシーバが引数aStringに指定した文字セットを含む場合にYESを返す。  *   * @param    characterSet  探索文字セット  * @return                 レシーバが引数aStringに指定した文字列を含む場合にYES  */- (BOOL) containsCharacterFromSet : (NSCharacterSet *) characterSet{	return ([self rangeOfCharacterFromSet : characterSet].length != 0);}//Data Using CFStringEncoding/**  * レシーバをデータで返す。  *   * @param    anEncoding  CFStringEncoding  * @return               文字列のデータ  */- (NSData *) dataUsingCFEncoding : (CFStringEncoding) anEncoding;{	return [self dataUsingCFEncoding : anEncoding			    allowLossyConversion : NO];}/**  * レシーバをデータで返す。  *   * @param    anEncoding  CFStringEncoding  * @param    lossy       失われるデータを無視  * @return               文字列のデータ  */- (NSData *) dataUsingCFEncoding : (CFStringEncoding) anEncoding            allowLossyConversion : (BOOL            ) lossy;{	return [(id)CFStringCreateExternalRepresentation(kCFAllocatorDefault,													(CFStringRef)self, 													anEncoding, 													lossy?TRUE:FALSE) autorelease];}/**  * 指定された文字列を改行(またはUnicodeの段落区切り文字)で区切り、  * それぞれ改行文字を含まない文字列を要素とする配列を返す。  * 改行を含まない、または末尾が改行の文字列の場合は、要素がひとつ  * の配列を返す。  *   * @param    aString  改行を含む文字列  * @return            改行文字を含まない文字列を要素とする配列  */- (NSArray *) componentsSeparatedByNewline{	NSMutableArray *lines;				//行毎に詰めていく配列	NSRange         lineRng;			//行の範囲	unsigned int    startIndex;			//最初の文字のインデックス	unsigned int    lineEndIndex;		//次の行（段落）の最初の文字のインデックス	unsigned int    contentsEndIndex;	//最初の改行文字のインデックス	unsigned int    len;				//文字列の長さ			lines = [NSMutableArray array];	len = [self length];	lineRng = NSMakeRange(0, 0);	//行毎に範囲を求め、切り出した文字列を	//配列に詰めていく。	do{		[self getLineStart : &startIndex		               end : &lineEndIndex		       contentsEnd : &contentsEndIndex		          forRange : lineRng];				lineRng.location = startIndex;		lineRng.length = (contentsEndIndex - startIndex);				//文字列を行単位で切り出し、配列の末尾へ		[lines addObject : [self substringWithRange : lineRng]];				//調べる範囲を次の行の先頭へ持っていく。		lineRng.location = lineEndIndex;		lineRng.length = 0;	}while(lineRng.location < len);		if(len > 0){		unichar		c;				c = [self characterAtIndex : len -1];		if('\n' == c ||'\r' == c)			[lines addObject : @""];	}	return lines;}/**  * 文字列をURLエンコードする。  *   * @param    unencodedString  エンコードする対象文字列  * @param    encoding         文字列のエンコード方式  * @param    asQuery          クエリとしてURLエンコードする。  * @param    leaveSlashes     @"/"をエンコードしないか  * @param    leaveColons      @":"をエンコードしないか  * @return                    URLエンコードされた文字列  */+ (NSString *) encodeURLEncoding : (NSString       *) unencodedString                        encoding : (CFStringEncoding) encoding                         asQuery : (BOOL            ) asQuery                    leaveSlashes : (BOOL            ) leaveSlashes                     leaveColons : (BOOL            ) leaveColons{	NSMutableString		*charactersToLeaveUnescaped_;	NSString			*CFURLEncoded_;		if(nil == unencodedString || 0 == [unencodedString length]) return unencodedString;	charactersToLeaveUnescaped_ = nil;	if(leaveSlashes || leaveColons){		charactersToLeaveUnescaped_ = [NSMutableString string];		if(leaveSlashes){			[charactersToLeaveUnescaped_ appendString : @"/"];		}		if(leaveColons){			[charactersToLeaveUnescaped_ appendString : @":"];		}	}		CFURLEncoded_ = (NSString*)CFURLCreateStringByAddingPercentEscapes(						CFAllocatorGetDefault(), 						(CFStringRef)unencodedString, 						(CFStringRef)charactersToLeaveUnescaped_, 						NULL, 						encoding);	return [CFURLEncoded_ autorelease];/*	//Source	NSData *source_;	unsigned const char *sbuf_;	unsigned int slen_;	unsigned int sindex_;	//Output	unichar *outbuf_;	unsigned int outsize_;	unsigned int outindex_;	NSString *escapedString;		if(nil == unencodedString || 0 == [unencodedString length])		return @"";	if(NO == [unencodedString containsCharacterFromSet : fnc_escapeCharacterSet()])		return unencodedString;	if(kCFStringEncodingInvalidId == encoding)		encoding = [self defaultURLStringEncoding];	//Source	source_ = [unencodedString dataUsingCFEncoding : encoding	                          allowLossyConversion : YES];	sbuf_ = [source_ bytes];	slen_ = [source_ length];	//Output	outsize_ = slen_ + (slen_ >> 2) + 12;	outbuf_ = NSZoneMalloc(NULL, (outsize_) * sizeof(unichar));	outindex_ = 0;		for(sindex_ = 0; sindex_ < slen_; sindex_++){		unsigned char ch;				ch = sbuf_[sindex_];		if(outindex_ >= outsize_ - 3){		   outsize_ += outsize_ >> 2;		   outbuf_ = NSZoneRealloc(NULL, outbuf_, (outsize_) * sizeof(unichar));		}		//replace 		if((strchr(st_nonEscapeASCIICharacters, ch) != NULL) ||		   (leaveSlashes && ch == '/') ||		   (leaveColons && ch == ':')){			outbuf_[outindex_++] = ch;		}else if(asQuery && ch == ' '){			outbuf_[outindex_++] = '+';		}else{			outbuf_[outindex_++] = '%';			outbuf_[outindex_++] = hex((ch & 0xF0) >> 4);			outbuf_[outindex_++] = hex(ch & 0x0F);		}	}	escapedString = [[NSString alloc] initWithCharactersNoCopy : outbuf_												length : outindex_										  freeWhenDone : YES];	//...	return [escapedString autorelease];*/}/**  * URLエンコードのさいにデフォルトで使用するエンコード方式  * を返す。  *   * @return     デフォルトで設定されているエンコード方式  */+ (CFStringEncoding) defaultURLStringEncoding{	return st_default_urlEncoding;}/**  * URLエンコードのさいにデフォルトで使用するエンコード方式  * を設定する。  *   * @param    defaultEncoding  デフォルトで設定されているエンコード方式  */+ (void) setDefaultURLStringEncoding : (CFStringEncoding) defaultEncoding{	st_default_urlEncoding = defaultEncoding;}/**  * 文字列をURLエンコードする。  *   * @param    encoding  文字列のエンコーディング  * @return             URLエンコードされた文字列  */- (NSString *) stringByURLEncodedUsingEncoding : (CFStringEncoding) encoding{	if(kCFStringEncodingInvalidId == encoding){		encoding = [[self class] defaultURLStringEncoding];	}	return [[self class] encodeURLEncoding : self                                  encoding : encoding                                   asQuery : NO                              leaveSlashes : NO                               leaveColons : NO];}- (NSString *) stringByURLDecodedUsingEncoding : (CFStringEncoding) encoding{	CFStringRef		decoded_;		if(kCFStringEncodingInvalidId == encoding)		encoding = [[self class] defaultURLStringEncoding];		decoded_ = CFURLCreateStringByReplacingPercentEscapes(					CFAllocatorGetDefault(), 					self, 					CFSTR(""));		return [(NSString*)decoded_ autorelease];}/**  * URLに用いられる文字のみで構成された文字列ならYESを返す。  * ただし、URI形式に沿っているとは限らない。  *   * @return     URLに用いられる文字のみで構成された文字列ならYES  */- (BOOL) isValidURLCharacters{	const BOOL	containsNonURLChar_ = [self containsCharacterFromSet : [NSCharacterSet nonURLCharacterSet]];	return (NO == containsNonURLChar_ && [self length] != 0);}/**  * 文字列をURLエンコードする。  *   * @return     URLエンコードされた文字列  */- (NSString *) stringByURLEncoded{	static char *urlencode_ = "%\",/][{}`~-_()*^$#!&=+";	int i;	char c;	NSMutableString *mstr_;		mstr_ = [self mutableCopyWithZone : [self zone]];		i = 0;	while((c = urlencode_[i++]) != '\0'){		NSAutoreleasePool *pool_;	//自動解放プール		NSString *seach_;			//探索文字		NSString *repl_;			//置換				pool_ = [[NSAutoreleasePool alloc] init];		seach_ = [NSString stringWithCString : &c 									  length : 1];		repl_ = [NSString stringWithFormat : @"%%%x", c];		[mstr_ replaceCharacters : seach_						toString : repl_];		[pool_ release];	}	//エスケープ文字はエンコーディングによって異なる。	[mstr_ replaceCharacters : @"\\"					toString : @"%5c"];	[mstr_ replaceCharacters : @"\245"					toString : @"%5c"];	//空白を"+"に。	[mstr_ replaceCharacters : @" "					toString : @"+"];		return [mstr_ autorelease];}- (NSString *) stringByReplaceEntityReference{	NSMutableString *mstr_;	if(NO == [self containsString : @"&"]) return self;		mstr_ = [self mutableCopyWithZone : [self zone]];	[mstr_ replaceEntityReference];	return [mstr_ autorelease];}/**  * 指定されたcharsをすべて、文字列replacement  * で置き換える。  *   * @param    chars        置き換えられる文字列  * @return                新しい文字列  */- (NSString *) stringByReplaceCharacters : (NSString        *) chars                                toString : (NSString        *) replacement{	return [self stringByReplaceCharacters : chars					              toString : replacement						           options : NSLiteralSearch];}/**  * 指定されたcharsをすべて、文字列replacement  * で置き換える。  *   * @param    chars        置き換えられる文字列  * @param    replacement  置換後の文字列  * @param    options      検索時のオプション  * @return                新しい文字列  */- (NSString *) stringByReplaceCharacters : (NSString        *) chars                                toString : (NSString        *) replacement                                 options : (unsigned int     ) options{	return [self stringByReplaceCharacters : chars					              toString : replacement						           options : options				                     range : NSMakeRange(0, [self length])];}/**  * 指定されたcharsをすべて、文字列replacement  * で置き換える。  *   * @param    chars        置き換えられる文字列  * @param    replacement  置換後の文字列  * @param    options      検索時のオプション  * @param    range        置き換える範囲  * @return                新しい文字列  */- (NSString *) stringByReplaceCharacters : (NSString        *) chars                                toString : (NSString        *) replacement                                 options : (unsigned int     ) options                                   range : (NSRange          ) aRange{	NSMutableString *mstr_;		if(NO == [self containsString : chars]) return self;	mstr_ = [self mutableCopyWithZone : [self zone]];	[mstr_ replaceCharacters : chars	                toString : replacement					 options : options					   range : aRange];	return [mstr_ autorelease];}/**  * レシーバのcharSetに含まれる文字列をすべて削除する。  *   * @param    charSet      置き換えられる文字のセット  * @return                新しい文字列  */- (NSString *)  stringByDeleteCharactersInSet : (NSCharacterSet  *) charSet{	return [self stringByDeleteCharactersInSet : charSet                                       options : 0];}/**  * レシーバのcharSetに含まれる文字列をすべて削除する。  *   * @param    charSet      置き換えられる文字のセット  * @param    range        置き換える範囲  * @return                新しい文字列  */- (NSString *)  stringByDeleteCharactersInSet : (NSCharacterSet  *) charSet                                      options : (unsigned int     ) options{	return [self stringByDeleteCharactersInSet : charSet                                       options : options                                         range : NSMakeRange(0, [self length])];}/**  * レシーバのcharSetに含まれる文字列をすべて削除する。  *   * @param    charSet      置き換えられる文字のセット  * @param    options      検索時のオプション  * @param    range        置き換える範囲  * @return                新しい文字列  */- (NSString *)  stringByDeleteCharactersInSet : (NSCharacterSet  *) charSet                                      options : (unsigned int     ) options                                        range : (NSRange          ) aRange{	NSMutableString *mstr_;		if(NO == [self containsCharacterFromSet : charSet]) return self;		mstr_ = [self mutableCopyWithZone : [self zone]];	[mstr_ deleteCharactersInSet : charSet					     options : options					       range : aRange];	return [mstr_ autorelease];}/**  * 先頭と末尾の連続する空白文字、タブ、改行を削除  * した文字列を返す。  *  * @return     新しい文字列  */- (NSString *) stringByStriped{	NSMutableString *mstr_;		mstr_ = [self mutableCopyWithZone : [self zone]];	[mstr_ strip];	return [mstr_ autorelease];}/**  * 先頭の連続する空白文字、タブ、改行を削除  * した文字列を返す。  *  * @return     新しい文字列  */- (NSString *) stringByStripedAtStart{	NSMutableString *mstr_;		mstr_ = [self mutableCopyWithZone : [self zone]];	[mstr_ stripAtStart];	return [mstr_ autorelease];}/**  * 末尾の連続する空白文字、タブ、改行を削除  * した文字列を返す。  *  * @return     新しい文字列  */- (NSString *) stringByStripedAtEnd{	NSMutableString *mstr_;		mstr_ = [self mutableCopyWithZone : [self zone]];	[mstr_ stripAtEnd];	return [mstr_ autorelease];}@end