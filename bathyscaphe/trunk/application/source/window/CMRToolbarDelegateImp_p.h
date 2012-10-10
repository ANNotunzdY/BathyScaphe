//:CMRToolbarDelegateImp_p.h
// encoding="UTF-8"

#import "CMRToolbarDelegateImp.h"
#import "CocoMonar_Prefix.h"
#import <SGAppKit/SGAppKit.h>



@interface CMRToolbarDelegateImp(Private)
- (NSToolbarItem *) itemForItemIdentifier : (NSString *) anIdentifier
								itemClass : (Class	   ) aClass;
- (void)setupControl:(NSControl *)viewItem onItem:(NSToolbarItem *)tbItem action:(SEL)action target:(NSWindowController *)wc;
- (NSToolbarItem *) appendToolbarItemWithItemIdentifier : (NSString *) itemIdentifier
                                      localizedLabelKey : (NSString *) label
                               localizedPaletteLabelKey : (NSString *) paletteLabel
                                    localizedToolTipKey : (NSString *) toolTip
                                                 action : (SEL       ) action
                                                 target : (id        ) target;
- (NSToolbarItem *) appendToolbarItemWithClass : (Class		) aClass
								itemIdentifier : (NSString *) itemIdentifier
							 localizedLabelKey : (NSString *) label
					  localizedPaletteLabelKey : (NSString *) paletteLabel
						   localizedToolTipKey : (NSString *) toolTip
										action : (SEL       ) action
										target : (id        ) target;

- (id)appendButton:(NSButton *)button
    withIdentifier:(NSString *)identifier
             label:(NSString *)label
      paletteLabel:(NSString *)paletteLabel
           toolTip:(NSString *)toolTip
            action:(SEL)action
      customizable:(BOOL)iconCustomizable;

- (void)customizeSegmentedControlIcons:(NSSegmentedControl *)control;

- (NSMutableDictionary *) itemDictionary;

-(NSArray *) unsupportedItemsArray;
@end



@interface CMRToolbarDelegateImp(Protected)
- (void) initializeToolbarItems : (NSWindow *) aWindow;
- (void) configureToolbar : (NSToolbar *) aToolbar;
@end
