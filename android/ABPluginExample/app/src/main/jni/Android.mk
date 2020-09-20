LOCAL_PATH := $(call my-dir)

###

include $(CLEAR_VARS)

LOCAL_MODULE            := lua
LOCAL_SRC_FILES         := ../jniLibs/$(TARGET_ARCH_ABI)/liblua.so

include $(PREBUILT_SHARED_LIBRARY)

###

include $(CLEAR_VARS)

LOCAL_MODULE            := gideros
LOCAL_SRC_FILES         := ../jniLibs/$(TARGET_ARCH_ABI)/libgideros.so

include $(PREBUILT_SHARED_LIBRARY)


###

#
# Plugins
#

###

include $(CLEAR_VARS)

LOCAL_MODULE           := abplugin
LOCAL_ARM_MODE         := arm
LOCAL_C_INCLUDES       := ${LOCAL_PATH}/gideros/include/
LOCAL_CFLAGS           := -O2
LOCAL_SRC_FILES        := abpluginbinder.cpp gabplugin.cpp
LOCAL_LDLIBS           := -ldl -llog
LOCAL_SHARED_LIBRARIES := lua gideros

include $(BUILD_SHARED_LIBRARY)

###

