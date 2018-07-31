//
// Created by lili on 2018/5/12.
//

#include "H264SoftDecoder.h"
#include "CommonTools.h"
#include "include/libyuv.h"
#define LOG_TAG "H264SoftDecoder"

H264SoftDecoder::H264SoftDecoder() {}
H264SoftDecoder::~H264SoftDecoder() {}

void H264SoftDecoder::startDecoder(ANativeWindow* window,int width, int height) {
    av_register_all();
    mWidth = width;
    mHeight = height;
    surfaceWindow = window;
    codecid = avcodec_find_decoder(CODEC_ID_H264);
    pCodecCtx = avcodec_alloc_context3(codecid);
    pCodecCtx->width = width;
    pCodecCtx->height = height;
    pCodecCtx->pix_fmt = PIX_FMT_YUV420P;
    avcodec_open2(pCodecCtx,codecid,NULL);
    pFrameYUV=avcodec_alloc_frame();
    argbBuffer = (uint8_t*)malloc(mWidth*mHeight*4);
}

void H264SoftDecoder::stopDecoder() {
    avcodec_free_frame(&pFrameYUV);
    avcodec_close(pCodecCtx);
    ANativeWindow_release(surfaceWindow);
    free(argbBuffer);
}

void H264SoftDecoder::decode(unsigned char *frameData,int length) {
    AVPacket packet;
    av_init_packet(&packet);
    packet.size = length;
    packet.data = frameData;

    int ret;
    int got_picture;
    ret = avcodec_decode_video2(pCodecCtx, pFrameYUV, &got_picture, &packet);
    if(ret<0){
        LOGI("decode error!!!");
    }else{
        if(got_picture){
            ANativeWindow_Buffer outBuffer;
            ANativeWindow_lock(surfaceWindow,&outBuffer,NULL);
            ANativeWindow_setBuffersGeometry(surfaceWindow,pCodecCtx->width,pCodecCtx->height,WINDOW_FORMAT_RGBA_8888);
            libyuv::I420ToARGB(pFrameYUV->data[0],pFrameYUV->linesize[0],
                       pFrameYUV->data[2],pFrameYUV->linesize[2],
                       pFrameYUV->data[1],pFrameYUV->linesize[1],
                       argbBuffer, mWidth*4,
                       pCodecCtx->width,pCodecCtx->height);

            uint8_t* dst = (uint8_t*)outBuffer.bits;
            int dstStride = outBuffer.stride*4;
            uint8_t * src = argbBuffer;
            int srcStride = mWidth*4;
            for(int h=0;h<mHeight;h++){
                memcpy(dst+h*dstStride,src+h*srcStride,srcStride);
            }
            ANativeWindow_unlockAndPost(surfaceWindow);
        }
    }
}
