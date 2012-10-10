//
//  BSThreadListItem.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 07/03/18.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <SQLiteDB.h>

@interface BSThreadListItem : NSObject<NSPasteboardWriting>
{
	id data;
}

+ (id)threadItemWithIdentifier:(NSString *)identifier boardName:(NSString *)boardName;
+ (id)threadItemWithIdentifier:(NSString *)identifier boardID:(NSUInteger)boardID;
+ (id)threadItemWithFilePath:(NSString *)path;
- (id)initWithIdentifier:(NSString *)identifier boardName:(NSString *)boardName;
- (id)initWithIdentifier:(NSString *)identifier boardID:(NSUInteger)boardID;
- (id)initWithFilePath:(NSString *)path;

+ (NSArray *)threadItemArrayFromCursor:(id <SQLiteCursor>)cursor;

- (NSString *)identifier;
- (NSString *)threadName;
- (NSUInteger)boardID;
- (NSString *)boardName;
- (NSString *)threadFilePath;
- (ThreadStatus)status;
- (NSNumber *)responseNumber;
- (NSNumber *)readNumber;
- (NSNumber *)delta;
- (NSDate *)creationDate;
- (NSDate *)modifiedDate;
- (NSDate *)lastWrittenDate;
- (BOOL)isDatOchi;

- (NSUInteger)label;

- (NSNumber *)threadNumber;
- (NSImage *)statusImage;

- (NSDictionary *)attribute;

- (void) setCachedValue:(id)value forKey:(NSString *)key;
- (id) cachedValueForKey:(NSString *)key;

@end


NSUInteger indexOfIdentifier(NSArray *array, NSString *identifier);
BSThreadListItem *itemOfTitle(NSArray *array, NSString *searchTitle);

