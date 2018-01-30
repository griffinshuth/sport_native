//
//  EaseMessageViewManager.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "EaseMessageViewManager.h"
#import <MapKit/MapKit.h>
#import "EaseMessageView.h"

@implementation EaseMessageViewManager
RCT_EXPORT_MODULE();
- (id) init
{
  self = [super init];
  if(!self) return nil;
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
  [self.agoraKit enableVideo];
  [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_360P swapWidthAndHeight:false];
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
}

RCT_EXPORT_METHOD(leaveChannel)
{
  [self.agoraKit leaveChannel:^(AgoraRtcStats *stat) {
    //[UIApplication sharedApplication].idleTimerDisabled = NO;
    //[AGVideoProcessing deregisterPreprocessing:self.agoraKit];
  }];
}

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
  EaseMessageView* v = [[EaseMessageView alloc] init];
  v.agoraKit = self.agoraKit;
  return v;
}
@end
