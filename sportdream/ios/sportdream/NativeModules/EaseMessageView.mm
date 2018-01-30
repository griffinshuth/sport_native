//
//  EaseMessageView.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "EaseMessageView.h"

@implementation EaseMessageView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(instancetype)init
{
  if(self = [super init])
  {
    self.videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    self.videoCanvas.uid = 0;
    self.videoCanvas.view = self;
    self.videoCanvas.renderMode = AgoraRtc_Render_Adaptive;
  }
  return self;
}

- (void)setUid:(NSNumber *)uid{
  _uid = uid;
  if(uid == 0){
    [self.agoraKit setupLocalVideo:self.videoCanvas];
  }else{
    self.videoCanvas.uid = [uid unsignedIntegerValue];
    [self.agoraKit setupRemoteVideo:self.videoCanvas];
  }
}

@end
