LOCAL_PATH := $(call my-dir)

###############################################################################
# ffmpeg libav
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := ffmpeg-libav
LOCAL_CATEGORY_PATH := multimedia/ffmpeg

LOCAL_DESCRIPTION := cross-platform tools and libraries to convert, manipulate and stream a wide range of multimedia formats and protocols


# Main compilation options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-shared \
	--enable-cross-compile \
	--enable-optimizations \
	--target-os="linux" \
	--cross-prefix="$(TARGET_CROSS)"

ifeq ("$(TARGET_ARCH)","x64")
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --arch="x86_64"
else
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --arch="$(TARGET_ARCH)"
endif

# Components options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-orc \
	--disable-programs \
	--disable-avconv \
	--disable-avplay \
	--disable-avprobe \
	--disable-avserver \
	--disable-avdevice \
	--disable-avresample \
	--disable-filters \
	--disable-network \
	--disable-yasm \
	--disable-bzlib

# Lisencing options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-gpl \
	--disable-version3 \
	--disable-nonfree

LOCAL_LIBRARIES := zlib

include $(BUILD_AUTOTOOLS)

