/**
 * $Id: AppDefaults-Bundle.m,v 1.18 2007-11-25 15:00:28 tsawada2 Exp $
 * 
 * AppDefaults-Bundle.m
 *
 * Copyright (c) 2004 Takanori Ishikawa, All rights reserved.
 * See the file LICENSE for copying permission.
 */

#import "AppDefaults_p.h"
#import "w2chConnect.h"
#import "UTILKit.h"
#import "CMRMainMenuManager.h"

#define ImagePreviewerPluginName  @"ImagePreviewer"
#define ImagePreviewerPluginType  @"plugin"

#define PreferencesPanePluginName  @"PreferencesPane"
#define PreferencesPanePluginType  @"plugin"

#define w2chConnectorPluginName    @"2chConnector"
#define w2chConnectorPluginType    @"plugin"
#define w2chConnectorClassName     @"SG2chConnector"
#define w2chAuthenticatorClassName @"w2chAuthenticator"

#define be2chAuthenticatorClassName @"be2chAuthenticator"

//static NSString *const AppDefaultsHelperAppNameKey = @"Helper Application Path";
static NSString *const AppDefaultsImagePreviewerSettingsKey = @"Preferences - ImagePreviewer Plugin";


#pragma mark -

@implementation AppDefaults(BundleSupport)
static Class st_class_2chAuthenticator;
static Class st_class_be2chAuthenticator;

- (NSMutableDictionary *) imagePreviewerPrefsDict
{
	if(nil == m_imagePreviewerDictionary){
		NSDictionary	*dict_;
		
		dict_ = [[self defaults] 
					dictionaryForKey : AppDefaultsImagePreviewerSettingsKey];
		m_imagePreviewerDictionary = [dict_ mutableCopy];
	}
	
	if(nil == m_imagePreviewerDictionary)
		m_imagePreviewerDictionary = [[NSMutableDictionary alloc] init];
	
	return m_imagePreviewerDictionary;
}

- (NSBundle *) moduleWithName : (NSString *) bundleName
                       ofType : (NSString *) type
                  inDirectory : (NSString *) bundlePath
{
    NSBundle    *bundles[] = {
                [NSBundle applicationSpecificBundle], 
                [NSBundle mainBundle],
                nil};
    NSBundle    **p = bundles;
    NSString    *path_ = nil;
    
    for (; *p != nil; p++)
        if (path_ = [*p pathForResource : bundleName
								 ofType : type
							inDirectory : bundlePath])
            break;
    
    if (nil == path_) {
        NSString *plugInsPath_;
        NSString *plugin_;

        plugin_ = [bundleName stringByAppendingPathExtension : type];
        //plugInsPath_ = [bundle_ builtInPlugInsPath];
		plugInsPath_ = [[NSBundle mainBundle] builtInPlugInsPath];
        path_ = [plugInsPath_ stringByAppendingPathComponent : plugin_];
    }
    return [NSBundle bundleWithPath : path_];
}

- (id)loadLinkPreviewer
{
    static Class kLinkPreviewerInstance;
    
    if (Nil == kLinkPreviewerInstance) {
        NSBundle	*module;
		Class		newPreviewerClass;

        module = [self moduleWithName:ImagePreviewerPluginName ofType:ImagePreviewerPluginType inDirectory:@"PlugIns"];

        if (!module) {
            NSLog(@"Couldn't load plugin<%@.%@>", ImagePreviewerPluginName, ImagePreviewerPluginType);
            return nil;
        }

		m_installedPreviewer = module;

		newPreviewerClass = [module principalClass];
		if (!newPreviewerClass || ![newPreviewerClass conformsToProtocol:@protocol(BSLinkPreviewing)]) {
			NSLog(@"Principal class <%@> doesn't conform to protocol BSLinkPreviewing! So we cancel loading this plugin", 
					newPreviewerClass ? NSStringFromClass(newPreviewerClass) : @"Nil");
			return nil;
		}
		
		kLinkPreviewerInstance = newPreviewerClass;
	}
	return [[[kLinkPreviewerInstance alloc] initWithPreferences:self] autorelease];
}

