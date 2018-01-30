//
//  AACEncode.m
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "AACEncode.h"

@interface AACEncode()
@property (nonatomic,strong) NSData* curFramePcmData;
@end

@implementation AACEncode
{
  AudioConverterRef _audioConverter;
  dispatch_queue_t _encodeQueue;
  uint32_t _audioMaxOutputFrameSize;
  uint32_t _channelCount;
  uint32_t _sampleRate;
  uint32_t _sampleSize;
  uint32_t _bitrate;
}

-(id)init
{
  self = [super init];
  if(self){
    _encodeQueue = dispatch_queue_create("audioencodequeue", DISPATCH_QUEUE_SERIAL);
    _channelCount = 1; //音频通道数量 1为单声道，2为立体声。除非使用外部硬件进行录制，否则通常使用单声道录制。
    _sampleRate = 44100; //音频采样率
    _sampleSize = 16; //音频采样位数
    _bitrate = 100000; //音频码率
  }
  return self;
}

-(void)startAACEncodeSession
{
  AudioStreamBasicDescription inputAudioDes = {
    .mFormatID = kAudioFormatLinearPCM,
    .mSampleRate = _sampleRate,
    .mBitsPerChannel = _sampleSize,
    .mFramesPerPacket = 1,
    .mBytesPerFrame = 2,
    .mBytesPerPacket = 2,
    .mChannelsPerFrame = _channelCount,
    .mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsNonInterleaved,
    .mReserved = 0
  };
  AudioStreamBasicDescription outputAudioDes = {
    .mChannelsPerFrame = _channelCount,
    .mFormatID = kAudioFormatMPEG4AAC,
    0
  };
  uint32_t outDesSize = sizeof(outputAudioDes);
  AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &outDesSize, &outputAudioDes);
  OSStatus status = AudioConverterNew(&inputAudioDes, &outputAudioDes, &_audioConverter);
  if (status != noErr) {
    NSLog(@"硬编码AAC创建失败");
  }
  
  //设置码率
  uint32_t aBitrate = _bitrate;
  uint32_t aBitrateSize = sizeof(aBitrate);
  status = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, aBitrateSize, &aBitrate);
  
  //查询最大输出
  uint32_t aMaxOutput = 0;
  uint32_t aMaxOutputSize = sizeof(aMaxOutput);
  AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &aMaxOutputSize, &aMaxOutput);
  _audioMaxOutputFrameSize = aMaxOutput;
  if (aMaxOutput == 0) {
    NSLog(@"AAC 获取最大frame size失败");
  }

}

-(void)stopAACEncodeSession
{
  AudioConverterDispose(_audioConverter);
  _audioConverter = NULL;
  self.curFramePcmData = nil;
  _audioMaxOutputFrameSize = 0;
}

//音频aac格式编码
-(void)encodeCMSampleBufferPCMData:(CMSampleBufferRef)sampleBuffer
{
  dispatch_sync(_encodeQueue,^{
    //获得pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    //分配空间
    int8_t* audio_data = malloc(audioDataSize);
    memset(audio_data, 0, audioDataSize);
    //获得CMBlockBufferRef
    //这个结构里面就保存了 PCM数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //直接将数据copy至我们自己分配的内存中
    CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    //生成NSData对象
    NSData* pcmData = [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
    
    self.curFramePcmData = pcmData;
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = _channelCount;
    outAudioBufferList.mBuffers[0].mDataByteSize = _audioMaxOutputFrameSize;
    outAudioBufferList.mBuffers[0].mData = malloc(_audioMaxOutputFrameSize);
    uint32_t outputDataPacketSize = 1;
    
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInputDataProc, (__bridge void * _Nullable)(self), &outputDataPacketSize, &outAudioBufferList, NULL);
    if(status == noErr){
      NSData *rawAAC = [NSData dataWithBytesNoCopy: outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
      [self.delegate dataEncodeToAAC:rawAAC];
    }else{
      NSLog(@"aac 编码错误");
    }
  });
}

-(void)encodeNSDataPCMData:(NSData*)pPCMData
{
  dispatch_sync(_encodeQueue,^{
    self.curFramePcmData = pPCMData;
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = _channelCount;
    outAudioBufferList.mBuffers[0].mDataByteSize = _audioMaxOutputFrameSize;
    outAudioBufferList.mBuffers[0].mData = malloc(_audioMaxOutputFrameSize);
    uint32_t outputDataPacketSize = 1;
    
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInputDataProc, (__bridge void * _Nullable)(self), &outputDataPacketSize, &outAudioBufferList, NULL);
    if(status == noErr){
      NSData *rawAAC = [NSData dataWithBytesNoCopy: outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
      [self.delegate dataEncodeToAAC:rawAAC];
    }else{
      NSLog(@"aac 编码错误");
    }
  });
}

//提供AAC编码需要的PCM数据回调
static OSStatus aacEncodeInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData){
  AACEncode *vc = (__bridge AACEncode *)inUserData;
  if (vc.curFramePcmData) {
    ioData->mBuffers[0].mData = (void *)vc.curFramePcmData.bytes;
    ioData->mBuffers[0].mDataByteSize = (uint32_t)vc.curFramePcmData.length;
    ioData->mNumberBuffers = 1;
    ioData->mBuffers[0].mNumberChannels = vc->_channelCount;
    
    return noErr;
  }
  
  return -1;
}
@end
