//
//  EaseMessageViewManager.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "AgorachatViewManager.h"
#import <MapKit/MapKit.h>
#import "AgorachatView.h"
#import <AgoraVideoChat/IAgoraMediaEngine.h>
#import <AgoraVideoChat/IAgoraRtcEngine.h>
#import "libyuv.h"

class AudioFrameObserver : public agora::media::IAudioFrameObserver
{
public:
  AudioFrameObserver()
  {
    
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
    return true;
  }
  virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
  {
    return true;
  }
};

class VideoFrameObserver : public agora::media::IVideoFrameObserver
{
public:
  VideoFrameObserver()
  {
    
  }
  virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
  {
    addOverplay(videoFrame);
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
    NSString* text = @"芒果";
    [text drawInRect:rect withAttributes:attributes];
    UIGraphicsPopContext();
    CGContextRelease(BitmapContext);
    //绘制结束
    for(int i=0;i<width*height;i=i+4){
      if(overlay[i+3] == 0){
        continue;
      }
      uint8_t b = argb[i];
      argb[i] = overlay[i];
      uint8_t g = argb[i+1];
      argb[i+1] = overlay[i+1];
      uint8_t r = argb[i+2];
      argb[i+2] = overlay[i+2];
    }
    libyuv::ARGBToI420(argb,width*4,(uint8_t*)videoFrame.yBuffer,videoFrame.yStride,(uint8_t*)videoFrame.uBuffer,videoFrame.uStride,(uint8_t*)videoFrame.vBuffer,videoFrame.vStride,width,height);
    free(argb);
    free(overlay);
  }
};

@implementation AgorachatViewManager
{
  AudioFrameObserver* s_audioFrameObserver;
  VideoFrameObserver* s_videoFrameObserver;
}
RCT_EXPORT_MODULE();
- (id) init
{
  self = [super init];
  if(!self) return nil;
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
  [self.agoraKit enableVideo];
  [self.agoraKit disableAudio];
  [self.agoraKit muteLocalAudioStream:YES];
  [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_120P swapWidthAndHeight:false];
  //[self.agoraKit switchCamera];
  return self;
}

RCT_EXPORT_METHOD(joinChannel:(NSString*)name)
{
  [self.agoraKit joinChannelByKey:nil channelName:name info:nil uid:0 joinSuccess:^(NSString* channel,
                                                                                         NSUInteger uid,NSInteger elapsed){
    //[self.agoraKit setEnableSpeakerphone:NO];
    //[UIApplication sharedApplication].idleTimerDisabled = YES;
    //[AGVideoProcessing registerPreprocessing:self.agoraKit];
  }];
  s_audioFrameObserver = new AudioFrameObserver();
  s_videoFrameObserver = new VideoFrameObserver();
  [self registerPreprocessing];
}

RCT_EXPORT_METHOD(leaveChannel)
{
  [self.agoraKit leaveChannel:^(AgoraRtcStats *stat) {
    //[UIApplication sharedApplication].idleTimerDisabled = NO;
    //[AGVideoProcessing deregisterPreprocessing:self.agoraKit];
  }];
  [self deregisterPreprocessing];
  delete s_audioFrameObserver;
  delete s_videoFrameObserver;
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
