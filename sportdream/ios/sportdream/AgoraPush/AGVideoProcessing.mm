//
//  AGVideoProcessing.m
//  sportdream
//
//  Created by lili on 2017/12/11.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "AGVideoProcessing.h"
#import <AgoraVideoChat/IAgoraRtcEngine.h>
#import <AgoraVideoChat/IAgoraMediaEngine.h>
#import "LivePusher.h"

class AgoraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
public:
  virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
  {
    return true;
  }
  virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
  {
    return true;
  }
  
  virtual bool onMixedAudioFrame(AudioFrame& audioFrame) override {
    [LivePusher addAudioBuffer:audioFrame.buffer length:audioFrame.bytesPerSample * audioFrame.samples];
    return true;
  }
  virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
  {
    return true;
  }
};

class AgoraVideoFrameObserver : public agora::media::IVideoFrameObserver
{
public:
  virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
  {
  
    [LivePusher addLocalYBuffer:videoFrame.yBuffer
                        uBuffer:videoFrame.uBuffer
                        vBuffer:videoFrame.vBuffer
                        yStride:videoFrame.yStride
                        uStride:videoFrame.uStride
                        vStride:videoFrame.vStride
                          width:videoFrame.width
                         height:videoFrame.height
                       rotation:videoFrame.rotation];
    return true;
  }
  virtual bool onRenderVideoFrame(unsigned int uid, VideoFrame& videoFrame) override
  {
  
    [LivePusher addRemoteOfUId:(unsigned int)uid
                       yBuffer:videoFrame.yBuffer
                       uBuffer:videoFrame.uBuffer
                       vBuffer:videoFrame.vBuffer
                       yStride:videoFrame.yStride
                       uStride:videoFrame.uStride
                       vStride:videoFrame.vStride
                         width:videoFrame.width
                        height:videoFrame.height
                      rotation:videoFrame.rotation];
    return true;
  }
};

static AgoraAudioFrameObserver s_audioFrameObserver;
static AgoraVideoFrameObserver s_videoFrameObserver;

@implementation AGVideoProcessing
+ (int) registerPreprocessing: (AgoraRtcEngineKit*) kit
{
  if (!kit) {
    return -1;
  }
  
  agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
  agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
  mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
  if (mediaEngine)
  {
    mediaEngine->registerAudioFrameObserver(&s_audioFrameObserver);
    mediaEngine->registerVideoFrameObserver(&s_videoFrameObserver);
  }
  
  //[LivePusher start];
  return 0;
}

+ (int) deregisterPreprocessing: (AgoraRtcEngineKit*) kit
{
  if (!kit) {
    return -1;
  }
  
  agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
  agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
  mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
  if (mediaEngine)
  {
    mediaEngine->registerAudioFrameObserver(NULL);
    mediaEngine->registerVideoFrameObserver(NULL);
  }
  
  //[LivePusher stop];
  return 0;
}
@end
