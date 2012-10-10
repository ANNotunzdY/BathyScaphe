//
//  URLConnector_Prefix.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/22.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <SGFoundation/SGFoundation.h>
#import <CocoMonar/CocoMonar.h>
#import "UTILKit.h"


#define PLUGIN_BUNDLE	[NSBundle bundleForClass:[SG2chConnector class]]

#define PluginLocalizedStringFromTable(key, tableName, comment)		\
	NSLocalizedStringFromTableInBundle(key, tableName, PLUGIN_BUNDLE, comment)
