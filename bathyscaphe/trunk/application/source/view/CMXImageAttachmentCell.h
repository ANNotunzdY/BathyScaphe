//
//  CMXImageAttachmentCell.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/29. 
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


/*!
 * @class       CMXImageAttachmentCell
 * @discussion  メールアイコンおよび新着位置画像
 */
@interface CMXImageAttachmentCell : NSTextAttachmentCell
{
    @private
    NSImageAlignment bs_imageAlignment;
}
- (NSImageAlignment)imageAlignment;
- (void)setImageAlignment:(NSImageAlignment)anImageAlignment;
@end
