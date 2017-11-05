//
//  EaseMessageViewManager.m
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "EaseMessageViewManager.h"
#import <MapKit/MapKit.h>
#import "EaseMessageView.h"

@implementation EaseMessageViewManager
RCT_EXPORT_MODULE();
-(UIView*)view
{
  return [[EaseMessageView alloc] init];
}
@end
