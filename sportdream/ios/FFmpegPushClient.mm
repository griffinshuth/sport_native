//
//  FFmpegPushClient.m
//  sportdream
//
//  Created by lili on 2018/4/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "FFmpegPushClient.h"
#import "PushStreamMetadata.h"
#import "PushStreamConfiguration.h"
#import "aac_thread.hpp"
#import "video_consumer_thread.hpp"
#import "pool_av_user.h"

@interface FFmpegPushClient()
@property (nonatomic,strong) h264encode* encode;
@property (nonatomic,assign) BOOL started;
@end

@implementation FFmpegPushClient
{
  ELPushStreamMetadata* _metaData;
  VideoConsumerThread* _consumer;
  AudioEncoderAdapter*            _audioEncoder;
  dispatch_queue_t                    _consumerQueue;
  double                              _startConnectTimeMills;
  int                                 _historyBitrate;
  NSTimeInterval                      _lastStopTime;
}

-(id)init
{
  if(self = [super init])
  {
    _started = false;
    //初始化视频输出模块
    NSArray *documentsPathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *document = [documentsPathArr lastObject];
    NSString* pushFileURL = [document stringByAppendingPathComponent:@"recording2.mp4"];
    NSString* pushNetURL = kFakePushURL;
    _metaData = [[ELPushStreamMetadata alloc] initWithRtmpUrl:pushNetURL videoWidth:kDesiredWidth videoHeight:kDesiredHeight videoFrameRate:kFrameRate videoBitRate:kAVGVideoBitRate audioSampleRate:kAudioSampleRate audioChannels:kAudioChannels audioBitRate:kAudioBitRate audioCodecName:kAudioCodecName
                                              qualityStrategy:0
                              adaptiveBitrateWindowSizeInSecs:WINDOW_SIZE_IN_SECS adaptiveBitrateEncoderReconfigInterval:NOTIFY_ENCODER_RECONFIG_INTERVAL adaptiveBitrateWarCntThreshold:PUB_BITRATE_WARNING_CNT_THRESHOLD
                                       adaptiveMinimumBitrate:300 * 1024
                                       adaptiveMaximumBitrate:1000 * 1024];
    _consumerQueue = dispatch_queue_create("com.easylive.RecordingStudio.consumerQueue", NULL);
  }
  return self;
}

-(void)dealloc
{
  
}

//delegate
-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds
{
  NSData *ns_pps = [NSData dataWithBytes:pps length:ppsLen];
  NSData *ns_sps = [NSData dataWithBytes:sps length:spsLen];
  [pool_av_user sendSpsPpsToPool:ns_sps pps:ns_pps timestramp:miliseconds];
  
}
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  NSData* ns_h264 = [NSData dataWithBytes:data length:length];
  [pool_av_user sendVideoDataToPool:ns_h264 isKeyFrame:isKeyFrame timestramp:miliseconds pts:pts dts:dts];
}
-(void)dataEncodeToH264:(const void*)data length:(size_t)length;
{

}


