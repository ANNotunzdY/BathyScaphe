//
//  CMRSpamFilter.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/12.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "BSMessageSample.h"

@class BSNGExpression;

@interface CMRSpamFilter : NSObject {
	@private
	NSMutableArray *m_spamCorpus; // Array of BSNGExpressions
    NSMutableArray *m_spamSamples; // Array of BSMessageSamples

	BOOL m_needsSaveToFiles;
	NSTimer *m_timer;
}

+ (id)sharedInstance;

- (void)resetSpamFilter;
- (void)saveNgExpressionsAndSamplesToFiles;

- (NSMutableArray *)ngExpressions;
- (void)setNgExpressions:(NSMutableArray *)aSpamCorpus;

- (void)addNGExpression:(BSNGExpression *)expression;

- (void)addMessageSample:(BSMessageSample *)sample;
- (void)removeMessageSample:(BSMessageSample *)sample;

- (BSMessageSample *)sampleOfType:(BSMessageSampleType)type object:(NSString *)sampleObject withBoard:(NSString *)boardName;

- (void)getSpamSampleObjectsForBoard:(NSString *)boardName
                            idString:(NSArray **)idsPtr
                                name:(NSArray **)namesPtr
                                mail:(NSArray **)mailsPtr;

- (BOOL)needsSaveToFiles;
- (void)setNeedsSaveToFiles:(BOOL)flag;

@property(readonly, retain) NSMutableArray *spamSamples;

@end


@interface CMRSpamFilter(FileReadWrite)
- (id)readFromContentsOfPropertyListFile:(NSString *)plistPath;
- (NSMutableArray *)restoreFromPlistToCorpus:(id)rep;
- (NSMutableArray *)restoreFromPlistToSamples:(id)rep;

- (NSArray *)propertyListRepresentation:(NSArray *)base; // Array of BSNGExpressions or BSMessageSamples
- (BOOL)saveRepresentation:(id)rep toFile:(NSString *)filepath;
@end
