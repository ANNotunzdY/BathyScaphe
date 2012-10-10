//
//  BSRepllCountdownSheetController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/02/11.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSReplyAlertSheetController.h"


@interface BSReplyCountdownSheetController : BSReplyAlertSheetController {
    NSTimer *m_timer;

    IBOutlet NSButton *autoRetryCheckbox;
    IBOutlet NSButton *retryButton;

    NSTimeInterval m_timerCount;
    double m_indicatorValue;
}

@property NSTimeInterval timerCount;
@property double indicatorValue;

@end
