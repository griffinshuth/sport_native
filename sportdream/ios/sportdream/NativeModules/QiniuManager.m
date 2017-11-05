//
//  QiniuManager.m
//  sportdream
//
//  Created by lili on 2017/9/26.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "QiniuManager.h"
#import "AppDelegate.h"

@implementation QiniuManager
RCT_EXPORT_MODULE(QiniuModule);

RCT_EXPORT_METHOD(upload:(NSString*)filepath)
{
  NSURL *url = [NSURL URLWithString:@"http://192.168.0.105:3000/getUploadToken?bucket=grassroot"];
  NSMutableURLRequest * theRequest = [NSMutableURLRequest requestWithURL:url];
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData* result = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
  NSString* token = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
  QNUploadManager *upManager = [[QNUploadManager alloc] init];
  QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
    NSLog(@"percent == %.2f", percent);
  }
                                                               params:nil
                                                             checkCrc:NO
                                                   cancellationSignal:nil];
  [upManager putFile:filepath key:nil token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
    NSLog(@"info ===== %@", info);
    NSLog(@"resp ===== %@", resp);
  }
              option:uploadOption];
}

RCT_EXPORT_METHOD(shortRecord)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoShortRecordViewController];
}

RCT_EXPORT_METHOD(Zhibo)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoZhiboViewController];
}

RCT_EXPORT_METHOD(h264Record)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoH264ViewController];
}
RCT_EXPORT_METHOD(gotoLocalNetwork)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoLocalNetworkViewController];
}














@end
