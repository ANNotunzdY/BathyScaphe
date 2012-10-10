//
//  SGFoundationUtils.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "SGNSR.h"

void *nsr_strncasestr(const char *str, const char *find, size_t length)
{
	char		c;
	size_t		n;
	char		*p = (char*)str;
	
	if (NULL == str || NULL == find)
		return NULL;
	if ( 0 == (n = strlen(find)) )
		return p;
	
	c = tolower(*find);
	for (; length >= n; p++, length--) {
		if (tolower(*p) == c && 0 == nsr_strncasecmp(p, find, n))
			return p;
	}
	
	return NULL;
}
void *nsr_strnstr(const char *str, const char *find, size_t length)
{
	char		c;
	size_t		n;
	char		*p = (char*)str;
	
	if (NULL == str || NULL == find)
		return NULL;
	if ( 0 == (n = strlen(find)) )
		return p;
	
	c = *find;
	for (; length >= n; p++, length--) {
		if (*p == c && 0 == strncmp(p, find, n))
			return p;
	}
	
	return NULL;
}
