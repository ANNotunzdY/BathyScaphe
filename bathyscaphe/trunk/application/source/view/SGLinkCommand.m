//
//  SGLinkCommand.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/16.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGLinkCommand.h"
#import "CocoMonar_Prefix.h"
#import <SGAppKit/SGAppKit.h>
#import "AppDefaults.h"

@implementation SGLinkCommand
- (id)link
{
    id      obj_;

    obj_ = [self objectValue];
    UTILAssertNotNil(obj_);

    return obj_;
}

- (NSURL *)URLValue
{
    if ([[self link] isKindOfClass:[NSURL class]]) {
        return [self link];
    }
    return [NSURL URLWithString:[self stringValue]];
}

- (NSString *)stringValue
{
    id link = [self link];
    return [link respondsToSelector:@selector(absoluteString)] ? [link absoluteString] : [link description];
}
@end


@implementation SGCopyLinkCommand : SGLinkCommand
- (void)execute:(id)sender
{
    NSPasteboard    *pboard_;
    NSArray         *types_;
    
    pboard_ = [NSPasteboard generalPasteboard];
    types_ = [NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil];
    [pboard_ declareTypes:types_ owner:nil];
    
    [[self URLValue] writeToPasteboard:pboard_];
    [pboard_ setString:[self stringValue] forType:NSStringPboardType];
}
@end


@implementation SGOpenLinkCommand
- (void)execute:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[self URLValue] inBackground:[CMRPref openInBg]];
}
@end


@implementation SGPreviewLinkCommand
- (void)execute:(id)sender
{
    id<BSLinkPreviewing> previewer = [CMRPref sharedLinkPreviewer];
    if (previewer) {
        [previewer previewLink:[self URLValue]];
        return;
    }
    id<BSImagePreviewerProtocol> oldPreviewer = [CMRPref sharedImagePreviewer];
    if (oldPreviewer) {
        [oldPreviewer showImageWithURL:[self URLValue]];
    }
}
@end
