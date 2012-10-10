//
//  BoardManager-BSAddition.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/30.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//


#import "BoardManager_p.h"
#import "NoNameInputController.h"
#import "DatabaseManager.h"
#import "BSBoardInfoInspector.h"

/* constants */
// NND means 'NoNameDict'.
static NSString *const NNDNoNameKey			= @"NoName";
static NSString *const NNDSortColumnKey		= @"SortColumn";
static NSString *const NNDIsAscendingKey	= @"IsAscending";
static NSString *const NNDSortDescriptors	= @"SortDescriptors";
static NSString *const NNDAlwaysBeLoginKey	= @"AlwaysBeLogin";
static NSString *const NNDDefaultKotehanKey = @"DefaultReplyName";
static NSString *const NNDDefaultMailKey	= @"DefaultReplyMail";
static NSString *const NNDAllThreadsAAKey	= @"AABoard";
static NSString *const NNDBeLoginPolicyTypeKey = @"BeLoginPolicy";
static NSString *const NNDAllowsNanashiKey	= @"AllowsNanashi";
static NSString *const NNDBrowserListColumnsKey = @"TableColumns";
static NSString *const NNDAllowsCharRefKey = @"AllowsCharRef";
static NSString *const NNDLastDetectedDateKey = @"LastDetectedDate";

// Available in Tenori Tiger and later.
NSString *const NNDTenoriTigerSortDescsKey = @"SortDescriptors_TT";


@implementation BoardManager(PrivateUtilities)
- (id)entryForBoardName:(NSString *)aBoardName
{
	return [[self noNameDict] objectForKey:aBoardName];
}

- (id)valueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(id)value
{
	id entry_ = [self entryForBoardName:boardName];
	id value_ = nil;
	
	if ([entry_ isKindOfClass:[NSDictionary class]]) {
		value_ = [entry_ valueForKey:key];
	}
	
	if (!value_) {
		value_ = value;
	}
    
	return value_;
}

- (void)setValue:(id)value forKey:(NSString *)key atBoard:(NSString *)boardName
{
	UTILAssertNotNilArgument(value,@"value");
	UTILAssertNotNilArgument(boardName,@"boardName");
	
	// can serialize using NSPropertyListSerialization.
	if (![NSPropertyListSerialization propertyList:value isValidForFormat:NSPropertyListBinaryFormat_v1_0]) {
		NSLog(@"It is not permitted though you try to put object which can not serialize using NSPropertyListSerialization into NoNameDict.");
		return;
	}	
	
	NSMutableDictionary		*NND = [self noNameDict];
	id entry_ = [self entryForBoardName:boardName];
	
	if (!entry_ || [entry_ isKindOfClass:[NSString class]]) {
		NSArray	*tempObjects, *tempKeys;
		
		if (entry_) {
			tempObjects = [NSArray arrayWithObjects:entry_, value, nil];
			tempKeys	= [NSArray arrayWithObjects:NNDNoNameKey, key, nil];
		} else {
			tempObjects = [NSArray arrayWithObjects:value, nil];
			tempKeys	= [NSArray arrayWithObjects:key, nil];
		}
		[NND setObject:[NSDictionary dictionaryWithObjects:tempObjects forKeys:tempKeys] forKey:boardName];
	} else {
		NSMutableDictionary		*mutableEntry_;
		mutableEntry_ = [entry_ mutableCopy];
		[mutableEntry_ setObject:value forKey:key];
		[NND setObject:mutableEntry_ forKey:boardName];
		[mutableEntry_ release];
	}
}

- (void)removeValueForKey:(NSString *)key atBoard:(NSString *)boardName
{
	NSMutableDictionary		*NND = [self noNameDict];
	id entry_ = [self entryForBoardName:boardName];
	
	if (!entry_ || [entry_ isKindOfClass:[NSString class]]) {
		return;
	} else {
		NSMutableDictionary		*mutableEntry_;
		mutableEntry_ = [entry_ mutableCopy];
		[mutableEntry_ removeObjectForKey:key];
		[NND setObject:mutableEntry_ forKey:boardName];
		[mutableEntry_ release];
	}
}

