//
//  CMRThreadAttributes.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/23.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadAttributes.h"
#import "CMRThreadSignature.h"

#import "CMRDocumentFileManager.h"
#import "BoardManager.h"
#import "AppDefaults.h"
#import "CMRHostHandler.h"


@interface NSObject(DatabaseManagerStub)
- (BOOL)isDatOchiBoardName:(NSString *)boardName threadIdentifier:(NSString *)identifier;
- (void)setIsDatOchi:(BOOL)flag boardName:(NSString *)boardName threadIdentifier:(NSString *)identifier;
- (void)setLabel:(NSUInteger)code
	   boardName:(NSString *)boardName
threadIdentifier:(NSString *)identifier;
@end


@implementation CMRThreadAttributes
- (id)initWithDictionary:(NSDictionary *)info
{
    if (self = [super init]) {
        [self addEntriesFromDictionary:info];
    }
    return self;
}

- (void)dealloc
{
    [m_attributes release];
    [super dealloc];
}

- (NSMutableDictionary *)getMutableAttributes
{
    if (!m_attributes) {
        m_attributes = [[NSMutableDictionary alloc] init];
    }
    
    return m_attributes;
}

- (NSDictionary *)dictionaryRepresentation
{
    return [self getMutableAttributes];
}

- (void)addEntriesFromDictionary:(NSDictionary *)newAttrs
{
    if (!newAttrs || [newAttrs count] == 0) {
        return;
    }
    [self willChangeValueForKey:@"windowFrame"];
    [self willChangeValueForKey:@"threadTitle"];
    [self willChangeValueForKey:@"displaySize"];
    [self willChangeValueForKey:@"displayPath"];
    [self willChangeValueForKey:@"modifiedDate"];
    [self willChangeValueForKey:@"createdDate"];
    [self willChangeValueForKey:@"isAAThread"];
    [self willChangeValueForKey:@"isMarkedThread"];
    [self willChangeValueForKey:@"isDatOchiThread"];

    [[self getMutableAttributes] addEntriesFromDictionary:newAttrs];

    [self didChangeValueForKey:@"isDatOchiThread"];
    [self didChangeValueForKey:@"isMarkedThread"];
    [self didChangeValueForKey:@"isAAThread"];
    [self didChangeValueForKey:@"createdDate"];
    [self didChangeValueForKey:@"modifiedDate"];
    [self didChangeValueForKey:@"displayPath"];
    [self didChangeValueForKey:@"displaySize"];
    [self didChangeValueForKey:@"threadTitle"];
    [self didChangeValueForKey:@"windowFrame"];
}

- (CMRThreadSignature *)threadSignature
{
    return [CMRThreadSignature threadSignatureWithIdentifier:[self datIdentifier] boardName:[self boardName]];
}

- (NSString *)datIdentifier
{
    return [[self class] identifierFromDictionary:[self getMutableAttributes]];
}

/* ログファイルがないため更新が必要 */
- (BOOL)needsToBeUpdatedFromLoadedContents
{
    return (![self threadTitle]) || ([self numberOfLoadedMessages] == 0);
}

- (BOOL)needsToUpdateLogFile
{
    return m_changed;
}

- (void)setNeedsToUpdateLogFile:(BOOL)flag
{
    m_changed = flag;
}

- (NSUInteger)numberOfLoadedMessages
{
    return [[self getMutableAttributes] unsignedIntegerForKey:CMRThreadLastLoadedNumberKey defaultValue:0];
}

- (void)setNumberOfLoadedMessages:(NSUInteger)numberOfMessages
{
    [[self getMutableAttributes] setUnsignedInteger:numberOfMessages forKey:CMRThreadLastLoadedNumberKey];
}

- (NSUInteger)numberOfMessages
{
    return [[self getMutableAttributes] unsignedIntegerForKey:CMRThreadNumberOfMessagesKey defaultValue:0];
}

- (NSString *)path
{
    return [[self class] pathFromDictionary:[self getMutableAttributes]];
}

