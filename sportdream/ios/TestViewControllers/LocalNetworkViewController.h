//
//  LocalNetworkViewController.h
//  sportdream
//
//  Created by lili on 2017/10/7.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraRecord.h"
#import "mp4Push.h"
#import "h264encode.h"
#import "LocalWifiNetwork.h"

@interface LocalNetworkViewController : UIViewController<CameraRecordDelegate,h264encodeDelegate,LocalWifiNetworkDelegate>

@end
