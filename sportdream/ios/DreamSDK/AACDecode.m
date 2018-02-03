//
//  AACDecode.m
//  sportdream
//
//  Created by lili on 2018/1/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AACDecode.h"
//封装格式
#import "libavformat/avformat.h"
//解码
#import "libavcodec/avcodec.h"
//缩放
#import "libswscale/swscale.h"
#import "libswresample/swresample.h"

@interface AACDecode()

@end

@implementation AACDecode
{
  AVCodecContext  *codecCtx;
  AVCodec * codec;
  SwrContext*                 _swrContext;
  void*                       _swrBuffer;
  NSUInteger                  _swrBufferSize;
  AVFrame *_audioFrame;
}

-(id)init
{
  self = [super init];
  if(self){
    //1.注册组件
    av_register_all();
    codec = avcodec_find_decoder(CODEC_ID_AAC);
    codecCtx = avcodec_alloc_context3(codec);
    _audioFrame = avcodec_alloc_frame();
    int openCodecErrCode = 0;
    if ((openCodecErrCode = avcodec_open2(codecCtx, codec, NULL)) < 0){
      NSLog(@"Open Audio Codec Failed openCodecErr is %s", av_err2str(openCodecErrCode));
    }
    _swrContext = NULL;
    // 初始化codecCtx
    codecCtx->codec_type = AVMEDIA_TYPE_AUDIO;
    codecCtx->sample_rate = 44100;
    codecCtx->channels = 1;
    codecCtx->bit_rate = 100000;
    codecCtx->channel_layout = av_get_default_channel_layout(1);
    
    if(codecCtx->sample_fmt != AV_SAMPLE_FMT_S16){
      _swrContext = swr_alloc_set_opts(NULL, av_get_default_channel_layout(codecCtx->channels), AV_SAMPLE_FMT_S16, codecCtx->sample_rate, av_get_default_channel_layout(codecCtx->channels), codecCtx->sample_fmt, codecCtx->sample_rate, 0, NULL);
      swr_init(_swrContext);
    }
  }
  return self;
}

-(void)startAACEncodeSession
{
  
}

-(void)stopAACEncodeSession
{
  if(codecCtx){
    avcodec_close(codecCtx);
    codecCtx = NULL;
  }
  if(_audioFrame){
    av_free(_audioFrame);
    _audioFrame = NULL;
  }
  
  if(_swrContext){
    swr_free(&_swrContext);
    _swrContext = NULL;
  }
  
  if(_swrBuffer){
    free(_swrBuffer);
    _swrBuffer = NULL;
    _swrBufferSize = 0;
  }
}

-(void)decodeAudioFrame:(NSData *)data SocketName:(NSString*)SocketName{
  
  AVPacket packet;
  av_init_packet(&packet);
  packet.size = (int)data.length;
  packet.data = (void*)data.bytes;
  int pktSize = packet.size;
  while (pktSize>0) {
    int got_frame = 0;
    int len = avcodec_decode_audio4(codecCtx, _audioFrame, &got_frame, &packet);
    if(len<0){
      NSLog(@"decode audio error, skip packet");
      break;
    }
    if(got_frame>0){
      NSData* pcmData = [self handleAudioFrame];
      if(pcmData){
        [self.delegate AACDecodeToPCM:pcmData SocketName:SocketName];
      }
    }
    if (0 == len)
      break;
    pktSize -= len;
  }
  av_free_packet(&packet);
}

-(NSData*)handleAudioFrame
{
  if (!_audioFrame->data[0])
    return nil;
  const NSUInteger numChannels = codecCtx->channels;
  NSInteger numFrames;
  void* audioData;
  
  if (_swrContext) {
    const NSUInteger ratio = 2;
    const int bufSize =  av_samples_get_buffer_size(NULL, (int)numChannels, (int)(_audioFrame->nb_samples * ratio), AV_SAMPLE_FMT_S16, 1);
    if (!_swrBuffer || _swrBufferSize < bufSize) {
      _swrBufferSize = bufSize;
      _swrBuffer = realloc(_swrBuffer, _swrBufferSize);
    }
    
    Byte *outbuf[2] = { _swrBuffer, 0 };
    numFrames = swr_convert(_swrContext,
                            outbuf,
                            (int)(_audioFrame->nb_samples * ratio),
                            (const uint8_t **)_audioFrame->data,
                            _audioFrame->nb_samples);
    if (numFrames < 0) {
      NSLog(@"fail resample audio");
      return nil;
    }
    audioData = _swrBuffer;
  }else{
    audioData = _audioFrame->data[0];
    numFrames = _audioFrame->nb_samples;
  }
  const NSUInteger numElements = numFrames * numChannels;
  NSMutableData *pcmData = [NSMutableData dataWithLength:numElements * sizeof(SInt16)];
  memcpy(pcmData.mutableBytes, audioData, numElements * sizeof(SInt16));
  
  return pcmData;
}

@end


















