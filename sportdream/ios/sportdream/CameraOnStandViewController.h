//
//  CameraOnStandViewController.h
//  sportdream
//
//  Created by lili on 2018/1/9.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraSlowMotionRecord.h"
#import "h264encode.h"

@interface CameraOnStandViewController : UIViewController<CameraSlowMotionRecordDelegate,h264encodeDelegate>

@end
