/**
  * $Id: CMRThreadsList.h,v 1.1.1.1 2005-05-11 17:51:04 tsawada2 Exp $
  * 
  * CMRThreadsList.h
  *
  * Copyright (c) 2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  */
#import <Cocoa/Cocoa.h>
#import "CocoMonar_Prefix.h"

@class CMRDownloader;
@class CMRSearchOptions;
@class CMRBBSSignature;
@class CMRThreadLayout;

#if PATCH
@class CMXDateFormatter;
#endif


typedef enum _ThreadsListSearchType{
	ThreadsListTitleSeach = 1,
	ThreadsListPathSearch,
} ThreadsListSearchType;

@interface CMRThreadsList : NSObject 
{
	CMRBBSSignature			*_BBSSignature;
	CMRThreadLayout			*_worker;
	
	NSMutableArray			*_threads;
	NSMutableArray			*_filteredThreads;
	NSMutableDictionary		*_threadsInfo;
	
	NSLock		*_threadsListUpdateLock;
	NSLock		*_filteredThreadsLock;
#if PATCH
	CMXDateFormatter * dateFormatter;
#endif
	BOOL		_isAscending;
}

+ (id) threadsListWithBBSSignature : (CMRBBSSignature *) aSignature;
- (id) initWithBBSSignature :  (CMRBBSSignature *) aSignature;

/**
  * 
  * 読み込みを開始。
  * 初期化したクラスは直後に呼び出すこと。
  * workerを保持する。
  * 
  */
- (void) startLoadingThreadsList : (CMRThreadLayout *) worker;
- (CMRThreadLayout *) worker;
- (void) setWorker : (CMRThreadLayout *) aWorker;

- (BOOL) isFavorites;
- (BOOL) addFavoriteAtRowIndex : (int          ) rowIndex
				   inTableView : (NSTableView *) tableView;

- (id) objectValueForBoardInfo;
@end





@interface CMRThreadsList(AccessingList)
- (NSMutableArray *) threads;
- (void) setThreads : (NSMutableArray *) aThreads;
- (NSMutableArray *) filteredThreads;
- (void) setFilteredThreads : (NSMutableArray *) aFilteredThreads;
- (int) filteringMask;
- (void) setFilteringMask : (int) mask;
- (BOOL) isAscending;
- (void) setIsAscending : (BOOL)  flag;
- (NSMutableDictionary *) threadsInfo;
- (void) setThreadsInfo : (NSMutableDictionary *) aThreadsInfo;
- (void) toggleIsAscending;
- (void) sortByKey : (NSString *) key;
- (void) _sortArrayByKey : (NSString       *) key
                   array : (NSMutableArray *) array;
@end


 
@interface CMRThreadsList(Attributes)
- (CMRBBSSignature *) BBSSignature;
- (NSString *) boardName;
- (NSString *) threadsListPath;
- (NSURL *) boardURL;

- (unsigned) numberOfThreads;
- (unsigned) numberOfFilteredThreads;
@end



@interface CMRThreadsList(Filter)
- (void) filterByDisplayingThreadAtPath : (NSString *) filepath;
- (void) filterByStatus : (int) status;
- (BOOL) filterByFindOperation : (CMRSearchOptions *) operation;

- (NSArray *) _arrayWithStatus : (ThreadStatus    ) status
               fromSortedArray : (NSMutableArray *) array
			     subarrayRange : (NSRangePointer  ) aRange;
- (void) _filteredThreadsLock;
- (void) _filteredThreadsUnlock;
@end



typedef BOOL(*TLSearchFunction)(NSDictionary *, void *);
@interface CMRThreadsList(SearchThreads)
- (NSMutableDictionary *) seachThreadByPath : (NSString *) filepath;
- (NSMutableDictionary *) seachThreadByPath : (NSString *) filepath
									inArray : (NSArray  *) array;
- (NSArray *) seachThreadsUsingFunction : (BOOL(*)(NSDictionary *, void *))checker 
                                context : (void  *) context;
- (NSArray *) _seachThreads : (ThreadsListSearchType) type
			        inArray : (NSArray *) array
			        context : (void    *) context;
- (NSArray *) _seachThreadsUsingFunction : (TLSearchFunction)checker 
							     inArray : (NSArray *) array
							     context : (void    *) context;
@end



@interface CMRThreadsList(DataSourceTemplates)
+ (void) resetDataSourceTemplates;

+ (id) objectValueTemplate : (id ) aValue
				   forTYpe : (int) aType;
@end


@interface CMRThreadsList(DataSource)
- (NSArray *) threadFilePathArrayWithRowIndexArray : (NSArray	  *) anIndexArray
									   inTableView : (NSTableView *)tableView;
- (ThreadStatus) threadStatusForThread : (NSDictionary *) aThread;
- (id) objectValueForIdentifier : (NSString *) identifier
					threadArray : (NSArray  *) threadArray
						atIndex : (int       ) index;
- (NSString *) threadFilePathAtRowIndex : (int          ) rowIndex
                            inTableView : (NSTableView *) tableView
							     status : (ThreadStatus *) status;
- (NSDictionary *) threadAttributesAtRowIndex : (int          ) rowIndex
                                  inTableView : (NSTableView *) tableView;

- (unsigned int) indexOfThreadWithPath : (NSString *) filepath;
#if PATCH
-(void)updateDateFormatter;
#endif
@end



@interface CMRThreadsList(Download)
- (void) downloadThreadsList;
- (void) postListDidUpdateNotification : (int) mask;
@end




@interface CMRThreadsList(ListImport)
+ (void) clearAttributes : (NSMutableDictionary *) attributes;
+ (NSMutableDictionary *) attributesForThreadsListWithContentsOfFile : (NSString *) path;
+ (id) threadsListTemplateWithPath : (NSString *) path;
@end



@interface w2chFavoriteItemList : CMRThreadsList
@end



// Notification
extern NSString *const CMRThreadsListDidUpdateNotification;
extern NSString *const CMRThreadsListDidChangeNotification;
extern NSString *const ThreadsListUserInfoSelectionHoldingMaskKey;
