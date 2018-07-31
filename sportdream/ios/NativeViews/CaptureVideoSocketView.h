//
//  CaptureVideoSocketView.h
//  sportdream
//
//  Created by lili on 2018/7/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CameraSlowMotionRecord.h"

@interface CaptureVideoSocketView : UIView<CameraSlowMotionRecordDelegate>
@property (nonatomic,assign) BOOL capture;
@end
