//
//  NSImage-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSImage-SGExtensions.h"
#import <SGFoundation/NSBundle-SGExtensions.h>


@implementation NSImage(SGExtensionDrawing)
- (void)drawSourceAtPoint:(NSPoint)aPoint
{
	[self drawAtPoint:aPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawSourceInRect:(NSRect)aRect
{
	[self drawInRect:aRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (id)imageBySettingAlphaValue:(CGFloat)delta
{
	NSImage *newImage_;

	newImage_ = [[[self class] allocWithZone:[self zone]] initWithSize:[self size]];
	[newImage_ lockFocus];
    [self drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:delta];
	[newImage_ unlockFocus];

	return [newImage_ autorelease];
}
@end


@implementation NSImage(SGExtensionsLoad)
+ (id)imageNamed:(NSString *)aName loadFromBundle:(NSBundle *)aBundle
{
    NSImage *image;
    NSString *path;
    image = [self imageNamed:aName];
    if (image) {
        return image;
    }
    path = [aBundle pathForImageResource:aName];
    if (!path) {
        return nil;
    }
    image = [[[self alloc] initWithContentsOfFile:path] autorelease];
    return image;
}

+ (id)imageAppNamed:(NSString *)aName
{
	static NSMutableDictionary *userImageCache;
	NSImage *image_;
	NSString *filepath_;

	if (!aName) {
        return nil;
    }
	if (!userImageCache) {
		userImageCache = [[NSMutableDictionary alloc] init];
	}
	image_ = [userImageCache objectForKey:aName];
	if (image_) {
        return image_;
	}
	filepath_ = [[NSBundle applicationSpecificBundle] pathForImageResource:aName];
	if (filepath_) {
		image_ = [[self alloc] initWithContentsOfFile:filepath_];
        if (image_ && [aName hasSuffix:@"Template"]) {
            [image_ setTemplate:YES];
        }
	}
	if (!image_) {
		image_ = [[self imageNamed:aName] retain];
	}
	if (!image_) {
		return nil;
	}
	[userImageCache setObject:image_ forKey:aName];
	[image_ release];

	return image_;
}
@end
