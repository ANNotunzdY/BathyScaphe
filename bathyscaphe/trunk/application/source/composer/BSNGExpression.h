//
//  BSNGExpression.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/08/09.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class OnigRegexp;
@protocol CMRPropertyListCoding;

enum {
	BSNGExpressionAtName = 1 << 0,
	BSNGExpressionAtMail = 1 << 1,
	BSNGExpressionAtMessage = 1 << 2,
};

#define BSNGExpressionAtAll	(BSNGExpressionAtName|BSNGExpressionAtMail|BSNGExpressionAtMessage)

@interface BSNGExpression : NSObject<CMRPropertyListCoding> {
	NSString *m_NGExpression;
	NSUInteger m_NGTargetMask;
	BOOL	m_isRegularExpression;

    OnigRegexp *m_regex; // may be nil...
}

- (id)initWithExpression:(NSString *)string targetMask:(NSUInteger)mask regularExpression:(BOOL)isRE;

- (NSString *)ngExpression;
- (void)setNgExpression:(NSString *)string;

- (NSUInteger)targetMask;
- (void)setTargetMask:(NSUInteger)mask;

- (BOOL)checksName;
- (void)setChecksName:(BOOL)check;
- (BOOL)checksMail;
- (void)setChecksMail:(BOOL)check;
- (BOOL)checksMessage;
- (void)setChecksMessage:(BOOL)check;

- (BOOL)isRegularExpression;
- (void)setIsRegularExpression:(BOOL)isRE;

- (BOOL)validAsRegularExpression;

- (OnigRegexp *)regex;
- (void)setRegex:(OnigRegexp *)obj;
@end
