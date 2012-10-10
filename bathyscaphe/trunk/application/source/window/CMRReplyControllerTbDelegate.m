//
//  CMRReplyControllerTbDelegate.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/05.
//  Copyright 2005-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRReplyControllerTbDelegate.h"
#import "CMRToolbarDelegateImp_p.h"
#import "CMRReplyController.h"


static NSString *const kReplyWindowToolbarIdentifier = @"Reply Window Toolbar";
static NSString *const kNewThreadWindowToolbarIdentifier = @"New Thread Window Toolbar";

static NSString *const kSendMessageIdentifier	= @"sendMessage";
static NSString *const kSendMessageLabelKey		= @"sendMessage Label";
static NSString *const kSendMessagePaletteLabelKey	= @"sendMessage Palette Label";
static NSString *const kSendMessageToolTipKey		= @"sendMessage ToolTip";

static NSString *const kSaveAsDraftIdentifier	= @"saveAsDraft";

static NSString *const kBeLoginIdentifier	= @"beLogin";
static NSString *const kBeLoginLabelKey		= @"beLogin Label";
static NSString *const kBeLoginPaletteLabelKey	= @"beLogin Palette Label";
static NSString *const kBeLoginToolTipKey		= @"beLogin ToolTip";

static NSString *const kInsertTemplateIdentifier = @"InsertTemplate";
static NSString *const kInsertTemplateLabelKey = @"InsertTemplate Label";
static NSString *const kInsertTemplateToolTipKey = @"InsertTemplate ToolTip";

static NSString *const kShowLocalRulesIdentifier = @"ShowLocalRules";
static NSString *const kShowLocalRulesLabelKey = @"ShowLocalRules Label";
static NSString *const kShowLocalRulesPaletteLabelKey = @"ShowLocalRules Palette Label";
static NSString *const kShowLocalRulesToolTipKey = @"ShowLocalRules ToolTip";

static NSString *const kFontIdentifier = @"FontPanel";
static NSString *const kFontLabelKey = @"FontPanel Label";
static NSString *const kFontToolTipKey = @"FontPanel ToolTip";


@implementation CMRReplyControllerTbDelegate
- (NSString *)identifier
{
	return kReplyWindowToolbarIdentifier;
}

- (NSButton *)sendButton
{
    return m_sendButton;
}

- (NSButton *)fontButton
{
    return m_fontButton;
}

- (NSButton *)localRulesButton
{
    return m_localRulesButton;
}
@end


@implementation CMRReplyControllerTbDelegate(Protected)
- (void)setupInsertTemplateItem:(NSToolbarItem *)anItem itemView:(NSPopUpButton *)aView
{
	NSMenuItem *menuItem_ = [[NSMenuItem alloc] initWithTitle:[self localizedString:kInsertTemplateLabelKey] action:NULL keyEquivalent:@""];
	NSSize size_;
	
	[aView retain];
	[aView removeFromSuperviewWithoutNeedingDisplay];
	[anItem setView:aView];
	size_ = [aView frame].size;
	[anItem setMinSize:size_];
	[anItem setMaxSize:size_];

	[aView release];
	
	[menuItem_ setSubmenu:[aView menu]];
	[anItem setMenuFormRepresentation:menuItem_];
	[menuItem_ release];
}

- (void)initializeToolbarItems:(NSWindow *)aWindow
{
	NSToolbarItem			*item_;
	NSWindowController		*wcontroller_;
    
    BOOL loadNibSuccess = [NSBundle loadNibNamed:@"CMRReplyControllerTbItems" owner:self];
    NSAssert(loadNibSuccess, @"Fail to load CMRReplyControllerTbItems.nib!");
	
	wcontroller_ = [aWindow windowController];
	UTILAssertNotNil(wcontroller_);

	[self appendButton:[self sendButton]
        withIdentifier:kSendMessageIdentifier
                 label:kSendMessageLabelKey
          paletteLabel:kSendMessagePaletteLabelKey
               toolTip:kSendMessageToolTipKey
                action:@selector(sendMessage:)
          customizable:YES];

    item_ = [self appendButton:[(CMRReplyController *)wcontroller_ toggleBeButton]
                withIdentifier:kBeLoginIdentifier
                         label:kBeLoginLabelKey
                  paletteLabel:kBeLoginPaletteLabelKey
                       toolTip:kBeLoginToolTipKey
                        action:@selector(toggleBeLogin:)
                  customizable:YES];
    [[item_ menuFormRepresentation] setTitle:[self localizedString:kBeLoginPaletteLabelKey]];

	item_ = [self appendToolbarItemWithItemIdentifier:kInsertTemplateIdentifier
									localizedLabelKey:kInsertTemplateLabelKey
							 localizedPaletteLabelKey:kInsertTemplateLabelKey
								  localizedToolTipKey:kInsertTemplateToolTipKey
											   action:NULL
											   target:wcontroller_];
	[self setupInsertTemplateItem:item_ itemView:[(CMRReplyController *)wcontroller_ templateInsertionButton]];
    
	[self appendButton:[self localRulesButton]
        withIdentifier:kShowLocalRulesIdentifier
                 label:kShowLocalRulesLabelKey
          paletteLabel:kShowLocalRulesLabelKey
               toolTip:kShowLocalRulesToolTipKey
                action:@selector(showLocalRules:)
          customizable:YES];

    [self appendButton:[self fontButton]
        withIdentifier:kFontIdentifier
                 label:kFontLabelKey
          paletteLabel:nil
               toolTip:kFontToolTipKey
                action:@selector(orderFrontFontPanel:)
          customizable:YES];
}
@end


@implementation CMRReplyControllerTbDelegate(Private)
- (NSArray *)unsupportedItemsArray
{
	return [[super unsupportedItemsArray] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:kSaveAsDraftIdentifier, NSToolbarShowFontsItemIdentifier, nil]];
}
@end


@implementation CMRReplyControllerTbDelegate(NSToolbarDelegate)
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
				kSendMessageIdentifier,
				NSToolbarSeparatorItemIdentifier,
//				kSaveAsDraftIdentifier,
				kInsertTemplateIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				kBeLoginIdentifier,
				nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
				kSendMessageIdentifier,
//				kSaveAsDraftIdentifier,
				kBeLoginIdentifier,
				kShowLocalRulesIdentifier,
				kInsertTemplateIdentifier,
//				NSToolbarShowFontsItemIdentifier,
                kFontIdentifier,
                NSToolbarSeparatorItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				nil];
}
@end


@implementation BSNewThreadControllerTbDelegate
- (NSString *)identifier
{
	return kNewThreadWindowToolbarIdentifier;
}
@end


@implementation BSNewThreadControllerTbDelegate(NSToolbarDelegate)
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
				kSendMessageIdentifier,
				NSToolbarSeparatorItemIdentifier,
				kInsertTemplateIdentifier,
				kShowLocalRulesIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				kBeLoginIdentifier,
				nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return [NSArray arrayWithObjects:
				kSendMessageIdentifier,
				kBeLoginIdentifier,
				kShowLocalRulesIdentifier,
				kInsertTemplateIdentifier,
//				NSToolbarShowFontsItemIdentifier,
                kFontIdentifier,
				NSToolbarSeparatorItemIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				NSToolbarSpaceItemIdentifier,
				nil];
}
@end
