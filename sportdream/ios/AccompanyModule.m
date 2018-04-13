//
//  AccompanyModule.m
//  sportdream
//
//  Created by lili on 2018/3/14.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AccompanyModule.h"
#import <Photos/photos.h>

@interface AccompanyModule()

@end

@implementation AccompanyModule
RCT_EXPORT_MODULE(AccompanyModule);

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"Progress"];
}

-(NSURL*)exportURL
{
  NSString* filePath = nil;
  NSUInteger count = 0;
  do{
    filePath = NSTemporaryDirectory();
    NSString* numberString = count>0?[NSString stringWithFormat:@"-%li",(unsigned long) count]:@"";
    NSString* fileNameString = [NSString stringWithFormat:@"masterpiece-%@.mp4",numberString];
    filePath = [filePath stringByAppendingPathComponent:fileNameString];
    count++;
  }while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
  
  return [NSURL fileURLWithPath:filePath];
}

-(void)writeExportedVideoToAssetsLibray:(NSURL*)outputURL
{
  NSURL* exportURL = outputURL;
  [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:exportURL];
  } completionHandler:^(BOOL success,NSError* error){
    NSLog(@"save sucess");
  }];
}

RCT_EXPORT_METHOD(addAccompany:(NSString*)videoPath audioPath:(NSString*)filename resolver:(RCTPromiseResolveBlock)resolve
rejecter:(RCTPromiseRejectBlock)reject)
{
  NSURL* audio_url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"mp3"];
  NSURL* video_url = [NSURL URLWithString:videoPath];
  NSDictionary* options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
  NSArray* keys = @[@"tracks",@"duration",@"commonMetadata"];
  
  AVAsset* videoAsset = [AVURLAsset URLAssetWithURL:video_url options:options];
  [videoAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
    CMTime video_time = [videoAsset duration];
    NSError* error = nil;
    AVKeyValueStatus status = [videoAsset statusOfValueForKey:@"duration" error:&error];
    switch (status) {
      case AVKeyValueStatusLoaded:
        
        break;
        
      default:
        break;
    }
  }];
  
  AVAsset* audioAsset = [AVURLAsset URLAssetWithURL:audio_url options:options];
  [audioAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
    CMTime audio_time = [audioAsset duration];
    NSError* error = nil;
    AVKeyValueStatus status = [audioAsset statusOfValueForKey:@"duration" error:&error];
    switch (status) {
      case AVKeyValueStatusLoaded:
        
        break;
        
      default:
        break;
    }
  }];
  
  AVMutableComposition* composition = [AVMutableComposition composition];
  AVMutableCompositionTrack* videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
  AVMutableCompositionTrack* audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
  
  CMTime cursorTime = kCMTimeZero;
  //延迟一段时间，等待媒体文件时长信息的获取
  double delayInSeconds = 1;
  int64_t delta = (int64_t)delayInSeconds*NSEC_PER_SEC;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delta);
  dispatch_after(popTime, dispatch_get_main_queue(), ^{
    CMTime video_time = [videoAsset duration];
    CMTime audio_time = [audioAsset duration];
    CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero, video_time);
    
    AVAssetTrack* assetTrack;
    assetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [videoTrack insertTimeRange:videoTimeRange ofTrack:assetTrack atTime:cursorTime error:nil];
    
    CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, video_time);
    assetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:audioTimeRange ofTrack:assetTrack atTime:cursorTime error:nil];
    
    //导出文件
    AVAssetExportSession* exportSession;
    NSString* preset = AVAssetExportPresetMediumQuality;
    exportSession = [AVAssetExportSession  exportSessionWithAsset:[composition copy] presetName:preset];
    exportSession.outputURL = [self exportURL];
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
      AVAssetExportSessionStatus status = exportSession.status;
      if(status == AVAssetExportSessionStatusCompleted){
        //[self writeExportedVideoToAssetsLibray:exportSession.outputURL];
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
          [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:exportSession.outputURL];
        } completionHandler:^(BOOL success,NSError* error){
          NSLog(@"save sucess");
          resolve(@{@"url":[exportSession.outputURL absoluteString]});
        }];
      }else{
        NSLog(@"Export Failed");
      }
    }];
  });
  
  
}
@end
