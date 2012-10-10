//
//  CMRNetGrobalLock.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/23.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

/*!
    @class		CMRNetGrobalLock
    @abstract   Utility class to prevent duplicate requests.
    @discussion A CMRNetGrobalLock object holds requests inProgress
				(request: URLs, signature, or other.)
				Network object should prevent duplicate request.
				IMPORTANT:
				A request MUST be immutable object, conforms to NSCopying.
*/
@interface CMRNetGrobalLock : NSObject {
    @private
    NSLock       *m_lock;
    NSMutableSet *m_requests; /* this and that */
}

+ (id)sharedInstance;

- (void)add:(id<NSCopying>)aRequest;
- (void)remove:(id<NSCopying>)aRequest;
- (BOOL)has:(id<NSCopying>)aRequest;
@end