- (NSString *)threadTitle
{
    return [[self class] threadTitleFromDictionary:[self getMutableAttributes]];
}

- (NSString *)boardName
{
    return [[self class] boardNameFromDictionary:[self getMutableAttributes]];
}

- (NSString *)bbsIdentifier
{
    return [[[self boardURL] stringValue] lastPathComponent];
}

- (NSURL *)boardURL
{
    return [[self class] boardURLFromDictionary:[self getMutableAttributes]];
}

- (NSURL *)threadURL
{
    return [[self class] threadURLFromDictionary:[self getMutableAttributes]];
}

- (NSString *)displaySize
{
    id length_;

    length_ = [[self getMutableAttributes] numberForKey:ThreadPlistLengthKey];

    if (length_) {
        NSString *str_;
        NSUInteger bytes = [length_ unsignedIntegerValue];
        NSUInteger kbytes = bytes / 1024;
// #warning 64BIT: Check formatting arguments
// 2010-05-23 tsawada2 修正済
        str_ = [NSString stringWithFormat:NSLocalizedString(@"%lu KB (%lu bytes)", nil), kbytes, bytes];
        return str_;
    }
    return nil;
}

- (NSString *)displayPath
{
    NSString    *path_;

    path_ = [[self class] pathFromDictionary:[self getMutableAttributes]];
    if (path_) {
        return path_;
    }
    return nil;
}

- (NSDate *)createdDate
{
    return [[self class] createdDateFromDictionary:[self getMutableAttributes]];
}

- (NSDate *)modifiedDate
{
    return [[self class] modifiedDateFromDictionary:[self getMutableAttributes]];
}

- (NSRect)windowFrame
{   
    return [[self getMutableAttributes] rectForKey:CMRThreadWindowFrameKey];
}

- (void)setWindowFrame:(NSRect)newFrame
{
    if (NSEqualRects(NSZeroRect, newFrame)) {
        return;
    }
    [[self getMutableAttributes] setRect:newFrame forKey:CMRThreadWindowFrameKey];
    [self setNeedsToUpdateLogFile:YES];
}

- (NSUInteger)lastIndex
{
    return [[self getMutableAttributes] unsignedIntegerForKey:CMRThreadLastReadedIndexKey defaultValue:NSNotFound];
}

- (void)setLastIndex:(NSUInteger)anIndex
{
    NSMutableDictionary *mdict_ = [self getMutableAttributes];
    id v;
    
    v = [mdict_ objectForKey:CMRThreadLastReadedIndexKey];
    [[v retain] autorelease];
    if (v && ![v respondsToSelector:@selector(unsignedIntegerValue)]) {
        [mdict_ removeObjectForKey:CMRThreadLastReadedIndexKey];
        v = nil;
    }
    if (NSNotFound == anIndex) {
        if (!v) {
            return;
        }
        [mdict_ removeObjectForKey:CMRThreadLastReadedIndexKey];
    } else {
        if ([v unsignedIntegerValue] == anIndex) {
            return;
        }
        [mdict_ setUnsignedInteger:anIndex forKey:CMRThreadLastReadedIndexKey];
    }
    [self setNeedsToUpdateLogFile:YES];
}

- (void)writeAttributes:(NSMutableDictionary *)aDictionary
{
    id v;
    
    v = [[self getMutableAttributes] objectForKey:CMRThreadWindowFrameKey];
    [aDictionary setNoneNil:v forKey:CMRThreadWindowFrameKey];
    v = [[self getMutableAttributes] objectForKey:CMRThreadVisibleRangeKey];
    [aDictionary setNoneNil:v forKey:CMRThreadVisibleRangeKey];
    v = [[self getMutableAttributes] objectForKey:CMRThreadLastReadedIndexKey];
    [aDictionary setNoneNil:v forKey:CMRThreadLastReadedIndexKey];
    /* CMRThreadUserStatus */
    v = [[self getMutableAttributes] objectForKey:CMRThreadUserStatusKey];
    [aDictionary setNoneNil:v forKey:CMRThreadUserStatusKey];
    
}
@end


