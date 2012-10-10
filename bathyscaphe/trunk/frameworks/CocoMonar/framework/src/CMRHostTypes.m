//
//  CMRHostTypes.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRHostTypes.h"
#import <SGFoundation/SGFoundation.h>
#import "UTILKit.h"



const char *CMRGetHostCStringFromBoardURL(NSURL *anURL, const char **pbbs)
{
	NSMutableData *buffer  = nil;
	
	const char	*path_;
	const char	*host_;
	size_t		bufSize;
	size_t		pathsize;
	char		*p;
	size_t		n;
	
	if (pbbs != NULL) {
        *pbbs = NULL;
    }
	if (NULL == anURL || NULL == (path_ = [[anURL absoluteString] UTF8String])) {
		return NULL;
    }

	pathsize = strlen(path_) * sizeof(char) + 1;
	
	buffer = SGTemporaryData();
	bufSize = [buffer length];
	if (bufSize < pathsize) {
		[buffer setLength:pathsize];
	}
	bufSize = [buffer length];
	p = (char*)[buffer mutableBytes];
	
	memset(p, bufSize, '\0');
	memmove(p, path_, pathsize);

	p = (char*)[[anURL scheme] UTF8String];
	if (NULL == p) {
        return NULL;
    }
	n = strlen(p);

	// http://pc.2ch.net/mac
	host_ = [buffer mutableBytes];
	// ://pc.2ch.net/mac
	host_ += n;
	
	// //pc.2ch.net/mac
	if (*host_ != ':') {
        return NULL;
    }
	host_++;

	// pc.2ch.net/mac
	while ('/' == *host_) {
		host_++;
	}
	while (1) {
		p = strrchr(host_, '/');
		if (NULL == p) {
			return host_;
		}
		*p = '\0';
		if (*(p +1) != '\0') {
			break;
        }
	}

	if (pbbs != NULL) {
        *pbbs = ++p;
	}
	return host_;
}

NSString *CMRGetHostStringFromBoardURL(NSURL *anURL, NSString **pbbs)
{
	const char	*host_;
	const char	*bbs_ = NULL;
	
	host_ = CMRGetHostCStringFromBoardURL(anURL, (pbbs ? &bbs_ : NULL));
	
	if (pbbs != NULL) {
		*pbbs = bbs_ ? [NSString stringWithUTF8String : bbs_] : nil;
	}
	return [NSString stringWithUTF8String:host_];
}

/*
 * read.cgiがパス仕様に対応していると期待できるか
 * 過去ログ倉庫、offlaw、板トップURLの判定などでも流用
 */
bool can_readcgi(const char *host)
{
//	const char	*p;
//	char		*ep;
//#warning 64BIT: Inspect use of long
//	long		l;
	
	if (NULL == host) {
        return false;
	}
	if (strstr(host, ".2ch.net")) {
		return !strstr(host, "tako") && !strstr(host, "piza.");
    }
	if (strstr(host, ".bbspink.com")) {
		return !strstr(host, "www.");
    }
	/* 64.71.128.0/18 216.218.128.0/17 のテスト */
//	p = strstr(host, "64.71.");
//	if (p) {
//		l = strtol(p + 6, &ep, 10);
//		if (*ep == '.' && (l & 0xc0) == 128) {
//			return true;
//        }
//	}
//	p = strstr(host, "216.218.");
//	if (p) {
//		l = strtol(p + 8, &ep, 10);
//		if (*ep == '.' && (l & 0x80) == 128) {
//			return true;
//        }
//	}
//	return strstr(host, ".he.net") != NULL;
    return false;
}

bool is_2channel(const char *host)
{
	return can_readcgi(host);
}

bool is_2ch_except_pink(const char *host)
{
    if (host == NULL) {
        return false;
    }
	if (strstr(host, ".2ch.net")) {
		return !strstr(host, "tako") && !strstr(host, "piza.");
    }
    return false;
}
    
bool is_2ch_belogin_needed(const char *host)
{
	if (host != NULL) {
		return strstr(host, "be.2ch.net") != NULL || strstr(host, "qa.2ch.net") != NULL;
	}
	return false;
}

bool is_jbbs_livedoor(const char *host)
{
	if (host != NULL) {
		return strstr(host, "jbbs.shitaraba.com") != NULL || strstr(host, "jbbs.livedoor.jp") != NULL || strstr(host, "jbbs.livedoor.com") != NULL;
	}
	return false;
}

bool is_machi(const char *host)
{
	return host ? strstr(host, ".machi.to") || strstr(host, ".machibbs.com") : false;
}
