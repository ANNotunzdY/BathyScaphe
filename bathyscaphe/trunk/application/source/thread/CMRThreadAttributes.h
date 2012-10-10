//
//  CMRThreadAttributes.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/23.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/SGFoundation.h>

@class CMRThreadSignature;

@interface CMRThreadAttributes : NSObject
{
    @private
    BOOL                    m_changed;      /* needs to write file */
    NSMutableDictionary     *m_attributes;  /* contains all properties */
}

- (id)initWithDictionary:(NSDictionary *)info;
- (NSDictionary *)dictionaryRepresentation;
- (void)addEntriesFromDictionary:(NSDictionary *)newAttrs;
- (void)writeAttributes:(NSMutableDictionary *)aDictionary;

- (CMRThreadSignature *)threadSignature;
- (NSString *)bbsIdentifier;
- (NSString *)datIdentifier;

- (BOOL)needsToBeUpdatedFromLoadedContents;
- (BOOL)needsToUpdateLogFile;
- (void)setNeedsToUpdateLogFile:(BOOL)flag;

- (NSUInteger)numberOfLoadedMessages;
- (void)setNumberOfLoadedMessages:(NSUInteger)nLoaded;

- (NSUInteger)numberOfMessages;

- (NSString *)path;
- (NSString *)threadTitle;
- (NSString *)boardName;
- (NSURL *)boardURL;
- (NSURL *)threadURL;
- (NSRect)windowFrame;
- (void)setWindowFrame:(NSRect)newFrame;
- (NSUInteger)lastIndex;
- (void)setLastIndex:(NSUInteger)anIndex;

- (NSString *)displaySize;
- (NSString *)displayPath;
- (NSDate *)createdDate;
- (NSDate *)modifiedDate;
@end

/* working with CMRThreadUserStatus */
@interface CMRThreadAttributes(UserStatus)
- (BOOL)isAAThread;
//- (void)setAAThread:(BOOL)flag; // Deprecated. Use -setIsAAThread: instead.
- (void)setIsAAThread:(BOOL)flag;
// Available in BathyScaphe 1.2 and later.
- (BOOL)isDatOchiThread;
//- (void)setDatOchiThread:(BOOL)flag; // Deprecated. Use -setIsDatOchiThread: instead.
- (void)setIsDatOchiThread:(BOOL)flag;
- (BOOL)isMarkedThread;
//- (void)setMarkedThread:(BOOL)flag; // Deprecated. Use -setIsMarkedThread: instead.
- (void)setIsMarkedThread:(BOOL)flag;
// Available in BathyScaphe 2.0 "Final Moratorium" and later.
- (NSUInteger)label;
- (void)setLabel:(NSUInteger)code;
@end


@interface CMRThreadAttributes(Converter)
+ (BOOL)isNewThreadFromDictionary:(NSDictionary *)dict;
+ (NSInteger)numberOfUpdatedFromDictionary:(NSDictionary *)dict;
+ (NSString *)pathFromDictionary:(NSDictionary *)dict;
+ (NSString *)identifierFromDictionary:(NSDictionary *)dict;

+ (NSString *)boardNameFromDictionary:(NSDictionary *)dict;
+ (NSString *)threadTitleFromDictionary:(NSDictionary *)dict;
+ (NSDate *)createdDateFromDictionary:(NSDictionary *)dict;
+ (NSDate *)modifiedDateFromDictionary:(NSDictionary *)dict;

+ (NSURL *)boardURLFromDictionary:(NSDictionary *)dict;
+ (NSURL *)threadURLFromDictionary:(NSDictionary *)dict;

+ (NSURL *)threadURLWithBoardID:(NSUInteger)boardID datIdentifier:(NSString *)identifier;

+ (NSURL *)threadURLWithLatestParamFromDict:(NSDictionary *)dict resCount:(NSInteger)count;
+ (NSURL *)threadURLWithHeaderParamFromDict:(NSDictionary *)dict resCount:(NSInteger)count;
+ (NSURL *)threadURLWithDefaultParameterFromDictionary:(NSDictionary *)dict;

+ (void)replaceKeywords:(NSMutableString *)theBuffer dictionary:(NSDictionary *)theThread;
+ (void)replaceKeywords:(NSMutableString *)theBuffer attributes:(CMRThreadAttributes *)theThread;
+ (void)fillBuffer:(NSMutableString *)theBuffer withThreadInfoForCopying:(NSArray *)threadAttrsAry;
@end
