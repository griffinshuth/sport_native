//
//  EaseMessageViewManager.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//
#import "platform_4_live_ffmpeg.h"
#import "AgorachatViewManager.h"
#import <MapKit/MapKit.h>
#import "AgorachatView.h"
#import <AgoraVideoChat/IAgoraMediaEngine.h>
#import <AgoraVideoChat/IAgoraRtcEngine.h>
#import "libyuv.h"
#import "PushStreamMetadata.h"
#import "PushStreamConfiguration.h"
#import "aac_thread.hpp"
#import "video_consumer_thread.hpp"
#import "pool_av_user.h"
#import "AGVideoProcessing.h"
#import "LivePusher.h"

static AgorachatViewManager* AgorachatViewManagerSelf;
@interface AgorachatViewManager()
@property (nonatomic,strong) h264encode* encode;
@property (nonatomic,assign) BOOL started;
@end

class AudioFrameObserver : public agora::media::IAudioFrameObserver
{
private:
  void* userdata;
public:
  AudioFrameObserver(void* obj)
  {
    userdata = obj;
  }
  virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
  {
    return true;
  }
  virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
  {
    return true;
  }
  
  virtual bool onMixedAudioFrame(AudioFrame& audioFrame) override {
    AgorachatViewManager *vc = (__bridge AgorachatViewManager *)userdata;
    if(vc.started){
      [pool_av_user sendAudioDataToPool:audioFrame.buffer length:audioFrame.bytesPerSample * audioFrame.samples];
    }
    return true;
  }
  virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
  {
    return true;
  }
};

class VideoFrameObserver : public agora::media::IVideoFrameObserver
{
private:
  void* userdata;
  int count;
public:
  VideoFrameObserver(void* obj)
  {
    userdata = obj;
    count = 0;
  }
  virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
  {
    addOverplay(videoFrame);
    AgorachatViewManager *vc = (__bridge AgorachatViewManager *)userdata;
    if(vc.started){
      [vc addLocalYBuffer:videoFrame.yBuffer
                  uBuffer:videoFrame.uBuffer
                  vBuffer:videoFrame.vBuffer
                  yStride:videoFrame.yStride
                  uStride:videoFrame.uStride
                  vStride:videoFrame.vStride
                    width:videoFrame.width
                   height:videoFrame.height
                 rotation:videoFrame.rotation];
    }
    return true;
  }
  virtual bool onRenderVideoFrame(unsigned int uid, VideoFrame& videoFrame) override
  {
    return true;
  }
  
private:
  void addOverplay(VideoFrame& videoFrame){
    int width = videoFrame.width;
    int height = videoFrame.height;
    videoFrame.rotation = 0;
    uint8_t* argb = (uint8_t*)malloc(width*height*4);
    libyuv::I420ToARGB((uint8_t*)videoFrame.yBuffer,videoFrame.yStride,(uint8_t*)videoFrame.uBuffer,videoFrame.uStride,(uint8_t*)videoFrame.vBuffer,videoFrame.vStride,argb,width*4,width,height);
    //绘制文字图层
    uint8_t* overlay = (uint8_t*)malloc(width*height*4);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef BitmapContext = CGBitmapContextCreate(overlay, width, height, 8, width*4, colorSpace, kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorSpace);
    CGContextTranslateCTM(BitmapContext, 0.0, height);
    CGContextScaleCTM(BitmapContext, 1.0, -1.0);
    UIGraphicsPushContext(BitmapContext);
    //开始绘制
    NSTextAlignment alignment = NSTextAlignmentLeft;
    NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.alignment = alignment;
    NSDictionary* attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:30],
                                 NSForegroundColorAttributeName:[UIColor redColor],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    CGRect rect = CGRectMake(50, 50, 200, 50);
    NSString* text = [NSString stringWithFormat:@"帧数：%d",count];
    [text drawInRect:rect withAttributes:attributes];
    UIGraphicsPopContext();
    CGContextRelease(BitmapContext);
    //绘制结束
    for(int i=0;i<width*height;i=i+4){
      if(overlay[i+3] == 0){
        continue;
      }
      argb[i] = overlay[i];
      argb[i+1] = overlay[i+1];
      argb[i+2] = overlay[i+2];
    }
    libyuv::ARGBToI420(argb,width*4,(uint8_t*)videoFrame.yBuffer,videoFrame.yStride,(uint8_t*)videoFrame.uBuffer,videoFrame.uStride,(uint8_t*)videoFrame.vBuffer,videoFrame.vStride,width,height);
    free(argb);
    free(overlay);
    count++;
  }
};

