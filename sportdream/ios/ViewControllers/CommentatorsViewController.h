//
//  CommentatorsViewController.h
//  sportdream
//
//  Created by lili on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AgoraKitRemoteCamera.h"

@interface CommentatorsViewController : UIViewController<AgoraKitRemoteCameraDelegate>
@property (nonatomic,strong) NSString* channelName;
@end