@implementation CMRThreadAttributes(UserStatus)
/* working with CMRThreadUserStatus */
- (CMRThreadUserStatus *)userStatus
{
    id rep_;
    CMRThreadUserStatus *s;
    
    rep_ = [[self dictionaryRepresentation] objectForKey:CMRThreadUserStatusKey];
    s = [CMRThreadUserStatus objectWithPropertyListRepresentation:rep_];

    if (!s) {
        s = [CMRThreadUserStatus statusWithUInt32Value:0];
    }
    return s;
}

- (BOOL)isAAThread
{
    return [[self userStatus] isAAThread];
}

- (void)setIsAAThread:(BOOL)flag
{
    CMRThreadUserStatus *s = [self userStatus];
    
    UTILAssertNotNil(s);
    if ([s isAAThread] == flag) {
        return;
    }
    [s setAAThread:flag];
    [[self getMutableAttributes] setObject:[s propertyListRepresentation] forKey:CMRThreadUserStatusKey];
    [self setNeedsToUpdateLogFile:YES];
}

- (void)setAAThread:(BOOL)flag
{
    [self setIsAAThread:flag];
}

- (BOOL)isDatOchiThread
{
    BOOL s1 = [[self userStatus] isDatOchiThread];
    BOOL s2;

    // ログファイルとデータベース間の整合性チェック。不整合ならログファイルにあわせる。
    // 本来ここですることではないが、他に良い場所が発見できなかった。
    {
        id m = [NSClassFromString(@"DatabaseManager") defaultManager];
        s2 = [m isDatOchiBoardName:[self boardName]
                  threadIdentifier:[self datIdentifier]];
        if((s1 && !s2) || (!s1 && s2)) {
            [m setIsDatOchi:s1
                  boardName:[self boardName]
           threadIdentifier:[self datIdentifier]];
        }
    }
    
    return s1;
}

- (void)setIsDatOchiThread:(BOOL)flag
{
    CMRThreadUserStatus *s = [self userStatus];
    
    {
        id m = [NSClassFromString(@"DatabaseManager") defaultManager];
        [m setIsDatOchi:flag
              boardName:[self boardName]
       threadIdentifier:[self datIdentifier]];
    }
    
    UTILAssertNotNil(s);
    if ([s isDatOchiThread] == flag) {
        return;
    }
    [s setDatOchiThread:flag];
    [[self getMutableAttributes] setObject:[s propertyListRepresentation] forKey:CMRThreadUserStatusKey];
    [self setNeedsToUpdateLogFile:YES];
}

- (void)setDatOchiThread:(BOOL)flag
{
    [self setIsDatOchiThread:flag];
}

- (BOOL)isMarkedThread
{
    return [[self userStatus] isMarkedThread];
}

- (void)setIsMarkedThread:(BOOL)flag
{
    CMRThreadUserStatus *s = [self userStatus];

    UTILAssertNotNil(s);
    if ([s isMarkedThread] == flag) {
        return;
    }
    [s setMarkedThread:flag];
    [[self getMutableAttributes] setObject:[s propertyListRepresentation] forKey:CMRThreadUserStatusKey];
    [self setNeedsToUpdateLogFile:YES];
}

- (void)setMarkedThread:(BOOL)flag
{
    [self setIsMarkedThread:flag];
}

- (NSUInteger)label
{
    return [[self userStatus] label];
}

- (void)setLabel:(NSUInteger)code
{
    CMRThreadUserStatus *s = [self userStatus];
	
	{
        id m = [NSClassFromString(@"DatabaseManager") defaultManager];
        [m setLabel:code
              boardName:[self boardName]
       threadIdentifier:[self datIdentifier]];
    }

    UTILAssertNotNil(s);
    if ([s label] == code) {
        return;
    }
    [s setLabel:code];
    [[self getMutableAttributes] setObject:[s propertyListRepresentation] forKey:CMRThreadUserStatusKey];
    [self setNeedsToUpdateLogFile:YES];

}
@end
