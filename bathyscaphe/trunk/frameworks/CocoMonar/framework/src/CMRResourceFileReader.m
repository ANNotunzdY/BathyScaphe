//
//  CMRResourceFileReader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRResourceFileReader.h"


NSString *const CMRReaderUnsupportedFormatException = @"CMRReaderUnsupportedFormatException";


@implementation CMRResourceFileReader
+ (id)readerWithContentsOfFile:(NSString *)filePath
{
    return [[[self alloc] initWithContentsOfFile:filePath] autorelease];
}

+ (id)readerWithContents:(id)fileContents
{
    return [[[self alloc] initWithContents:fileContents] autorelease];
}

- (id)initWithContentsOfFile:(NSString *)filePath
{
    id          fileContents_;
    Class       cResource_;

    cResource_ = [[self class] resourceClass];
    NSAssert2([cResource_ instancesRespondToSelector:@selector(initWithContentsOfFile:)],
                @"instance of %@ must be responseTo <%@>.",
                NSStringFromClass(cResource_),
                NSStringFromSelector(@selector(initWithContentsOfFile:)));

    bs_filepath = [filePath copy];
    fileContents_ = [[cResource_ alloc] initWithContentsOfFile:filePath];
    if (self = [self initWithContents:fileContents_]) {
        //...
    }
    [fileContents_ release];
    return self;
}

- (id)initWithContents:(id)fileContents
{
    if (self = [self init]) {
        @try {
            // サブクラスはここで例外CMRReaderUnsupportedFormatException
            // を投げることもできる。
            // もし、例外が発生せず、かつnil == fileContentsならば、自身を解放し
            // nilを返す。
            [self setFileContents:fileContents];
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:CMRReaderUnsupportedFormatException]) {
                fileContents = nil;
            } else {
                @throw;
            }
        }

        if (!fileContents) {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    [bs_contents release];
    [bs_filepath release];
    [super dealloc];
}

+ (Class)resourceClass
{
    return [NSString class];
}

- (id)fileContents
{
    return bs_contents;
}

- (void)setFileContents:(id)aFileContents
{
    id tmp;

    if (aFileContents) {
        if (![aFileContents isKindOfClass:[[self class] resourceClass]]) {
            [NSException raise:CMRReaderUnsupportedFormatException
                        format:@"Unsupported file contents. "
                               @"expected %@ but was %@",
                               NSStringFromClass([[self class] resourceClass]),
                               NSStringFromClass([aFileContents class])];
        }
    }

    tmp = bs_contents;
    bs_contents = [aFileContents retain];
    [tmp release];
}

- (NSString *)filepath
{
    return bs_filepath;
}
@end
