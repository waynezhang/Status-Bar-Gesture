SDKVERSION = 5.0
messages = yes

ifeq ($(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init
	./framework/git-submodule-recur.sh init
	$(MAKE) $(MAKEFLAGS) MAKELEVEL=0 $@
else

TWEAK_NAME = gesture
gesture_OBJC_FILES = gesture.m
gesture_FRAMEWORKS = UIKit
gesture_PRIVATE_FRAMEWORKS = GraphicsServices

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

endif
