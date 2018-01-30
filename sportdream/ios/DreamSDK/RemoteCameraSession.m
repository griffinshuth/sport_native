//
//  RemoteCameraSession.m
//  sportdream
//
//  Created by lili on 2018/1/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "RemoteCameraSession.h"

@implementation RemoteCameraSession
-(id)initWithView:(UIView*)view uid:(NSUInteger)uid
{
  self = [super init];
  if(self){
    self.uid = uid;
    self.hostingView = view;
    self.name = @"";
    self.canvas = [[AgoraRtcVideoCanvas alloc] init];
    self.canvas.uid = uid;
    self.canvas.view = self.hostingView;
    self.canvas.renderMode = AgoraRtc_Render_Adaptive;
  }
  return self;
}
@end

