LOCAL_PATH :=$(call my-dir)
include $(CLEAR_VARS)

LOCAL_CFLAGS += -D__STDC_CONSTANT_MACROS
LOCAL_C_INCLUDES := \
    $(LOCAL_PATH)/3rdparty \
    $(LOCAL_PATH)/3rdparty/ffmpeg/include \
	$(LOCAL_PATH)/include

LOCAL_SRC_FILES := \
    libyuv/compare.cc           \
    libyuv/compare_common.cc    \
    libyuv/convert.cc           \
    libyuv/convert_argb.cc      \
    libyuv/convert_from.cc      \
    libyuv/convert_from_argb.cc \
    libyuv/convert_to_argb.cc   \
    libyuv/convert_to_i420.cc   \
    libyuv/cpu_id.cc            \
    libyuv/planar_functions.cc  \
    libyuv/rotate.cc            \
    libyuv/rotate_any.cc        \
    libyuv/rotate_argb.cc       \
    libyuv/rotate_common.cc     \
    libyuv/row_any.cc           \
    libyuv/row_common.cc        \
    libyuv/scale.cc             \
    libyuv/scale_any.cc         \
    libyuv/scale_argb.cc        \
    libyuv/scale_common.cc      \
    libyuv/video_common.cc      \
    udp.c   \
    YUVUtils.c \
    FFmpegDecoder.cpp \
    FFmpegEncoder.cpp \
    H264SoftEncoder.cpp \
    H264SoftDecoder.cpp \
    egl_core.cpp \
    egl_share_context.cpp \
    H264Output.cpp  \
    video_gl_surface_render.cpp

ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
    LOCAL_CFLAGS += -DLIBYUV_NEON
    LOCAL_SRC_FILES += \
        libyuv/compare_neon.cc.neon    \
        libyuv/rotate_neon.cc.neon     \
        libyuv/row_neon.cc.neon        \
        libyuv/scale_neon.cc.neon
endif

ifeq ($(TARGET_ARCH_ABI),arm64-v8a)
    LOCAL_CFLAGS += -DLIBYUV_NEON
    LOCAL_SRC_FILES += \
        libyuv/compare_neon64.cc    \
        libyuv/rotate_neon64.cc     \
        libyuv/row_neon64.cc        \
        libyuv/scale_neon64.cc
endif

ifeq ($(TARGET_ARCH_ABI),$(filter $(TARGET_ARCH_ABI), x86 x86_64))
    LOCAL_SRC_FILES += \
        libyuv/compare_gcc.cc       \
        libyuv/rotate_gcc.cc        \
        libyuv/row_gcc.cc           \
        libyuv/scale_gcc.cc
endif

LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libfdk-aac.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libavfilter.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libvo-aacenc.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libavformat.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libavcodec.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libavutil.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libswscale.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libswresample.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libpostproc.a
LOCAL_LDFLAGS += $(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI)/libx264.a

LOCAL_LDLIBS := -L$(SYSROOT)/usr/lib -llog
# Link with OpenSL ES
LOCAL_LDLIBS += -lOpenSLES
# Link with OpenGL ES
LOCAL_LDLIBS += -lGLESv2
LOCAL_LDLIBS += -lz
#LOCAL_LDLIBS += -lgomp
LOCAL_LDLIBS += -landroid
LOCAL_LDLIBS += -lEGL

LOCAL_LDLIBS += -L$(LOCAL_PATH)/3rdparty/prebuilt/$(TARGET_ARCH_ABI) -lfdk-aac -lvo-aacenc

LOCAL_MODULE :=ndkmain
include $(BUILD_SHARED_LIBRARY)
