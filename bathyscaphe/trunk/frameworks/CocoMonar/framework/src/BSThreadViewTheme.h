//
//  BSThreadViewTheme.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/22.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>


@interface BSThreadViewTheme : NSObject<NSCoding, NSCopying> {
	NSString			*m_identifier;
	NSMutableDictionary *m_themeDict;
	NSMutableDictionary *m_additionalThemeDict; // Popup, Reply
    NSMutableDictionary *m_moreAdditionalThemeDict; // Hilite Colors, ID colors
	BOOL				m_popupUsesAltTextColor;
	CGFloat				m_popupBgAlpha;
	CGFloat				m_replyBgAlpha;
    
    BOOL    m_isInternalTheme;
    BOOL m_popupUsesAltHiliteColor;
}

- (id) initWithIdentifier: (NSString *) aString;
- (id) initWithContentsOfFile: (NSString *) filePath;
- (BOOL) writeToFile: (NSString *) filePath atomically: (BOOL) atomically;
- (BOOL)writeToFile:(NSString *)filePath options:(NSUInteger)mask error:(NSError **)errorPtr; // Available in Tenori Tiger.

- (NSString *) identifier;
- (void) setIdentifier: (NSString *) aString;
@end

@interface BSThreadViewTheme(Accessors)
- (NSFont *) baseFont;
- (void) setBaseFont: (NSFont *) font;
- (NSColor *) baseColor;
- (void) setBaseColor: (NSColor *) color;

- (NSColor *) nameColor;
- (void) setNameColor: (NSColor *) color;

- (NSFont *) titleFont;
- (void) setTitleFont: (NSFont *) font;
- (NSColor *) titleColor;
- (void) setTitleColor: (NSColor *) color;

- (NSFont *) hostFont;
- (void) setHostFont: (NSFont *) font;
- (NSColor *) hostColor;
- (void) setHostColor: (NSColor *) color;

- (NSFont *) beFont;
- (void) setBeFont: (NSFont *) font;

- (NSFont *) messageFont;
- (void) setMessageFont: (NSFont *) font;
- (NSColor *) messageColor;
- (void) setMessageColor: (NSColor *) color;

- (NSFont *) AAFont;
- (void) setAAFont: (NSFont *) font;

- (NSFont *) bookmarkFont;
- (void) setBookmarkFont: (NSFont *) font;
- (NSColor *) bookmarkColor;
- (void) setBookmarkColor: (NSColor *) color;

- (NSColor *) linkColor;
- (void) setLinkColor: (NSColor *) color;

- (NSColor *) backgroundColor;
- (void) setBackgroundColor: (NSColor *) color;
@end

@interface BSThreadViewTheme(Additions)
- (NSColor *) popupBackgroundColor;
- (NSColor *) popupBackgroundColorIgnoringAlpha;
- (void) setPopupBackgroundColorIgnoringAlpha: (NSColor *) opaqueColor;
- (CGFloat) popupBackgroundAlphaValue;
- (void) setPopupBackgroundAlphaValue: (CGFloat) alpha;

- (BOOL) popupUsesAlternateTextColor;
- (void) setPopupUsesAlternateTextColor: (BOOL) flag;
- (NSColor *) popupAlternateTextColor;
- (void) setPopupAlternateTextColor: (NSColor *) color;

- (NSFont *) replyFont;
- (void) setReplyFont: (NSFont *) font;
- (NSColor *) replyColor;
- (void) setReplyColor: (NSColor *) color;

- (NSColor *) replyBackgroundColor;
- (NSColor *) replyBackgroundColorIgnoringAlpha;
- (void) setReplyBackgroundColorIgnoringAlpha: (NSColor *) opaqueColor;
- (CGFloat) replyBackgroundAlphaValue;
- (void) setReplyBackgroundAlphaValue: (CGFloat) alpha;
@end


@interface BSThreadViewTheme(DotInvaderAddition)
- (BOOL)isInternalTheme;
- (void)setIsInternalTheme:(BOOL)flag;
@end


@interface BSThreadViewTheme(BabyUniverseDayAddition)
- (NSColor *)hiliteColor;
- (void)setHiliteColor:(NSColor *)color;
- (NSColor *)messageFilteredColor;
- (void)setMessageFilteredColor:(NSColor *)color;

- (BOOL)popupUsesAlternateHiliteColor;
- (void)setPopupUsesAlternateHiliteColor:(BOOL)flag;
- (NSColor *)popupAlternateHiliteColor;
- (void)setPopupAlternateHiliteColor:(NSColor *)color;

- (NSFont *)nameFont;
- (void)setNameFont:(NSFont *)font;

- (NSColor *)informativeIDColor;
- (void)setInformativeIDColor:(NSColor *)color;
- (NSColor *)warningIDColor;
- (void)setWarningIDColor:(NSColor *)color;
- (NSColor *)criticalIDColor;
- (void)setCriticalIDColor:(NSColor *)color;
@end


extern NSString *const kThreadViewThemeDefaultThemeIdentifier;
extern NSString *const kThreadViewThemeCustomThemeIdentifier;
