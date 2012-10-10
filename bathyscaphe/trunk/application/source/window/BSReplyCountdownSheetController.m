//
//  BSRepllCountdownSheetController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/02/11.
//  Copyright 2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSReplyCountdownSheetController.h"
#import "AppDefaults.h"


@implementation BSReplyCountdownSheetController
@synthesize timerCount = m_timerCount;
@synthesize indicatorValue = m_indicatorValue;

- (NSString *)windowNibName
{
    return @"BSReplyCountdownSheet";
}

- (id)init
{
    if (self = [super init]) {
        self.timerCount = [CMRPref timeIntervalForNinjaFirstWait];
        self.indicatorValue = 20.0;
        [autoRetryCheckbox setEnabled:YES];
        [autoRetryCheckbox setState:([CMRPref autoRetryAfterNinjaFirstWait] ? NSOnState : NSOffState)];
        [retryButton setEnabled:NO];
        m_timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdown:) userInfo:nil repeats:YES] retain];
    }
    return self;
}

- (void)countdown:(NSTimer *)aTimer
{
    self.timerCount = (self.timerCount - 1);
    self.indicatorValue = (self.timerCount / 6);
    if (self.timerCount == 0) {
        [aTimer invalidate];
        if ([autoRetryCheckbox state] == NSOnState) {
            [[self window] orderOut:nil];
            [CMRPref setAutoRetryAfterNinjaFirstWait:YES];
            [NSApp endSheet:[self window] returnCode:NSAlertFirstButtonReturn];
        } else {
            [CMRPref setAutoRetryAfterNinjaFirstWait:NO];
            [autoRetryCheckbox setEnabled:NO];
            [retryButton setEnabled:YES];
        }
    }
}

- (void)dealloc
{
    [m_timer invalidate];
    [m_timer release];
    [super dealloc];
}

- (IBAction)endSheetWithCodeAsTag:(id)sender
{
	[m_timer invalidate];
	[super endSheetWithCodeAsTag:sender];
}

// 暫定上書き
- (void)showHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://info.2ch.net/wiki/index.php?%C7%A6%CB%A1%C4%A1%B4%AC%CA%AA"]];
}
@end
