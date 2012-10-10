//
//  SGFileLocation.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/17.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <SGFoundation/SGFoundationBase.h>

@class SGFileRef;

/*!
 * @class       SGFileLocation
 * @abstract    An Object represents file location.
 * @discussion
 *   An instance of SGFileLocation represents file location
 *   as file name (Unicode) and its parent directory reference.
 */
@interface SGFileLocation : NSObject<NSCopying>
{
    @private
    SGFileRef *m_directory;
    NSString *m_name;
}
+ (id)fileLocationWithName:(NSString *)aFileName directory:(SGFileRef *)aDirectory;
- (id)initWithName:(NSString *)aFileName directory:(SGFileRef *)aDirectory;

+ (id)fileLocationAtPath:(NSString *)aFilePath;
- (id)initLocationAtPath:(NSString *)aFilePath;

/* Resolve alias if needed. */
- (SGFileRef *)actualDirectory;
- (SGFileRef *)directory;
- (NSString *)name;

- (BOOL)exists;
- (SGFileRef *)fileRef;
- (NSString *)filepath;
@end
