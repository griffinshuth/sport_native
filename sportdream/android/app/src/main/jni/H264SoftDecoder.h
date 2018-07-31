//
// Created by lili on 2018/5/12.
//

#ifndef SPORTDREAM_H264SOFTDECODER_H
#define SPORTDREAM_H264SOFTDECODER_H
#include <android/native_window.h>
#include <android/native_window_jni.h>
extern "C" {
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libswscale/swscale.h"
}

class H264SoftDecoder {
public:
    H264SoftDecoder();
    ~H264SoftDecoder();

public:
    void startDecoder(ANativeWindow* window,int width,int height);
    void stopDecoder();
    void decode(unsigned char* frameData,int length);

private:
    ANativeWindow* surfaceWindow;
    uint8_t* argbBuffer;
    int mWidth;
    int mHeight;
    AVCodecContext  *pCodecCtx;
    AVFrame *pFrameYUV;
    AVCodec * codecid;
};


#endif //SPORTDREAM_H264SOFTDECODER_H
