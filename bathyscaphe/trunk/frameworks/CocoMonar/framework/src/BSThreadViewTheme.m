//
//  BSThreadViewTheme.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/22.
//  Copyright 2007-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadViewTheme.h"
#import "UTILAssertion.h"

NSString *const kThreadViewThemeDefaultThemeIdentifier = @"jp.tsawada2.BathyScaphe.ThreadViewTheme.default";
NSString *const kThreadViewThemeCustomThemeIdentifier = @"jp.tsawada2.BathyScaphe.ThreadViewTheme.custom";

@implementation BSThreadViewTheme
- (NSMutableDictionary *) themeDict
{
	return m_themeDict;
}
- (void) setThemeDict: (NSMutableDictionary *) mutableDict
{
	[mutableDict retain];
	[m_themeDict release];
	m_themeDict = mutableDict;
}
- (NSMutableDictionary *) additionalThemeDict
{
	return m_additionalThemeDict;
}
- (void) setAdditionalThemeDict: (NSMutableDictionary *) mutableDict
{
	[mutableDict retain];
	[m_additionalThemeDict release];
	m_additionalThemeDict = mutableDict;
}
- (NSMutableDictionary *)moreAdditionalThemeDict
{
    return m_moreAdditionalThemeDict;
}
- (void)setMoreAdditionalThemeDict:(NSMutableDictionary *)mutableDict
{
    [mutableDict retain];
    [m_moreAdditionalThemeDict release];
    m_moreAdditionalThemeDict = mutableDict;
}

- (NSString *)identifier
{
	return m_identifier;
}
- (void) setIdentifier: (NSString *) aString
{
	[aString retain];
	[m_identifier release];
	m_identifier = aString;
}

- (id) initWithIdentifier: (NSString *) aString
{
	if (self = [super init]) {
		[self setIdentifier:aString];
		[self setThemeDict:[NSMutableDictionary dictionary]];
		[self setAdditionalThemeDict:[NSMutableDictionary dictionary]];
        [self setMoreAdditionalThemeDict:[NSMutableDictionary dictionary]];
		[self setPopupUsesAlternateTextColor:NO];
		[self setPopupBackgroundAlphaValue:1.0];
		[self setReplyBackgroundAlphaValue:1.0];
        [self setIsInternalTheme:NO];
	}
	return self;
}

- (id) initWithContentsOfFile: (NSString *) filePath
{
	if ((self = [NSKeyedUnarchiver unarchiveObjectWithFile: filePath])) {
		[self retain];
	}
	return self;
}

- (BOOL) writeToFile: (NSString *) filePath atomically: (BOOL) atomically
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self];
	return [data writeToFile: filePath atomically: atomically];
}

- (BOOL)writeToFile:(NSString *)filePath options:(NSUInteger)mask error:(NSError **)errorPtr
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
	return [data writeToFile:filePath options:mask error:errorPtr];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *set = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"popupBackgroundColor"]) {
        return [set setByAddingObjectsFromSet:[NSSet setWithObjects:@"popupBackgroundColorIgnoringAlpha", @"popupBackgroundAlphaValue", nil]];
    } else if ([key isEqualToString:@"replyBackgroundColor"]) {
        return [set setByAddingObjectsFromSet:[NSSet setWithObjects:@"replyBackgroundColorIgnoringAlpha", @"replyBackgroundAlphaValue", nil]];
    }
    return set;
}

- (id) init
{
	return [self initWithIdentifier: @""];
}

- (void) dealloc
{
    [m_moreAdditionalThemeDict release];
	[m_additionalThemeDict release];
	[m_themeDict release];
	[m_identifier release];
	[super dealloc];
}

