/**
  * UTILKit.h
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.
  * See the file LICENSE for copying permission.
  * encoding="UTF-8"
  */
#ifndef UTILKIT_H_INCLUDED
#define UTILKIT_H_INCLUDED

#import "UTILAssertion.h"
#import "UTILDescription.h"
#import "UTILError.h"

#ifdef __cplusplus
extern "C" {
#endif



#define UTILNumberOfCArray(carray)	(sizeof(carray)/sizeof(carray[0]))



// abstract method / not yet implement
#define UTILAbstractMethodInvoked	\
		[NSException raise : @"Abstract method invoked."			\
				    format : @"[%@ %@] is an abstract method.",		\
			NSStringFromClass([self class]),\
			NSStringFromSelector(_cmd)]


// Exception Handling
#define UTILCatchException(x) if([(x) isEqualToString :[localException name]])

// notification
#define UTILNotifyName(name)	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self]
#define UTILNotifyInfo(name, info)	[[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:info]
#define UTILNotifyInfo3(name, info, key)	\
	[[NSNotificationCenter defaultCenter]\
		postNotificationName:name\
		object:self\
		userInfo:[NSDictionary dictionaryWithObject:info forKey:key]]


// object is nil or NSNull
#define UTILObjectIsNull(obj)	(nil == (obj) || [NSNull null] == (id)(obj))



// switch
#define		UTILUnknownSwitchCase(x)	\
		[NSException raise : NSGenericException\
					format : @"Unsupported Switch Case (%ld).\n\t%@",\
							(long)x,\
							UTIL_HANDLE_FAILURE_IN_METHOD]
#define		UTILUnknownCSwitchCase(x)	\
		[NSException raise : NSGenericException\
					format : @"Unsupported Switch Case (%d).\n\t%@",\
							x,\
							UTIL_HANDLE_FAILURE_IN_FUNCTION]
#define		UTILUnknownCSwitchCaseNSInteger(x)	\
		[NSException raise : NSGenericException\
					format : @"Unsupported Switch Case (%ld).\n\t%@",\
							(long)x,\
							UTIL_HANDLE_FAILURE_IN_FUNCTION]


// 比較
#define		UTILComparisionResultPrimitives(x, y)	\
(x == y) ? NSOrderedSame : ((x > y) ? NSOrderedDescending : NSOrderedAscending)

#define		UTILComparisionResultObjects(receiver, other)	((nil == receiver) ? ((nil == other) ? NSOrderedSame : NSOrderedAscending) : [receiver compare : other])


#define		UTILComparisionResultReversed(x)	\
(NSOrderedAscending == x ? NSOrderedDescending : (NSOrderedDescending == x ? NSOrderedAscending : NSOrderedSame))



#ifdef __cplusplus
}  /* End of the 'extern "C"' block */
#endif

#endif /* UTILKIT_H_INCLUDED */

