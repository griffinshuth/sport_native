//
//  AudioRecord.m
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "AudioRecord.h"

@interface AudioRecord()
//音频设备
@property (nonatomic,strong) AVCaptureDeviceInput* audioInputDevice;
//输出数据接收
@property (nonatomic,strong) AVCaptureAudioDataOutput* audioDataOutput;
@property (nonatomic,strong) AVCaptureSession* captureSession;
@end

@implementation AudioRecord
{
  
}

-(id)init
{
  self = [super init];
  if(self){
    [self initInputDevice];
    [self createOutput];
    [self createCaptureSession];
  }
  return self;
}

//初始化音视频输入设备
-(void) initInputDevice
{
  AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
}

-(void)createOutput
{
  dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
  [self.audioDataOutput setSampleBufferDelegate:self queue:captureQueue];
}

-(void)createCaptureSession
{
  self.captureSession = [[AVCaptureSession alloc] init];
  [self.captureSession beginConfiguration];
  
  if([self.captureSession canAddInput:self.audioInputDevice])
  {
    [self.captureSession addInput:self.audioInputDevice];
  }
  
  if([self.captureSession canAddOutput:self.audioDataOutput])
  {
    [self.captureSession addOutput:self.audioDataOutput];
  }
  [self.captureSession commitConfiguration];
}

-(void) destroyCaptureSession{
  if (self.captureSession) {
    [self.captureSession removeInput:self.audioInputDevice];
    [self.captureSession removeOutput:self.self.audioDataOutput];
  }
  self.captureSession = nil;
}

//音视频采样数据回调接口
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection
{
  [self.delegate captureAudioOutput:sampleBuffer];
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
