//
//  IndexField.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/09.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface IndexField : NSTextField {
}
@end


@interface NSObject(IndexFieldDelegateExtension)
- (NSRange)selectRangeWithTextField:(NSTextField *)textField;
@end
