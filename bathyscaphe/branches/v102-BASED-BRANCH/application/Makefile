# 
# makefile for CocoMonar application
#

ROOT = ..

include $(ROOT)/config

app:
	$(PBXBUILD) -target bathyscaphe $(BUILD_OPTION)

all:
	$(PBXBUILD) $(BUILD_OPTION)

clean:
	$(PBXBUILD) -alltargets clean
	rm -rf $(BUILD_DIR)
