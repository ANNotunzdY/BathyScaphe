//
//  BSLastUpdatedHeaderCell.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/11/19.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLastUpdatedHeaderCell.h"
#import <SGAppKit/SGAppKit.h>

@implementation BSLastUpdatedHeaderCell
- (id)initWithImageNameBase:(NSString *)imageNameBase
{
    if (self = [super initImageCell:nil]) {
        NSString *imageNameLeft = [imageNameBase stringByAppendingString:@"Left"];
        NSString *imageNameMiddle = [imageNameBase stringByAppendingString:@"Middle"];
        NSString *imageNameRight = [imageNameBase stringByAppendingString:@"Right"];
        
        NSImage *leftImage = [NSImage imageAppNamed:imageNameLeft];
        if (!leftImage) {
            [self autorelease];
            return nil;
        }

        m_leftImage = [leftImage retain];
        m_middleImage = [[NSImage imageAppNamed:imageNameMiddle] retain];
        m_rightImage = [[NSImage imageAppNamed:imageNameRight] retain];
        
        [self setImage:leftImage];
    }
    return self;
}

- (void)dealloc
{
    [m_leftImage release];
    [m_middleImage release];
    [m_rightImage release];
    [super dealloc];
}

- (NSRect)cellFrameForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(NSUInteger)charIndex
{
    NSRect originalRect = [super cellFrameForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];

    NSTextView *textView = [textContainer textView];
    CGFloat textViewWidth = NSWidth([textView frame]);
    CGFloat imageWidth = textViewWidth - 10;
    CGFloat imageHeight = originalRect.size.height;
    
    return NSMakeRect(originalRect.origin.x, originalRect.origin.y, imageWidth, imageHeight);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView
{
    NSDrawThreePartImage(cellFrame, m_leftImage, m_middleImage, m_rightImage, NO, NSCompositeSourceOver, 1.0, [aView isFlipped]);
}

- (BOOL)wantsToTrackMouse
{
    return NO;
}
@end
