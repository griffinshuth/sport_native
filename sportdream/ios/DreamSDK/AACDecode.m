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
  AudioConverterRef _audioConverter;
  dispatch_queue_t _decodeQueue;
  AudioBufferList outAudioBufferList;

}

-(id)init
{
  self = [super init];
  if(self){
    _decodeQueue = dispatch_queue_create("audiodecodequeue", DISPATCH_QUEUE_SERIAL);
    UInt32 bytesPerSample = sizeof (SInt16);
    AudioStreamBasicDescription outputAudioDes = {
      .mFormatID = kAudioFormatLinearPCM,
      .mSampleRate = 44100,
      .mBitsPerChannel = bytesPerSample*8,
      .mFramesPerPacket = 1,
      .mBytesPerFrame = bytesPerSample,
      .mBytesPerPacket = bytesPerSample,
      .mChannelsPerFrame = 1, //单通道 mono
      .mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsNonInterleaved,
      .mReserved = 0
    };
    AudioStreamBasicDescription inFormat;
    memset(&inFormat, 0, sizeof(inFormat));
    inFormat.mSampleRate        = 44100;
    inFormat.mFormatID          = kAudioFormatMPEG4AAC;
    inFormat.mFormatFlags       = kMPEG4Object_AAC_LC;
    inFormat.mBytesPerPacket    = 0;
    inFormat.mFramesPerPacket   = 1024;
    inFormat.mBytesPerFrame     = 0;
    inFormat.mChannelsPerFrame  = 1;
    inFormat.mBitsPerChannel    = 0;
    inFormat.mReserved          = 0;
    OSStatus status = AudioConverterNew(&inFormat, &outputAudioDes, &_audioConverter);
    if (status != noErr) {
      NSLog(@"初始化硬解码AAC创建失败");
    }
  }
  return self;
}

-(void)startAACEncodeSession
{
  //1.注册组件
  av_register_all();
  //封装格式上下文
  AVFormatContext *pFormatCtx = avformat_alloc_context();
  
}

-(void)stopAACEncodeSession
{

}

-(void)decodeAudioFrame:(NSData *)frame{
  
 
}

@end


















