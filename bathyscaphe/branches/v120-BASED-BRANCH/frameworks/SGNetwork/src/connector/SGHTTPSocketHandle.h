//: SGHTTPSocketHandle.h
/**
  * $Id: SGHTTPSocketHandle.h,v 1.1.1.1 2005-05-11 17:51:50 tsawada2 Exp $
  * 
  * Copyright (c) 2001-2003, Takanori Ishikawa.  All rights reserved.
  * See the file LICENSE for copying permission.
  */

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <SGNetwork/SGHTTPConnector.h>

@interface SGHTTPSocketHandle : SGHTTPConnector
{
	NSFileHandle *m_socketHandle;		//Socketから生成したFileHandle
}
@end
