//
//  BSLastUpdatedHeaderCell.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/11/19.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSLastUpdatedHeaderCell : NSTextAttachmentCell {
    NSImage *m_leftImage;
    NSImage *m_middleImage;
    NSImage *m_rightImage;
}

- (id)initWithImageNameBase:(NSString *)imageNameBase;

@end