-(void)startStreaming
{
  if(_started){
    return;
  }
  if(NULL == _consumer){
    _consumer = new VideoConsumerThread();
  }
  
  __weak __typeof(self) weakSelf = self;
  dispatch_async(_consumerQueue, ^(void) {
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    char* videoOutputURI = [ELPushStreamMetadata nsstring2char:strongSelf->_metaData.rtmpUrl];
    char* audioCodecName = [ELPushStreamMetadata nsstring2char:strongSelf->_metaData.audioCodecName];
    strongSelf->_startConnectTimeMills = [[NSDate date] timeIntervalSince1970] * 1000;
    LivePacketPool::GetInstance()->initRecordingVideoPacketQueue();
    LivePacketPool::GetInstance()->initAudioPacketQueue((int)strongSelf->_metaData.audioSampleRate);
    LiveAudioPacketPool::GetInstance()->initAudioPacketQueue();
    std::map<std::string, int> configMap;
    configMap["adaptiveBitrateWindowSizeInSecs"] = (int)strongSelf->_metaData.adaptiveBitrateWindowSizeInSecs;
    configMap["adaptiveBitrateEncoderReconfigInterval"] = (int)strongSelf->_metaData.adaptiveBitrateEncoderReconfigInterval;
    configMap["adaptiveBitrateWarCntThreshold"] = (int)strongSelf->_metaData.adaptiveBitrateWarCntThreshold;
    configMap["adaptiveMinimumBitrate"] = (int)strongSelf->_metaData.adaptiveMinimumBitrate/1024;
    configMap["adaptiveMaximumBitrate"] = (int)strongSelf->_metaData.adaptiveMaximumBitrate/1024;
    if (_historyBitrate != 0 && _historyBitrate != -1           && _historyBitrate>=configMap["adaptiveMinimumBitrate"]    &&
        _lastStopTime                                           &&
        ([NSDate date].timeIntervalSince1970-_lastStopTime)<60) {
      configMap["adaptiveHistoryBitrate"] = _historyBitrate;
    }
    
    int consumerInitCode = strongSelf->_consumer->init(videoOutputURI, (int)strongSelf->_metaData.videoWidth, (int)strongSelf->_metaData.videoHeight, (int)strongSelf->_metaData.videoFrameRate, (int)strongSelf->_metaData.videoBitRate, (int)strongSelf->_metaData.audioSampleRate, (int)strongSelf->_metaData.audioChannels, (int)strongSelf->_metaData.audioBitRate, audioCodecName,
                                                       (int)strongSelf->_metaData.qualityStrategy, configMap);
    delete[] audioCodecName;
    delete[] videoOutputURI;
    
    if(consumerInitCode >= 0) {
      strongSelf->_consumer->startAsync();
      NSLog(@"cosumer open video output success...");
      _audioEncoder = new AudioEncoderAdapter();
      char* audioCodecName = [ELPushStreamMetadata nsstring2char:kAudioCodecName];
      _audioEncoder->init(LivePacketPool::GetInstance(), kAudioSampleRate, kAudioChannels, kAudioBitRate, audioCodecName);
      delete[] audioCodecName;
      
      self.encode = [[h264encode alloc] initEncodeWith:_metaData.videoWidth height:_metaData.videoHeight framerate:_metaData.videoFrameRate bitrate:_metaData.videoBitRate];
      self.encode.delegate = self;
      [self.encode startH264EncodeSession];
      _started = true;
    } else {
      NSLog(@"cosumer open video output failed...");
      LivePacketPool::GetInstance()->destoryRecordingVideoPacketQueue();
      LivePacketPool::GetInstance()->destoryAudioPacketQueue();
      LiveAudioPacketPool::GetInstance()->destoryAudioPacketQueue();
      
    }
  });
}
-(void)stopStreaming
{
  if(!_started){
    return;
  }
  _historyBitrate = PublisherRateFeedback::GetInstance()->getQualityAgent()->getBitrate();
  _lastStopTime = [NSDate date].timeIntervalSince1970;
  
  if (_consumer) {
    _consumer->stop();
    delete _consumer;
    _consumer = NULL;
  }
  
  if(NULL != _audioEncoder){
    _audioEncoder->destroy();
    delete _audioEncoder;
    _audioEncoder = NULL;
  }
  
  [self.encode stopH264EncodeSession];
  _started = false;
}

-(BOOL)isPushing
{
  return _started;
}
- (void)sendYUVData:(unsigned char *)pYUVBuff dataLength:(unsigned int)length
{
  if(_started){
    NSData *sampleBuffer = [NSData dataWithBytesNoCopy:pYUVBuff length:length];
    [self.encode encodeH264Frame:sampleBuffer];
  }
}

- (void)sendRGBAData:(unsigned char *)pRGBABuff dataLength:(unsigned int)length
{
  if(_started){
    [self.encode encodeBytes:pRGBABuff];
  }
}
- (void)sendPCMData:(unsigned char*)pPCMData dataLength:(unsigned int)length
{
  if(_started){
    [pool_av_user sendAudioDataToPool:pPCMData length:length];
  }
}

@end
