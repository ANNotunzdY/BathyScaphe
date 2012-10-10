//:SGContextHelpPanel.m
// encoding="UTF-8"

#import "SGContextHelpPanel.h"
#import "CMXPopUpWindowController.h"


@implementation NSWindow(PopUpWindow)
- (BOOL)isPopUpWindow
{
	return NO;
}
@end


@implementation SGContextHelpPanel
- (id<SGContextHelpPanelDelegate>)delegate
{
    return (id<SGContextHelpPanelDelegate>)[super delegate];
}

- (void)setDelegate:(id<SGContextHelpPanelDelegate>)aDelegate
{
    [super setDelegate:aDelegate];
}

- (NSColor *)sizedRoundedBackground:(NSColor *)baseColor
{
    NSImage *bg = [[NSImage alloc] initWithSize:[self frame].size];
    [bg lockFocus];
    
    // Make background path
	NSRect bgRect = NSMakeRect(0, 0, [bg size].width, [bg size].height);
    NSInteger minX = NSMinX(bgRect);
    NSInteger midX = NSMidX(bgRect);
    NSInteger maxX = NSMaxX(bgRect);
    NSInteger minY = NSMinY(bgRect);
    NSInteger midY = NSMidY(bgRect);
    NSInteger maxY = NSMaxY(bgRect);
    CGFloat radius = 6;
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) 
                                     toPoint:NSMakePoint(maxX, midY) 
                                      radius:radius];
    
	// 右上ゾーン
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) 
                                     toPoint:NSMakePoint(midX, maxY) 
                                      radius:radius];
	// 左上ゾーン
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) 
                                     toPoint:NSMakePoint(minX, midY) 
                                      radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:bgRect.origin 
                                     toPoint:NSMakePoint(midX, minY) 
                                      radius:radius];
    [bgPath closePath];
    
    // Composite background color into bg
    [baseColor set];
    [bgPath fill];
    
    [bg unlockFocus];
    
    return [NSColor colorWithPatternImage:[bg autorelease]];
}

- (void)updateBackgroundColorWithRoundedCorner:(NSColor *)bgColor
{
    NSColor *color = [self sizedRoundedBackground:bgColor];
    [self setBackgroundColor:color];
}

- (BOOL)isPopUpWindow
{
	return YES;
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (BOOL)canBecomeMainWindow
{
	return NO;
}

- (BOOL)makeFirstResponder:(NSResponder *)responder
{
    id<SGContextHelpPanelDelegate> delegate = [self delegate];
    if (delegate && [delegate respondsToSelector:@selector(contextHelpPanel:firstResponderWillChange:)]) {
        [delegate contextHelpPanel:self firstResponderWillChange:responder];
    }
    return [super makeFirstResponder:responder];
}

- (NSWindow *)ownerWindow
{
	CMXPopUpWindowController *c;
	
	c = [self windowController];
	if (![c isKindOfClass:[CMXPopUpWindowController class]]) {
		return nil;
	}
	return [c ownerWindow];
}

- (void)performMiniaturize:(id)sender
{
	[[self ownerWindow] performMiniaturize:sender];
}
- (void)performClose:(id)sender
{
	[[self ownerWindow] performClose:sender];
}

/*
	2005-07-12 tsawada2<tsawada2@users.sourceforge.jp>
	NSPanel では、 Esc キーが「パネルを閉じる」ショートカットとして動作している。
	ポップアップをクリックしてから Esc キーを押すと親ウインドウも一緒に閉じる問題については、
	上のメソッドで performClose: をパスしているのが原因であるから、それをやめれば直る。
	しかし、そもそも「Esc キーでポップアップを閉じたい」わけではないので（閉じたい人もいるかも？）、
	Esc キーのイベント自体をここでブロックして、無効にすることにする。
*/
- (void)cancelOperation:(id)sender
{
	//NSLog(@"Escape key has been blocked.");
}
@end
