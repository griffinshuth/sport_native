//
//  LiveCommentatorsViewController.h
//  sportdream
//
//  Created by lili on 2018/1/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioRecord.h"
#import "AACEncode.h"
#import "LocalWifiNetwork.h"

@interface LiveCommentatorsViewController : UIViewController<AudioRecordDelegate,AACEncodeDelegate,LocalWifiNetworkDelegate>

@end
