//
//  VideoGPUFilterModule.m
//  sportdream
//
//  Created by lili on 2018/3/15.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "VideoGPUFilterModule.h"
#import <GPUImage/GPUImage.h>
#import <Photos/photos.h>

@interface VideoGPUFilterModule()
@property (strong,nonatomic) GPUImageMovie *movieFile;
@property (strong,nonatomic) GPUImageOutput<GPUImageInput> *filter;
@property (strong,nonatomic) GPUImageMovieWriter *movieWriter;
@property (strong,nonatomic) NSTimer * timer;
@end

@implementation VideoGPUFilterModule
{
  
}
RCT_EXPORT_MODULE(VideoGPUFilterModule);

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"FilterProgress"];
}

- (void)retrievingProgress
{
  float progress = self.movieFile.progress;
  [self sendEventWithName:@"FilterProgress" body:@{@"percent": [NSNumber numberWithFloat:progress]}];
}


RCT_EXPORT_METHOD(processFilters:(NSString*)filePath resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSURL* sampleURL = [NSURL URLWithString:filePath];
  self.movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
  self.movieFile.playAtActualSpeed = NO;
  self.filter = [[GPUImagePixellateFilter alloc] init];
  [self.movieFile addTarget:self.filter];
  NSString* pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/GPUMovie.mp4"];
  unlink([pathToMovie UTF8String]);
  NSURL* movieURL = [NSURL fileURLWithPath:pathToMovie];
  self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(640.0, 480.0)];
  [self.filter addTarget:self.movieWriter];
  
  self.movieWriter.shouldPassthroughAudio = YES;
  self.movieFile.audioEncodingTarget = self.movieWriter;
  [self.movieFile enableSynchronizedEncodingUsingMovieWriter:self.movieWriter];
  
  [self.movieWriter startRecording];
  [self.movieFile startProcessing];
  
  self.timer = [NSTimer scheduledTimerWithTimeInterval:0.3f
                                           target:self
                                         selector:@selector(retrievingProgress)
                                         userInfo:nil
                                          repeats:YES];
  
  __weak typeof(self) weakSelf=self;
  [self.movieWriter setCompletionBlock:^{
    [weakSelf.filter removeTarget:weakSelf.movieWriter];
    [weakSelf.movieWriter finishRecording];
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
      [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:movieURL];
    } completionHandler:^(BOOL success,NSError* error){
      NSLog(@"save sucess");
      resolve(@{@"url":[movieURL absoluteString]});
    }];
    [weakSelf.timer invalidate];
    weakSelf.timer = nil;
  }];
  
}
@end






















