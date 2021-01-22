
LOCAL_PATH := $(call my-dir)

# Optional prebuilt package: ffmpeg version of nvidia codec SDK headers
$(call register-prebuilt-pkg-config-module,ffnvcodec,ffnvcodec)

include $(CLEAR_VARS)

LOCAL_MODULE := ffmpeg-libav
LOCAL_CATEGORY_PATH := multimedia/ffmpeg
LOCAL_DESCRIPTION := Cross-platform tools and libraries to convert, manipulate and stream a wide range of multimedia formats and protocols

LOCAL_CONFIG_FILES := aconfig.in
$(call load-config)

ifeq ("$(TARGET_ARCH)","x64")
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --arch="x86_64"
else
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --arch="$(TARGET_ARCH)"
endif

# Main compilation options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-shared \
	--enable-cross-compile \
	--enable-optimizations \
	--cross-prefix="$(TARGET_CROSS)"

ifeq ("$(TARGET_OS)","windows")
  ifeq ("$(TARGET_ARCH)","x86")
    LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --target-os="mingw32"
  else ifeq ("$(TARGET_ARCH)","x64")
    LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --target-os="mingw64"
  endif
else
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --target-os="$(TARGET_OS)"
endif

# on x86_*, nasm is expected
ffmpeg_use_nasm := $(if $(filter $(TARGET_ARCH),x86 x64),1,0)

ifeq ("$(ffmpeg_use_nasm)","1")
  LOCAL_DEPENDS_HOST_MODULES := host.nasm
else
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --disable-x86asm
endif

# Components options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-orc \
	--disable-avconv \
	--disable-avplay \
	--disable-avprobe \
	--disable-avserver \
	--disable-avdevice \
	--disable-avresample \
	--disable-filters \
	--disable-bzlib \
	--disable-stripping

# Licensing options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-gpl \
	--disable-version3 \
	--disable-nonfree

# User selected components
#
# By default all decoders/encoders/parsers/muxers/demuxers are disabled to
# reduce the compilation time.
# When a user needs a specific component a new configuration should be added
# to 'aconfig.in' and an entry should be added in this section
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --disable-everything

ifdef CONFIG_FFMPEG_HEVC_DECODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-avcodec \
	--enable-decoder=hevc
endif

ifdef CONFIG_FFMPEG_AVC_DECODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-avcodec \
	--enable-decoder=h264
endif

ifdef CONFIG_FFMPEG_AAC_ENCODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-avcodec \
	--enable-encoder=aac
endif

ifdef CONFIG_FFMPEG_MOV_FORMAT
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-demuxer=mov \
	--enable-muxer=mov
endif

ifdef CONFIG_FFMPEG_PROGRAMS
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-protocol=file \
	--enable-demuxer=h264 \
	--enable-muxer=h264 \
	--enable-parser=h264 \
	--enable-muxer=mp4
else
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-programs
endif

ifdef CONFIG_FFMPEG_ENABLE_VDPAU
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-vdpau \
	--enable-decoder=h264_vdpau
endif

# Optional NVDEC HW decoding support: use the nvidia headers as prebuilt package
LOCAL_CONDITIONAL_LIBRARIES := \
	OPTIONAL:ffnvcodec
ifneq ("$(call is-module-in-build-config,ffnvcodec)","")
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-nvdec \
	--enable-hwaccel=h264_nvdec \
	--enable-hwaccel=hevc_nvdec
endif

# License check (shall be the last rule)
ifneq (,$(filter --enable-nonfree --enable-version3 --enable-nonfree, \
	$(LOCAL_AUTOTOOLS_CONFIGURE_ARGS)))
$(warning some options: "$(filter --enable-nonfree --enable-version3 \
	--enable-nonfree, $(LOCAL_AUTOTOOLS_CONFIGURE_ARGS))" \
	are not compatible with a release)
endif

# Export libraries
LOCAL_EXPORT_LDLIBS = \
	-lavcodec \
	-lavutil \
	-lavformat \
	-lavfilter \
	-lswresample \
	-lswscale

LOCAL_LIBRARIES := zlib

include $(BUILD_AUTOTOOLS)
