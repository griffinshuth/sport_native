//
//  QiniuManager.m
//  sportdream
//
//  Created by lili on 2017/9/26.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "QiniuManager.h"
#import "AppDelegate.h"
#import <Photos/photos.h>

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

RCT_EXPORT_METHOD(getFilePathByAssetsPath:(NSString*)path width:(int)width height:(int)height resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSURL* url = [[NSURL alloc] initWithString:path];
  NSArray* array = [[NSArray alloc] initWithObjects:url, nil];
  PHFetchResult* result = [PHAsset fetchAssetsWithALAssetURLs:array options:nil];
  long count = result.count;
  [[PHImageManager defaultManager] requestImageForAsset:result.firstObject targetSize:CGSizeMake(width, height) contentMode:PHImageContentModeAspectFill options:nil resultHandler:^(UIImage * _Nullable Image, NSDictionary * _Nullable info) {
    if (![[info objectForKey:PHImageResultIsDegradedKey] boolValue]) {
      NSString *filePath = nil;
      NSData *data = nil;
      /*if (UIImagePNGRepresentation(Image) == nil) {
        data = UIImageJPEGRepresentation(Image, 1.0);
      } else {
        data = UIImagePNGRepresentation(Image);
      }*/
      
      data = UIImageJPEGRepresentation(Image, 0.5);
      
      //图片保存的路径
      //这里将图片放在沙盒的documents文件夹中
      NSString *DocumentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
      
      //文件管理器
      NSFileManager *fileManager = [NSFileManager defaultManager];
      
      //把刚刚图片转换的data对象拷贝至沙盒中
      [fileManager createDirectoryAtPath:DocumentsPath withIntermediateDirectories:YES attributes:nil error:nil];
      NSString *ImagePath = [[NSString alloc] initWithFormat:@"/uploadcache.jpeg"];
      [fileManager createFileAtPath:[DocumentsPath stringByAppendingString:ImagePath] contents:data attributes:nil];
      
      //得到选择后沙盒中图片的完整路径
      filePath = [[NSString alloc] initWithFormat:@"%@%@", DocumentsPath, ImagePath];
      
      resolve(@{@"FilePath": filePath,@"filelen":[NSNumber numberWithLong:data.length]});
    }
  }];
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
