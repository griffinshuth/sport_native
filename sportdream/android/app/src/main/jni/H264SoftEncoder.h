//
// Created by lili on 2018/6/13.
//

#ifndef SPORTDREAM_H264SOFTENCODER_H
#define SPORTDREAM_H264SOFTENCODER_H
extern "C" {
#include "libavformat/avformat.h"
#include "libavcodec/avcodec.h"
#include "libswscale/swscale.h"
}

class H264SoftEncoder {
public:
    H264SoftEncoder();
    ~H264SoftEncoder();

public:
    void startEncoder(int width,int height,int fps,int bitrate);
    void stopEncoder();
    int encode(unsigned char* NV21Data, unsigned char* outH264Data);

private:
    int mWidth;
    int mHeight;
    int mFps;
    int mBitrate;
    AVCodecContext* pCodecCtx;
    AVFrame* pFrameYUV;
    AVCodec* codecid;
    unsigned char *picture_buf;
    int framecount;
    AVPacket packet;
};


#endif //SPORTDREAM_H264SOFTENCODER_H
