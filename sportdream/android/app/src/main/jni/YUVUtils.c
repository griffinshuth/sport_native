//
// Created by lili on 2018/4/26.
//

#include "com_sportdream_nativec_YUVUtils.h"
#include "include/libyuv.h"
#include <jni.h>

JNIEXPORT void JNICALL Java_com_sportdream_nativec_YUVUtils_NV21Scale
        (JNIEnv * env, jobject jobj, jint big_width, jint big_height, jbyteArray bigdata, jint small_width, jint small_height, jbyteArray smalldata)
{
    int i = 0;
    jbyte * BigNV21 = (jbyte*)(*env)->GetByteArrayElements(env, bigdata, 0);
    jbyte * SmallNV21 = (jbyte*)(*env)->GetByteArrayElements(env, smalldata, 0);

    jbyte* BigI420buffer = malloc(big_width*big_height*3/2);
    jbyte* smallI420buffer = malloc(small_width*small_height*3/2);
    //把NV21格式的数据转换成I420
    NV21ToI420(BigNV21, big_width,
    BigNV21+big_width*big_height, big_width,
    BigI420buffer, big_width,
    BigI420buffer+big_width*big_height, big_width/2,
    BigI420buffer+big_width*big_height+big_width*big_height/4, big_width/2,
    big_width, big_height);
    //缩放
    I420Scale(BigI420buffer, big_width,
    BigI420buffer+big_width*big_height, big_width/2,
    BigI420buffer+big_width*big_height+big_width*big_height/4, big_width/2,
    big_width, big_height,
    smallI420buffer, small_width,
    smallI420buffer+small_width*small_height, small_width/2,
    smallI420buffer+small_width*small_height+small_width*small_height/4, small_width/2,
    small_width, small_height,
    kFilterBox);
    //把缩放后的数据转换成NV21
    I420ToNV21(smallI420buffer, small_width,
    smallI420buffer+small_width*small_height, small_width/2,
    smallI420buffer+small_width*small_height+small_width*small_height/4, small_width/2,
    SmallNV21, small_width,
    SmallNV21+small_width*small_height, small_width,
    small_width, small_height);

    free(BigI420buffer);
    free(smallI420buffer);
    (*env)->ReleaseByteArrayElements(env,bigdata,BigNV21,0);
    (*env)->ReleaseByteArrayElements(env,smalldata,SmallNV21,0);
}

