//
//  CaptureVideoSocketViewManager.m
//  sportdream
//
//  Created by lili on 2018/7/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CaptureVideoSocketViewManager.h"
#import "CaptureVideoSocketView.h"

@implementation CaptureVideoSocketViewManager
RCT_EXPORT_MODULE();
RCT_EXPORT_VIEW_PROPERTY(capture, BOOL);

-(UIView*)view
{
  CaptureVideoSocketView* view = [[CaptureVideoSocketView alloc] init];
  return view;
}

@end
