//:FCController_p.h#import "FCController.h"#import "PreferencePanes_Prefix.h"// プログレス・バー#define kBarStyleTag			0#define kSpiningStyleTag		1@interface FCController(ViewAccessor)- (NSButton *) alternateFontButton;- (NSColorWell *) threadViewBGColorWell;- (NSColorWell *) threadViewColorWell;- (NSColorWell *) messageColorWell;- (NSColorWell *) messageNameColorWell;- (NSColorWell *) messageTitleColorWell;- (NSColorWell *) messageAnchorColorWell;- (NSColorWell *) messageFilteredColorWell;- (NSColorWell *) messageTextEnhancedColorWell;- (NSButton *) hasAnchorULButton;- (NSColorWell *) newThreadColorWell;- (NSColorWell *) threadsListColorWell;- (NSButton *) threadViewFontButton;- (NSButton *) messageFontButton;- (NSButton *) itemTitleFontButton;- (NSButton *) threadsListFontButton;- (NSButton *) newThreadFontButton;- (NSColorWell *) resPopUpBGColorWell;- (NSColorWell *) resPopUpTextColorWell;- (NSButton *) resPopUpUsesTCButton;- (NSButton *) resPopUpIsSeeThroughButton;- (NSButton *) shouldAntialiasButton;- (NSTextField *) rowHeightField;- (NSTextField *) spaceWidthField;- (NSTextField *) spaceHeightField;- (NSButton *) drawsGridCheckBox;- (NSButton *) drawStripedCheckBox;- (NSStepper *) rowHeightStepper;- (NSStepper *) spaceWidthStepper;- (NSStepper *) spaceHeightStepper;- (NSButton *) replyFontButton;- (NSColorWell *) replyTextColorWell;- (NSColorWell *) replyBackgroundColorWell;- (NSButton *) resPopUpScrollerIsSmall;- (NSColorWell *) boardListTextColorWell;- (NSColorWell *) messageHostColorWell;- (NSButton *) hostFontButton;- (NSButton *) boardListTextFontButton;- (NSButton *) beProfileFontButton;- (NSTextField *) boardListRowHeightField;- (NSStepper *) boardListRowHeightStepper;- (void) updateTableRowSettings;- (void) updateBoardListRowSettings;- (NSFont *) getFontOf : (int) btnTag;@end