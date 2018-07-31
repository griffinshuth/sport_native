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
  return @[@"uploadProgress"];
}

RCT_EXPORT_METHOD(upload:(NSString*)filepath uploadTokenUrl:(NSString*)uploadTokenUrl resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSURL *url = [NSURL URLWithString:uploadTokenUrl];
  NSMutableURLRequest * theRequest = [NSMutableURLRequest requestWithURL:url];
  NSURLResponse *response = nil;
  NSError *error = nil;
  NSData* result = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
  NSString* token = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
  QNUploadManager *upManager = [[QNUploadManager alloc] init];
  QNUploadOption *uploadOption = [[QNUploadOption alloc] initWithMime:nil progressHandler:^(NSString *key, float percent) {
    NSLog(@"percent == %.2f", percent);
    [self sendEventWithName:@"uploadProgress" body:@{@"percent": [NSNumber numberWithFloat:percent]}];
  }
                                                               params:nil
                                                             checkCrc:NO
                                                   cancellationSignal:nil];
  [upManager putFile:filepath key:nil token:token complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
    NSLog(@"info ===== %@", info);
    NSLog(@"resp ===== %@", resp);
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

RCT_EXPORT_METHOD(gotoCameraOnStand:(NSString*)deviceID cameraType:(int)cameraType cameraName:(NSString*)cameraName roomID:(int)roomID isSlowMotion:(BOOL)isSlowMotion ip:(NSString*)ip)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoCameraOnStandViewController:deviceID cameraType:cameraType cameraName:cameraName roomID:roomID isSlowMotion:isSlowMotion ip:ip];
}

RCT_EXPORT_METHOD(gotoDirectorServer:(NSString*)channelName)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoDirectorServerViewController:channelName];
}

RCT_EXPORT_METHOD(gotoCommentators:(NSString*)channelName)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoCommentatorsViewController:channelName];
}

RCT_EXPORT_METHOD(gotoCheerleader:(NSString*)channelName)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoCheerLeaderViewController:channelName];
}

RCT_EXPORT_METHOD(gotoLiveCommentators:(NSString*)deviceID cameraType:(int)cameraType cameraName:(NSString*)cameraName roomID:(int)roomID)
{
  AppDelegate* delegate =  (AppDelegate*)[UIApplication sharedApplication].delegate;
  [delegate gotoLiveCommentatorsViewController:deviceID cameraType:cameraType cameraName:cameraName roomID:roomID];
}
















@end
