//
//  missing.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/06/04.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "missing.h"
#import "CocoMonar_Prefix.h"

void setUserInterfaceItemTitle(id item, NSString *title)
{
    if (![item respondsToSelector:@selector(setTitle:)]) {
        return;
    }
    [item setTitle:title];
}

void setUserInterfaceItemState(id item, BOOL condition)
{
    if (![item respondsToSelector:@selector(setState:)]) {
        return;
    }
    [item setState:condition ? NSOnState : NSOffState];
}

void setUserInterfaceItemStateDirectly(id item, NSCellStateValue state)
{
    if (![item respondsToSelector:@selector(setState:)]) {
        return;
    }
    [item setState:state];
}


@implementation NSObject(MissingExtensions)
- (void)exchangeNotificationObserver:(NSString *)notificationName
                            selector:(SEL)notifiedSelector
                         oldDelegate:(id)oldDelegate
                         newDelegate:(id)newDelegate
{
    NSNotificationCenter *center_;

    center_ = [NSNotificationCenter defaultCenter];
    if (oldDelegate) {
        [center_ removeObserver:self
                           name:notificationName
                         object:oldDelegate];
    }
    if (newDelegate) {
        [center_ addObserver:self
                    selector:notifiedSelector
                        name:notificationName
                      object:newDelegate];
    }
}

- (void)registerToNotificationCenter
{

}

- (void)removeFromNotificationCenter
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
