
LOCAL_PATH := $(call my-dir)

ifeq ("$(TARGET_OS_FLAVOUR)","native")
  # Optional prebuilt package: OpenH264 prebuilt binaries
  $(call register-prebuilt-pkg-config-module,libopenh264,openh264)
endif

include $(CLEAR_VARS)

LOCAL_MODULE := ffmpeg-libav
LOCAL_CATEGORY_PATH := multimedia/ffmpeg
LOCAL_DESCRIPTION := Cross-platform tools and libraries to convert, manipulate and stream a wide range of multimedia formats and protocols

# Disable Vulkan beta extensions to prevent build errors caused by missing
# 'vulkan_beta.h' in the Android NDK/toolchain and to ensure binary stability.
LOCAL_CFLAGS += -DVK_ENABLE_BETA_EXTENSIONS=0

LOCAL_CONFIG_FILES := aconfig.in
$(call load-config)

ifeq ("$(TARGET_OS)","darwin")
  FFMPEG_ARCH := $(firstword $(subst -arch ,,$(APPLE_ARCH)))
  # Extra flags for all Apple archs
  EXTRA_FLAGS := $(foreach a,$(APPLE_ARCH),$(a))
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
    --arch=$(FFMPEG_ARCH) \
    --extra-cflags="$(EXTRA_FLAGS)" \
    --extra-ldflags="$(EXTRA_FLAGS)"
else ifeq ("$(TARGET_ARCH)","x64")
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --arch=x86_64
else
  LOCAL_AUTOTOOLS_CONFIGURE_ARGS += --arch=$(TARGET_ARCH)
endif

# Main compilation options
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-shared \
	--enable-cross-compile \
	--enable-optimizations \
	--cross-prefix="$(TARGET_CROSS)" \
	--cc=$(TARGET_CC) \
	--cxx=$(TARGET_CXX)

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

# Optional NVCODEC HW encoding/decoding support: use the nvidia headers
LOCAL_CONDITIONAL_LIBRARIES := \
	CONFIG_FFMPEG_ENABLE_NVCODEC:ffnvcodec
ifdef CONFIG_FFMPEG_ENABLE_NVCODEC
LOCAL_DEPENDS_MODULES += ffnvcodec
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-nvdec \
	--enable-nvenc
endif

# Optional OpenH264 encoding support
ffmpeg_has_openh264 := $(call is-module-in-build-config,libopenh264)
ifneq ("$(ffmpeg_has_openh264)","")
LOCAL_CONDITIONAL_LIBRARIES := \
	CONFIG_FFMPEG_ENABLE_OPENH264:libopenh264
ifdef CONFIG_FFMPEG_ENABLE_OPENH264
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-libopenh264
endif
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
# Only avcodec is enabled.
# When a user needs a specific component a new configuration should be added
# to 'aconfig.in' and an entry should be added in this section
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-all \
	--disable-everything \
	--enable-avcodec
LOCAL_EXPORT_LDLIBS += \
	-lavcodec \
	-lavutil

ifdef CONFIG_FFMPEG_ENABLE_NVMPI
LOCAL_COPY_TO_BUILD_DIR := 1
LOCAL_DEPENDS_MODULES += jetson-ffmpeg
define LOCAL_CMD_BOOTSTRAP
	(cd $(PRIVATE_SRC_DIR)/../jetson-ffmpeg && bash ./ffpatch.sh $(PRIVATE_SRC_DIR))
endef
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-nvmpi
ifdef CONFIG_FFMPEG_HEVC_DECODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-decoder=hevc_nvmpi
endif
ifdef CONFIG_FFMPEG_AVC_DECODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-decoder=h264_nvmpi
endif
endif

ifdef CONFIG_FFMPEG_HEVC_DECODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-decoder=hevc
ifdef CONFIG_FFMPEG_ENABLE_NVCODEC
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-hwaccel=hevc_nvdec
endif
endif

ifdef CONFIG_FFMPEG_AVC_DECODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-decoder=h264
ifdef CONFIG_FFMPEG_ENABLE_NVCODEC
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-hwaccel=h264_nvdec
endif
endif

ifdef CONFIG_FFMPEG_HEVC_ENCODING
ifdef CONFIG_FFMPEG_ENABLE_NVCODEC
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-encoder=hevc_nvenc
endif
endif

ifdef CONFIG_FFMPEG_AVC_ENCODING
ifdef CONFIG_FFMPEG_ENABLE_NVCODEC
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-encoder=h264_nvenc
endif
ifneq ("$(ffmpeg_has_openh264)","")
ifdef CONFIG_FFMPEG_ENABLE_OPENH264
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-encoder=libopenh264
endif
endif
endif

ifdef CONFIG_FFMPEG_AAC_ENCODING
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-encoder=aac
endif

ifdef CONFIG_FFMPEG_MOV_FORMAT
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-avformat \
	--enable-demuxer=mov \
	--enable-muxer=mov
endif

ifdef CONFIG_FFMPEG_PROGRAMS
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-avfilter \
	--enable-avformat \
	--enable-swresample \
	--enable-swscale \
	--enable-ffmpeg \
	--enable-ffplay \
	--enable-ffprobe \
	--enable-protocol=file \
	--enable-demuxer=h264 \
	--enable-muxer=h264 \
	--enable-parser=h264 \
	--enable-demuxer=mov \
	--enable-muxer=mp4
LOCAL_EXPORT_LDLIBS += \
	-lavformat \
	-lavfilter \
	-lswresample \
	-lswscale
else
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--disable-programs
endif

ifdef CONFIG_FFMPEG_ENABLE_VDPAU
LOCAL_AUTOTOOLS_CONFIGURE_ARGS += \
	--enable-vdpau \
	--enable-decoder=h264_vdpau
endif

# License check (shall be the last rule)
ifneq (,$(filter --enable-nonfree --enable-version3 --enable-nonfree, \
	$(LOCAL_AUTOTOOLS_CONFIGURE_ARGS)))
$(warning some options: "$(filter --enable-nonfree --enable-version3 \
	--enable-nonfree, $(LOCAL_AUTOTOOLS_CONFIGURE_ARGS))" \
	are not compatible with a release)
endif

LOCAL_LIBRARIES := zlib
ifdef CONFIG_FFMPEG_ENABLE_NVMPI
LOCAL_LIBRARIES += jetson-ffmpeg
endif

define LOCAL_AUTOTOOLS_CMD_POST_INSTALL
	@rm -rf $(TARGET_OUT_STAGING)/usr/share/ffmpeg
endef

include $(BUILD_AUTOTOOLS)
