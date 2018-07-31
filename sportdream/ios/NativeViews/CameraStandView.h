//
//  HighlightView.h
//  sportdream
//
//  Created by lili on 2018/5/23.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "h264decode.h"

@interface CameraStandView : UIView
@property (nonatomic,strong) h264decode* decoder;
@property (nonatomic, copy) NSNumber * uid;
@end