- (id)loadImagePreviewer
{
    static Class kPreviewerInstance;
    
    if (Nil == kPreviewerInstance) {
        NSBundle	*module;
		Class		previewerClass;

        module = [self moduleWithName:ImagePreviewerPluginName ofType:ImagePreviewerPluginType inDirectory:@"PlugIns"];

        if (!module) {
            NSLog(@"Couldn't load plugin<%@.%@>", ImagePreviewerPluginName, ImagePreviewerPluginType);
            return nil;
        }

		m_installedPreviewer = module;

		previewerClass = [module principalClass];
		if (!previewerClass || ![previewerClass conformsToProtocol:@protocol(BSImagePreviewerProtocol)]) {
			NSLog(@"Principal class <%@> doesn't conform to protocol BSImagePreviewerProtocol! So we cancel loading this plugin", 
					previewerClass ? NSStringFromClass(previewerClass) : @"Nil");
			return nil;
		}
		
		kPreviewerInstance = previewerClass;
	}
	return [[[kPreviewerInstance alloc] initWithPreferences:self] autorelease];
}

- (id)loadPreferencesPane
{
    static Class kPreferencesPaneInstance;

    if (Nil == kPreferencesPaneInstance) {
        NSBundle	*module;
		Class		preferencesPaneClass;

        module = [self moduleWithName:PreferencesPanePluginName ofType:PreferencesPanePluginType inDirectory:nil];

        if (!module) {
            NSLog(@"Couldn't load plugin<%@.%@>", PreferencesPanePluginName, PreferencesPanePluginType);
            return nil;
		}

		preferencesPaneClass = [module principalClass];
		if (!preferencesPaneClass || ![preferencesPaneClass conformsToProtocol:@protocol(BSPreferencesPaneProtocol)]) {
			NSLog(@"Principal class <%@> doesn't conform to protocol BSPreferencesPaneProtocol! So we cancel loading this plugin", 
					preferencesPaneClass ? NSStringFromClass(preferencesPaneClass) : @"Nil");
			return nil;
		}
		
		kPreferencesPaneInstance = preferencesPaneClass;
    }
    return [[[kPreferencesPaneInstance alloc] initWithPreferences:self] autorelease];
}

- (id<w2chConnect>) w2chConnectWithURL : (NSURL        *) anURL
                            properties : (NSDictionary *) properties
{
    static Class st_class_2chConnector;
    
    if (Nil == st_class_2chConnector) {
        NSBundle *module_;
        
        module_ = [self moduleWithName : w2chConnectorPluginName
                                ofType : w2chConnectorPluginType
                           inDirectory : nil];
        if (nil == module_) {
            NSLog(@"Couldn't load plugin<%@.%@>", 
                    w2chConnectorPluginName,
                    w2chConnectorPluginType);
            return nil;
        } else {
            if (Nil == st_class_2chAuthenticator) {
                st_class_2chAuthenticator = 
                  [module_ classNamed : w2chAuthenticatorClassName];
                NSAssert3(
                    (st_class_2chAuthenticator != Nil),
                    @"Couldn't load Class<%@> in <%@.%@>",
                    w2chAuthenticatorClassName,
                    w2chConnectorPluginName,
                    w2chConnectorPluginType);
                [st_class_2chAuthenticator setPreferencesObject : self];
            }
            st_class_2chConnector = [module_ classNamed : w2chConnectorClassName];
        }
    }
    if (Nil == st_class_2chConnector) {
        NSLog(@"Couldn't load Class<%@> in <%@.%@>", 
                w2chConnectorClassName,
                w2chConnectorPluginName,
                w2chConnectorPluginType);
        return nil;
    }
    
    return [st_class_2chConnector connectorWithURL : anURL
                              additionalProperties : properties];
}


- (id<BSPreferencesPaneProtocol>)sharedPreferencesPane
{
    static id instance_;
    if (!instance_) {
        instance_ = [[self loadPreferencesPane] retain];
    }
    return instance_;
}

- (id<BSLinkPreviewing>)sharedLinkPreviewer
{
    static id instance_;
    if (!instance_) {
        instance_ = [[self loadLinkPreviewer] retain];
    }
    return instance_;
}

