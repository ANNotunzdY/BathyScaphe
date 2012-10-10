//:CMRToolbarDelegateImp.h
/**
  *
  * encoding="UTF-8"
  * @version Fri Jun 14 2002
  *
  */
#import <Foundation/Foundation.h>
#import "CMRToolbarDelegate.h"

@interface CMRToolbarDelegateImp : NSObject<CMRToolbarDelegate, NSToolbarDelegate>
{
	NSMutableDictionary		*m_itemDictionary;
}
@end