- (NSString *)stringValueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(NSString *)value
{
    id entry_ = [self entryForBoardName:boardName];
    NSString *str_ = nil;

    if ([entry_ isKindOfClass:[NSDictionary class]]) {
        str_ = [entry_ stringForKey:key];
    }

    if (!str_) {
        str_ = value;
    }
    return str_;
}

- (void) setStringValue: (NSString *) value forKey: (NSString *) key atBoard: (NSString *) boardName
{
	UTILAssertNotNil(value);
	UTILAssertNotNil(boardName);
	
	NSMutableDictionary		*nnd_ = [self noNameDict];
	id entry_ = [self entryForBoardName:boardName];
	
	if (entry_ == nil || [entry_ isKindOfClass:[NSString class]]) {
		NSArray	*tempObjects, *tempKeys;
		
		if (entry_ != nil) {
			tempObjects = [NSArray arrayWithObjects:entry_, value, nil];
			tempKeys	= [NSArray arrayWithObjects:NNDNoNameKey, key, nil];
		} else {
			tempObjects = [NSArray arrayWithObjects:value, nil];
			tempKeys	= [NSArray arrayWithObjects:key, nil];
		}
		[nnd_ setObject: [NSDictionary dictionaryWithObjects:tempObjects forKeys:tempKeys]
				 forKey: boardName];
	} else {
		NSMutableDictionary		*mutableEntry_;
		mutableEntry_ = [entry_ mutableCopy];
		[mutableEntry_ setObject: value forKey: key];
		[nnd_ setObject: mutableEntry_ forKey: boardName];
		[mutableEntry_ release];
	}
}

- (BOOL)boolValueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(BOOL)value
{
	id entry_ = [self entryForBoardName:boardName];

	if ([entry_ isKindOfClass:[NSDictionary class]] && [[entry_ allKeys] containsObject:key]) {
        return [entry_ boolForKey:key];
	}

	return value;
}

- (void) setBoolValue: (BOOL) value forKey: (NSString *) key atBoard: (NSString *) boardName
{
	UTILAssertNotNil(boardName);
	
	NSMutableDictionary		*nnd_ = [self noNameDict];
	id entry_ = [self entryForBoardName:boardName];
	
	if(entry_ == nil || [entry_ isKindOfClass:[NSString class]]) {
		NSArray	*tempObjects, *tempKeys;
		NSNumber  *value_ = [NSNumber numberWithBool: value];
		
		if (entry_ != nil) {
			tempObjects = [NSArray arrayWithObjects:entry_, value_, nil];
			tempKeys	= [NSArray arrayWithObjects:NNDNoNameKey, key, nil];
		} else {
			tempObjects = [NSArray arrayWithObjects:value_, nil];
			tempKeys	= [NSArray arrayWithObjects:key, nil];
		}
		[nnd_ setObject: [NSDictionary dictionaryWithObjects:tempObjects forKeys:tempKeys]
				 forKey: boardName];
	} else {
		NSMutableDictionary		*mutableEntry_;
		mutableEntry_ = [entry_ mutableCopy];
		[mutableEntry_ setBool: value forKey: key];
		[nnd_ setObject: mutableEntry_ forKey: boardName];
		[mutableEntry_ release];
	}
}

- (NSDate *)dateValueForKey:(NSString *)key atBoard:(NSString *)boardName defaultValue:(NSDate *)value
{
    id entry = [self entryForBoardName:boardName];
    if ([entry isKindOfClass:[NSDictionary class]]) {
        id object = [entry objectForKey:key];
        if (object && [object isKindOfClass:[NSDate class]]) {
            return (NSDate *)object;
        }
    }
    return value;
}

