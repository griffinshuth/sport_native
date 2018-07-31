//
// Created by lili on 2018/5/12.
//
#include "com_sportdream_DreamSDK_FFmpegDecoder.h"
#include <unistd.h>
#include "H264Output.h"
#include "H264SoftDecoder.h"

H264SoftDecoder* decoder = NULL;
static ANativeWindow* window = 0;

JNIEXPORT jint JNICALL Java_com_sportdream_DreamSDK_FFmpegDecoder_startNative
        (JNIEnv * env, jobject obj, jint width, jint height,jint texWidth,jint texHeight,jbyteArray rgbaData, jobject surface){

    window = ANativeWindow_fromSurface(env,surface);
    ANativeWindow_setBuffersGeometry(window,texWidth,texHeight,WINDOW_FORMAT_RGBA_8888);
    ANativeWindow_Buffer windowBuffer;
    ANativeWindow_lock(window,&windowBuffer,NULL);
    jbyte * temp = (jbyte*)(env)->GetByteArrayElements(rgbaData, 0);
    uint8_t* dst = (uint8_t*)windowBuffer.bits;
    int dstStride = windowBuffer.stride*4;
    uint8_t * src = (uint8_t *)temp;
    int srcStride = texWidth*4;
    for(int h=0;h<texHeight;h++){
        memcpy(dst+h*dstStride,src+h*srcStride,srcStride);

    }
    ANativeWindow_unlockAndPost(window);

    (env)->ReleaseByteArrayElements(rgbaData,temp,0);

    decoder = new H264SoftDecoder();
    decoder->startDecoder(window,texWidth,texHeight);
    return 1;
}


JNIEXPORT void JNICALL Java_com_sportdream_DreamSDK_FFmpegDecoder_stopNative
        (JNIEnv * env, jobject obj, jint handler){
    decoder->stopDecoder();
    delete decoder;
}


JNIEXPORT void JNICALL Java_com_sportdream_DreamSDK_FFmpegDecoder_DecodeFrameNative
        (JNIEnv * env, jobject obj, jint handler, jbyteArray h264Data,jint length){
    jbyte * temp = (jbyte*)(env)->GetByteArrayElements(h264Data, 0);
    uint8_t * src = (uint8_t *)temp;
    decoder->decode(src,length);
    (env)->ReleaseByteArrayElements(h264Data,temp,0);
}

