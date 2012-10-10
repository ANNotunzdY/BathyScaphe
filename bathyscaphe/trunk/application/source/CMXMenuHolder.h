//
//  CMXMenuHolder.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/11/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSLabelMenuItemView;

@interface CMXMenuHolder : NSObject {
    IBOutlet NSMenu *_menu;
}
+ (NSMenu *)menuFromBundle:(NSBundle *)bundle nibName:(NSString *)nibName;
- (id)initWithBundle:(NSBundle *)bundle nibName:(NSString *)nibName;
- (NSMenu *)menu;
@end


@interface BSLabelMenuItemHolder : NSObject {
    IBOutlet BSLabelMenuItemView *m_labelMenuItemView;
}
+ (BSLabelMenuItemView *)labelMenuItemView;
- (BSLabelMenuItemView *)labelMenuItemView;
@end
