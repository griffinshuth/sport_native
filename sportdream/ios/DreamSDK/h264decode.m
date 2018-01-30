//
//  h264decode.m
//  sportdream
//
//  Created by lili on 2017/12/28.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "h264decode.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AAPLEAGLLayer.h"
#import <GPUImage/GPUImage.h>
#import "libyuv.h"

@interface decodeDataHandle:GPUImageRawDataOutput
@property (nonatomic,weak) h264decode* capture;
@end

@implementation decodeDataHandle
{
  
}
- (instancetype)initWithImageSize:(CGSize)newImageSize resultsInBGRAFormat:(BOOL)resultsInBGRAFormat capture:(h264decode *)capture
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
  [self.capture.delegate dataFromPostProgress:(NSData*)yuvData frameTime:frameTime];
}
@end

@interface h264decode()
@property (nonatomic,strong) GPUImageRawDataInput* rawDataInput;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) decodeDataHandle* output;
@property (nonatomic,strong) UIView* overlayView;

@property (nonatomic,strong) UILabel* label;
@property (nonatomic,strong) NSDate *startTime;
@end

@implementation h264decode
{
  int width;   //只有后处理有用
  int height;  //只有后处理有用
  BOOL havePostProcess; //是否使用GPUImage进行后期处理
  uint8_t* _sps;
  NSInteger _spsSize;
  uint8_t* _pps;
  NSInteger _ppsSize;
  VTDecompressionSessionRef _decoderSession;
  CMVideoFormatDescriptionRef _decoderFormatDescription;
  dispatch_queue_t _decodeQueue;
  UIView* playbackView;
  AAPLEAGLLayer* _glLayer;
  uint32_t decodePixelFormat;
  GPUImageAlphaBlendFilter* blendFilter;
  GPUImageUIElement *uielement;
  GPUImageBrightnessFilter *BrightnessFilter;
  //初始化都为false，第一次收到sps和pps后，都设置为true，然后初始化编码器，编码器初始化完毕后，马上都置为false，如果收到新的sps pps 后，则使用新的sps pps 重启解码器
  BOOL isReceiveSPS;
  BOOL isReceivePPS;
  
  
  
}

-(id)initWithView:(UIView*)view
{
  self = [super init];
  if(self){
    isReceiveSPS = false;
    isReceivePPS = false;
    _sps = NULL;
    _spsSize = 0;
    _pps = NULL;
    _ppsSize = 0;
    havePostProcess = false;
    decodePixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    _decodeQueue = dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL);
    if(view){
      playbackView = view;
      //CGFloat screen_width = CGRectGetWidth([UIScreen mainScreen].bounds);
      //_glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, screen_width, 200)];
      _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, playbackView.frame.size.width, playbackView.frame.size.height)];
      [playbackView.layer addSublayer:_glLayer];
    }
  }
  return self;
}

-(id)initWithGPUImageView:(UIView*)preview
{
  self = [super init];
  if(self){
    isReceiveSPS = false;
    isReceivePPS = false;
    _sps = NULL;
    _spsSize = 0;
    _pps = NULL;
    _ppsSize = 0;
    width = 1280;
    height = 720;
    havePostProcess = true;
    decodePixelFormat = kCVPixelFormatType_32BGRA;
    _decodeQueue = dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL);
    playbackView = preview;
    [self initGPUImage];
  }
  return self;
}

-(void)dealloc
{
  free(_sps);
  _sps = NULL;
  free(_pps);
  _pps = NULL;
  _spsSize = _ppsSize = 0;
}

-(void)setPreview:(UIView*)view
{
  playbackView = view;
  _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, playbackView.frame.size.width, playbackView.frame.size.height)];
  [playbackView.layer addSublayer:_glLayer];
}

