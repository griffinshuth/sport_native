//
//  CheerLeaderViewController.h
//  sportdream
//
//  Created by lili on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AgoraKitRemoteCamera.h"
#import "KTVAUGraphRecorder.h"

@interface CheerLeaderViewController : UIViewController<AgoraKitRemoteCameraDelegate,KTVAUGraphRecorderDelegate>
@property (nonatomic,strong) NSString* channelName;
@end