+ (NSMutableDictionary *) defaultAdditionalThemeDict
{
	static NSMutableDictionary *g_template = nil;
	if (g_template == nil) {
		g_template = [[NSMutableDictionary alloc] initWithCapacity: 5];
		[g_template setObject: [NSColor colorWithCalibratedRed: 255.0/255.0 green: 255.0/255.0 blue: 160.0/255.0 alpha: 1.0]
					   forKey: @"popupBackgroundColorBase"];
		[g_template setObject: [NSColor blackColor] forKey: @"popupAlternateTextColor"];
		[g_template setObject: [NSFont systemFontOfSize: 13.0] forKey: @"replyFont"];
		[g_template setObject: [NSColor blackColor] forKey: @"replyColor"];
		[g_template setObject: [NSColor whiteColor] forKey: @"replyBackgroundColorBase"];
	}
	return g_template;
}

+ (NSMutableDictionary *)defaultMoreAdditionalThemeDict
{
    static NSMutableDictionary *g_moreTemplate = nil;
    if (!g_moreTemplate) {
        g_moreTemplate = [[NSMutableDictionary alloc] initWithCapacity:3];
        [g_moreTemplate setObject:[NSColor yellowColor] forKey:@"hiliteColor"];
        [g_moreTemplate setObject:[NSColor yellowColor] forKey:@"popupAlternateHiliteColor"];
        [g_moreTemplate setObject:[NSColor brownColor] forKey:@"messageFilteredColor"];
        [g_moreTemplate setObject:[NSColor blueColor] forKey:@"informativeIDColor"];
        [g_moreTemplate setObject:[NSColor purpleColor] forKey:@"warningIDColor"];
        [g_moreTemplate setObject:[NSColor redColor] forKey:@"criticalIDColor"];
    }
    return g_moreTemplate;
}

- (void)printDebugStringIfNeeded:(NSString *)string
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"BSUserDebugEnabled"]) {
        NSLog(@"*** USER DEBUG *** We should create default value of %@ for old theme archive %@.", string, [self identifier]);
    }
}

- (void)fixEarlySneakyDict:(id)invalidDict fixLevel:(NSUInteger)level
{
    UTILAssertKindOfClass(invalidDict, NSMutableDictionary);
    if (level == 0) {
        [invalidDict setObject:[NSColor brownColor] forKey:@"messageFilteredColor"];
    }
    [invalidDict setObject:[NSColor blueColor] forKey:@"informativeIDColor"];
    [invalidDict setObject:[NSColor purpleColor] forKey:@"warningIDColor"];
    [invalidDict setObject:[NSColor redColor] forKey:@"criticalIDColor"];
    [self setMoreAdditionalThemeDict:invalidDict];
}

