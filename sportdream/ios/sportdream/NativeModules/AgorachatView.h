//
//  EaseMessageView.h
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EaseUI.h"
#import <AgoraVideoChat/AgoraVideoChat.h>

@interface AgorachatView : UIView
@property (strong, nonatomic) AgoraRtcEngineKit *agoraKit;
@property (strong, nonatomic) AgoraRtcVideoCanvas *videoCanvas;
@property (nonatomic, copy) NSNumber * uid;
@end