- (void)setDateValue:(NSDate *)value forKey:(NSString *)key atBoard:(NSString *)boardName
{
    NSMutableDictionary *noNameDict = [self noNameDict];
    id entry = [self entryForBoardName:boardName];
    if (!entry || [entry isKindOfClass:[NSString class]]) { // old format...
        NSArray *tempObjects, *tempKeys;
        if (entry) {
            tempObjects = [NSArray arrayWithObjects:entry, value, nil];
            tempKeys = [NSArray arrayWithObjects:NNDNoNameKey, key, nil];
        } else {
            tempObjects = [NSArray arrayWithObject:value];
            tempKeys = [NSArray arrayWithObject:key];
        }
        [noNameDict setObject:[NSDictionary dictionaryWithObjects:tempObjects forKeys:tempKeys] forKey:boardName];
    } else {
        NSMutableDictionary *mutableEntry = [entry mutableCopy];
        [mutableEntry setObject:value forKey:key];
        [noNameDict setObject:mutableEntry forKey:boardName];
        [mutableEntry release];
    }
}
@end


@implementation BoardManager(BoardProperties)
- (NSMutableDictionary *)noNameDict
{
	if (!_noNameDict) {
		NSString *errorStr = [NSString string];
		NSData	*plistData;
		
		plistData = [NSData dataWithContentsOfFile:[[self class] NNDFilepath]];
		if (plistData) {
			_noNameDict = [NSPropertyListSerialization propertyListFromData:plistData
														   mutabilityOption:NSPropertyListMutableContainersAndLeaves
																	 format:NULL
														   errorDescription:&errorStr];
			if (!_noNameDict) {
				NSLog(@"BoardManager failed to read BoardProperties.plist. Reason: %@", errorStr);
			} else {
				[_noNameDict retain];
			}
		}
	}

	if (!_noNameDict) {
		_noNameDict = [[NSMutableDictionary alloc] init];
	}
	
	return _noNameDict;
}

- (BOOL)saveNoNameDict
{
	NSString *errorStr = [NSString string];
	NSMutableDictionary	*noNameDict_ = [self noNameDict];
	NSData *binaryData_ = [NSPropertyListSerialization dataFromPropertyList:noNameDict_
																	 format:NSPropertyListBinaryFormat_v1_0
														   errorDescription:&errorStr];

	if (!binaryData_) {
		NSLog(@"BoardManager failed to serialize noNameDict using NSPropertyListSerialization.");
		return [noNameDict_ writeToFile:[[self class] NNDFilepath] atomically:YES];
	}

	return [binaryData_ writeToFile:[[self class] NNDFilepath] atomically:YES];
}


#pragma mark Sorting
- (NSArray *)sortDescriptorsForBoard:(NSString *)boardName
{
    return [self sortDescriptorsForBoard:boardName useDefaultDescs:YES];
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors forBoard:(NSString *)boardName
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:sortDescriptors];
	[self setValue:data forKey:NNDTenoriTigerSortDescsKey atBoard:boardName];
}

#pragma mark Reply
- (BOOL)hasAllowsCharRefEntryAtBoard:(NSString *)boardName
{
    id entry = [self entryForBoardName:boardName];
    if ([entry isKindOfClass:[NSDictionary class]] && [[entry allKeys] containsObject:NNDAllowsCharRefKey]) {
        return YES;
    }

    // エントリが無くても、2ch 以外なら YES を返してしまう。
    // この状態で -allowsCharRefAtBoard: を呼べば defaultValue:NO が返る。
	const char *hs;	
	hs = [[[self URLForBoardName:boardName] host] UTF8String];
	if (NULL == hs) {
		return YES;
    }
	if (!is_2channel(hs)) {
        return YES;	
    }

    // 2ch の場合は SETTING.TXT を読んで解析する必要がある
    return NO;
}

- (BOOL)allowsCharRefAtBoard:(NSString *)boardName
{
    return [self boolValueForKey:NNDAllowsCharRefKey atBoard:boardName defaultValue:NO];
}

