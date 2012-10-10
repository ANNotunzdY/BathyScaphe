//
//  SGBaseQueue.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/07.
//  Copyright 2005-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

/*!
 * @header     SGBaseQueue
 * @discussion さまざまなキュー
 */
#import <Foundation/Foundation.h>


/*!
 * @protocol   SGBaseQueue
 * @abstract   キューのプロトコル定義
 * @discussion このプロトコルに適合するクラスのインスタンスは
 *             キューとして利用できる
 */
@protocol SGBaseQueue<NSObject>
- (void)put:(id)item;
- (id)take;
- (BOOL)isEmpty;
@end


@interface SGBaseQueue : NSObject<SGBaseQueue> {
	NSMutableArray	*_mutableArray;
}

+ (id)queue;
@end


@interface SGBaseThreadSafeQueue : SGBaseQueue
{
	NSLock			*_lock;
}
@end
