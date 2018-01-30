//
//  AgoraKitRemoteCamera.m
//  sportdream
//
//  Created by lili on 2018/1/16.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AgoraKitRemoteCamera.h"
#import <AgoraVideoChat/IAgoraMediaEngine.h>
#import <AgoraVideoChat/IAgoraRtcEngine.h>

class AudioFrameObserver : public agora::media::IAudioFrameObserver
{
private:
  void* userdata;
public:
  AudioFrameObserver(void* userdata)
  {
    this->userdata = userdata;
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
    AgoraKitRemoteCamera* vc = (__bridge AgoraKitRemoteCamera*)userdata;
    [vc.delegate addAudioBuffer:audioFrame.buffer length:audioFrame.bytesPerSample * audioFrame.samples];
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
public:
  VideoFrameObserver(void* userdata)
  {
    this->userdata = userdata;
  }
  virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
  {
    videoFrame.rotation = 0;
    AgoraKitRemoteCamera* vc = (__bridge AgoraKitRemoteCamera*)userdata;
    [vc.delegate addLocalYBuffer:videoFrame.yBuffer
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
    AgoraKitRemoteCamera* vc = (__bridge AgoraKitRemoteCamera*)userdata;
    [vc.delegate addRemoteOfUId:(unsigned int)uid
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

@interface AgoraKitRemoteCamera()
@property (nonatomic,strong) AgoraRtcEngineKit* agoraKit;
@property (assign, nonatomic) AgoraRtcClientRole clientRole;
@property (nonatomic,strong) NSString* channelName;
@property (nonatomic,assign) BOOL useExternalVideoSource;
@property (nonatomic,strong) AgoraRtcVideoCanvas* localCanvas;
@property (nonatomic,strong) UIView* localView;
@end

@implementation AgoraKitRemoteCamera
{
  AudioFrameObserver* s_audioFrameObserver;
  VideoFrameObserver* s_videoFrameObserver;
}
static NSInteger streamID = 0;

-(id)initWithChannelName:(NSString*)channelName useExternalVideoSource:(BOOL)useExternalVideoSource localView:(UIView*)localView
{
  self = [super init];
  if(self){
    self.clientRole = AgoraRtc_ClientRole_Broadcaster;
    self.channelName = channelName;
    self.useExternalVideoSource = useExternalVideoSource;
    self.localView = localView;
    [self loadAgoraRtcEngineKit];
  }
  return self;
}

-(void)dealloc
{
  
}

-(void)loadAgoraRtcEngineKit
{
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
  [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
  [self.agoraKit setMixedAudioFrameParametersWithSampleRate:44100 samplesPerCall:1024];
  [self.agoraKit setClientRole:self.clientRole withKey:nil];
  [self.agoraKit muteLocalAudioStream:YES]; //默认禁止往网络发送本地音频流，该方法不影响录音状态，并没有禁用麦克风。
  if(self.useExternalVideoSource){
    [self.agoraKit setExternalVideoSource:YES useTexture:FALSE pushMode:YES];
    [self.agoraKit enableVideo];
  }else{
    [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_720P swapWidthAndHeight:false];
    [self.agoraKit enableDualStreamMode:YES];
    [self.agoraKit setRemoteDefaultVideoStreamType:AgoraRtc_VideoStream_Low];
    [self.agoraKit enableVideo];
    self.localCanvas = [[AgoraRtcVideoCanvas alloc] init];
    self.localCanvas.uid = 0;
    self.localCanvas.view = self.localView;
    self.localCanvas.renderMode = AgoraRtc_Render_Fit;
    [self.agoraKit setupLocalVideo:self.localCanvas];
    [self.agoraKit startPreview];
  }
  //创建数据流
  [self.agoraKit createDataStream:&streamID reliable:true ordered:true];
  [self joinChannel];
}

-(void) joinChannel
{
  [self.agoraKit joinChannelByKey:nil channelName:_channelName info:nil uid:0 joinSuccess:nil];
  void* userdata = (__bridge void*)self;
  s_audioFrameObserver = new AudioFrameObserver(userdata);
  s_videoFrameObserver = new VideoFrameObserver(userdata);
  [self registerPreprocessing];
}

- (void)leaveChannel {
  [self.agoraKit setupLocalVideo:nil];
  [self.agoraKit leaveChannel:nil];
  [self.agoraKit stopPreview];
  [self deregisterPreprocessing];
  delete s_audioFrameObserver;
  delete s_videoFrameObserver;
}

- (void)sendDataWithString:(NSString *)message {
  NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
  [self.agoraKit sendStreamMessage:streamID data:data];
}

-(void)pushExternalVideoData:(CVPixelBufferRef)NV12Data timeStamp:(CMTime)timeStamp
{
  AgoraVideoFrame* frame = [[AgoraVideoFrame alloc] init];
  frame.format = 12;
  frame.textureBuf = NV12Data;
  frame.strideInPixels = 1280;
  frame.height = 720;
  frame.time = timeStamp;
  [self.agoraKit pushExternalVideoFrame:frame];
}

-(void)setupRemoteVideo:(AgoraRtcVideoCanvas*)canvas
{
  [self.agoraKit setupRemoteVideo:canvas];
}

-(void)setRemoteBigSmallStream:(NSUInteger)uid isBig:(BOOL)isBig
{
  if(isBig){
    [self.agoraKit setRemoteVideoStream:uid type:AgoraRtc_VideoStream_High];
  }else{
    [self.agoraKit setRemoteVideoStream:uid type:AgoraRtc_VideoStream_Low];
  }
}

-(void)switchCamera
{
  [self.agoraKit switchCamera];
}

- (void)setCameraZoomFactor:(CGFloat)zoomFactor
{
  [self.agoraKit setCameraZoomFactor:zoomFactor];
}

- (void)setCameraFocusPositionInPreview:(CGPoint)position
{
  [self.agoraKit setCameraFocusPositionInPreview:position];
}

- (void)setCameraTorchOn:(BOOL)isOn
{
  [self.agoraKit setCameraTorchOn:isOn];
}

- (void)setCameraAutoFocusFaceModeEnabled:(BOOL)enable
{
  [self.agoraKit setCameraAutoFocusFaceModeEnabled:enable];
}

- (void)setEnableSpeakerphone:(BOOL)enableSpeaker
{
  [self.agoraKit setEnableSpeakerphone:enableSpeaker];
}

//将自己静音,允许/禁止往网络发送本地音频流
- (void)muteLocalAudioStream:(BOOL)muted
{
  [self.agoraKit muteLocalAudioStream:muted];
}

//允许或停止接收和播放所有远端音频流
- (void)muteAllRemoteAudioStreams:(BOOL)muted
{
  [self.agoraKit muteAllRemoteAudioStreams:muted];
}

//允许或停止接收和播放指定音频流
- (void)muteRemoteAudioStream:(NSUInteger)uid muted:(BOOL)muted
{
  [self.agoraKit muteRemoteAudioStream:uid mute:muted];
}

//暂停发送本地视频流,该方法不影响本地视频流获取，没有禁用摄像头
- (void)muteLocalVideoStream:(BOOL)muted
{
  [self.agoraKit muteLocalVideoStream:muted];
}

//停止接收和播放所有远端视频流
- (void)muteAllRemoteVideoStreams:(BOOL)mute
{
  [self.agoraKit muteAllRemoteVideoStreams:mute];
}

//停止接收和播放指定用户的视频流
- (void)muteRemoteVideoStream:(NSUInteger)uid mute:(BOOL)mute
{
  [self.agoraKit muteRemoteVideoStream:uid mute:mute];
}

//开始播放伴奏
- (void) startAudioMixing: (NSString*) filePath
                loopback: (BOOL) loopback
                 replace: (BOOL) replace
                   cycle: (NSInteger) cycle
{
  [self.agoraKit startAudioMixing:filePath loopback:loopback replace:replace cycle:cycle];
}

//停止播放伴奏
- (void)stopAudioMixing
{
  [self.agoraKit stopAudioMixing];
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
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
  [self.delegate didJoinedOfUid:uid elapsed:elapsed];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
  
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
  [self.delegate didOfflineOfUid:uid reason:reason];
}

-(void)rtcEngine:(AgoraRtcEngineKit *)engine receiveStreamMessageFromUid:(NSUInteger)uid streamId:(NSInteger)streamId data:(NSData *)data {
  NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [self.delegate receiveStreamMessageFromUid:uid streamId:streamId data:message];
  
}

- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
 
}

- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
  
}


@end




















