- (void)setAllowsCharRef:(BOOL)flag atBoard:(NSString *)boardName
{
    [self setBoolValue:flag forKey:NNDAllowsCharRefKey atBoard:boardName];
}

#pragma mark (SledgeHammer Addition)
- (BOOL) alwaysBeLoginAtBoard:(NSString *) boardName
{
	BSBeLoginPolicyType	policy_;
	
	policy_ = [self typeOfBeLoginPolicyForBoard:boardName];
	
	if ((policy_ == BSBeLoginTriviallyOFF) || (policy_ == BSBeLoginNoAccountOFF)) {
		return NO;
	
	} else if (policy_ == BSBeLoginTriviallyNeeded) {
		return YES;

	} else {
        id entry_ = [self entryForBoardName:boardName];

        if ([entry_ isKindOfClass: [NSDictionary class]] && [[entry_ allKeys] containsObject: NNDAlwaysBeLoginKey]) {
	       return [entry_ boolForKey: NNDAlwaysBeLoginKey];
        }

        return [CMRPref shouldLoginBe2chAnyTime];
	}
}

- (void) setAlwaysBeLogin:(BOOL	   ) alwaysLogin
				  atBoard:(NSString *) boardName
{
    [self setBoolValue: alwaysLogin forKey: NNDAlwaysBeLoginKey atBoard: boardName];
}

- (NSString *)defaultKotehanForBoard:(NSString *)boardName
{
	return [self stringValueForKey:NNDDefaultKotehanKey atBoard:boardName defaultValue:[CMRPref defaultReplyName]];
}

- (void) setDefaultKotehan:(NSString *) aName
				  forBoard:(NSString *) boardName
{
    [self setStringValue: aName forKey: NNDDefaultKotehanKey atBoard: boardName];
}

- (NSString *)defaultMailForBoard:(NSString *)boardName
{
	return [self stringValueForKey:NNDDefaultMailKey atBoard:boardName defaultValue:[CMRPref defaultReplyMailAddress]];
}

- (void) setDefaultMail:(NSString *) aString
			   forBoard:(NSString *) boardName
{
    [self setStringValue: aString forKey: NNDDefaultMailKey atBoard: boardName];
}

- (id)itemForName:(NSString *)boardName
{
	id list_;
	id item_;
	
	list_ = [self userList];
	item_ = [list_ itemForName:boardName ofType:BoardListBoardItem];
	if (item_) {
        return item_;
	}
	list_ = [self defaultList];
	item_ = [list_ itemForName:boardName ofType:BoardListBoardItem];

	return item_;
}

- (BSBeLoginPolicyType)typeOfBeLoginPolicyForBoard:(NSString *)boardName
{
	if (![CMRPref availableBe2chAccount]) {
		return BSBeLoginNoAccountOFF;
    }

	const char *hs;

	hs = [[[self URLForBoardName:boardName] host] UTF8String];

	if (NULL == hs) {
		return BSBeLoginDecidedByUser;
    }

	if (!is_2ch_except_pink(hs)) {
        return BSBeLoginTriviallyOFF;
    }

    id entry_ = [self entryForBoardName:boardName];

    if ([entry_ isKindOfClass:[NSDictionary class]]) {
        if ([[entry_ allKeys] containsObject:NNDBeLoginPolicyTypeKey]) {
            return [entry_ unsignedIntegerForKey:NNDBeLoginPolicyTypeKey];
        }
    }

	return BSBeLoginDecidedByUser;
}

