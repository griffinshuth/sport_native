//
//  VideoChatAndPush.m
//  sportdream
//
//  Created by lili on 2018/1/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "VideoChatAndPush.h"
#import "VideoChatSession.h"
#import "ChatVideoViewLayouter.h"
#import "AGVideoProcessing.h"

@interface VideoChatAndPush()
@property (strong, nonatomic) AgoraRtcEngineKit *agoraKit;
@property (assign, nonatomic) AgoraRtcClientRole clientRole;
@property (assign, nonatomic) BOOL isBroadcaster;
@property (strong,nonatomic) UIView* containerView;
@property (strong, nonatomic) NSMutableArray<VideoChatSession *> *videoSessions;
@property (strong, nonatomic) ChatVideoViewLayouter *viewLayouter;
@end

@implementation VideoChatAndPush
{
  NSString* _channelName;
  BOOL _useExternalVideoSource;
  UIView* _externalPreview;
}

- (BOOL)isBroadcaster {
  return self.clientRole == AgoraRtc_ClientRole_Broadcaster;
}

- (ChatVideoViewLayouter *)viewLayouter {
  if (!_viewLayouter) {
    _viewLayouter = [[ChatVideoViewLayouter alloc] init];
  }
  return _viewLayouter;
}

-(id)initWithChannelName:(NSString*)channelName isBroadcaster:(BOOL)isBroadcaster view:(UIView*)view useExternalVideoSource:(BOOL)useExternalVideoSource externalPreview:(UIView*)externalPreview
{
  self = [super init];
  if(self){
    self.videoSessions = [[NSMutableArray alloc] init];
    if(isBroadcaster){
      self.clientRole = AgoraRtc_ClientRole_Broadcaster;
    }else{
      self.clientRole = AgoraRtc_ClientRole_Audience;
    }
    self.containerView = view;
    _channelName = channelName;
    _useExternalVideoSource = useExternalVideoSource;
    _externalPreview = externalPreview;
    [self loadAgoraKit];
  }
  return self;
}

-(void)dealloc
{
  [self leaveChannel];
}

- (void)setVideoSessions:(NSMutableArray<VideoChatSession *> *)videoSessions {
  _videoSessions = videoSessions;
  [self updateInterfaceWithAnimation:YES];
}

- (void)updateInterfaceWithAnimation:(BOOL)animation {
  if (animation) {
    [UIView animateWithDuration:0.3 animations:^{
      [self updateInterface];
      [self.containerView layoutIfNeeded];
    }];
  } else {
    [self updateInterface];
  }
}

- (void)updateInterface {
  NSArray *displaySessions;
  displaySessions = [self.videoSessions copy];
  [self.viewLayouter layoutSessions:displaySessions inContainer:self.containerView];
}

-(void)addLocalSession
{
  VideoChatSession* localSession = [VideoChatSession localSession];
  [self.videoSessions addObject:localSession];
  [self.agoraKit setupLocalVideo:localSession.canvas];
  [self updateInterfaceWithAnimation:YES];
}

-(void)addExternalLocalSession
{
  VideoChatSession* localSession = [VideoChatSession localSessionFromExternal:_externalPreview];
  [self.videoSessions addObject:localSession];
  [self updateInterfaceWithAnimation:YES];
}

- (VideoChatSession *)fetchSessionOfUid:(NSUInteger)uid {
  for (VideoChatSession *session in self.videoSessions) {
    if (session.uid == uid) {
      return session;
    }
  }
  return nil;
}

- (VideoChatSession *)videoSessionOfUid:(NSUInteger)uid {
  VideoChatSession *fetchedSession = [self fetchSessionOfUid:uid];
  if (fetchedSession) {
    return fetchedSession;
  } else {
    VideoChatSession *newSession = [[VideoChatSession alloc] initWithUid:uid];
    [self.videoSessions addObject:newSession];
    [self updateInterfaceWithAnimation:YES];
    return newSession;
  }
}

- (void)leaveChannel {
  [self.agoraKit setupLocalVideo:nil];
  [self.agoraKit leaveChannel:nil];
  if (self.isBroadcaster) {
    [self.agoraKit stopPreview];
  }
  for (VideoChatSession *session in self.videoSessions) {
    [session.hostingView removeFromSuperview];
  }
  [self.videoSessions removeAllObjects];
  [AGVideoProcessing deregisterPreprocessing:self.agoraKit];
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

- (void)loadAgoraKit {
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
  [self.agoraKit setChannelProfile:AgoraRtc_ChannelProfile_LiveBroadcasting];
  [self.agoraKit setMixedAudioFrameParametersWithSampleRate:44100 samplesPerCall:1024];
  
  [self.agoraKit setClientRole:self.clientRole withKey:nil];
  [self.agoraKit muteLocalAudioStream:YES];
  if(_useExternalVideoSource){
    [self.agoraKit setExternalVideoSource:YES useTexture:TRUE pushMode:YES];
    [self.agoraKit enableVideo];
    [self addExternalLocalSession];
  }else{
    [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_720P swapWidthAndHeight:false];
    [self.agoraKit enableDualStreamMode:YES];
    [self.agoraKit enableVideo];
    if(self.isBroadcaster){
      [self.agoraKit startPreview];
    }
    [self addLocalSession];
  }
  
  [self.agoraKit joinChannelByKey:nil channelName:_channelName info:nil uid:0 joinSuccess:nil];
  
  [AGVideoProcessing registerPreprocessing:self.agoraKit];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
  VideoChatSession *userSession = [self videoSessionOfUid:uid];
  [self.agoraKit setupRemoteVideo:userSession.canvas];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed {
  if (self.videoSessions.count) {
    [self updateInterfaceWithAnimation:NO];
  }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
  VideoChatSession *deleteSession;
  for (VideoChatSession *session in self.videoSessions) {
    if (session.uid == uid) {
      deleteSession = session;
    }
  }
  
  if (deleteSession) {
    [self.videoSessions removeObject:deleteSession];
    [deleteSession.hostingView removeFromSuperview];
    [self updateInterfaceWithAnimation:YES];
  }
}

@end