- (id)initWithCoder:(NSCoder *)coder
{
	if (self = [super init]) {
		if ([coder allowsKeyedCoding]) {
			[self setIdentifier:[coder decodeObjectForKey:@"identifier"]];
			[self setThemeDict:[coder decodeObjectForKey:@"themeDict"]];
			if (![coder containsValueForKey: @"additionalThemeDict"]) { // old format?
                [self printDebugStringIfNeeded:@"additionalThemeDict"];
				[self setAdditionalThemeDict:[[self class] defaultAdditionalThemeDict]];
				[self setPopupUsesAlternateTextColor:NO];
				[self setPopupBackgroundAlphaValue:0.8];
				[self setReplyBackgroundAlphaValue:1.0];
			} else {
				[self setAdditionalThemeDict: [coder decodeObjectForKey: @"additionalThemeDict"]];
				[self setPopupUsesAlternateTextColor: [coder decodeBoolForKey: @"popupUsesAltTextColor"]];
				[self setPopupBackgroundAlphaValue: [coder decodeDoubleForKey:@"popupBgAlpha"]];
				[self setReplyBackgroundAlphaValue: [coder decodeDoubleForKey:@"replyBgAlpha"]];
			}
            if (![coder containsValueForKey:@"internalTheme"]) { // old format?
                [self printDebugStringIfNeeded:@"internalTheme"];
                [self setIsInternalTheme:NO];
            } else {
                [self setIsInternalTheme:[coder decodeBoolForKey:@"internalTheme"]];
            }
            if (![coder containsValueForKey:@"moreAdditionalThemeDict"]) { // old format?
                [self printDebugStringIfNeeded:@"moreAdditionalThemeDict"];
                [self setMoreAdditionalThemeDict:[[self class] defaultMoreAdditionalThemeDict]];
                [self setPopupUsesAlternateHiliteColor:NO];
            } else {
                id obj = [coder decodeObjectForKey:@"moreAdditionalThemeDict"];
                if (![obj objectForKey:@"messageFilteredColor"]) {
                    [self fixEarlySneakyDict:obj fixLevel:0];
                } else if (![obj objectForKey:@"informativeIDColor"]) {
                    [self fixEarlySneakyDict:obj fixLevel:1];
                } else {
                    [self setMoreAdditionalThemeDict:obj];
                }
                [self setPopupUsesAlternateHiliteColor:[coder decodeBoolForKey:@"popupUsesAltHiliteColor"]];
            }
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	if ([coder allowsKeyedCoding]) {
        [coder encodeBool:m_popupUsesAltHiliteColor forKey:@"popupUsesAltHiliteColor"];
        [coder encodeObject:m_moreAdditionalThemeDict forKey:@"moreAdditionalThemeDict"];
        [coder encodeBool:m_isInternalTheme forKey:@"internalTheme"];
		[coder encodeDouble:m_replyBgAlpha forKey:@"replyBgAlpha"];
		[coder encodeDouble:m_popupBgAlpha forKey:@"popupBgAlpha"];
		[coder encodeBool:m_popupUsesAltTextColor forKey:@"popupUsesAltTextColor"];
		[coder encodeObject:m_additionalThemeDict forKey:@"additionalThemeDict"];
		[coder encodeObject:m_themeDict forKey:@"themeDict"];
		[coder encodeObject:m_identifier forKey:@"identifier"];
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	BSThreadViewTheme *tmpcopy;
	NSString *tmpId = [[self identifier] copyWithZone:zone];
	NSMutableDictionary *tmpDict = [[self themeDict] mutableCopyWithZone:zone];
	NSMutableDictionary *tmpAddDict = [[self additionalThemeDict] mutableCopyWithZone:zone];
    NSMutableDictionary *tmpMoreAddDict = [[self moreAdditionalThemeDict] mutableCopyWithZone:zone];
	
	tmpcopy = [[[self class] allocWithZone:zone] initWithIdentifier:tmpId];
	[tmpcopy setThemeDict:tmpDict];
	[tmpcopy setAdditionalThemeDict:tmpAddDict];
	[tmpcopy setPopupUsesAlternateTextColor:[self popupUsesAlternateTextColor]];
	[tmpcopy setPopupBackgroundAlphaValue:[self popupBackgroundAlphaValue]];
	[tmpcopy setReplyBackgroundAlphaValue:[self replyBackgroundAlphaValue]];
    [tmpcopy setIsInternalTheme:[self isInternalTheme]];
    [tmpcopy setMoreAdditionalThemeDict:tmpMoreAddDict];
    [tmpcopy setPopupUsesAlternateHiliteColor:[self popupUsesAlternateHiliteColor]];

	[tmpId release];
	[tmpDict release];
	[tmpAddDict release];
    [tmpMoreAddDict release];
	
	return tmpcopy;
}
@end


@implementation BSThreadViewTheme(Accessors)
- (NSFont *) baseFont
{
	return [[self themeDict] objectForKey: @"baseFont"];
}
- (void) setBaseFont: (NSFont *) font
{
	[[self themeDict] setObject: font forKey: @"baseFont"];
}

- (NSColor *) baseColor
{
	return [[self themeDict] objectForKey: @"baseColor"];
}
- (void) setBaseColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"baseColor"];
}

- (NSColor *) nameColor
{
	return [[self themeDict] objectForKey: @"nameColor"];
}
- (void) setNameColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"nameColor"];
}