- (void) setTypeOfBeLoginPolicy: (BSBeLoginPolicyType) aType forBoard: (NSString *) boardName
{
	if (aType == BSBeLoginDecidedByUser) return; // Currently not need to record it
	
	UTILAssertNotNil(boardName);

	NSMutableDictionary		*nnd_ = [self noNameDict];
	id entry_ = [self entryForBoardName:boardName];
	
	if(entry_ == nil || [entry_ isKindOfClass:[NSString class]]) {
		NSArray	*tempObjects, *tempKeys;
		NSNumber  *value_ = [NSNumber numberWithUnsignedInteger:aType];
		
		if (entry_ != nil) {
			tempObjects = [NSArray arrayWithObjects:entry_, value_, nil];
			tempKeys	= [NSArray arrayWithObjects:NNDNoNameKey, NNDBeLoginPolicyTypeKey, nil];
		} else {
			tempObjects = [NSArray arrayWithObjects:value_, nil];
			tempKeys	= [NSArray arrayWithObjects:NNDBeLoginPolicyTypeKey, nil];
		}
		[nnd_ setObject: [NSDictionary dictionaryWithObjects:tempObjects forKeys:tempKeys]
				 forKey: boardName];
	} else {
		NSMutableDictionary		*mutableEntry_;
		mutableEntry_ = [entry_ mutableCopy];
		[mutableEntry_ setUnsignedInteger:aType forKey:NNDBeLoginPolicyTypeKey];
		[nnd_ setObject:mutableEntry_ forKey:boardName];
		[mutableEntry_ release];
	}
}

#pragma mark NoNameArray
- (NSArray *)defaultNoNameArrayForBoard:(NSString *)boardName
{
	id entry_;
	
	entry_ = [self entryForBoardName:boardName];
	
	if ([entry_ isKindOfClass:[NSDictionary class]]) {
		id	object_ = [entry_ objectForKey:NNDNoNameKey];
		if ([object_ isKindOfClass:[NSString class]]) {
			return [NSArray arrayWithObject:object_];
		} else if ([object_ isKindOfClass:[NSArray class]]) {
			return object_;
		}
	} else if ([entry_ isKindOfClass:[NSString class]]) {
		return [NSArray arrayWithObject:[[self noNameDict] stringForKey:boardName]];
	}

	return nil;
}

- (void)setDefaultNoNameArray:(NSArray *)array forBoard:(NSString *)boardName
{
	UTILAssertNotNil(array);
	UTILAssertNotNil(boardName);

	BOOL	shouldRemove = ([array count] == 0) ? YES:NO;

    NSMutableDictionary *nnd_ = [self noNameDict]; 	
	id entry_ = [self entryForBoardName:boardName];

	if (!entry_ || [entry_ isKindOfClass:[NSString class]]) {
		if (shouldRemove) {
			[nnd_ removeObjectForKey:boardName];
		} else {
			[nnd_ setObject:[NSDictionary dictionaryWithObject:array forKey:NNDNoNameKey] forKey:boardName];
		}
	} else {
		NSMutableDictionary		*mutableEntry_;
		
		mutableEntry_ = [entry_ mutableCopy];
		
		if (shouldRemove) {
			[mutableEntry_ removeObjectForKey:NNDNoNameKey];
		} else {
			[mutableEntry_ setObject:array forKey:NNDNoNameKey];
		}
		[nnd_ setObject:mutableEntry_ forKey:boardName];
		[mutableEntry_ release];
	}
}

- (void) addNoName: (NSString *) additionalNoName forBoard: (NSString *) boardName
{
	UTILAssertNotNil(additionalNoName);
	UTILAssertNotNil(boardName);

	NSMutableArray *tmpArray;
	NSArray *tmpArrayBase = [self defaultNoNameArrayForBoard:boardName];

	if (!tmpArrayBase) {
		tmpArray = [[NSMutableArray alloc] initWithCapacity:1];
	} else {
		if ([tmpArrayBase containsObject:additionalNoName]) { // 既に登録されている
			return;
		}
		tmpArray = [tmpArrayBase mutableCopy];
	}
	[tmpArray addObject:additionalNoName];
	[[BSBoardInfoInspector sharedInstance] willChangeValueForKey:@"noNamesArray"];
	[self setDefaultNoNameArray:tmpArray forBoard:boardName];
	[[BSBoardInfoInspector sharedInstance] didChangeValueForKey:@"noNamesArray"];
	[tmpArray release];
}

