//
//  QiniuPlayViewManager.m
//  sportdream
//
//  Created by lili on 2017/12/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "QiniuPlayViewManager.h"
#import "QiniuPlayView.h"

@implementation QiniuPlayViewManager
@synthesize bridge = _bridge;
RCT_EXPORT_MODULE();
- (UIView *)view
{
  return [[QiniuPlayView alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}

- (NSArray *)customDirectEventTypes
{
  return @[
           @"onLoading",
           @"onPaused",
           @"onShutdown",
           @"onError",
           @"onPlaying"
           ];
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(started, BOOL);
RCT_EXPORT_VIEW_PROPERTY(muted, BOOL);
@end
