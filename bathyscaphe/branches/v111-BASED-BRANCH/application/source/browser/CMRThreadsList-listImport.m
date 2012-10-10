/**
  * $Id: CMRThreadsList-listImport.m,v 1.1.1.1.4.6 2006-09-01 13:46:54 masakih Exp $
  * BathyScaphe
  *
  *
  * Copyright 2005-2006 BathyScaphe Project. All rights reserved.
  *
  */

#import "CMRThreadsList_p.h"
#import "CMRThreadLayout.h"
#import "CMRThreadsUpdateListTask.h"
#import "CMRThreadsListReadFileTask.h"

static BOOL synchronizeThAttrForSync2(NSMutableDictionary *theThread, NSDictionary *fromFavorite)
{
	unsigned		nCorrectLoaded_;
	ThreadStatus	status_;
	
	nCorrectLoaded_ = [fromFavorite unsignedIntForKey : CMRThreadLastLoadedNumberKey defaultValue : 0];

	[theThread setUnsignedInt : nCorrectLoaded_
					   forKey : CMRThreadLastLoadedNumberKey];

	if (nCorrectLoaded_ == 0) {
		status_ = ThreadNoCacheStatus;
	} else {
		unsigned	nRes_ = [theThread unsignedIntForKey : CMRThreadNumberOfMessagesKey];
		if (nCorrectLoaded_ >= nRes_) {
			status_ = ThreadLogCachedStatus;
			[theThread setObject : [fromFavorite objectForKey : CMRThreadModifiedDateKey] forKey : CMRThreadModifiedDateKey];
		} else {
			status_ = ThreadUpdatedStatus;
		}
	}

	[theThread setUnsignedInt : status_
					   forKey : CMRThreadStatusKey];
	
	return YES;
}

#pragma mark -

@implementation CMRThreadsList(ListImport)
// ������������Ԃ�
+ (void) clearAttributes : (NSMutableDictionary *) attributes
{
	// ------ �K�v�Ȃ����e�͎̂Ă�B------
	NSString *removeKeys_[] = 
				{
					CMRThreadNumberOfUpdatedKey,
					CMRThreadLastLoadedNumberKey,
					CMRThreadCreatedDateKey,
					CMRThreadModifiedDateKey,
					ThreadPlistContentsKey,
					ThreadPlistLengthKey,
					CMRThreadWindowFrameKey,
					CMRThreadLastReadedIndexKey,
					CMRThreadVisibleRangeKey
				};
	unsigned		i, cnt;
	
	cnt = UTILNumberOfCArray(removeKeys_);
	for(i = 0; i < cnt; i++)
		[attributes removeObjectForKey : removeKeys_[i]];
	
	// �X�e�[�^�X���N���A
	[attributes setUnsignedInt : ThreadNoCacheStatus
						forKey : CMRThreadStatusKey];
}

+ (NSMutableDictionary *) attributesForThreadsListWithContentsOfFile : (NSString *) path
{
	NSMutableDictionary		*attributes_;
	unsigned				numMessages_;
	NSArray					*messageArray_;
	NSNumber				*status_;
	NSString *removeKeys_[] = {	ThreadPlistContentsKey,
								ThreadPlistLengthKey,
								CMRThreadWindowFrameKey,
								CMRThreadLastReadedIndexKey,
								CMRThreadVisibleRangeKey };
	unsigned		i, cnt;
	
	attributes_ = [NSMutableDictionary dictionaryWithContentsOfFile : path];
	if(nil == attributes_)
		return nil;
	
	messageArray_ = [attributes_ objectForKey : ThreadPlistContentsKey];
	numMessages_ = (nil == messageArray_) ? 0 : [messageArray_ count];
	status_ = [NSNumber numberWithUnsignedInt : ThreadLogCachedStatus];
	
	[attributes_ setObject : path
					forKey : CMRThreadLogFilepathKey];
	
	[attributes_ setUnsignedInt : numMessages_
						 forKey : CMRThreadLastLoadedNumberKey];
	[attributes_ setUnsignedInt : ThreadLogCachedStatus
						 forKey : CMRThreadStatusKey];
	
	cnt = UTILNumberOfCArray(removeKeys_);
	for(i = 0; i < cnt; i++)
		[attributes_ removeObjectForKey : removeKeys_[i]];
	
	
	return attributes_;
}