#pragma mark ReinforceII Addition
- (BOOL)allowsNanashiAtBoard:(NSString *)boardName
{
	return [self boolValueForKey:NNDAllowsNanashiKey atBoard:boardName defaultValue:YES];
}

- (void)setAllowsNanashi:(BOOL)allows atBoard:(NSString *)boardName
{
    [self setBoolValue:allows forKey:NNDAllowsNanashiKey atBoard:boardName];
}

#pragma mark Starlight Breaker Addition
- (void)passPropertiesOfBoardName:(NSString *)boardName toBoardName:(NSString *)newBoardName
{
	if (!boardName || !newBoardName || [boardName isEqualToString: newBoardName]) return;
	id dict = [[self noNameDict] objectForKey:boardName];
	if (!dict) return;

	[[self noNameDict] setObject:dict forKey:newBoardName];
	[[self noNameDict] removeObjectForKey:boardName];
}
/*
- (id)browserListColumnsForBoard:(NSString *)boardName
{
	return [self valueForKey:NNDBrowserListColumnsKey atBoard:boardName defaultValue:[CMRPref threadsListTableColumnState]];
}

- (void)setBrowserListColumns:(id)plist forBoard:(NSString *)boardName
{
	if (!plist) {
		[self removeValueForKey:NNDBrowserListColumnsKey atBoard:boardName];
	} else {
		[self setValue:plist forKey:NNDBrowserListColumnsKey atBoard:boardName];
	}
}
*/
#pragma mark -
- (NSDate *)lastDetectedDateForBoard:(NSString *)boardName
{
    return [self dateValueForKey:NNDLastDetectedDateKey atBoard:boardName defaultValue:nil];
}

- (void)setLastDetectedDate:(NSDate *)date forBoard:(NSString *)boardName
{
    [self setDateValue:date forKey:NNDLastDetectedDateKey atBoard:boardName];
}

- (NSString *)askUserAboutDefaultNoNameForBoard:(NSString *)boardName presetValue:(NSString *)aValue
{
	NoNameInputController	*controller_;
	NSString				*v;
	
	controller_ = [[NoNameInputController alloc] init];
	v = [controller_ askUserAboutDefaultNoNameForBoard:boardName presetValue:aValue];
    if (v) {
        [self addNoName:v forBoard:boardName];
    }
	[controller_ release];
	
	return v;
}

- (BOOL)needToDetectNoNameForBoard:(NSString *)boardName shouldInputManually:(BOOL *)boolPtr
{
    BOOL showsDebugLog = [[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey];
	if ([boardName hasSuffix:@"headline"]) {
        if (showsDebugLog) {
            NSLog(@"** USER DEBUG ** This board (%@) is headline board, so not need to detect.", boardName);
        }
        return NO;
    }
	NSArray *set_ = [self defaultNoNameArrayForBoard:boardName];
	if (!set_ || [set_ count] == 0) {
        if (showsDebugLog) {
            NSLog(@"** USER DEBUG ** Can not found nanashi-san list of board %@, so NEED to detect.", boardName);
        }
        if (boolPtr != NULL) {
            *boolPtr = YES;
        }
        return YES;
	}

    NSDate *date = [self lastDetectedDateForBoard:boardName];
    if (!date || fabs([date timeIntervalSinceNow] > 60*60*24*90)) {
        if (showsDebugLog) {
            NSLog(@"** USER DEBUG ** Too old since last detected of board %@, so NEED to detect.", boardName);
        }
        if (boolPtr != NULL) {
            *boolPtr = NO;
        }
        return YES;
    }
    if (showsDebugLog) {
        NSLog(@"** USER DEBUG ** Board properties of board %@ is available, so not need to detect.", boardName);
    }
	return NO;
}
@end
