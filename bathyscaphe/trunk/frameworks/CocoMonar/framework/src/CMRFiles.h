//
//  CMRFiles.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#define CMRUserBoardFile		@"board.plist"
#define CMRDefaultBoardFile		@"board_default.plist"
#define CMRCookiesFile			@"Cookies.plist"
#define CMRHistoryFile			@"History.plist"
//#define CMRNoNamesFile			@"NoNames.plist"
//#define CMRFavoritesFile		@"Favorites.plist"
//#define CMRFavMemoFile			@"Favorites_Memo.plist"

#define BSBoardPropertiesFile	@"BoardProperties.plist"
#define BSDownloadableTypesFile	@"DownloadableLinkTypes.plist"
#define BSReplyTextTemplatesFile	@"ReplyTextTemplates.plist"
#define BSNGExpressionsFile     @"NGExpressions.plist"

/*!
 * @abstract    
 *
 * ~/Library/Application Support/(AppName)/(XXX)
 * [CMRFileManager supportDirectoryWithName:]
 *
 * @defined    CMXLogsDirectory
 * @defined    CMXDocumentsDirectory
 * @defined    CMXResourcesDirectory
 * @defined    CMRBookmarksDirectory
 *
 * @discussion  Application Specific Files
 */

#define CMRLogsDirectory			@"Logs"
#define CMRDocumentsDirectory		@"Documents"
#define CMRResourcesDirectory		@"Resources"
#define CMRBookmarksDirectory		@"Bookmarks"
#define BSThemesDirectory			@"Themes"