@implementation AgorachatViewManager
{
  AudioFrameObserver* s_audioFrameObserver;
  VideoFrameObserver* s_videoFrameObserver;
  
  ELPushStreamMetadata* _metaData;
  VideoConsumerThread* _consumer;
  AudioEncoderAdapter*            _audioEncoder;
  dispatch_queue_t                    _consumerQueue;
  double                              _startConnectTimeMills;
  int                                 _historyBitrate;
  NSTimeInterval                      _lastStopTime;

}
RCT_EXPORT_MODULE();
- (id) init
{
  self = [super init];
  if(!self) return nil;
  
  void* userdata = (__bridge void*)self;
  s_audioFrameObserver = new AudioFrameObserver(userdata);
  s_videoFrameObserver = new VideoFrameObserver(userdata);
  
  _started = false;
  
  //初始化视频输出模块
  NSArray *documentsPathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *document = [documentsPathArr lastObject];
  NSString* pushFileURL = [document stringByAppendingPathComponent:@"recording.mp4"];
  NSString* pushNetURL = kFakePushURL;
  _metaData = [[ELPushStreamMetadata alloc] initWithRtmpUrl:pushFileURL videoWidth:kDesiredWidth videoHeight:kDesiredHeight videoFrameRate:kFrameRate videoBitRate:kAVGVideoBitRate audioSampleRate:kAudioSampleRate audioChannels:kAudioChannels audioBitRate:kAudioBitRate audioCodecName:kAudioCodecName
                                                qualityStrategy:0
                                adaptiveBitrateWindowSizeInSecs:WINDOW_SIZE_IN_SECS adaptiveBitrateEncoderReconfigInterval:NOTIFY_ENCODER_RECONFIG_INTERVAL adaptiveBitrateWarCntThreshold:PUB_BITRATE_WARNING_CNT_THRESHOLD
                                         adaptiveMinimumBitrate:300 * 1024
                                         adaptiveMaximumBitrate:1000 * 1024];
   _consumerQueue = dispatch_queue_create("com.easylive.RecordingStudio.consumerQueue", NULL);
  
  AgorachatViewManagerSelf =self;
  return self;
}

- (void)addLocalYBuffer:(void *)yBuffer
                uBuffer:(void *)uBuffer
                vBuffer:(void *)vBuffer
                yStride:(int)yStride
                uStride:(int)uStride
                vStride:(int)vStride
                  width:(int)width
                 height:(int)height
               rotation:(int)rotation
{
  int remoteYBufferSize = yStride * height;
  int remoteUBufferSize = uStride * height / 2;
  int remoteVBufferSize = vStride * height / 2;
  int dataLength = remoteYBufferSize + remoteUBufferSize + remoteVBufferSize;
  //unsigned char *NV12Data = (unsigned char *)malloc(dataLength);
  //libyuv::I420ToNV12((const uint8*)yBuffer, yStride, (const uint8*)uBuffer, uStride, (const uint8*)vBuffer, vStride, NV12Data, yStride, NV12Data+remoteYBufferSize, uStride+vStride, yStride, height);
  //NSData *sampleBuffer = [NSData dataWithBytesNoCopy:NV12Data length:dataLength];
  //[self.encode encodeH264Frame:sampleBuffer];
  uint8* argb = (uint8*)malloc(width*height*4);
  //NSLog(@"width:%d,height:%d",width,height);
  libyuv::I420ToARGB((const uint8*)yBuffer,yStride,(const uint8*)uBuffer,uStride,(const uint8*)vBuffer,vStride,argb,yStride*4,width,height);
  [self.encode encodeBytes:argb];
  free(argb);
}
- (void)addRemoteOfUId:(unsigned int)uid
               yBuffer:(void *)yBuffer
               uBuffer:(void *)uBuffer
               vBuffer:(void *)vBuffer
               yStride:(int)yStride
               uStride:(int)uStride
               vStride:(int)vStride
                 width:(int)width
                height:(int)height
              rotation:(int)rotation{
  
}

-(void)dealloc{
  delete s_audioFrameObserver;
  delete s_videoFrameObserver;
}

