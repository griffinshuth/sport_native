//
//  RemoteControlView.h
//  sportdream
//
//  Created by lili on 2018/3/13.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>
#import <MediaPlayer/MediaPlayer.h>

@interface RemoteControlView : MPVolumeView
@property (nonatomic, copy) RCTBubblingEventBlock onChange;
@property (nonatomic,strong) UISlider* volumeViewSlider;
@property (nonatomic,assign) BOOL lastAuto;
@property (nonatomic,assign) BOOL isVolumeChangeInInit;
@end
