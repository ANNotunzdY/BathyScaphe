//
//  BSSExpParser.h
//  BSSpotlighter
//
//  Created by Hori,Masaki on 06/05/16.
//  Copyright 2006-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSSTokenizer;

@interface BSSExpParser : NSObject
{}

+ (id)sharedInstance;

+ (NSPredicate *)predicateForString:(NSString *)string forKey:(NSString *)key;
+ (NSPredicate *)predicateForTokens:(BSSTokenizer *)token forKey:(NSString *)key;

- (NSPredicate *)predicateForTokens:(BSSTokenizer *)token forKey:(NSString *)key;
- (NSString *)predicateStringForTokens:(BSSTokenizer *)token forKey:(NSString *)key;
@end


@interface BSSTokenizer : NSObject
{
	NSArray *mTokens;
	
	NSUInteger mCurrentIndex;
	NSUInteger mSavedIndex;
}


+ (id)tokenizerWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;

+ (NSArray *)tokensFromString:(NSString *)string;

- (NSString *)currentToken;
- (NSString *)nextToken; // return nil, if not have next token.
- (BOOL)hasNextToken;

- (NSUInteger)count;
- (NSUInteger)currentIndex;

- (BSSTokenizer *)tokenizerWithRange:(NSRange)range;

- (void)saveTokenIndex;
- (void)restoreTokenIndex;

- (void)rewind;

@end