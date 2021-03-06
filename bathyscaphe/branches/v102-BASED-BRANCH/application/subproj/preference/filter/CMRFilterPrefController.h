/**
  * $Id: CMRFilterPrefController.h,v 1.3 2005-07-29 21:18:28 tsawada2 Exp $
  * 
  * CMRFilterPrefController.h
  *
  * Copyright (c) 2003-2004 Takanori Ishikawa, All rights reserved.
  * See the file LICENSE for copying permission.
  */
#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"



@interface CMRFilterPrefController : PreferencesController
{
	IBOutlet NSButton	*_spamFilterEnabledCheckBox;
	IBOutlet NSButton	*_usesSpamMessageCorpusCheckBox;
	IBOutlet NSMatrix	*_spamFilterBehaviorMatrix;
	
	// detail sheet
	IBOutlet NSWindow	*_detailSheet;
	IBOutlet NSTextView	*_spamMessageCorpusTextView;
}
- (IBAction) changeSpamFilterEnabled : (id) sender;
- (IBAction) changeUsesSpamMessageCorpus : (id) sender;
- (IBAction) changeSpamFilterBehavior : (id) sender;
- (IBAction) resetSpamDB : (id) sender;

- (IBAction) openDetailSheet : (id) sender;
- (IBAction) closeDetailSheet : (id) sender;
@end