- (NSFont *) titleFont
{
	return [[self themeDict] objectForKey: @"titleFont"];
}
- (void) setTitleFont: (NSFont *) font
{
	[[self themeDict] setObject: font forKey: @"titleFont"];
}
- (NSColor *) titleColor
{
	return [[self themeDict] objectForKey: @"titleColor"];
}
- (void) setTitleColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"titleColor"];
}

- (NSFont *) hostFont
{
	return [[self themeDict] objectForKey: @"hostFont"];
}
- (void) setHostFont: (NSFont *) font
{
	[[self themeDict] setObject: font forKey: @"hostFont"];
}
- (NSColor *) hostColor
{
	return [[self themeDict] objectForKey: @"hostColor"];
}
- (void) setHostColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"hostColor"];
}

- (NSFont *) beFont
{
	return [[self themeDict] objectForKey: @"beFont"];
}
- (void) setBeFont: (NSFont *) font
{
	[[self themeDict] setObject: font forKey: @"beFont"];
}

- (NSFont *) messageFont
{
	return [[self themeDict] objectForKey: @"messageFont"];
}
- (void) setMessageFont: (NSFont *) font
{
	[[self themeDict] setObject: font forKey: @"messageFont"];
}
- (NSColor *) messageColor
{
	return [[self themeDict] objectForKey: @"messageColor"];
}
- (void) setMessageColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"messageColor"];
}

- (NSFont *) AAFont
{
	return [[self themeDict] objectForKey: @"AAFont"];
}
- (void) setAAFont: (NSFont *) font
{
	[[self themeDict] setObject: font forKey: @"AAFont"];
}

- (NSFont *) bookmarkFont
{
	return [[self themeDict] objectForKey: @"bookmarkFont"];
}
- (void) setBookmarkFont: (NSFont *) font
{
	[[self themeDict] setObject: font forKey: @"bookmarkFont"];
}
- (NSColor *) bookmarkColor
{
	return [[self themeDict] objectForKey: @"bookmarkColor"];
}
- (void) setBookmarkColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"bookmarkColor"];
}

- (NSColor *) linkColor
{
	return [[self themeDict] objectForKey: @"linkColor"];
}
- (void) setLinkColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"linkColor"];
}

- (NSColor *) backgroundColor
{
	return [[self themeDict] objectForKey: @"backgroundColor"];
}
- (void) setBackgroundColor: (NSColor *) color
{
	[[self themeDict] setObject: color forKey: @"backgroundColor"];
}
@end

@implementation BSThreadViewTheme(Additions)
- (NSColor *) popupBackgroundColor
{
	return [[self popupBackgroundColorIgnoringAlpha] colorWithAlphaComponent: [self popupBackgroundAlphaValue]];
}
- (NSColor *) popupBackgroundColorIgnoringAlpha;
{
	return [[self additionalThemeDict] objectForKey: @"popupBackgroundColorBase"];
}
- (void) setPopupBackgroundColorIgnoringAlpha: (NSColor *) opaqueColor;
{
	[[self additionalThemeDict] setObject: opaqueColor forKey: @"popupBackgroundColorBase"];
}
- (CGFloat) popupBackgroundAlphaValue
{
	return m_popupBgAlpha;
}
- (void) setPopupBackgroundAlphaValue: (CGFloat) alpha
{
	m_popupBgAlpha = alpha;
}

- (BOOL) popupUsesAlternateTextColor
{
	return m_popupUsesAltTextColor;
}
- (void) setPopupUsesAlternateTextColor: (BOOL) flag
{
	m_popupUsesAltTextColor = flag;
}
- (NSColor *) popupAlternateTextColor;
{
	return [[self additionalThemeDict] objectForKey: @"popupAlternateTextColor"];
}
- (void) setPopupAlternateTextColor: (NSColor *) color;
{
	[[self additionalThemeDict] setObject: color forKey: @"popupAlternateTextColor"];
}

