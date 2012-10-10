//
//  BSSearchOptions.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/17.
//  Copyright 2007-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <CocoMonar/CocoMonar.h>

// For future use (Currently unused.)
enum {
	BSSearchNoTargetMask = 0,
	BSSearchForNameMask = 1 << 0,
	BSSearchForMailMask = 1 << 1,
	BSSearchForIDMask = 1 << 2,
	BSSearchForHostMask = 1 << 3,
	BSSearchForMessageMask = 1 << 4,
	BSSearchForAllMask = 0x1F,
};
	
@interface BSSearchOptions : NSObject<NSCopying> {//, CMRPropertyListCoding> {
	@private
	NSString		*m_searchString;
	NSArray			*m_targetKeysArray;
	CMRSearchMask	m_searchMask;
	// For future use
//	unsigned int	m_targetsMask;
}

+ (id)operationWithFindObject:(NSString *)searchString
					   options:(CMRSearchMask)options
						target:(NSArray *)keysArray;
- (id) initWithFindObject:(NSString *)searchString
				  options:(CMRSearchMask)options
				   target:(NSArray *)keysArray;

- (NSString *)findObject;
- (NSArray *)targetKeysArray;
- (CMRSearchMask)optionMasks;

- (BOOL)optionStateForOption:(CMRSearchMask)opt;
- (void)setOptionState:(BOOL)flag forOption:(CMRSearchMask)opt;

// {0,1,1,0,1} -> {@"mail", @"IDString", @"cachedMessage"} みたいな変換
+ (NSArray *)keysArrayFromStatesArray:(NSArray *)statesArray;

// For future use
/*- (BOOL)isCaseInsensitive;
- (void)setIsCaseInsensitive:(BOOL)checkBoxState;
- (BOOL)isLinkOnly;
- (void)setIsLinkOnly:(BOOL)checkBoxState;
- (BOOL)usesRegularExpression;
- (void)setUsesRegularExpression:(BOOL)flag;

- (unsigned int)searchTargets;
- (void)setSearchTargets:(unsigned int)targetsMask;*/
@end
