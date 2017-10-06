LOCAL_PATH := $(call my-dir)

###############################################################################
# ffmpeg libav
###############################################################################

include $(CLEAR_VARS)

LOCAL_MODULE := ffmpeg-libav
LOCAL_CATEGORY_PATH := multimedia/ffmpeg

LOCAL_DESCRIPTION := cross-platform tools and libraries to convert, manipulate and stream a wide range of multimedia formats and protocols

LOCAL_CONFIG_FILES := aconfig.in
$(call load-config)


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

ifdef CONFIG_FFMPEG_MINIMAL_AVC_HEVC_DECODING

# Components options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-all \
	--enable-avcodec \
	--enable-decoder=h264 \
	--enable-decoder=hevc

ifdef CONFIG_FFMPEG_ENABLE_CUVID

# WARNING: non-free software is enabled in this configuration,
# the software must not be distributed with cuvid enabled.

LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-decoder=h264_cuvid \
	--enable-decoder=hevc_cuvid \
	--enable-nvenc \
	--enable-cuda \
	--enable-cuvid \
	--enable-libnpp \
	--enable-nonfree \
	--extra-cflags=-I/usr/local/cuda/include \
	--extra-ldflags=-L/usr/local/cuda/lib64

endif

ifdef CONFIG_FFMPEG_ENABLE_VDPAU

LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-decoder=h264_vdpau \
	--enable-vdpau

endif

# Export libraries
LOCAL_EXPORT_LDLIBS = -lavcodec -lavutil

else

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

endif

LOCAL_LIBRARIES := zlib

include $(BUILD_AUTOTOOLS)

