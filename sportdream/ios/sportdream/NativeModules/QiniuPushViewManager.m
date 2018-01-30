//
//  QiniuPushViewManager.m
//  sportdream
//
//  Created by lili on 2017/12/12.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "QiniuPushViewManager.h"
#import "QiniuPushView.h"

@implementation QiniuPushViewManager
RCT_EXPORT_MODULE();
- (NSArray *)customDirectEventTypes
{
  return @[
           @"onReady",
           @"onConnecting",
           @"onStreaming",
           @"onShutdown",
           @"onIOError",
           @"onDisconnected"
           ];
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_VIEW_PROPERTY(rtmpURL, NSString);
RCT_EXPORT_VIEW_PROPERTY(profile, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(started, BOOL);
RCT_EXPORT_VIEW_PROPERTY(muted, BOOL);
RCT_EXPORT_VIEW_PROPERTY(zoom, NSNumber);
RCT_EXPORT_VIEW_PROPERTY(focus, BOOL);
RCT_EXPORT_VIEW_PROPERTY(camera, NSString);

@synthesize bridge = _bridge;
-(UIView*)view
{
  return [[QiniuPushView alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
}
@end
