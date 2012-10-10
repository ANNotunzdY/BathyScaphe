//
//  SGFile+AppSupport.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/17.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <SGFoundation/SGFileRef.h>


@interface SGFileRef(SGApplicationSupport)
// ~/Library/Application Support
+ (SGFileRef *)applicationSupportFolderRef;
// ~/Library/Application Support/(ExecutableName)
+ (SGFileRef *)applicationSpecificFolderRef;
@end
