//
//  VideoChatAndPush.h
//  sportdream
//
//  Created by lili on 2018/1/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraVideoChat/AgoraVideoChat.h>

@interface VideoChatAndPush : NSObject<AgoraRtcEngineDelegate>
-(id)initWithChannelName:(NSString*)channelName isBroadcaster:(BOOL)isBroadcaster view:(UIView*)view useExternalVideoSource:(BOOL)useExternalVideoSource externalPreview:(UIView*)externalPreview;
-(void)pushExternalVideoData:(CVPixelBufferRef)NV12Data timeStamp:(CMTime)timeStamp;

@end
