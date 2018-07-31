//
// Created by lili on 2018/6/13.
//
#include "com_sportdream_DreamSDK_FFmpegEncoder.h"
#include "H264SoftEncoder.h"
#include <unistd.h>

JNIEXPORT jlong JNICALL Java_com_sportdream_DreamSDK_FFmpegEncoder_startEncoderNative
        (JNIEnv * env, jobject jobject1, jint width, jint height, jint fps, jint bitrate)
{
    H264SoftEncoder* encoder = new H264SoftEncoder();
    encoder->startEncoder(width,height,fps,bitrate);
    return (jlong)encoder;
}

/*
 * Class:     com_sportdream_DreamSDK_FFmpegEncoder
 * Method:    stopEncoderNative
 * Signature: ()V
 */
JNIEXPORT void JNICALL Java_com_sportdream_DreamSDK_FFmpegEncoder_stopEncoderNative
        (JNIEnv * env, jobject jobject1,jlong handler)
{
    H264SoftEncoder* encoder = (H264SoftEncoder*)handler;
    encoder->stopEncoder();
    delete encoder;
}

/*
 * Class:     com_sportdream_DreamSDK_FFmpegEncoder
 * Method:    encodeNative
 * Signature: ([B[B)I
 */
JNIEXPORT jint JNICALL Java_com_sportdream_DreamSDK_FFmpegEncoder_encodeNative
        (JNIEnv * env, jobject jobject1,jlong handler, jbyteArray NV21Data, jbyteArray outH264)
{
    jbyte * NV21Data_pointer = (jbyte*)(env)->GetByteArrayElements(NV21Data, 0);
    jbyte * outH264_pointer =  (jbyte*)(env)->GetByteArrayElements(outH264, 0);

    H264SoftEncoder* encoder = (H264SoftEncoder*)handler;

    int length = encoder->encode((uint8_t *)NV21Data_pointer,(uint8_t *)outH264_pointer);

    (env)->ReleaseByteArrayElements(NV21Data,NV21Data_pointer,0);
    (env)->ReleaseByteArrayElements(outH264,outH264_pointer,0);
    return length;
}


