//
//  VideoChatSession.m
//  sportdream
//
//  Created by lili on 2018/1/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "VideoChatSession.h"

@implementation VideoChatSession
-(id)initWithUid:(NSUInteger)uid
{
  if(self = [super init]){
    self.uid = uid;
    self.hostingView = [[UIView alloc] init];
    self.hostingView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.canvas = [[AgoraRtcVideoCanvas alloc] init];
    self.canvas.uid = uid;
    self.canvas.view = self.hostingView;
    self.canvas.renderMode = AgoraRtc_Render_Fit;
  }
  return self;
}

+(id)localSession{
  return [[VideoChatSession alloc] initWithUid:0];
}

+(id)localSessionFromExternal:(UIView*)preview
{
  VideoChatSession* session = [[VideoChatSession alloc] init];
  session.uid = 0;
  session.hostingView = preview;
  session.hostingView.translatesAutoresizingMaskIntoConstraints = NO;
  return session;
}
@end