-(void)initGPUImage
{
  self.rawDataInput = [[GPUImageRawDataInput alloc] initWithBytes:nil size:CGSizeMake(0, 0)];
  self.filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
  [playbackView addSubview:self.filterView];
  //[self setGPUImageViewRect];
  self.output = [[decodeDataHandle alloc] initWithImageSize:CGSizeMake(width, height) resultsInBGRAFormat:YES capture:self];
  
  // 水印
  self.startTime = [NSDate date];
  self.label = [[UILabel alloc] initWithFrame:CGRectMake(100, 100, 440, 200)];
  self.label.text = @"我是水印";
  self.label.font = [UIFont systemFontOfSize:50];
  self.label.textColor = [UIColor blueColor];
  self.label.backgroundColor = [UIColor clearColor];
  UIImage *video_logo = [UIImage imageNamed:@"video_logo.png"];
  UIImageView *logo_imageView = [[UIImageView alloc] initWithImage:video_logo];
  self.overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
  self.overlayView.backgroundColor = [UIColor clearColor];
  CGRect logo_frame = logo_imageView.frame;
  logo_frame.origin = CGPointMake(1000, 62);
  logo_imageView.frame = logo_frame;
  [self.overlayView addSubview:logo_imageView];
  [self.overlayView addSubview:self.label];
  
  UIImage* video_data = [UIImage imageNamed:@"video_data.png"];
  UIImageView* data_imageView = [[UIImageView alloc] initWithImage:video_data];
  CGRect data_frame = data_imageView.frame;
  data_frame.origin = CGPointMake(820, 567);
  data_imageView.frame = data_frame;
  [self.overlayView addSubview:data_imageView];
  
  UILabel* team1name = [[UILabel alloc] initWithFrame:CGRectMake(870, 567, 148, 26)];
  team1name.text = @"骑士队";
  team1name.font = [UIFont systemFontOfSize:25];
  team1name.textColor = [UIColor whiteColor];
  team1name.backgroundColor = [UIColor clearColor];
  [self.overlayView addSubview:team1name];
  
  uielement = [[GPUImageUIElement alloc] initWithView:self.overlayView];
  blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
  blendFilter.mix = 1.0f;
  BrightnessFilter = [[GPUImageBrightnessFilter alloc] init];
  BrightnessFilter.brightness = 0;
  
  //设置滤镜链
  [self.rawDataInput addTarget:BrightnessFilter];
  [BrightnessFilter addTarget:blendFilter];
  [uielement addTarget:blendFilter];
  [blendFilter addTarget:self.filterView];
  [blendFilter addTarget:self.output];
  
  __unsafe_unretained GPUImageUIElement *weakUIElementInput = uielement;
  __weak typeof(self) ws = self;
  [BrightnessFilter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
    ws.label.text = [NSString stringWithFormat:@"Time: %f s", -[ws.startTime timeIntervalSinceNow]];
    [weakUIElementInput update];
  }];
}

-(void)setGPUImageViewRect
{
  self.filterView.translatesAutoresizingMaskIntoConstraints = NO;
  NSLayoutConstraint* contraint_width = [NSLayoutConstraint constraintWithItem:self.filterView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:playbackView attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
  [playbackView addConstraint:contraint_width];
  
  NSLayoutConstraint* contraint_height = [NSLayoutConstraint constraintWithItem:self.filterView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:playbackView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
  [playbackView addConstraint:contraint_height];
}

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
  
  CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
  *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

-(void)postProcess:(NSData*)brgaBuffer width:(int)width height:(int)height
{
  [self.rawDataInput updateDataFromBytes:(void*)brgaBuffer.bytes size:CGSizeMake(width, height)];
  [self.rawDataInput processData];
  
  [uielement update];
}

-(bool)startH264Decoder{
  if(!isReceiveSPS || !isReceivePPS){
    return FALSE;
  }
  if(_decoderSession){
    return FALSE;
  }
  const uint8_t* const parameterSetPointers[2] = {_sps,_pps};
  const size_t parameterSetSizes[2] = {_spsSize,_ppsSize};
  OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &_decoderFormatDescription);
  if(status == noErr){
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    //uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &decodePixelFormat) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon = NULL;
    status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decoderFormatDescription, NULL, attrs, &callBackRecord, &_decoderSession);
    CFRelease(attrs);
  }else{
    NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
  }
  //重置元数据标记
  isReceivePPS = false;
  isReceiveSPS = false;
  return YES;
}

-(void)stopH264Decoder{
  if(_decoderSession){
    VTDecompressionSessionInvalidate(_decoderSession);
    CFRelease(_decoderSession);
    _decoderSession = NULL;
  }
  if(_decoderFormatDescription){
    CFRelease(_decoderFormatDescription);
    _decoderFormatDescription = NULL;
  }
}

-(CVPixelBufferRef)decodeframe:(Byte*)buffer size:(size_t)size{
  CVPixelBufferRef outputPixelBuffer = NULL;
  CMBlockBufferRef blockBuffer = NULL;
  OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void*)buffer, size, kCFAllocatorNull, NULL, 0, size, 0, &blockBuffer);
  if(status == kCMBlockBufferNoErr){
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {size};
    status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decoderFormatDescription, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
    if(status == kCMBlockBufferNoErr && sampleBuffer){
      VTDecodeFrameFlags flags = 0;
      VTDecodeInfoFlags flagOut = 0;
      OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decoderSession, sampleBuffer, flags, &outputPixelBuffer, &flagOut);
      if(decodeStatus == kVTInvalidSessionErr) {
        NSLog(@"IOS8VT: Invalid session, reset decoder session");
      } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
        NSLog(@"IOS8VT: decode failed status=%d(Bad data)", decodeStatus);
      } else if(decodeStatus != noErr) {
        NSLog(@"IOS8VT: decode failed status=%d", decodeStatus);
      }
      CFRelease(sampleBuffer);
    }
    CFRelease(blockBuffer);
  }
  
  return outputPixelBuffer;
}