- (NSFont *) replyFont
{
	return [[self additionalThemeDict] objectForKey: @"replyFont"];
}
- (void) setReplyFont: (NSFont *) font
{
	[[self additionalThemeDict] setObject: font forKey: @"replyFont"];
}
- (NSColor *) replyColor;
{
	return [[self additionalThemeDict] objectForKey: @"replyColor"];
}
- (void) setReplyColor: (NSColor *) color;
{
	[[self additionalThemeDict] setObject: color forKey: @"replyColor"];
}

- (NSColor *) replyBackgroundColor
{
	return [[self replyBackgroundColorIgnoringAlpha] colorWithAlphaComponent: [self replyBackgroundAlphaValue]];
}
- (NSColor *) replyBackgroundColorIgnoringAlpha;
{
	return [[self additionalThemeDict] objectForKey: @"replyBackgroundColorBase"];
}
- (void) setReplyBackgroundColorIgnoringAlpha: (NSColor *) opaqueColor;
{
	[[self additionalThemeDict] setObject: opaqueColor forKey: @"replyBackgroundColorBase"];
}
- (CGFloat) replyBackgroundAlphaValue
{
	return m_replyBgAlpha;
}
- (void) setReplyBackgroundAlphaValue: (CGFloat) alpha
{
	m_replyBgAlpha = alpha;
}
@end


@implementation BSThreadViewTheme(DotInvaderAddition)
- (BOOL)isInternalTheme
{
    return m_isInternalTheme;
}

- (void)setIsInternalTheme:(BOOL)flag
{
    m_isInternalTheme = flag;
}
@end


@implementation BSThreadViewTheme(BabyUniverseDayAddition)
- (NSColor *)hiliteColor
{
    return [[self moreAdditionalThemeDict] objectForKey:@"hiliteColor"];
}

- (void)setHiliteColor:(NSColor *)color
{
    [[self moreAdditionalThemeDict] setObject:color forKey:@"hiliteColor"];
}

- (NSColor *)messageFilteredColor
{
    return [[self moreAdditionalThemeDict] objectForKey:@"messageFilteredColor"];
}

- (void)setMessageFilteredColor:(NSColor *)color
{
    [[self moreAdditionalThemeDict] setObject:color forKey:@"messageFilteredColor"];
}

- (BOOL)popupUsesAlternateHiliteColor
{
    return m_popupUsesAltHiliteColor;
}

- (void)setPopupUsesAlternateHiliteColor:(BOOL)flag
{
    m_popupUsesAltHiliteColor = flag;
}

- (NSColor *)popupAlternateHiliteColor
{
    return [[self moreAdditionalThemeDict] objectForKey:@"popupAlternateHiliteColor"];
}

- (void)setPopupAlternateHiliteColor:(NSColor *)color
{
    [[self moreAdditionalThemeDict] setObject:color forKey:@"popupAlternateHiliteColor"];
}

- (NSFont *)nameFont
{
    id tmp = [[self moreAdditionalThemeDict] objectForKey:@"nameFont"];
    return tmp ?: [self baseFont];
}

- (void)setNameFont:(NSFont *)font
{
    [[self moreAdditionalThemeDict] setObject:font forKey:@"nameFont"];
}

- (NSColor *)informativeIDColor
{
    return [[self moreAdditionalThemeDict] objectForKey:@"informativeIDColor"];
}

- (void)setInformativeIDColor:(NSColor *)color
{
    [[self moreAdditionalThemeDict] setObject:color forKey:@"informativeIDColor"];
}

- (NSColor *)warningIDColor
{
    return [[self moreAdditionalThemeDict] objectForKey:@"warningIDColor"];
}

- (void)setWarningIDColor:(NSColor *)color
{
    [[self moreAdditionalThemeDict] setObject:color forKey:@"warningIDColor"];
}

- (NSColor *)criticalIDColor
{
    return [[self moreAdditionalThemeDict] objectForKey:@"criticalIDColor"];
}

- (void)setCriticalIDColor:(NSColor *)color
{
    [[self moreAdditionalThemeDict] setObject:color forKey:@"criticalIDColor"];
}
@end
