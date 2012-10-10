//
//  NSAppleScript-SGExtensions.m
//  SGAppKit
//
//  Created by Tsutomu Sawada on 08/06/08.
//  Copyright 2008 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSAppleScript-SGExtensions.h"
#import <Carbon/Carbon.h>

@implementation NSAppleScript(SGExtensions)
- (BOOL)doHandler:(NSString *)handlerName withParameters:(NSArray *)params error:(NSDictionary **)errPtr
{
	NSInteger	i;
	NSAppleEventDescriptor* parameters = [NSAppleEventDescriptor listDescriptor];
	NSAppleEventDescriptor* eachParameter;
	for (i=0; i<[params count]; i++) {
		eachParameter = [NSAppleEventDescriptor descriptorWithString:[params objectAtIndex:i]];
		[parameters insertDescriptor:eachParameter atIndex:i+1];
	}

	// AppleEventターゲットを作成する
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor* target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber
																					bytes:&psn
// #warning 64BIT: Inspect use of sizeof
// 2010-03-07 tsawada2 検討済
																				   length:sizeof(ProcessSerialNumber)];

	NSAppleEventDescriptor* handler = [NSAppleEventDescriptor descriptorWithString:[handlerName lowercaseString]];

	// AppleScriptサブルーチンのイベントを作成する、
	// メソッド名とパラメータリストを設定する
	NSAppleEventDescriptor* event =
		[NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
												 eventID:kASSubroutineEvent
										targetDescriptor:target
												returnID:kAutoGenerateReturnID
										   transactionID:kAnyTransactionID];

	[event setParamDescriptor:handler forKeyword:keyASSubroutineName];
	[event setParamDescriptor:parameters forKeyword:keyDirectObject];

	// AppleScriptのイベントを呼び出す
	if (![self executeAppleEvent:event error:errPtr]){
		// 'errors' からエラーを報告する
		return NO;
	}
	return YES;
}
@end