-(void)decodeH264WithoutHeader:(NSData*)nalu
{
  size_t size = nalu.length+4;
  Byte* buffer = malloc(size);
  [nalu getBytes:buffer+4 length:nalu.length];
  dispatch_async(_decodeQueue,^{
    uint32_t nalSize = (uint32_t)(nalu.length);
    uint32_t big_nalSize = CFSwapInt32HostToBig(nalSize);
    uint8_t *pNalSize = (uint8_t*)(&big_nalSize);
    buffer[0] = *(pNalSize);
    buffer[1] = *(pNalSize + 1);
    buffer[2] = *(pNalSize + 2);
    buffer[3] = *(pNalSize + 3);
    
    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = buffer[4] & 0x1F;
    switch (nalType) {
      case 0x05:
        NSLog(@"Nal type is IDR frame");
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
      case 0x07:
        NSLog(@"Nal type is SPS");
        if(_sps != NULL){
          free(_sps);
        }
        _spsSize = size - 4;
        _sps = malloc(_spsSize);
        memcpy(_sps, buffer + 4, _spsSize);
        isReceiveSPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
        }
        break;
      case 0x08:
        NSLog(@"Nal type is PPS");
        if(_pps != NULL){
          free(_pps);
        }
        _ppsSize = size - 4;
        _pps = malloc(_ppsSize);
        memcpy(_pps, buffer + 4, _ppsSize);
        isReceivePPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
        }
        break;
        
      default:
        NSLog(@"Nal type is B/P frame");
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
    }
    
    if(pixelBuffer) {
      if(havePostProcess){
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        Byte* pixel = CVPixelBufferGetBaseAddress(pixelBuffer);
        int length = bufferWidth*bufferHeight*4;
        NSData* BRGABuffer = [[NSData alloc] initWithBytes:pixel length:length];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        dispatch_sync(dispatch_get_main_queue(), ^{
          [self postProcess:BRGABuffer width:bufferWidth height:bufferHeight];
        });
      }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
          _glLayer.pixelBuffer = pixelBuffer;
        });
      }
      CVPixelBufferRelease(pixelBuffer);
    }
    
    free(buffer);
  });
  
}

-(void)decodeH264:(NSData*)nalu
{
  size_t size = [nalu length];
  Byte* buffer = malloc(size);
  [nalu getBytes:buffer length:size];
  dispatch_async(_decodeQueue,^{
    uint32_t nalSize = (uint32_t)(size - 4);
    uint32_t big_nalSize = CFSwapInt32HostToBig(nalSize);
    uint8_t *pNalSize = (uint8_t*)(&big_nalSize);
    buffer[0] = *(pNalSize);
    buffer[1] = *(pNalSize + 1);
    buffer[2] = *(pNalSize + 2);
    buffer[3] = *(pNalSize + 3);
    
    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = buffer[4] & 0x1F;
    switch (nalType) {
      case 0x05:
        NSLog(@"Nal type is IDR frame");
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
      case 0x07:
        NSLog(@"Nal type is SPS");
        if(_sps != NULL){
          free(_sps);
        }
        _spsSize = size - 4;
        _sps = malloc(_spsSize);
        memcpy(_sps, buffer + 4, _spsSize);
        isReceiveSPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
        }
        break;
      case 0x08:
        NSLog(@"Nal type is PPS");
        if(_pps != NULL){
          free(_pps);
        }
        _ppsSize = size - 4;
        _pps = malloc(_ppsSize);
        memcpy(_pps, buffer + 4, _ppsSize);
        isReceivePPS = true;
        if(isReceiveSPS && isReceivePPS){
          [self stopH264Decoder];
          [self startH264Decoder];
        }
        break;
        
      default:
        NSLog(@"Nal type is B/P frame");
        if(_decoderSession){
          pixelBuffer = [self decodeframe:buffer size:size];
        }
        break;
    }
    
    if(pixelBuffer) {
      if(havePostProcess){
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        Byte* pixel = CVPixelBufferGetBaseAddress(pixelBuffer);
        int length = bufferWidth*bufferHeight*4;
        NSData* BRGABuffer = [[NSData alloc] initWithBytesNoCopy:pixel length:length];
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        dispatch_sync(dispatch_get_main_queue(), ^{
          [self postProcess:BRGABuffer width:bufferWidth height:bufferHeight];
        });
      }else{
        dispatch_sync(dispatch_get_main_queue(), ^{
          _glLayer.pixelBuffer = pixelBuffer;
        });
      }
      CVPixelBufferRelease(pixelBuffer);
    }
    
    free(buffer);
  });
}

@end
