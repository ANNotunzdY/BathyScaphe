//
//  CMRToolbarDelegateImp.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/05.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRToolbarDelegateImp_p.h"

static NSString *const st_pIndicatorItemIdentifier		= @"progressIndicator";

static NSString *const st_localizableStringsTableName	= @"ToolbarItems";


@implementation CMRToolbarDelegateImp
- (void)dealloc
{
	[m_itemDictionary release];
	[super dealloc];
}

+ (NSString *)localizableStringsTableName
{
	return st_localizableStringsTableName;
}

#pragma mark CMRToolbarDelegate Protocol
- (NSString *)identifier
{
	return nil;
}

- (NSToolbarItem *)itemForItemIdentifier:(NSString *)anIdentifier
{
	if ([[self unsupportedItemsArray] containsObject:anIdentifier]) return nil;
	return [self itemForItemIdentifier:anIdentifier itemClass:[NSToolbarItem class]];
}

- (void)attachToolbarWithWindow:(NSWindow *)aWindow
{
	NSToolbar		*toolbar_;
	
	UTILAssertNotNilArgument(aWindow, @"Window");
	
	toolbar_ = [[NSToolbar alloc] initWithIdentifier:[self identifier]];

	[self configureToolbar:toolbar_];
	[self initializeToolbarItems:aWindow];
	[toolbar_ setDelegate:self];

	[aWindow setToolbar:toolbar_];
	[toolbar_ release];
}
@end


@implementation CMRToolbarDelegateImp(Private)
- (NSToolbarItem *)itemForItemIdentifier:(NSString *)anIdentifier itemClass:(Class)aClass
{
	NSToolbarItem		*item_;
	item_ = [[self itemDictionary] objectForKey:anIdentifier];
	if(!item_){
		item_ = [[aClass alloc] initWithItemIdentifier:anIdentifier];
		[[self itemDictionary] setObject:item_ forKey:anIdentifier];
		[item_ release];
	}
	return item_;
}

- (void)setupControl:(NSControl *)viewItem onItem:(NSToolbarItem *)tbItem action:(SEL)action target:(NSWindowController *)wc
{
    NSSize itemSize;
    [viewItem retain];
    [viewItem removeFromSuperviewWithoutNeedingDisplay];
    [viewItem setTarget:wc];
    [viewItem setAction:action];
    [tbItem setView:viewItem];
    [viewItem release];
    
    itemSize = [viewItem bounds].size;
    [tbItem setMinSize:itemSize];
    [tbItem setMaxSize:itemSize];
    
    if ([tbItem isKindOfClass:[BSSegmentedControlTbItem class]]) {
        [(BSSegmentedControlTbItem *)tbItem setDelegate:wc];
    }
}

- (NSToolbarItem *)appendToolbarItemWithClass:(Class) aClass
							   itemIdentifier:(NSString *)itemIdentifier
							localizedLabelKey:(NSString *)label
					 localizedPaletteLabelKey:(NSString *)paletteLabel
						  localizedToolTipKey:(NSString *)toolTip
									   action:(SEL)action
									   target:(id)target
{
	NSToolbarItem		*item_;
	
	item_ = [self itemForItemIdentifier:itemIdentifier itemClass:aClass];
	[item_ setLabel:[self localizedString:label]];
	[item_ setPaletteLabel:[self localizedString:paletteLabel]];
	[item_ setToolTip:[self localizedString:toolTip]];
	[item_ setAction:action];
	[item_ setTarget:target];
	return item_;
}

- (NSToolbarItem *)appendToolbarItemWithItemIdentifier:(NSString *)itemIdentifier
									 localizedLabelKey:(NSString *)label
							  localizedPaletteLabelKey:(NSString *)paletteLabel
								   localizedToolTipKey:(NSString *)toolTip
												action:(SEL)action
												target:(id)target
{
	return [self appendToolbarItemWithClass:[NSToolbarItem class]
							 itemIdentifier:itemIdentifier
						  localizedLabelKey:label
				   localizedPaletteLabelKey:paletteLabel
						localizedToolTipKey:toolTip
									 action:action
									 target:target];
}

