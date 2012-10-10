//
//  SGFileLocation.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/17.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGFileLocation.h"
#import <SGFoundation/SGFileRef.h>


@implementation SGFileLocation
#pragma mark PRIVATE
- (void)setDirectory:(SGFileRef *)aDirectory
{
    id tmp;

    tmp = m_directory;
    m_directory = [aDirectory retain];
    [tmp release];
}

- (void)setName:(NSString *)aName
{
    id tmp;

    tmp = m_name;
    m_name = [aName retain];
    [tmp release];
}

#pragma mark PUBLIC
+ (id)fileLocationWithName:(NSString *)aFileName directory:(SGFileRef *)aDirectory
{
    return [[[self alloc] initWithName:aFileName directory:aDirectory] autorelease];
}

- (id)initWithName:(NSString *)aFileName directory:(SGFileRef *)aDirectory
{
    if (!aDirectory) {
        [self release];
        return nil;
    }
    if (self = [self init]) {
        [self setName:aFileName];
        [self setDirectory:aDirectory];
    }
    return self;
}

+ (id)fileLocationAtPath:(NSString *)aFilePath
{
    return [[[self alloc] initLocationAtPath:aFilePath] autorelease];
}

- (id)initLocationAtPath:(NSString *)aFilePath
{
    SGFileRef *directory;
    NSString *name;

    name = [aFilePath lastPathComponent];
    directory = [SGFileRef fileRefWithPath:[aFilePath stringByDeletingLastPathComponent]];

    return [self initWithName:name directory:directory];
}

- (id)init
{
    if (self = [super init]) {
        ;
    }
    return self;
}

- (void)dealloc
{
    [m_directory release];
    [m_name release];
    [super dealloc];
}

- (SGFileRef *)actualDirectory
{
    return [[self directory] fileRefResolvingLinkIfNeeded];
}

- (SGFileRef *)directory
{
    return m_directory;
}

- (NSString *)name
{
    return m_name;
}

- (BOOL)exists
{
    return ([self fileRef] != nil);
}

- (SGFileRef *)fileRef
{
    return [[self actualDirectory] fileRefWithChildName:[self name]];
}

- (NSString *)filepath
{
    return [[[self actualDirectory] filepath] stringByAppendingPathComponent:[self name]];
}

#pragma mark NSObject
- (BOOL)isEqual:(id)other
{
    if (self == other) {
        return YES;
    }
    if (!other) {
        return NO;
    }
    if ([other isKindOfClass:[self class]]) {
        BOOL ret;

        ret = [[self name] isEqual:[other name]];
        if (!ret) {
            return NO;
        }
        ret = [[self directory] isEqual:[other directory]];
        if (!ret) {
            return NO;
        }
        return YES;
    }

    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:
            @"<%@:%p> directory:%@ name:%@",
            [self className], self,
            [[self directory] filepath],
            [self name]];
}

- (NSUInteger)hash
{
    return ([[self name] hash] ^ [[self directory] hash]);
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)aZone
{
    return [self retain];
}
@end
