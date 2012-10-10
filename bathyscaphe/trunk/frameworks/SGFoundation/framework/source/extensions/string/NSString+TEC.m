//
//  NSString+TEC.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/NSString-SGExtensions.h>
#import <SGFoundation/String+Utils.h>
#import <SGFoundation/NSMutableString-SGExtensions.h>
#import <SGFoundation/NSCharacterSet-SGExtensions.h>
#import "UTILKit.h"

// BOM
static const UniChar kBOMUniChar = 0xFEFF;

static TextEncoding GetTextEncodingForNSString(void);
static NSString *AllocateNSStringWithBytesUsingTEC(const UInt8 *srcBuffer, size_t srcLength, TextEncoding theEncoding, BOOL flush);



@implementation NSString(SGExtensionTEC)
// Using TEC
- (id)initWithDataUsingTEC:(NSData *)theData encoding:(TextEncoding)encoding
{
    return AllocateNSStringWithBytesUsingTEC([theData bytes], [theData length], encoding, YES);
}

+ (id)stringWithDataUsingTEC:(NSData *)theData encoding:(TextEncoding)encoding
{
    return [[[self alloc] initWithDataUsingTEC:theData encoding:encoding] autorelease];
}
@end


static TextEncoding GetTextEncodingForNSString(void)
{
    return CreateTextEncoding(kTextEncodingUnicodeDefault, kTextEncodingDefaultVariant, kUnicode16BitFormat);
}

// #if __LP64__
// typedef signed int                      SInt32; // %d
// #else
// typedef signed long                     SInt32; // %ld
// #endif
// typedef SInt32 OSStatus;
// typedef UInt32 CFStringEncoding;
static NSString *AllocateNSStringWithBytesUsingTEC(const UInt8 *srcBuffer, size_t srcLength, TextEncoding theEncoding, BOOL flush)
{

    static TECObjectRef     cachedConverter = NULL;
    static CFStringEncoding cachedEncoding  = kCFStringEncodingInvalidId;
    
    OSStatus            err;
    TECObjectRef        encodingConverter = NULL;
    CFStringEncoding    encoding          = theEncoding;
    CFMutableStringRef  result            = nil;

    // Naki-Wakare
    NSUInteger nw_partialCharLen;
    UInt8 nw_partialCharBuffer[16];

    // Get a Text Encoding Converter for the passed-in encoding.
    if (cachedEncoding == encoding) {
        encodingConverter = cachedConverter;
        TECClearConverterContextInfo(encodingConverter);
        
        cachedConverter = NULL;
        cachedEncoding  = kCFStringEncodingInvalidId;
    } else {
        TextEncoding        toEncoding;
        
        toEncoding = GetTextEncodingForNSString();
        err = TECCreateConverter(
                    &encodingConverter,
                    encoding,
                    toEncoding);
        
        if (err) {
            goto ErrTECCreateConverter;
        }
        TECSetBasicOptions(encodingConverter, kUnicodeForceASCIIRangeMask);
    }
    // Naki-Wakare
    nw_partialCharLen = 0;
    // End Naki-Wakare
    const UInt8     *sourcePointer = srcBuffer;
    ByteCount       sourceLength   = srcLength;

    result = (CFMutableStringRef)[[NSMutableString alloc] init];
    while (1) {
        UniChar     buffer[4096];
        // Naki-Wakare
        ByteCount   bytesRead = 0;
        // End Naki-Wakare
        ByteCount   bytesWritten = 0;
        bool        doingFlush = false;
        
        if (sourceLength == 0) {
            if (!flush) {
                // Done.
                break;
            }
            doingFlush = true;
        }
         
        if (doingFlush) {
            err = TECFlushText(encodingConverter,
                            (UInt8 *)buffer,
// #warning 64BIT: Inspect use of sizeof
// 2010-03-20 tsawada2 検討済
                            sizeof(buffer),
                            &bytesWritten);
            // Naki-Wakare
            nw_partialCharLen = 0;
            // End Naki-Wakare
        } else {
// Naki-Wakare
//          ByteCount   bytesRead = 0;
            bytesRead = 0;
            // End Naki-Wakare
            err = TECConvertText(
                    encodingConverter,
                    sourcePointer,
                    sourceLength,
                    &bytesRead,
                    (UInt8 *)buffer,
// #warning 64BIT: Inspect use of sizeof
// 2010-03-20 tsawada2 検討済
                    sizeof(buffer),
                    &bytesWritten);
            sourcePointer += bytesRead;
            sourceLength  -= bytesRead;
        }
        
        // Appending Decoded Bytes
        if (bytesWritten) {
            NSInteger i;
            NSInteger start = 0;
            NSInteger characterCount = 0;
            
// #warning 64BIT: Check formatting arguments
// 2010-03-20 tsawada2 検証済
            NSCAssert2(bytesWritten % sizeof(UniChar) == 0,
                @"Written Bytes must be sizeof(UniChar)<%u> * X, but was %u",
                sizeof(UniChar),
                bytesWritten);
            
            characterCount = bytesWritten / sizeof(UniChar);
            for (i = 0; i < characterCount; i++) {
                // BOM:
                if (kBOMUniChar == buffer[i]) {
                    if (start != i) {
                        CFStringAppendCharacters(
                            result,
                            (&buffer[start]),
                            i - start);
                    }
                    start = i + 1;
                }
            }
            if (start != characterCount) {
                CFStringAppendCharacters(
                    result,
                    (&buffer[start]),
                    characterCount - start);
            }
        }
        
        // MalformedInput || UndefinedElement
        if (err == kTextMalformedInputErr || err == kTextUndefinedElementErr) {
            // FIXME: Put in FFFD character here?
            TECClearConverterContextInfo(encodingConverter);
            if (sourceLength) {
                sourcePointer += 1;
                sourceLength -= 1;
            }
            err = noErr;
        }
        // Naki-Wakare
        if (nw_partialCharLen > 0) {
            NSUInteger skipLen;
            if (bytesRead < nw_partialCharLen) {
                skipLen = 0;
            } else {
                skipLen = bytesRead - nw_partialCharLen;
            }
            sourcePointer = srcBuffer + skipLen;
            sourceLength = srcLength - skipLen;
            if (err == kTECPartialCharErr) {
                err = noErr;
            }
            nw_partialCharLen = 0;
        }
        // End Naki-Wakare
        if (err == kTECOutputBufferFullStatus) {
            continue;
        }
        // Naki-Wakare
        if (err == kTECPartialCharErr) {
            if (sourceLength < 16) {
                memcpy(nw_partialCharBuffer, sourcePointer, sourceLength);
                nw_partialCharLen = sourceLength;
            }
            sourcePointer += sourceLength;
            sourceLength = 0;
            err = noErr;
        }
        // End Naki-Wakare
        if (err != noErr) {
            goto ErrTextDecoding;
        }
        // Done
        if (doingFlush) {
            break;
        }
    }
    
    return (id)result;

ErrTECCreateConverter:
// #warning 64BIT: Check formatting arguments
// 2010-03-20 tsawada2 検討済
#if __LP64__
    NSLog(@"[TEC] won't convert from text encoding 0x%X, error %d", encoding, err);
#else
    NSLog(@"[TEC] won't convert from text encoding 0x%lX, error %ld", encoding, err);
#endif
    return nil;
ErrTextDecoding:
    [(NSString *)result release]; 
// #warning 64BIT: Check formatting arguments
// 2010-03-20 tsawada2 検討済
#if __LP64__
    NSLog(@"[TEC] text decoding failed with error %d", err);
#else
    NSLog(@"[TEC] text decoding failed with error %ld", err);
#endif
    return nil;
}
