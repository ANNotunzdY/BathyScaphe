//
//  SGContainerTableView.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/08.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface SGContainerTableView : NSView {
	@private
	id				m_dataSource;
	NSUInteger	m_gridStyleMask;
	NSColor			*m_bgColor;
}

- (id)dataSource;
- (void)setDataSource:(id)aDataSource;

- (NSUInteger)gridStyleMask;
- (void)setGridStyleMask:(NSUInteger)gridType;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)aColor;

- (void)reloadData;

- (NSInteger)numberOfRows;
- (NSRect)rectOfRow:(NSInteger)rowIndex;

- (void)scrollRowToVisible:(NSInteger)rowIndex;

- (void)drawBackgroundInClipRect:(NSRect)clipRect;
- (void)drawGridInClipRect:(NSRect)aRect;
@end


@interface NSObject(SGContainerTableViewDataSource)
- (NSInteger)numberOfRowsInContainerTableView:(SGContainerTableView *)aContainerTableView;
- (NSView *)containerTableView:(SGContainerTableView *)aContainerTableView viewAtRow:(NSInteger)rowIndex;
@end
