# 
# makefile for BathyScaphe all frameworks.
#

PBXBUILD = /usr/bin/xcodebuild
BUILD_OPTION = -configuration Deployment
OGREKIT_BUILD_OPTIONS = -target 'OgreKit (without Find Panel)' -configuration Release
COCOAONIG_BUILD_OPTIONS = -target 'CocoaOniguruma' -configuration Release
CLEAN_OPTIONS = -alltargets
BUILD_DIR = build

SGFOUNDATION_FRWK = SGFoundation
SGAPPKIT_FRWK = SGAppKit
COCOMONAR_FRWK = CocoMonar
OGREKIT_FRWK = OgreKit
COCOAONIG_FRWK = CocoaOniguruma/framework

.PHONY: SGFoundation  SGAppKit CocoMonar CocoaOniguruma

all: SGFoundation SGAppKit CocoMonar CocoaOniguruma
	
SGFoundation: 
	cd $(SGFOUNDATION_FRWK) && $(PBXBUILD) $(BUILD_OPTION)
	
SGAppKit: SGFoundation
	cd $(SGAPPKIT_FRWK) && $(PBXBUILD) $(BUILD_OPTION)

CocoMonar: SGFoundation
	cd $(COCOMONAR_FRWK) && $(PBXBUILD) $(BUILD_OPTION)

OgreKit:
	cd $(OGREKIT_FRWK) && $(PBXBUILD) $(OGREKIT_BUILD_OPTIONS)

CocoaOniguruma:
	cd $(COCOAONIG_FRWK) && $(PBXBUILD) $(COCOAONIG_BUILD_OPTIONS)

clean: clean-SGFoundation clean-SGAppKit clean-CocoMonar clean-CocoaOniguruma

clean-SGFoundation: 
	cd $(SGFOUNDATION_FRWK) && $(PBXBUILD) $(CLEAN_OPTIONS) clean && rm -fr $(BUILD_DIR)
	
clean-SGAppKit:
	cd $(SGAPPKIT_FRWK) && $(PBXBUILD) $(CLEAN_OPTIONS) clean && rm -fr $(BUILD_DIR)

clean-CocoMonar:
	cd $(COCOMONAR_FRWK) && $(PBXBUILD) $(CLEAN_OPTIONS) clean && rm -fr $(BUILD_DIR)

clean-OgreKit:
	cd $(OGREKIT_FRWK) && $(PBXBUILD) $(CLEAN_OPTIONS)  -configuration Release clean && rm -fr $(BUILD_DIR)

clean-CocoaOniguruma:
	cd $(COCOAONIG_FRWK) && $(PBXBUILD) $(CLEAN_OPTIONS)  -configuration Release clean && rm -fr $(BUILD_DIR)

