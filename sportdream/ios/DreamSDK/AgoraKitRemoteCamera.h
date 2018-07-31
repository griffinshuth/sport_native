//
//  AgoraKitRemoteCamera.h
//  sportdream
//
//  Created by lili on 2018/1/16.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraVideoChat/AgoraVideoChat.h>

@protocol AgoraKitRemoteCameraDelegate <NSObject>
- (void)didjoinChannelSuccess;
- (void)firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed;
- (void)didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed;
- (void)didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason;
- (void)receiveStreamMessageFromUid:(NSUInteger)uid streamId:(NSInteger)streamId data:(NSString *)data;
- (void)addLocalYBuffer:(void *)yBuffer
                uBuffer:(void *)uBuffer
                vBuffer:(void *)vBuffer
                yStride:(int)yStride
                uStride:(int)uStride
                vStride:(int)vStride
                  width:(int)width
                 height:(int)height
               rotation:(int)rotation;
- (void)addRemoteOfUId:(unsigned int)uid
               yBuffer:(void *)yBuffer
               uBuffer:(void *)uBuffer
               vBuffer:(void *)vBuffer
               yStride:(int)yStride
               uStride:(int)uStride
               vStride:(int)vStride
                 width:(int)width
                height:(int)height
              rotation:(int)rotation;

- (void)onMixedAudioFrame:(void *)buffer length:(int)length;
- (void)onPlaybackAudioFrameBeforeMixing:(void *)buffer length:(int)length uid:(int)uid;
@end

@interface AgoraKitRemoteCamera : NSObject<AgoraRtcEngineDelegate>
@property (nonatomic, weak) id <AgoraKitRemoteCameraDelegate> delegate;

-(id)initWithChannelName:(NSString*)channelName useExternalVideoSource:(BOOL)useExternalVideoSource localView:(UIView*)localView useExternalAudioSource:(BOOL)useExternalAudioSource externalSampleRate:(int)externalSampleRate externalChannelsPerFrame:(int)externalChannelsPerFrame;
-(void)joinChannel;
- (void)leaveChannel;
- (void)sendDataWithString:(NSString *)message;
-(void)pushExternalVideoData:(NSData*)NV12Data timeStamp:(CMTime)timeStamp;
-(void)pushExternalAudioFrameRawData:(void *)data
                             samples:(NSUInteger)samples
                           timestamp:(NSTimeInterval)timestamp;
-(void)setupRemoteVideo:(AgoraRtcVideoCanvas*)canvas;
-(void)setRemoteBigSmallStream:(NSUInteger)uid isBig:(BOOL)isBig;
-(void)switchCamera;
- (void)setCameraZoomFactor:(CGFloat)zoomFactor;
- (void)setCameraFocusPositionInPreview:(CGPoint)position;
- (void)setCameraTorchOn:(BOOL)isOn;
- (void)setCameraAutoFocusFaceModeEnabled:(BOOL)enable;
- (void)setEnableSpeakerphone:(BOOL)enableSpeaker;
- (void)muteLocalAudioStream:(BOOL)muted;
- (void)muteAllRemoteAudioStreams:(BOOL)muted;
- (void)muteRemoteAudioStream:(NSUInteger)uid muted:(BOOL)muted;
- (void)muteLocalVideoStream:(BOOL)muted;
- (void)muteAllRemoteVideoStreams:(BOOL)mute;
- (void)muteRemoteVideoStream:(NSUInteger)uid mute:(BOOL)mute;
- (void) startAudioMixing: (NSString*) filePath
                 loopback: (BOOL) loopback
                  replace: (BOOL) replace
                    cycle: (NSInteger) cycle;
- (void)stopAudioMixing;

@end
