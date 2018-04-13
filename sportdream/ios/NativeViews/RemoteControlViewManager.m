//
//  RemoteControlViewManager.m
//  sportdream
//
//  Created by lili on 2018/3/13.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "RemoteControlViewManager.h"
#import "RemoteControlView.h"

@implementation RemoteControlViewManager
RCT_EXPORT_MODULE()
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)
- (UIView *)view
{
  return [[RemoteControlView alloc] init];
}
@end
