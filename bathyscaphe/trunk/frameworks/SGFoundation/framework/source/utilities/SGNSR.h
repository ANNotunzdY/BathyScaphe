//
//  SGNSR.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

/*!
 * @header     SGNSR
 * @discussion Non Standard Routines Interface <string.h>
 */

#ifndef SGNSR_INCLUDED
#define SGNSR_INCLUDED

#include <stddef.h>
#include <string.h>
#include <SGFoundation/SGBase.h>

SG_DECL_BEGIN

#define nsr_strdup(s)			strdup(s)
#define nsr_bzero(p, size)		bzero(p, size)
#define nsr_strcasecmp(s1, s2)	strcasecmp(s1, s2)
#define nsr_strncasecmp(s1, s2, len)	strncasecmp(s1, s2, len)
#define nsr_memcasestr(p, s, n)	nsr_strncasestr((const char*)p, s, n)



SG_EXPORT
void *nsr_strncasestr(const char *str, const char *find, size_t length);
SG_EXPORT
void *nsr_strnstr(const char *str, const char *find, size_t length);



SG_DECL_END

#endif /* SGNSR_INCLUDED */
