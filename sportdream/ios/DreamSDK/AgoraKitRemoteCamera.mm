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

class RemoteCameraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
private:
  void* userdata;
public:
  RemoteCameraAudioFrameObserver(void* userdata)
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
    [vc.delegate onMixedAudioFrame:audioFrame.buffer length:audioFrame.bytesPerSample * audioFrame.samples];
    return true;
  }
  virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
  {
    AgoraKitRemoteCamera* vc = (__bridge AgoraKitRemoteCamera*)userdata;
    [vc.delegate onPlaybackAudioFrameBeforeMixing:audioFrame.buffer length:audioFrame.bytesPerSample * audioFrame.samples uid:uid];
    return true;
  }
};

class RemoteCameraVideoFrameObserver : public agora::media::IVideoFrameObserver
{
private:
  void* userdata;
public:
  RemoteCameraVideoFrameObserver(void* userdata)
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
@property (nonatomic,assign) BOOL useExternalAudioSource;
@property (nonatomic,assign) int externalSampleRate;
@property (nonatomic,assign) int externalChannelsPerFrame;
@property (nonatomic,strong) AgoraRtcVideoCanvas* localCanvas;
@property (nonatomic,strong) UIView* localView;
@end

@implementation AgoraKitRemoteCamera
{
  RemoteCameraAudioFrameObserver* s_audioFrameObserver;
  RemoteCameraVideoFrameObserver* s_videoFrameObserver;
}
static NSInteger streamID = 0;

-(id)initWithChannelName:(NSString*)channelName useExternalVideoSource:(BOOL)useExternalVideoSource localView:(UIView*)localView useExternalAudioSource:(BOOL)useExternalAudioSource externalSampleRate:(int)externalSampleRate externalChannelsPerFrame:(int)externalChannelsPerFrame
{
  self = [super init];
  if(self){
    self.clientRole = AgoraRtc_ClientRole_Broadcaster;
    self.channelName = channelName;
    self.useExternalVideoSource = useExternalVideoSource;
    self.useExternalAudioSource = useExternalAudioSource;
    self.externalSampleRate = externalSampleRate;
    self.externalChannelsPerFrame = externalChannelsPerFrame;
    self.localView = localView;
    [self loadAgoraRtcEngineKit];
  }
  return self;
}

-(void)dealloc
{
  [self.agoraKit leaveChannel:nil];
}

-(void)loadAgoraRtcEngineKit
{
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
  [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
  [self.agoraKit setMixedAudioFrameParametersWithSampleRate:44100 samplesPerCall:1024];
  [self.agoraKit setClientRole:self.clientRole withKey:nil];
  //[self.agoraKit muteLocalAudioStream:YES]; //默认禁止往网络发送本地音频流，该方法不影响录音状态，并没有禁用麦克风。
  if(self.useExternalAudioSource){
    [self.agoraKit enableExternalAudioSourceWithSampleRate:self.externalSampleRate channelsPerFrame:self.externalChannelsPerFrame];
  }
  if(self.useExternalVideoSource){
    [self.agoraKit setExternalVideoSource:YES useTexture:FALSE pushMode:YES];
    [self.agoraKit enableDualStreamMode:YES];
    [self.agoraKit setRemoteDefaultVideoStreamType:AgoraRtc_VideoStream_Low];
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
  [self.agoraKit joinChannelByKey:nil channelName:_channelName info:nil uid:0 joinSuccess:^(NSString* channel,
                                                                                            NSUInteger uid,NSInteger elapsed){
    
  }];
  void* userdata = (__bridge void*)self;
  s_audioFrameObserver = new RemoteCameraAudioFrameObserver(userdata);
  s_videoFrameObserver = new RemoteCameraVideoFrameObserver(userdata);
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

-(void)pushExternalVideoData:(NSData*)NV12Data timeStamp:(CMTime)timeStamp
{
  AgoraVideoFrame* frame = [[AgoraVideoFrame alloc] init];
  frame.format = 2;
  frame.dataBuf = NV12Data;
  frame.strideInPixels = 1280;
  frame.height = 720;
  frame.time = timeStamp;
  [self.agoraKit pushExternalVideoFrame:frame];
}

-(void)pushExternalAudioFrameRawData:(void *)data
                             samples:(NSUInteger)samples
                           timestamp:(NSTimeInterval)timestamp
{
  [self.agoraKit pushExternalAudioFrameRawData:data samples:samples timestamp:timestamp];
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
//该回调方法表示该客户端成功加入了指定的频道。同 joinChannelByToken() API 的 joinSuccessBlock 回调。
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didJoinChannel:(NSString * _Nonnull)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed
{
  
}

//当用户调用 leaveChannel 离开频道后，SDK 会触发该回调。
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didLeaveChannelWithStats:(AgoraRtcStats * _Nonnull)stats
{
  
}

//提示有主播加入了频道。如果该客户端加入频道时已经有主播在频道中，SDK 也会向应用程序上报这些已在频道中的用户
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
  [self.delegate didJoinedOfUid:uid elapsed:elapsed];
}

//提示第一帧本地视频画面已经显示在屏幕上。
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
  [self.delegate firstLocalVideoFrameWithSize:size elapsed:elapsed];
}

//提示有主播离开了频道（或掉线）。SDK 判断用户离开频道（或掉线）的依据是超时: 在一定时间内（15 秒）没有收到对方的任何数据包，判定为对方掉线。 在网络较差的情况下，可能会有误报。建议可靠的掉线检测应该由信令来做。
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
  [self.delegate didOfflineOfUid:uid reason:reason];
}

//接收到对方数据流消息的回调 
-(void)rtcEngine:(AgoraRtcEngineKit *)engine receiveStreamMessageFromUid:(NSUInteger)uid streamId:(NSInteger)streamId data:(NSData *)data {
  NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [self.delegate receiveStreamMessageFromUid:uid streamId:streamId data:message];
  
}

//该回调每 2 秒触发，向APP报告频道内所有用户当前的上行、下行网络质量。用户 ID。表示该回调报告的是持有该ID的用户的网络质量 。当 uid 为 0 时，返回的是本地用户的网络质量
/*AgoraNetworkQualityUnknown(0)：网络质量未知
 AgoraNetworkQualityExcellent(1)：网络质量极好
 AgoraNetworkQualityGood(2)：用户主观感觉和 excellent 差不多，但码率可能略低于 excellent
 AgoraNetworkQualityPoor(3)：用户主观感受有瑕疵但不影响沟通
 AgoraNetworkQualityBad(4)：勉强能沟通但不顺畅
 AgoraNetworkQualityVBad(5)：网络质量非常差，基本不能沟通
 AgoraNetworkQualityDown(6)：完全无法沟通*/
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine networkQuality:(NSUInteger)uid txQuality:(AgoraRtcQuality)txQuality rxQuality:(AgoraRtcQuality)rxQuality
{
  
}

//在 SDK 和服务器失去了网络连接时，触发该回调。失去连接后，除非APP主动调用 leaveChannel，SDK 会一直自动重连。
- (void)rtcEngineConnectionDidInterrupted:(AgoraRtcEngineKit *)engine {
 
}

//有时候由于网络原因，客户端可能会和服务器失去连接，SDK 会进行自动重连，自动重连成功后触发此回调方法。
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didRejoinChannel:(NSString * _Nonnull)channel withUid:(NSUInteger)uid elapsed:(NSInteger) elapsed
{
  
}

//在 SDK 和服务器失去了网络连接后，会触发 rtcEngineConnectionDidInterrupted 回调，并自动重连。 在一定时间内（默认 10 秒）如果没有重连成功，触发 rtcEngineConnectionDidLost 回调。除非 APP 主动调用 leaveChannel，SDK 仍然会自动重连。
- (void)rtcEngineConnectionDidLost:(AgoraRtcEngineKit *)engine {
  
}


@end




















































