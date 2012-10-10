//
//  CMXMenuHolder.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/11/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMXMenuHolder.h"
#import "BSLabelMenuItemView.h"
#import "BSLabelManager.h"
#import "UTILKit.h"


@implementation CMXMenuHolder
+ (NSMenu *)menuFromBundle:(NSBundle *)bundle nibName:(NSString *)nibName
{
    id instance_;

    instance_ = [[self alloc] initWithBundle:bundle nibName:nibName];
    [instance_ autorelease];

    return [instance_ menu];
}

- (id)initWithBundle:(NSBundle *)bundle nibName:(NSString *)nibName
{
    UTILAssertNotNilArgument(bundle, @"bundle");
    UTILAssertNotNilArgument(nibName, @"nibName");
    if (self = [super init]) {
        NSDictionary *externalNameTable_;
        
        externalNameTable_ = [NSDictionary dictionaryWithObjectsAndKeys:self, @"NSOwner", nil];
        if(![bundle loadNibFile:nibName externalNameTable:externalNameTable_ withZone:[self zone]]) {
            NSLog(@"Can't locate nib file %@", nibName);

            [self release];
            return nil;
        }
    }
    return self;
}

- (NSMenu *)menu
{
    return _menu;
}

- (void)dealloc
{
    [_menu release];
    [super dealloc];
}
@end


@implementation BSLabelMenuItemHolder
+ (BSLabelMenuItemView *)labelMenuItemView
{
    id instance_;
    instance_ = [[self alloc] init];
    [instance_ autorelease];
    return [instance_ labelMenuItemView];
}

- (id)init
{
    if (self = [super init]) {
        [NSBundle loadNibNamed:@"BSLabelMenuItem" owner:self];
        (void)[BSLabelManager defaultManager];
    }
    return self;
}

- (BSLabelMenuItemView *)labelMenuItemView
{
    return m_labelMenuItemView;
}


- (void)dealloc
{
    [m_labelMenuItemView release];
    [super dealloc];
}
@end
