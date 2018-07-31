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
#import "VideoPlayer.h"
#import "h264encode.h"
#import "AudioMixer.h"

@interface DirectorServerViewController : UIViewController<AACDecodeDelegate,LocalWifiNetworkDelegate,PostProgressDelegate,AgoraKitRemoteCameraDelegate,VideoPlayerDelegate,h264encodeDelegate,AudioMixerDelegate>
@property (nonatomic,strong)NSString* AgoraChannelName;
@property (nonatomic,strong)NSString* rtmpPushUrl;
@property (nonatomic,strong)NSString* rtmpPlayUrl;
@property (nonatomic,strong)NSString* hlsPlayUrl;
@end
