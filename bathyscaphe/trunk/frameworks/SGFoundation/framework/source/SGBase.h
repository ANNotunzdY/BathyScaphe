//
//  SGBase.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#ifndef SGBASE_H_INCLUDED
#define SGBASE_H_INCLUDED



#ifndef SG_DECL_BEGIN
#ifdef __cplusplus
#define SG_DECL_BEGIN  extern "C" {
#define SG_DECL_END    }
#else  /*! __cplusplus */
#define SG_DECL_BEGIN
#define SG_DECL_END
#endif /* #ifdef __cplusplus */
#endif /* #ifndef SG_DECL_BEGIN */

SG_DECL_BEGIN



/* NULL / TRUE / FALSE */
#ifndef NULL
#define NULL	0
#endif
#ifndef FALSE
#define FALSE	0
#endif
#ifndef TRUE
#define TRUE	1
#endif

/* external/inline decleration */
#ifndef SG_EXPORT
#define SG_EXPORT			extern
#endif
#ifndef SG_STATIC_INLINE
#define SG_STATIC_INLINE	static __inline__
#endif



/*-------------------------------------------------------------
 * BASIC TYPES
 */

/*
SGByte:
----------------------------------------
8-bit unsigned integer, a Octet.
*/
typedef unsigned char SGByte;



SG_DECL_END

#endif /* SGBASE_H_INCLUDED */