RCT_EXPORT_METHOD(initAgora)
{
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
  [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
  [self.agoraKit setClientRole:AgoraRtc_ClientRole_Broadcaster withKey:nil];
  [self.agoraKit setMixedAudioFrameParametersWithSampleRate:44100 samplesPerCall:1024];
  [self.agoraKit enableVideo];
  [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_360P_4 swapWidthAndHeight:false];
  [self.agoraKit enableAudio];
  [self.agoraKit switchCamera];
}

RCT_EXPORT_METHOD(destroyAgora)
{
  self.agoraKit = nil;
}

RCT_EXPORT_METHOD(joinChannel:(NSString*)name)
{
  [self.agoraKit joinChannelByKey:nil channelName:name info:nil uid:0 joinSuccess:^(NSString* channel,
                                                                                         NSUInteger uid,NSInteger elapsed){
    [UIApplication sharedApplication].idleTimerDisabled = YES;
  }];
  
  //[self registerPreprocessing];
  [AGVideoProcessing registerPreprocessing:self.agoraKit];
}

RCT_EXPORT_METHOD(leaveChannel)
{
  //[self deregisterPreprocessing];
  [AGVideoProcessing deregisterPreprocessing:self.agoraKit];
  [self.agoraKit leaveChannel:^(AgoraRtcStats *stat) {
    [UIApplication sharedApplication].idleTimerDisabled = FALSE;
  }];
}

RCT_EXPORT_METHOD(startRCTRecord)
{
  //[self startRecord];
  [LivePusher start];
}

RCT_EXPORT_METHOD(stopRCTRecord)
{
  //[self stopRecord];
  [LivePusher stop];
}

void SignalHandler(int signal) {
  NSLog(@"connection is closed!!!");
  UIAlertView *alert =
  [[UIAlertView alloc]
   initWithTitle:@"出错啦"
   message:[NSString stringWithFormat:@"服务器断开连接，请退出"]
   delegate:AgorachatViewManagerSelf
   cancelButtonTitle:@"退出"
   otherButtonTitles:@"继续", nil];
  [alert show];
}

-(void)startRecord
{
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
      signal(SIGPIPE, SignalHandler);
    } else {
      NSLog(@"cosumer open video output failed...");
      LivePacketPool::GetInstance()->destoryRecordingVideoPacketQueue();
      LivePacketPool::GetInstance()->destoryAudioPacketQueue();
      LiveAudioPacketPool::GetInstance()->destoryAudioPacketQueue();
    
    }
  });
}

-(void)startZhibo
{
  
}

-(void)stopRecord
{
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
  signal(SIGPIPE, SIG_DFL);
}

-(void)registerPreprocessing
{
  agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)self.agoraKit.getNativeHandle;
  agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
  mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
  if (mediaEngine)
  {
    mediaEngine->registerAudioFrameObserver(s_audioFrameObserver);
    mediaEngine->registerVideoFrameObserver(s_videoFrameObserver);
  }
}

-(void)deregisterPreprocessing
{
  agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)self.agoraKit.getNativeHandle;
  agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
  mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
  if (mediaEngine)
  {
    mediaEngine->registerAudioFrameObserver(NULL);
    mediaEngine->registerVideoFrameObserver(NULL);
  }
}

//delegate
-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds
{
  //[self.rtmpPush sendVideoSpsPps:(void*)pps ppsLen:(int)ppsLen sps:(void*)sps spsLen:(int)spsLen];
  NSData *ns_pps = [NSData dataWithBytes:pps length:ppsLen];
  NSData *ns_sps = [NSData dataWithBytes:sps length:spsLen];
  [pool_av_user sendSpsPpsToPool:ns_sps pps:ns_pps timestramp:miliseconds];
  
}
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  //[self.rtmpPush sendH264Packet:(void*)data size:(int)length isKeyFrame:isKeyFrame];
  NSData* ns_h264 = [NSData dataWithBytes:data length:length];
  [pool_av_user sendVideoDataToPool:ns_h264 isKeyFrame:isKeyFrame timestramp:miliseconds pts:pts dts:dts];
}
-(void)dataEncodeToH264:(const void*)data length:(size_t)length;
{
  //[self writeH264Data:data length:length];
}

//delegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size: (CGSize)size elapsed:(NSInteger)elapsed {
  NSNumber *myNumber = [NSNumber numberWithUnsignedInteger:uid];
  [self.bridge.eventDispatcher sendAppEventWithName:@"firstRemoteVideoDecoded" body:@{@"uid": myNumber}];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
  NSNumber *myNumber = [NSNumber numberWithUnsignedInteger:uid];
  [self.bridge.eventDispatcher sendAppEventWithName:@"didOffline" body:@{@"uid": myNumber}];
}
RCT_EXPORT_VIEW_PROPERTY(uid, NSNumber)
-(UIView*)view
{
  AgorachatView* v = [[AgorachatView alloc] init];
  v.agoraKit = self.agoraKit;
  return v;
}
@end
