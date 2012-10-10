//
//  CMRReplyController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/11/05.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CMRStatusLineWindowController.h"


@interface CMRReplyController : CMRStatusLineWindowController<NSTextViewDelegate>
{
	IBOutlet NSComboBox			*_nameComboBox;
	IBOutlet NSTextField		*_mailField;
	IBOutlet NSButton			*_sageButton;
	IBOutlet NSButton			*_deleteMailButton;
	IBOutlet NSScrollView		*_scrollView;

	IBOutlet NSPopUpButton		*m_templateInsertionButton;
    IBOutlet NSButton           *m_toggleBeButton;
	IBOutlet NSObjectController	*m_controller;

	NSTextView			*_textView;
}

// working with NSDocument...
- (void)synchronizeMessengerWithData;
- (void)markUnableToEncodeCharacters:(NSIndexSet *)indexes forKey:(NSString *)formKey;
- (void)markUnableToEncodeCharacters:(NSIndexSet *)indexes atView:(NSTextView *)textView;

- (IBAction)insertSage:(id)sender;
- (IBAction)deleteMail:(id)sender;
- (IBAction)pasteAsQuotation:(id)sender;
- (IBAction)insertTextTemplate:(id)sender;
@end


@interface CMRReplyController(View)
- (NSComboBox *)nameComboBox;
- (NSTextField *)mailField;
- (NSTextView *)textView;
- (NSScrollView *)scrollView;
- (NSButton *)sageButton;
- (NSButton *)deleteMailButton;
- (NSPopUpButton *)templateInsertionButton;
- (NSObjectController *)objectController;
- (NSButton *)toggleBeButton;
@end
