//
//  BSIPIPathTransformer.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/07/10.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIPathTransformer.h"


@implementation BSIPIPathTransformer
+ (Class)transformedValueClass
{
    return [NSString class];
}
 
+ (BOOL)allowsReverseTransformation
{
    return NO;
}
 
- (id)transformedValue:(id)beforeObject
{
    if (!beforeObject) {
        return nil;
    }

    if ([beforeObject isKindOfClass:[NSURL class]]) {
        beforeObject = [beforeObject absoluteString];
    }

    return [beforeObject lastPathComponent];
}
@end


@implementation BSIPIImageIgnoringDPITransformer
+ (Class)transformedValueClass
{
    return [NSImage class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)beforeObject
{
    if (!beforeObject || ![beforeObject isKindOfClass:[NSString class]]) {
        return nil;
    }

    NSImage *image_ = [[NSImage alloc] initWithContentsOfFile:beforeObject];
    if (!image_) {
        return nil;
    }

//    NSImageRep *tmp_ = [image_ bestRepresentationForDevice:nil]; // 10.6 から Deprecated なので…
    NSImageRep *tmp_ = [[image_ representations] lastObject]; // 暫定 -bestRepresentationForRect:context:hints: はあるけど、forRect: と言われても…
    if ([tmp_ isKindOfClass:[NSPDFImageRep class]]) {
        // PDF crop box
        NSRect bounds = [(NSPDFImageRep *)tmp_ bounds];
        NSImage *newPDFImage = [[NSImage alloc] initWithSize:bounds.size];

        [newPDFImage lockFocus];

        // 背景を白くする
        [[NSColor whiteColor] set];
        NSRectFill(bounds);

        // もとの PDF 内容を合成
        NSRect imageRect;
        imageRect.origin = NSZeroPoint;
        imageRect.size = [image_ size];
        [image_ drawAtPoint:NSZeroPoint fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];

        [newPDFImage unlockFocus];
        [image_ release];
        return [newPDFImage autorelease];
    }

    CGFloat wi, he;
    NSSize newSize;
    wi = [tmp_ pixelsWide];
    he = [tmp_ pixelsHigh];
    newSize = NSMakeSize(wi, he);
    // ignore DPI
    [tmp_ setSize:newSize];

    NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
    [newImage addRepresentation:tmp_];
    [image_ release];
    return [newImage autorelease];
}
@end
