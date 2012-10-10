//
//  BSReplyTextTemplateManager.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/12/20.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSMenu.h>
#import "BSReplyTextTemplate.h"

@interface BSReplyTextTemplateManager : NSObject<NSCoding, NSMenuDelegate> { // ツールバー絡みで NSCoding が必要
    NSMutableArray *m_templates;
}

+ (id)defaultManager;

- (NSString *)templateForDisplayName:(NSString *)aString;
- (NSString *)templateForShortcutKeyword:(NSString *)aString;

- (NSMutableArray *)templates;
- (void)setTemplates:(NSMutableArray *)anArray;
- (NSUInteger)countOfTemplates;
- (id)objectInTemplatesAtIndex:(NSUInteger)index;
- (void)insertObject:(id)anObject inTemplatesAtIndex:(NSUInteger)index;
- (void)removeObjectFromTemplatesAtIndex:(NSUInteger)index;
- (void)replaceObjectInTemplatesAtIndex:(NSUInteger)index withObject:(id)anObject;

- (void)writeToFileNow;
@end


@interface BSBugReportingTemplate : BSReplyTextTemplate {
    // Special template for bug-reporting.
}
@end
