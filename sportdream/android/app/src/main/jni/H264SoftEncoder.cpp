//
// Created by lili on 2018/6/13.
//

#include "H264SoftEncoder.h"
#include "include/libyuv.h"
#include "CommonTools.h"
#define LOG_TAG "H264SoftEncoder"

H264SoftEncoder::H264SoftEncoder(){}
H264SoftEncoder::~H264SoftEncoder(){}

void H264SoftEncoder::startEncoder(int width, int height, int fps, int bitrate) {
    this->mWidth = width;
    this->mHeight = height;
    this->mFps = fps;
    this->mBitrate = bitrate;
    this->framecount = 0;

    av_register_all();
    this->codecid = avcodec_find_encoder(CODEC_ID_H264);
    pCodecCtx = avcodec_alloc_context3(codecid);
    pCodecCtx->width = width;
    pCodecCtx->height = height;
    pCodecCtx->pix_fmt = PIX_FMT_YUV420P;
    pCodecCtx->bit_rate = bitrate;
    pCodecCtx->gop_size = fps;
    pCodecCtx->time_base = (AVRational){1, fps};
    pCodecCtx->max_b_frames = 0;
    pCodecCtx->rc_initial_buffer_occupancy = 1;
    avcodec_open2(pCodecCtx,codecid,NULL);
    pFrameYUV=avcodec_alloc_frame();
    pFrameYUV->width = width;
    pFrameYUV->height = height;
    pFrameYUV->format = AV_PIX_FMT_YUV420P;
    int picture_size = avpicture_get_size(pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    unsigned char *picture_buf = (uint8_t *)av_malloc(picture_size);
    avpicture_fill((AVPicture *)pFrameYUV, picture_buf, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    av_new_packet(&packet, 0);
}

void H264SoftEncoder::stopEncoder() {
    avcodec_close(pCodecCtx);
    //av_free_packet(&packet);
    //av_free(picture_buf);
    av_free(&pFrameYUV);
}

int H264SoftEncoder::encode(unsigned char* NV21Data, unsigned char* outH264Data) {
    int length = 0;
    //把NV21数据转换成YUV420格式然后存入pFrameYUV
    uint8_t * I420buffer = (uint8_t *)malloc(mWidth*mHeight*3/2);
    //把NV21格式的数据转换成I420
    libyuv::NV21ToI420(NV21Data, mWidth,
               NV21Data+mWidth*mHeight, mWidth,
               I420buffer, mWidth,
               I420buffer+mWidth*mHeight, mWidth/2,
               I420buffer+mWidth*mHeight+mWidth*mHeight/4, mWidth/2,
               mWidth, mHeight);
    pFrameYUV->data[0] = I420buffer;
    pFrameYUV->data[1] = I420buffer+mWidth*mHeight;
    pFrameYUV->data[2] = I420buffer+mWidth*mHeight+mWidth*mHeight/4;
    pFrameYUV->pts = framecount;
    framecount++;

    int got_picture = 0;
    int ret = avcodec_encode_video2(pCodecCtx, &packet, pFrameYUV, &got_picture);
    if(ret<0){
       //encode failed
        LOGI("decode error:%d",ret);
    }
    if(got_picture == 1){
        length = packet.size;
        memcpy(outH264Data,packet.data,length);
    }else{
        LOGI("got_picture:%d",got_picture);
    }
    av_packet_unref(&packet);
    free(I420buffer);
    return length;
}
