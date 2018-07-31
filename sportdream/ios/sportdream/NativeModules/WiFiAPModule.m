//
//  WiFiAPModule.m
//  sportdream
//
//  Created by lili on 2018/5/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "WiFiAPModule.h"

@implementation WiFiAPModule
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(openWifiSetting)
{
  NSURL*url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
  
  if([[UIApplication sharedApplication] canOpenURL:url]) {
    [[UIApplication sharedApplication]openURL:url];
  }
}

RCT_EXPORT_METHOD(openAPUI)
{
  NSURL*url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
  
  if([[UIApplication sharedApplication] canOpenURL:url]) {
    [[UIApplication sharedApplication]openURL:url];
  }
}
@end
