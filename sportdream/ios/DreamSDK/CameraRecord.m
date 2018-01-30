//
//  CameraRecord.m
//  sportdream
//
//  Created by lili on 2017/12/21.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "CameraRecord.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import "libyuv.h"

//GPUImageRawDataOutput
@interface captureDataHandle:GPUImageRawDataOutput
@property (nonatomic,weak) CameraRecord* capture;
@end

@implementation captureDataHandle
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat capture:(CameraRecord *)capture
{
  self = [super initWithImageSize:newImageSize resultsInBGRAFormat:resultsInBGRAFormat];
  if (self) {
    self.capture = capture;
  }
  return self;
}
-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex
{
  [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
  //将bgra转为yuv
  //图像宽度
  int width =imageSize.width;
  //图像高度
  int height = imageSize.height;
  //宽*高
  int w_x_h = width * height;
  //yuv数据长度 = (宽 * 高) * 3 / 2
  int yuv_len = w_x_h * 3 / 2;
  
  //yuv数据
  uint8_t *yuv_bytes = malloc(yuv_len);
  [self lockFramebufferForReading];
  ARGBToNV12(self.rawBytesForImage, width * 4, yuv_bytes, width, yuv_bytes + w_x_h, width, width, height);
  [self unlockFramebufferAfterReading];
  NSData *yuvData = [NSData dataWithBytesNoCopy:yuv_bytes length:yuv_len];
  [self.capture.delegate captureOutput:yuvData frameTime:frameTime];
}
@end

@interface CameraRecord ()

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIView* preview;
@property (nonatomic, strong) captureDataHandle* output;
@end

@implementation CameraRecord
{
  int width;
  int height;
  GPUImageAlphaBlendFilter* blendFilter;
  GPUImageUIElement *uielement;
}

-(id)initWithPreview:(UIView*)preview width:(int)width height:(int)height
{
  self = [super init];
  if(self){
    width = width;
    height = height;
    self.preview = preview;
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageView alloc] initWithFrame:CGRectZero];
    [self.preview addSubview:self.filterView];
    [self setGPUImageViewRect];
    self.output = [[captureDataHandle alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:YES capture:self];
    // 水印
    NSDate *startTime = [NSDate date];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 240, 100)];
    label.text = @"我是水印";
    label.font = [UIFont systemFontOfSize:30];
    label.textColor = [UIColor redColor];
    UIImage *image = [UIImage imageNamed:@"basketballcourt.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    subView.backgroundColor = [UIColor clearColor];
    imageView.center = CGPointMake(subView.bounds.size.width / 2, subView.bounds.size.height / 2);
    [subView addSubview:imageView];
    [subView addSubview:label];
    uielement = [[GPUImageUIElement alloc] initWithView:subView];
    
    blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    blendFilter.mix = 1.0f;
    
    
    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    GPUImageFilter *filter = [[GPUImageFilter alloc] init];
    [self.videoCamera addTarget:filter];
    [filter addTarget:blendFilter];
    [uielement addTarget:blendFilter];
    [blendFilter addTarget:self.filterView];
    [blendFilter addTarget:self.output];
    __unsafe_unretained GPUImageUIElement *weakUIElementInput = uielement;
    
    [filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
      label.text = [NSString stringWithFormat:@"Time: %f s", -[startTime timeIntervalSinceNow]];
      [weakUIElementInput update];
    }];
    
  }
  return self;
}

-(void)dealloc
{
  
}

-(void)setGPUImageViewRect
{
  self.filterView.translatesAutoresizingMaskIntoConstraints = NO;
  NSLayoutConstraint* contraint_width = [NSLayoutConstraint constraintWithItem:self.filterView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.preview attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
  [self.preview addConstraint:contraint_width];
  
  NSLayoutConstraint* contraint_height = [NSLayoutConstraint constraintWithItem:self.filterView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.preview attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
  [self.preview addConstraint:contraint_height];
}

-(void)startCapture
{
  [self.videoCamera startCameraCapture];
}

-(void)stopCapture
{
  [self.videoCamera stopCameraCapture];
}
@end
