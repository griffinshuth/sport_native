//
//  CameraSlowMotionRecord.m
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "CameraSlowMotionRecord.h"
#import "MyLayout.h"

@interface CameraSlowMotionRecord()
@property (nonatomic,strong) dispatch_queue_t videoQueue;
@property (nonatomic,strong) AVCaptureSession* captureSession;
@property (nonatomic,strong) AVCaptureDeviceInput* videoInput;
@property (nonatomic,strong) AVCaptureVideoDataOutput* videoDataOutput;
@property (nonatomic,strong) UIView* preview;
@end

@implementation CameraSlowMotionRecord
{
  BOOL _isSlowMotion;
}

-(id)initWithPreview:(UIView*)preview isSlowMotion:(BOOL)isSlowMotion
{
  self = [super init];
  if(self){
    self.preview = preview;
    _isSlowMotion = isSlowMotion;
    AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:captureQueue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoDataOutput setVideoSettings:@{
                                             (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                             }];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession beginConfiguration];
    if([self.captureSession canAddInput:self.videoInput])
    {
      [self.captureSession addInput:self.videoInput];
    }
   
    if([self.captureSession canAddOutput:self.videoDataOutput])
    {
      [self.captureSession addOutput:self.videoDataOutput];
    }
 
    if(!_isSlowMotion){
      [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }else{
      self.captureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
    }
    
    [self setVideoDataOutputConfig];
    [self.captureSession commitConfiguration];
    
    if(_isSlowMotion){
      [self configureCameraForHighestFrameRate:videoDevice];
    }else{
      if ( [videoDevice lockForConfiguration:NULL] == YES ) {
        videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 25);
        [videoDevice unlockForConfiguration];
      }
    }
  
    AVCaptureVideoPreviewLayer* previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [previewLayer setFrame:self.preview.frame];
    [self.preview.layer addSublayer:previewLayer];
  }
  return self;
}

//设置视频配置信息，横竖屏设置
-(void) setVideoDataOutputConfig{
  for (AVCaptureConnection *conn in self.videoDataOutput.connections) {
    if (conn.isVideoStabilizationSupported) {
      [conn setPreferredVideoStabilizationMode:AVCaptureVideoStabilizationModeAuto];
    }
    if (conn.isVideoOrientationSupported) {
      [conn setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    if (conn.isVideoMirrored) {
      [conn setVideoMirrored: YES];
    }
  }
}

//配置高速摄像机
- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device
{
  AVCaptureDeviceFormat *bestFormat = nil;
  AVFrameRateRange *bestFrameRateRange = nil;
  float maxframerate = 0;
  for ( AVCaptureDeviceFormat *format in [device formats] ) {
    for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
      if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
        bestFormat = format;
        bestFrameRateRange = range;
        maxframerate = bestFrameRateRange.maxFrameRate;
        NSLog(@"maxframerate:%f",maxframerate);
      }
    }
  }
  if ( bestFormat ) {
    if ( [device lockForConfiguration:NULL] == YES ) {
      device.activeFormat = bestFormat;
      device.activeVideoMinFrameDuration = bestFrameRateRange.minFrameDuration;
      device.activeVideoMaxFrameDuration = bestFrameRateRange.minFrameDuration;
      [device unlockForConfiguration];
    }
  }
}

//音视频采样数据回调接口
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection
{
  [self.delegate captureOutput:sampleBuffer];
}

-(void)startCapture
{
  [self.captureSession startRunning];
}

-(void)stopCapture
{
  [self.captureSession stopRunning];
}
@end