- (void)customizeSegmentedControlIcons:(NSSegmentedControl *)control
{
    NSInteger count = [control segmentCount];
    for (NSInteger i = 0; i < count; i++) {
        NSString *imageName = [[control imageForSegment:i] name];
        if (imageName) {
            NSBundle *appSupport = [NSBundle applicationSpecificBundle];
            NSString *altImageFilePath = [appSupport pathForImageResource:imageName];
            if (altImageFilePath) {
                NSImage *altImage = [[NSImage alloc] initWithContentsOfFile:altImageFilePath];
                [altImage setTemplate:YES];
                [control setImage:altImage forSegment:i];
                [altImage release];
            }
        }
    }
}

- (id)appendButton:(NSButton *)button
    withIdentifier:(NSString *)identifier
             label:(NSString *)label
      paletteLabel:(NSString *)paletteLabel
           toolTip:(NSString *)toolTip
            action:(SEL)action
      customizable:(BOOL)iconCustomizable
{
    NSToolbarItem *item = [self itemForItemIdentifier:identifier itemClass:[BSNSControlToolbarItem class]];
    NSString *localizedLabel = [self localizedString:label];
    [item setLabel:localizedLabel];
    [item setPaletteLabel:[self localizedString:(paletteLabel ?: label)]];
    [item setToolTip:[self localizedString:toolTip]];

    [button retain];

    // カスタムアイコンにすり替える
    if (iconCustomizable) {
        NSString *imageName = [[button image] name];
        if (imageName) {
            NSBundle *appSupport = [NSBundle applicationSpecificBundle];
            NSString *altImageFilePath = [appSupport pathForImageResource:imageName];
            if (altImageFilePath) {
                NSImage *altImage = [[NSImage alloc] initWithContentsOfFile:altImageFilePath];
                [altImage setTemplate:YES];
                [button setImage:altImage];
                [altImage release];
            }
        }
    }

    [button removeFromSuperviewWithoutNeedingDisplay];
    [item setView:button];
    // 10.5 以降、-setMinSize:, -setMaxSize を呼ばなければ元々の -view のサイズが使われる
    [button release];

    // -setAction:, -setTarget: は -view に転送される
    [item setAction:action];
    [item setTarget:nil];
    
    // view item では「テキストのみ表示」のときのための -menuFormRepresentation が必須
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:localizedLabel action:action keyEquivalent:@""];
    [menuItem setTarget:nil];
    [item setMenuFormRepresentation:menuItem];
    [menuItem release];

    return item;
}

- (NSArray *)unsupportedItemsArray
{
	static NSArray *cachedUnsupportedItems = nil;
	if (!cachedUnsupportedItems) {
		cachedUnsupportedItems = [[NSArray alloc] initWithObjects:st_pIndicatorItemIdentifier, nil];
	}
	return cachedUnsupportedItems;
}

- (NSMutableDictionary *)itemDictionary
{
	if(!m_itemDictionary) {
		m_itemDictionary = [[NSMutableDictionary alloc] init];
	}
	return m_itemDictionary;
}
@end


@implementation CMRToolbarDelegateImp(Protected)
- (void)initializeToolbarItems:(NSWindow *)aWindow
{
	UTILAbstractMethodInvoked;
}

- (void)configureToolbar:(NSToolbar *)aToolbar
{
	[aToolbar setAllowsUserCustomization:YES];
	[aToolbar setAutosavesConfiguration:YES];
}
@end


@implementation CMRToolbarDelegateImp(NSToolbarDelegate)
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemId willBeInsertedIntoToolbar:(BOOL)willBeInserted
{
	UTILAssertNotNilArgument(toolbar, @"Toolbar");
	UTILAssertNotNilArgument(itemId, @"itemIdentifier");
	
	if (![[self identifier] isEqualToString:[toolbar identifier]]) {
        return nil;
    }

	return [self itemForItemIdentifier:itemId];
}
@end
