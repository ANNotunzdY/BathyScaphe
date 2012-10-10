//
//  BoardWarrior.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/08/06.
//  Copyright 2006-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class BSURLDownload, BSModalStatusWindowController;

enum {
	BWDidFailInitializeAppleScript = -1000,
	BWDidFailExecuteAppleScriptHandler = -1001//,
/*	BWDidFailCreatingLogFile = -2000,
	BWDidFailWritingLogToFile = -2001 // reserved */
};

@interface BoardWarrior : NSObject {
	@private	
	BSURLDownload	*m_currentDownload; // No retain/release
	NSString		*m_bbsMenuPath;

	id				m_delegate; // No retain/release

    BSModalStatusWindowController *m_statusWindowController;
    NSModalSession m_session;
}

+ (id)warrior;

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

- (BOOL)syncBoardLists;

- (BOOL)isInProgress;
- (NSString *)logFilePath;
@end


@interface NSObject(BoardWarriorDelegate)
- (void)warriorWillStartSyncing:(BoardWarrior *)warrior;
- (void)warriorDidFinishSyncing:(BoardWarrior *)warrior;
- (void)warrior:(BoardWarrior *)warrior didFailSync:(NSError *)error;
//- (void)warrior:(BoardWarrior *)warrior didFailLogging:(NSError *)error;
@end

extern NSString *const kBoardWarriorErrorDomain;
