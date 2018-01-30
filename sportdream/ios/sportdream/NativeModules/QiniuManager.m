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

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"uploadsuccessed"];
}

RCT_EXPORT_METHOD(upload:(NSString*)filepath resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSURL *url = [NSURL URLWithString:@"http://192.168.0.105/getUploadToken?bucket=grassroot"];
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
      //[self sendEventWithName:@"uploadsuccessed" body:@{@"name": resp[@"key"]}];
    resolve(@{@"name": resp[@"key"]});
  }
              option:uploadOption];
}

RCT_EXPORT_METHOD(Zhibo:(NSString*)url)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoZhiboViewController:url];
}

RCT_EXPORT_METHOD(playZhibo:(NSString*)url)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoQiniuPlayerViewController:url];
}

RCT_EXPORT_METHOD(h264Record:(NSString*)url)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoH264ViewController:url];
}
RCT_EXPORT_METHOD(gotoLocalNetwork)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoLocalNetworkViewController];
}

RCT_EXPORT_METHOD(gotoVideoChat)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoVideoChatViewController];
}

RCT_EXPORT_METHOD(gotoMatchDirector)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoMatchDirectorViewController];
}

RCT_EXPORT_METHOD(gotoARCameraView)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoARCameraViewController];
}

RCT_EXPORT_METHOD(gotoCameraOnStand)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoCameraOnStandViewController];
}

RCT_EXPORT_METHOD(gotoDirectorServer)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoDirectorServerViewController];
}

RCT_EXPORT_METHOD(gotoCommentators)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoCommentatorsViewController];
}

RCT_EXPORT_METHOD(gotoLiveCommentators)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoLiveCommentatorsViewController];
}
















@end
