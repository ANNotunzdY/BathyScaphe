//
//  BSTGrepResult.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/09/20.
//  Copyright 2010-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSTGrepResult.h"
#import "CMRThreadLinkProcessor.h"
#import "CMRThreadSignature.h"


@implementation BSTGrepResult
- (id)initWithOrderStr:(NSString *)orderStr URL:(NSString *)URLStr titleWithBoldTag:(NSString *)titleContainsBoldTag
{
    if (self = [super init]) {
        NSMutableString *tmp = [titleContainsBoldTag mutableCopy];
        [tmp replaceOccurrencesOfString:@"<b>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tmp length])];
        [tmp replaceOccurrencesOfString:@"</b>" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, [tmp length])];
        m_threadTitle = (NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)tmp, NULL);

        [tmp release];
        m_order = [orderStr unsignedIntegerValue];
        m_threadURLString = [URLStr retain];
    }
    return self;
}

- (id)initWithOrderNo:(NSUInteger)orderNo URL:(NSString *)URLStr titleWithoutBoldTag:(NSString *)titleContainsNoBoldTag
{
    if (self = [super init]) {
        m_threadTitle = (NSString *)CFXMLCreateStringByUnescapingEntities(kCFAllocatorDefault, (CFStringRef)titleContainsNoBoldTag, NULL);
        m_order = orderNo;
        m_threadURLString = [URLStr retain];
    }
    return self;
}

- (void)dealloc
{
    [m_threadTitle release];
    [m_threadURLString release];
    [super dealloc];
}

- (NSUInteger)order
{
    return m_order;
}

- (NSString *)threadURLString
{
    return m_threadURLString;
}

- (NSString *)threadTitle
{
    return m_threadTitle;
}

- (NSURL *)threadURL
{
    return [NSURL URLWithString:[self threadURLString]];
}

- (NSString *)boardName
{
    NSString *result = nil;
    [CMRThreadLinkProcessor parseThreadLink:[self threadURL] boardName:&result boardURL:NULL filepath:NULL];
    return result;
}

- (CMRThreadSignature *)threadSignature
{
    NSString *path = nil;
    [CMRThreadLinkProcessor parseThreadLink:[self threadURL] boardName:NULL boardURL:NULL filepath:&path];
    if (!path) {
        return nil;
    }
    return [CMRThreadSignature threadSignatureFromFilepath:path];
}

#pragma mark NSPasteboardWriting
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [NSArray arrayWithObjects:BSPasteboardTypeThreadSignature, (NSString *)kUTTypeURL, NSPasteboardTypeString, nil];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    if ([type isEqualToString:BSPasteboardTypeThreadSignature]) {
        return [[self threadSignature] pasteboardPropertyListForType:type];
    } else if ([type isEqualToString:NSPasteboardTypeString]) {
        return [NSString stringWithFormat:@"%@\n%@", [self threadTitle], [self threadURLString]];
    } else if ([type isEqualToString:(NSString *)kUTTypeURL]) {
        return [[self threadURL] pasteboardPropertyListForType:(NSString *)kUTTypeURL];
    }
    return nil;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    return 0;
}
@end