/**
  * path�����ɃX���b�h�ꗗ��plist�`���t�@�C�������݂��Ȃ��ꍇ��
  * ���̃��\�b�h�������I�ɍ쐬����B
  * ���̃��\�b�h��writeToFirle:atomically�ɉ����ł���I�u�W�F�N�g��
  * �Ԃ��̂ŁA�t�@�C���ɕۑ����邱�ƁB
  * 
  * @param     �f���̃f�B���N�g��
  * @return     writeToFirle:atomically�ɉ����ł���I�u�W�F�N�g
  */
+ (id) threadsListTemplateWithPath : (NSString *) boardDirectory
{
	NSFileManager			*fileManager;
	SGFileRef				*boardDirRef_;
	NSString				*filename_;
	NSString				*fileExtention_;
	NSDirectoryEnumerator	*iter_;
	NSMutableArray			*list_;
	NSAutoreleasePool		*pool_;
	
	BOOL					isDirectory_;
	BOOL					result_;
	
	// 
	// �ɑΉ�����Library/���̃f�B���N�g��������
	// �u~~.thread�v���O�t�@�C�����烍�O�X���b�h�����W�B
	// 
	fileManager = [NSFileManager defaultManager];
	result_ = [fileManager fileExistsAtPath : boardDirectory isDirectory : &isDirectory_];
	
	if(NO == (result_ && isDirectory_)){
		UTILMethodLog;
		UTILDebugWrite2(
			@"ERR: fileExistsAtPath:%@ fail isDirectory = %@",
			boardDirectory,
			UTILBOOLString(isDirectory_));
		
		return nil;
	}
	
	boardDirRef_ = [SGFileRef fileRefWithPath : boardDirectory];
	UTILAssertNotNil(boardDirRef_);
	
	fileExtention_ = [[CMRDocumentFileManager defaultManager] threadDocumentFileExtention];
	
	list_ = [NSMutableArray array];
	
	pool_ = [[NSAutoreleasePool alloc] init];

	iter_ = [fileManager enumeratorAtPath : boardDirectory];
	while ((filename_ = [iter_ nextObject])){
		SGFileRef		*fileRef_;
		NSString			*acrualPath_;
		NSMutableDictionary *dict_;
		//
		// �g���q��thread�̃t�@�C�������𒊏o
		// 
		if(NO == [[filename_ pathExtension] isEqualToString : fileExtention_])
			continue;

		
		fileRef_ = [boardDirRef_ fileRefWithChildName : filename_];
		acrualPath_ = [fileRef_ pathContentResolvingLinkIfNeeded];
		if(nil == acrualPath_)
			continue;
		
		dict_ = [self attributesForThreadsListWithContentsOfFile : acrualPath_];
		if(nil == dict_) 
			continue;
		
		[list_ addObject : dict_];
	}

	[pool_ release];
	//NSLog(@"END");
	return list_;
}
@end


#if 0
@implementation CMRThreadsList(ReadThreadsList)
- (void) doLoadThreadsList : (CMRThreadLayout *) worker
{
	CMRThreadsListReadFileTask		*task_;
	
	
	UTILAssertNotNilArgument(worker, @"Thread Layout(Worker)");
	[self setWorker : worker];
	
	task_ = [[CMRThreadsListReadFileTask alloc]
				initWithThreadsListPath : [self threadsListPath]
				pathMapping : [self threadsInfo]];
	
	// �i�s�󋵂�\�����邽�߂̏��
	[task_ setBoardName : [self boardName]];
	[task_ setIdentifier : [self boardName]];
	
	// �I���ʒm
	[[NSNotificationCenter defaultCenter]
			addObserver : self
			selector : @selector(threadsUpdateListTaskDidFinish:)
			name : CMRThreadsUpdateListTaskDidFinishNotification
			object : task_];
	
	if(1)
		[[self worker] push : task_];
	else
		[task_ executeWithLayout : [self worker]];
	
	[task_ release];
}
- (void) startUpdateThreadsList : (NSMutableArray *) aList
						 update : (BOOL            ) isUpdated
					 usesWorker : (BOOL            ) usesWorker;
{
	CMRThreadsUpdateListTask		*task_;
	
	
	UTILAssertNotNilArgument(aList, @"Threads List Array");
	
	task_ = [[CMRThreadsUpdateListTask alloc]
				initWithLoadedList : aList
				pathMapping : [self threadsInfo]
				update : isUpdated];
	
	// �i�s�󋵂�\�����邽�߂̏��
	[task_ setBoardName : [self boardName]];
	[task_ setIdentifier : [self boardName]];
	
	// �I���ʒm
	[[NSNotificationCenter defaultCenter]
			addObserver : self
			selector : @selector(threadsUpdateListTaskDidFinish:)
			name : CMRThreadsUpdateListTaskDidFinishNotification
			object : task_];
	if (usesWorker)
		[[self worker] push : task_];
	else
		[task_ executeWithLayout : [self worker]];

	[task_ release];
}

