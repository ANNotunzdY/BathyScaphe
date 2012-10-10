//
//  BSIPIArrayController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/11.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <AppKit/NSArrayController.h>


@interface BSIPIArrayController : NSArrayController {

}
- (IBAction)removeAll:(id)sender;
- (IBAction)selectFirst:(id)sender;
- (IBAction)selectLast:(id)sender;

- (NSUInteger)countOfArrangedObjects;
@end
