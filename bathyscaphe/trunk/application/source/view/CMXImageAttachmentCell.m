//
//  CMXImageAttachmentCell.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/29. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMXImageAttachmentCell.h"


@implementation CMXImageAttachmentCell
- (NSImageAlignment)imageAlignment
{
    return bs_imageAlignment;
}
- (void)setImageAlignment:(NSImageAlignment)anImageAlignment
{
    bs_imageAlignment = anImageAlignment;
}

#pragma mark Overrides
- (NSRect)cellFrameForTextContainer:(NSTextContainer *)textContainer
               proposedLineFragment:(NSRect)lineFrag
                      glyphPosition:(NSPoint)position
                     characterIndex:(NSUInteger)charIndex
{
    NSRect cellFrame_;
    NSSize cellSize_;
    CGFloat yOffset_;
    
    cellSize_ = [self cellSize];
    cellFrame_ = [super cellFrameForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];

    yOffset_ = NSHeight(lineFrag) - cellSize_.height;

    switch ([self imageAlignment]) {
    case NSImageAlignCenter:
        yOffset_ /= 2;
        break;
    case NSImageAlignTop:
    case NSImageAlignTopLeft:
    case NSImageAlignTopRight:
        yOffset_ = 0;
        break;
    case NSImageAlignBottom:
    case NSImageAlignBottomLeft:
    case NSImageAlignBottomRight:
        if (yOffset_ > 0) yOffset_ = 0;
        break;
    case NSImageAlignLeft:
    case NSImageAlignRight:
    default:
        yOffset_ = 0;
        break;
    }
    
    cellFrame_.origin.y += yOffset_;

    return cellFrame_;
}

- (BOOL)wantsToTrackMouse
{
    return NO;
}
@end