- (void) _applyFavItemsPool
{
	NSEnumerator	*iter_;
	NSMutableArray	*array_;
	NSString		*path_;
	CMRFavoritesManager	*fm_ = [CMRFavoritesManager defaultManager];
	
	array_ = [[fm_ itemsForRemoving] copy];
	if (array_ == nil || [array_ count] == 0) {
		[array_ release];
		return;
	}
	
	iter_ = [array_ objectEnumerator];
	while(path_ = [iter_ nextObject]){
		NSMutableDictionary		*thread_;
		
		thread_ = [self seachThreadByPath : path_];
		if (thread_ != nil) {
			[[self class] clearAttributes : thread_];
			[fm_ removeFromPoolWithFilePath : path_];
		}
	}
	
	[array_ release];
}


- (void) _syncFavItemsPool
{
	NSEnumerator	*iter_;
	NSMutableArray	*array_;
	NSString		*path_;
	CMRFavoritesManager	*fm_ = [CMRFavoritesManager defaultManager];
	
	array_ = [[fm_ itemsForChange] copy];

	if (array_ == nil || [array_ count] == 0) {
		[array_ release];
		return;
	}
	
	iter_ = [array_ objectEnumerator];
	while(path_ = [iter_ nextObject]){
		NSMutableDictionary		*thread_;
		
		thread_ = [self seachThreadByPath : path_];
		if (thread_ != nil) {
			int		i;

			i = [[fm_ favoritesItemsIndex] indexOfObject : path_];
			if (i == NSNotFound) break;

			if(synchronizeThAttrForSync2(thread_, [[fm_ favoritesItemsArray] objectAtIndex : i])) {
				// ��Еt���͂������
				[fm_ removeFromPoolWithFilePath : path_];
			}
		}
	}
	
	[array_ release];
}

- (void) threadsUpdateListTaskDidFinish : (NSNotification *) aNotification
{
	id					object_;
	NSDictionary		*userInfo_;
	NSMutableArray		*threadsArray_;
	NSMutableDictionary	*threadsInfo_;
	NSNumber			*isUpdated_;
	
	
	UTILAssertNotificationName(
		aNotification,
		CMRThreadsUpdateListTaskDidFinishNotification);
	
	// 2003-10-07 Takanori Ishikawa <takanori@gd5.so-net.ne.jp>
	// --------------------------------
	// * �^�X�N��SGBaseObject�Ƃ��čė��p����邽�߁A�ʂ̍X�V�œ�d�ɌĂяo�����
	// �A���邢�͑��̔̍X�V�ŌĂяo����Ă��܂��\��������B
	// �����
	// * �^�X�N�̎��ʎq����ɂ��Ĕ���
	// * �o�^�����ʒm�͉������Ă����B
	
	object_ = [aNotification object];
	UTILAssertKindOfClass(object_, CMRThreadsUpdateListTask);
	if(NO == [[object_ identifier] isEqual : [self boardName]])
		return;
	
	
	userInfo_ = [aNotification userInfo];
	
	threadsArray_	= [userInfo_ objectForKey : kCMRUserInfoThreadsArrayKey];
	threadsInfo_	= [userInfo_ objectForKey : kCMRUserInfoThreadsDictKey];
	isUpdated_		= [userInfo_ objectForKey : kCMRUserInfoIsUpdatedKey];
	UTILAssertKindOfClass(threadsArray_, NSMutableArray);
	UTILAssertKindOfClass(threadsInfo_, NSMutableDictionary);
	UTILAssertKindOfClass(isUpdated_, NSNumber);
	

	[_threadsListUpdateLock lock];
	[self _applyFavItemsPool];
	[self _syncFavItemsPool];
	[self setThreads : threadsArray_];
	[_threadsListUpdateLock unlock];
	//[self postListDidUpdateNotification : CMRAutoscrollWhenTLUpdate];
	
	if(NO == [isUpdated_ boolValue]){
		//
		// �t�@�C������̓ǂݍ���
		//
		if([CMRPref isOnlineMode] && ![self isFavorites]){
			// 
			// �����X�V
			// 
			[self downloadThreadsList];
		} else {
			[self postListDidUpdateNotification : CMRAutoscrollWhenTLUpdate];
		}
	} else {
		[self postListDidUpdateNotification : CMRAutoscrollWhenTLUpdate];
	}
	[[NSNotificationCenter defaultCenter]
			removeObserver : self
			name : [aNotification name]
			object : [aNotification object]];
}
@end

#endif
