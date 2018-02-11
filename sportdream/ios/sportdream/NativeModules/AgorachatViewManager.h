//
//  EaseMessageViewManager.h
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <React/RCTViewManager.h>
#import <AgoraVideoChat/AgoraVideoChat.h>
#import "../AgoraPush/AGVideoProcessing.h"

@interface AgorachatViewManager : RCTViewManager <AgoraRtcEngineDelegate>
@property (strong, nonatomic) AgoraRtcEngineKit *agoraKit;
@end
