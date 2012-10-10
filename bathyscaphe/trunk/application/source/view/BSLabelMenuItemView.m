//
//  BSLabelMenuView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/10/03.
//  Copyright 2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLabelMenuItemView.h"
#import "BSLabelManager.h"

/*
#define LABEL_CODE_0             (0x01) //  1
#define LABEL_CODE_1             (0x02) //  2
#define LABEL_CODE_2             (0x04) //  4
#define LABEL_CODE_3             (0x08) //  8
#define LABEL_CODE_4             (0x10) // 16
#define LABEL_CODE_5             (0x20) // 32
#define LABEL_CODE_6             (0x40) // 64
#define LABEL_CODE_7             (0x80) //128
*/
@implementation BSLabelMenuItemView
- (UInt32)maskForCode:(NSInteger)code
{
    if (code == 0) {
        return 1;
    }
    return pow(2, code);
}

- (BOOL)isSelected:(NSInteger)code
{
    UInt32 mask = [self maskForCode:code];
    return ((selectedLabels & mask) > 0);
}
    
- (void)setSelected:(BOOL)isLabeled forLabel:(NSInteger)code clearOthers:(BOOL)clear
{
    if (clear) {
        selectedLabels = 0;
        if (!isLabeled) { // code ラベルを剥がし、かつ他のラベルもすべて剥がす <=> どのラベルも（ラベル「無し」さえも）未選択
            return;
        }
    }
    UInt32 mask = [self maskForCode:code];
    if (isLabeled) {
        selectedLabels |= mask;
    } else {
        selectedLabels  = selectedLabels&~mask;
    }
}

- (void)deselectAll
{
    selectedLabels = 0;
}

- (NSInteger)clickedLabel
{
    return cursorInsideLabelIcon;
}

- (BOOL)isEnabled
{
    return m_isEnabled;
}

- (void)setEnabled:(BOOL)flag
{
    m_isEnabled = flag;
}

- (id)target
{
    return m_target;
}

- (void)setTarget:(id)obj
{
    m_target = obj;
}

- (void)setupTrackingAreas
{
    NSTrackingAreaOptions options = (NSTrackingEnabledDuringMouseDrag|
                                     NSTrackingMouseEnteredAndExited|
                                     NSTrackingActiveInActiveApp|
                                     NSTrackingActiveAlways);		
    NSInteger labelCode;
    for (labelCode = 0; labelCode < 8; labelCode++) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:labelCode] forKey:@"LabelCode"];
        NSTrackingArea *ta = [[NSTrackingArea alloc] initWithRect:[[self viewWithTag:labelCode] frame] options:options owner:self userInfo:userInfo];
        [self addTrackingArea:ta];
        [ta release];
    }
}

- (void)awakeFromNib
{
    selectedLabels = 0;
    cursorInsideLabelIcon = NSNotFound;
    m_isEnabled = NO;

    [self setupTrackingAreas];
}

- (NSInteger)trackerIDFromDict:(NSDictionary *)dict
{
	id whichTracker = [dict objectForKey:@"LabelCode"];
	return [whichTracker integerValue];
}

- (void)mouseEntered:(NSEvent *)event
{
    if (![self isEnabled]) {
        return;
    }
    NSInteger tmp = [self trackerIDFromDict:[event userData]];
	cursorInsideLabelIcon = tmp;
    
	[self setNeedsDisplay:YES];

    if (tmp > 0) {
        [(NSTextField *)[self viewWithTag:-2] setStringValue:[[[BSLabelManager defaultManager] displayNames] objectAtIndex:(tmp - 1)]];
    } else {
        [(NSTextField *)[self viewWithTag:-2] setStringValue:@""];
    }
}

- (void)mouseExited:(NSEvent *)event
{
    if (![self isEnabled]) {
        return;
    }
	cursorInsideLabelIcon = NSNotFound;
    
	[self setNeedsDisplay:YES];
    [(NSTextField *)[self viewWithTag:-2] setStringValue:@""];
}

- (void)mouseUp:(NSEvent *)event
{
    if (![self isEnabled]) {
        return;
    }

	[[[self enclosingMenuItem] menu] cancelTracking];
    if (cursorInsideLabelIcon == NSNotFound) {
        return;
    } else {
        (void)[NSApp sendAction:@selector(toggleLabeledThread:) to:[self target] from:self];
        cursorInsideLabelIcon = NSNotFound;
    }
	[self setNeedsDisplay:YES];
}

- (void)viewDidMoveToWindow
{
    if ([self window]) {
        id target = [NSApp targetForAction:@selector(toggleLabeledThread:) to:[self target] from:self];
        if ([target conformsToProtocol:@protocol(BSLabelMenuItemViewValidation)]) {
            BOOL flag = [target validateLabelMenuItem:self];
            [self setEnabled:flag];
        } else {
            selectedLabels = 0;
            [self setEnabled:NO];
        }
        [(NSTextField *)[self viewWithTag:11] setTextColor:([self isEnabled] ? [NSColor controlTextColor] : [NSColor disabledControlTextColor])];
        [(NSTextField *)[self viewWithTag:-2] setStringValue:@""];
        NSInteger i;
        NSString *nameFormat = [self isEnabled] ? @"LabelIcon%ld" : @"LabelIconDisabled%ld";
        for (i = 1; i < 8; i++) {
            [(NSImageView *)[self viewWithTag:i] setImage:[NSImage imageNamed:[NSString stringWithFormat:nameFormat, (long)i]]];
        }
    }
}

-(void)drawRect:(NSRect)rect
{
	NSInteger labelCode;
    for (labelCode = 0; labelCode < 8; labelCode++) {
        if (cursorInsideLabelIcon == labelCode) {
            [[NSColor secondarySelectedControlColor] set];
            NSRectFill([[self viewWithTag:labelCode] frame]);
            [[NSColor gridColor] set];
            NSFrameRectWithWidth(NSInsetRect([[self viewWithTag:labelCode] frame], -1, -1), 1.5);
        }

        if ([self isSelected:labelCode] && [self isEnabled]) {
            [[NSColor gridColor] set];
            NSFrameRectWithWidth(NSInsetRect([[self viewWithTag:labelCode] frame], -1, -1), 1.5);
        }
    }
}
@end
