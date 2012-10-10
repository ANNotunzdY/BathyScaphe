//
//  DatabaseUpdater.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 07/02/03.
//  Copyright 2007 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DatabaseManager.h"

@interface DatabaseUpdater : NSObject
{
	IBOutlet NSWindow *window;
	IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField *information;
}

+ (BOOL)updateFrom:(NSInteger)fromVersion to:(NSInteger)toVersion;

@end

@interface DatabaseUpdater(UpdateMethod)
- (BOOL) updateDB;
@end