//
//  SGLinkCommand.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/16.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGFunctor.h"


@interface SGLinkCommand : SGFunctor
- (id)link;
- (NSURL *)URLValue;
- (NSString *)stringValue;
@end


@interface SGCopyLinkCommand : SGLinkCommand
@end


@interface SGOpenLinkCommand : SGLinkCommand
@end


@interface SGPreviewLinkCommand : SGLinkCommand
@end
