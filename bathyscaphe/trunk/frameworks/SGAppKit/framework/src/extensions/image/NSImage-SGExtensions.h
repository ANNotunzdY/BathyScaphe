//
//  NSImage-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSImage.h>


@interface NSImage(SGExtensionDrawing)
- (void)drawSourceAtPoint:(NSPoint)aPoint;
- (void)drawSourceInRect:(NSRect)aPoint;
- (id)imageBySettingAlphaValue:(CGFloat)delta;
@end


@interface NSImage(SGExtensionsLoad)
+ (id)imageNamed:(NSString *)aName loadFromBundle:(NSBundle *)aBundle;
/*!
 * @method      imageAppNamed:preferUserDirectory:
 * @abstract    ユーザのサポートディレクトリを優先的に探す
 * @discussion  
 * @param name  画像名
 * @result      画像
 */
+ (id)imageAppNamed:(NSString *)aName;
@end
