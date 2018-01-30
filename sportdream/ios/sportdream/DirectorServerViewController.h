//
//  DirectorServerViewController.h
//  sportdream
//
//  Created by lili on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocalWifiNetwork.h"
#import "h264decode.h"
#import "AgoraKitRemoteCamera.h"
#import <AVFoundation/AVFoundation.h>
#import "AACDecode.h"

@interface DirectorServerViewController : UIViewController<AACDecodeDelegate,LocalWifiNetworkDelegate,PostProgressDelegate,AgoraKitRemoteCameraDelegate>

@end
