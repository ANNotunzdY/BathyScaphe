/**
  * $Id: PreferencesPane-Toolbar.m,v 1.2 2005-05-22 18:02:26 tsawada2 Exp $
  * 
  * PreferencesPane-Toolbar.m
  *
  * Copyright (c) 2003, Takanori Ishikawa.
  * See the file LICENSE for copying permission.
  */
#import "PreferencesPane.h"
#import "PreferencesController.h"
#import "AppDefaults.h"
#import "PreferencePanes_Prefix.h"

@implementation PreferencesPane(ToolbarSupport)
/* Accessor for _toolbarItems */
- (NSMutableDictionary *) toolbarItems
{
	if(nil == _toolbarItems){
		_toolbarItems = [[NSMutableDictionary alloc] init];
	}
	return _toolbarItems;
}


/**
  * 引数itemIdentifierで指定されたツールバーの項目を返す。
  * 重複する項目もありえるので、コピーを作成すること。
  * 
  * @param    toolbar         ツールバー
  * @param    itemIdentifier  識別子
  * @param    flag            項目が追加される場合はYES
  * @return                   ツールバーの項目
  */

- (NSToolbarItem *) toolbar : (NSToolbar *) toolbar
      itemForItemIdentifier : (NSString  *) itemIdentifier
  willBeInsertedIntoToolbar : (BOOL       ) flag
{
	NSToolbarItem	*item_;
	NSString		*name_;
	NSToolbarItem	*newItem_;
	NSArray			*list_;
	
	item_ = [[self toolbarItems] objectForKey : itemIdentifier];
	name_ = [item_ itemIdentifier];

	list_ = flag ? [self toolbarDefaultItemIdentifiers : toolbar]
	             : [self toolbarAllowedItemIdentifiers : toolbar];
	
	newItem_ = [item_ copyWithZone : [self zone]];
	
	if(NSNotFound == [list_ indexOfObject : name_]){
		[newItem_ release];
		return nil;
	}
	[newItem_ setTarget : self];
	if ([newItem_ view] != nil) {
		[newItem_ setMinSize : [[newItem_ view] bounds].size];
		[newItem_ setMaxSize : [[newItem_ view] bounds].size];
	}
	
	return [newItem_ autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers : (NSToolbar *) toolbar
{
	if(NO == [[toolbar identifier] isEqualToString : PPToolbarIdentifier])
		return [NSArray empty];
	
	return [NSArray arrayWithObjects :
				PPGeneralPreferencesIdentifier,
				PPAccountSettingsIdentifier,
				PPFilterPreferencesIdentifier,
				PPFontsAndColorsIdentifier,
				PPReplyDefaultIdentifier,
				PPAdvancedPreferencesIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers : (NSToolbar *) toolbar
{
	if(NO == [[toolbar identifier] isEqualToString : PPToolbarIdentifier])
		return [NSArray empty];
	
	return [NSArray arrayWithObjects :
				PPGeneralPreferencesIdentifier,
				PPAccountSettingsIdentifier,
				PPFilterPreferencesIdentifier,
				PPFontsAndColorsIdentifier,
				PPReplyDefaultIdentifier,
				PPAdvancedPreferencesIdentifier,
				NSToolbarFlexibleSpaceItemIdentifier,
				nil];
}

/*
Mac OS X 10.3以上で、ツールバーで選択されている項目をハイライトするための仕掛け
ハイライトを許可する項目の配列を作って渡す。
10.2.x以前ではこのメソッドは呼ばれない。
*/
- (NSArray *) toolbarSelectableItemIdentifiers : (NSToolbar *) toolbar
{
	if(NO == [[toolbar identifier] isEqualToString : PPToolbarIdentifier])
		return [NSArray empty];
	
	return [NSArray arrayWithObjects :
				PPGeneralPreferencesIdentifier,
				PPAccountSettingsIdentifier,
				PPFilterPreferencesIdentifier,
				PPFontsAndColorsIdentifier,
				PPReplyDefaultIdentifier,
				PPAdvancedPreferencesIdentifier,
				nil];
}

/*
- (NSImage *) _imageResourceWithName : (NSString *) name
{
	NSBundle *bundle_;
	NSString *filepath_;
	bundle_ = [NSBundle bundleForClass : [self class]];
	filepath_ = [bundle_ pathForImageResource : name];
	
	if(nil == filepath_) return nil;
	
	return [[[NSImage alloc] initWithContentsOfFile : filepath_] autorelease];
}
*/

/*
- (NSImage *) _toolbarIconWithName : (NSString *) name
{
	static NSSize _tbItemSize = {32, 32};
	NSImage *tbItemImage_;
	NSSize   oldSize_;
	NSSize   newSize_;
	
	tbItemImage_ = [self _imageResourceWithName : name];
	if(nil == tbItemImage_) return nil;

	newSize_.width = (oldSize_.width <= _tbItemSize.width)
						? oldSize_.width 
						: _tbItemSize.width;
	newSize_.height = (oldSize_.height <= _tbItemSize.height)
						? oldSize_.height 
						: _tbItemSize.height;
	if(NO == NSEqualSizes(newSize_, _tbItemSize)){
		[tbItemImage_ setSize : newSize_];
	}
	
	return tbItemImage_;
}
*/

- (void) setupToolbar
{
	NSToolbar				*toolbar_;
	NSToolbarItem			*tbItem_;
	NSEnumerator			*iter_;
	PreferencesController	*controller_;
	SEL action_ = @selector(selectController:);
	
	toolbar_= [[NSToolbar alloc] initWithIdentifier : PPToolbarIdentifier];
	
	iter_ = [[self controllers] objectEnumerator];
	while(controller_ = [iter_ nextObject]){
		if(nil == [controller_ identifier])
			continue;
		
		tbItem_ = [controller_ makeToolbarItem];
		[[self toolbarItems] setObject:tbItem_ forKey:[tbItem_ itemIdentifier]];
		[tbItem_ setTarget : self];
		[tbItem_ setAction : action_];
		[tbItem_ release];
	}
	
	[toolbar_ setDelegate : self];
	[toolbar_ setAllowsUserCustomization : NO];
	[toolbar_ setAutosavesConfiguration : NO];
	
/*
2003-11-11 Takanori Ishikawa <takanori@gd5.so-net.ne.jp>
--------------------------------------------------------
実行時のOSバージョンチェック
NSAppKitVersionNumberでやってもいいんだけど、10.2でビルドしているので
Objective-CならrespondsToSelector:でチェックしても安全
*/
	if([toolbar_ respondsToSelector : @selector(setSelectedItemIdentifier:)]){
		
		//Mac OS X 10.3以降では、ペインに応じてツールバーボタンをハイライトさせる。
		//最初に「環境設定」を開く時に、ハイライトされているべきツールバーボタンは何か？
		NSUserDefaults *defaults_;
		NSString       *shouldSelectedTbIdentifier_;
		
		defaults_ = [NSUserDefaults standardUserDefaults];
		shouldSelectedTbIdentifier_ = [defaults_ stringForKey : PPLastOpenPaneIdentifier];
		//最後に開いていたペインがわからない場合、「表示」ペインにする。即ち「表示」ツールバーボタンを選択。
		if(nil == shouldSelectedTbIdentifier_)
		        shouldSelectedTbIdentifier_ = PPFontsAndColorsIdentifier;
		
		// ハイライトさせる
		
		[toolbar_ setSelectedItemIdentifier: shouldSelectedTbIdentifier_];
	}

	[[self window] setToolbar : toolbar_];
	[toolbar_ release];
}
@end