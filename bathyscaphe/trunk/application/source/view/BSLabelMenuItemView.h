//
//  BSLabelMenuView.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/10/03.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSLabelMenuItemView : NSView {
    @private
    UInt32 selectedLabels;
    NSInteger cursorInsideLabelIcon;
    BOOL m_isEnabled;
    id m_target; // no retain / release
}

- (BOOL)isSelected:(NSInteger)code;
- (void)setSelected:(BOOL)isLabeled forLabel:(NSInteger)code clearOthers:(BOOL)clear;
- (void)deselectAll;
- (NSInteger)clickedLabel;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

- (id)target;
- (void)setTarget:(id)obj;
@end


@protocol BSLabelMenuItemViewValidation
- (BOOL)validateLabelMenuItem:(BSLabelMenuItemView *)item;
@end
