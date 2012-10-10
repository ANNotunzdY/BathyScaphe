//
//  BSBoardListView.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/09/20.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

/*enum {
    BSBoardListRowSizeStyleSmall = 1,
    BSBoardListRowSizeStyleMedium = 2,
    BSBoardListRowSizeStyleLarge = 3,
};
typedef NSInteger BSBoardListRowSizeStyle;*/

@interface BSBoardListView : NSOutlineView {
	// From FileTreeView.h
	BOOL isInstalledTextInputEvent;
	BOOL isFindBegin;
	BOOL isUsingInputWindow;
	NSText *fieldEditor; // No retain/release
	NSTimer *resetTimer;
	EventHandlerRef textInputEventHandler;

//    BSBoardListRowSizeStyle bs_rowSizeStyle;
}

//- (BSBoardListRowSizeStyle)bsRowSizeStyle;
//- (void)setBsRowSizeStyle:(BSBoardListRowSizeStyle)style;
@end

//
// Type-To-Select Support
// Available in Starlight Breaker.
//
// From FileTreeView.m (part of StationaryPalette by 栗田哲郎)
// BathyScaphe プロジェクトに対し、栗田氏のご厚意により特別に FileTreeView.m を
// 修正 BSD ライセンスに基づいて使用する許可を得ています。
//

@interface BSBoardListView(TypeToSelect)
- (void)findForString:(NSString *)aString;
- (void)stopResetTimer;
- (void)insertTextInputSendText:(NSString *)aString;
@end


@interface NSObject(BSBoardListViewTTSDelegate)
- (NSIndexSet *)outlineView:(BSBoardListView *)boardListView findForString:(NSString *)typedString;
@end
