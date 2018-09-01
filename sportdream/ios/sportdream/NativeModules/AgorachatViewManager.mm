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

@interface AgorachatViewManager()

@end

/*class AudioFrameObserver : public agora::media::IAudioFrameObserver
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
};*/

/*class VideoFrameObserver : public agora::media::IVideoFrameObserver
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
};*/

@implementation AgorachatViewManager
{

}
RCT_EXPORT_MODULE();
- (id) init
{
  self = [super init];
  if(self){
  
  }
  return self;
}

-(void)dealloc{
  
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
  //[self.agoraKit switchCamera];
}

RCT_EXPORT_METHOD(initAgoraWithoutAudio)
{
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
  [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
  [self.agoraKit setClientRole:AgoraRtc_ClientRole_Broadcaster withKey:nil];
  [self.agoraKit setMixedAudioFrameParametersWithSampleRate:44100 samplesPerCall:1024];
  [self.agoraKit enableVideo];
  [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_360P_11 swapWidthAndHeight:false];
  [self.agoraKit disableAudio];
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
    NSNumber *myuid = [NSNumber numberWithUnsignedInteger:uid];
    [self.bridge.eventDispatcher sendAppEventWithName:@"joinChannelSuccess" body:@{@"myuid": myuid}];  }];
  
  [AGVideoProcessing registerPreprocessing:self.agoraKit];
}

RCT_EXPORT_METHOD(leaveChannel)
{
  [AGVideoProcessing deregisterPreprocessing:self.agoraKit];
  [self.agoraKit leaveChannel:^(AgoraRtcStats *stat) {
    [UIApplication sharedApplication].idleTimerDisabled = FALSE;
  }];
}

RCT_EXPORT_METHOD(startRCTRecord:(NSString*)filename resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  //[self startRecord];
  //NSString* url = @"rtmp://pili-publish.2310live.com/grasslive/singlematch_roomid";
  NSString* url = filename;
  [LivePusher start:url isRtmp:false];
  signal(SIGPIPE, SignalHandler);
  
  NSArray *documentsPathArr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *document = [documentsPathArr lastObject];
    NSString* absoluteUrl = [document stringByAppendingPathComponent:url];
  resolve(@{@"localpath": absoluteUrl});
}

RCT_EXPORT_METHOD(stopRCTRecord)
{
  //[self stopRecord];
  [LivePusher stop];
  signal(SIGPIPE, SIG_DFL);
}

RCT_EXPORT_METHOD(setPlayerNames:(NSString*)myname othername:(NSString*)othername)
{
  [LivePusher setPlayerNames:myname othername:othername];
}

RCT_EXPORT_METHOD(setMatchScores:(int)myscore otherscore:(int)otherscore)
{
  [LivePusher setMatchScores:myscore otherscore:otherscore];
}

RCT_EXPORT_METHOD(setMatchTime:(int)currentTime)
{
  [LivePusher setMatchTime:currentTime];
}

void SignalHandler(int signal) {
  NSLog(@"connection is closed!!!");
}

-(void)startRecord
{
  //服务器断开连接时，客户端会收到这个信号，如果忽略，则app自动退出
  signal(SIGPIPE, SignalHandler);
}

-(void)stopRecord
{
  signal(SIGPIPE, SIG_DFL);
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