- (id<BSImagePreviewerProtocol>)sharedImagePreviewer
{
    static id instance_;
    if (!instance_) {
        instance_ = [[self loadImagePreviewer] retain];
    }
    return instance_;
}

- (id<w2chAuthenticationStatus>)shared2chAuthenticator
{    
    if (Nil == st_class_2chAuthenticator) {
        NSBundle *module_;
        
        module_ = [self moduleWithName:w2chConnectorPluginName ofType:w2chConnectorPluginType inDirectory:nil];
        if (!module_) {
            NSLog(@"Couldn't load plugin<%@.%@>", w2chConnectorPluginName, w2chConnectorPluginType);
            return nil;
        } else {
			st_class_2chAuthenticator = [module_ classNamed:w2chAuthenticatorClassName];
			NSAssert3(
				(st_class_2chAuthenticator != Nil),
				@"Couldn't load Class<%@> in <%@.%@>",
				w2chAuthenticatorClassName,
				w2chConnectorPluginName,
				w2chConnectorPluginType);
			[st_class_2chAuthenticator setPreferencesObject:self];
        }
	}
	return [st_class_2chAuthenticator defaultAuthenticator];
}

- (id<be2chAuthenticationStatus>)sharedBe2chAuthenticator
{    
    if (Nil == st_class_be2chAuthenticator) {
        NSBundle *module_;
        
        module_ = [self moduleWithName:w2chConnectorPluginName ofType:w2chConnectorPluginType inDirectory:nil];
        if (!module_) {
            NSLog(@"Couldn't load plugin<%@.%@>", w2chConnectorPluginName, w2chConnectorPluginType);
            return nil;
        } else {
			st_class_be2chAuthenticator = [module_ classNamed:be2chAuthenticatorClassName];
			NSAssert3(
                      (st_class_be2chAuthenticator != Nil),
                      @"Couldn't load Class<%@> in <%@.%@>",
                      be2chAuthenticatorClassName,
                      w2chConnectorPluginName,
                      w2chConnectorPluginType);
			[st_class_be2chAuthenticator setPreferencesObject:self];
        }
	}
	return [st_class_be2chAuthenticator defaultAuthenticator];
}

- (NSBundle *)installedPreviewerBundle
{
	if (!m_installedPreviewer) {
        [self loadLinkPreviewer];
        if (!m_installedPreviewer) {
            [self loadImagePreviewer];
        }
	}
	return m_installedPreviewer;
}

- (void)letPreviewerShowPreferences:(id)sender
{
	if ([self previewerSupportsShowingPreferences]) {
        id previewer = [self sharedLinkPreviewer];
        if (!previewer) {
            previewer = [self sharedImagePreviewer];
        }
		[previewer showPreviewerPreferences:sender];
	}
}

- (BOOL)previewerSupportsShowingPreferences
{
    id previewer = [self sharedLinkPreviewer];
    if (!previewer) {
        previewer = [self sharedImagePreviewer];
    }
	return [previewer respondsToSelector:@selector(showPreviewerPreferences:)];
}

- (BOOL)previewerSupportsAppReset:(NSString **)resetLabelPtr
{
    id previewer = [self sharedLinkPreviewer];
    if (!previewer) {
        return NO;
    }
    if (![previewer respondsToSelector:@selector(resetPreviewer:)]) {
        return NO;
    }
    if (resetLabelPtr != NULL) {
        NSString *displayName = [m_installedPreviewer objectForInfoDictionaryKey:@"BSPreviewerResetLabel"];
        if (displayName) {
            *resetLabelPtr = displayName;
        } else {
            *resetLabelPtr = NSLocalizedString(@"Reset:Previewer Default", @"Label for reset previewer checkbox");
        }
    }
    return YES;
}

- (void) _loadImagePreviewerSettings
{
}

- (BOOL) _saveImagePreviewerSettings
{
	NSDictionary			*dict_;
	
	dict_ = [self imagePreviewerPrefsDict];
	
	UTILAssertNotNil(dict_);
	[[self defaults] setObject : dict_
						forKey : AppDefaultsImagePreviewerSettingsKey];
	return YES;
}
@end
