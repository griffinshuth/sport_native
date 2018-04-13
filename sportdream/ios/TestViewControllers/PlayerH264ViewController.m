//
//  PlayerH264ViewController.m
//  sportdream
//
//  Created by lili on 2017/10/2.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "PlayerH264ViewController.h"
#import <VideoToolbox/VideoToolbox.h>
#import "AAPLEAGLLayer.h"
#import "VideoFileParser.h"

#define PLS_SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)
#define PLS_SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define TitleView_HEIGHT 64

@interface PlayerH264ViewController ()
{
  uint8_t* _sps;
  NSInteger _spsSize;
  uint8_t* _pps;
  NSInteger _ppsSize;
  VTDecompressionSessionRef _decoderSession;
  CMVideoFormatDescriptionRef _decoderFormatDescription;
  AAPLEAGLLayer* _glLayer;
}
@property (strong, nonatomic) UIView* titleView;
@property (strong,nonatomic) UIView* playView;
@end

static void didDecompress( void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration ){
  
  CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
  *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

@implementation PlayerH264ViewController

-(bool)initH264Decoder{
  if(_decoderSession){
    return YES;
  }
  const uint8_t* const parameterSetPointers[2] = {_sps,_pps};
  const size_t parameterSetSizes[2] = {_spsSize,_ppsSize};
  OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, 4, &_decoderFormatDescription);
  if(status == noErr){
    CFDictionaryRef attrs = NULL;
    const void *keys[] = { kCVPixelBufferPixelFormatTypeKey };
    //      kCVPixelFormatType_420YpCbCr8Planar is YUV420
    //      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange is NV12
    uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
    attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = didDecompress;
    callBackRecord.decompressionOutputRefCon = NULL;
    status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decoderFormatDescription, NULL, attrs, &callBackRecord, &_decoderSession);
    CFRelease(attrs);
  }else{
    NSLog(@"IOS8VT: reset decoder session failed status=%d", status);
  }
  return YES;
}

-(void)clearH264Decoder{
  if(_decoderSession){
    VTDecompressionSessionInvalidate(_decoderSession);
    CFRelease(_decoderSession);
    _decoderSession = NULL;
  }
  if(_decoderFormatDescription){
    CFRelease(_decoderFormatDescription);
    _decoderFormatDescription = NULL;
  }
  free(_sps);
  free(_pps);
  _spsSize = _ppsSize = 0;
}

-(CVPixelBufferRef)decode:(VideoPacket*)vp{
  CVPixelBufferRef outputPixelBuffer = NULL;
  CMBlockBufferRef blockBuffer = NULL;
  OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, (void*)vp.buffer, vp.size, kCFAllocatorNull, NULL, 0, vp.size, 0, &blockBuffer);
  if(status == kCMBlockBufferNoErr){
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {vp.size};
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

-(void)decodeFile:(NSString*)fileName {
  NSString *path = fileName;
  VideoFileParser *parser = [VideoFileParser alloc];
  [parser open:path];
  
  VideoPacket *vp = nil;
  while(true) {
    vp = [parser nextPacket];
    if(vp == nil) {
      break;
    }
    
    uint32_t nalSize = (uint32_t)(vp.size - 4);
    uint32_t big_nalSize = CFSwapInt32HostToBig(nalSize);
    uint8_t *pNalSize = (uint8_t*)(&big_nalSize);
    vp.buffer[0] = *(pNalSize);
    vp.buffer[1] = *(pNalSize + 1);
    vp.buffer[2] = *(pNalSize + 2);
    vp.buffer[3] = *(pNalSize + 3);
    
    CVPixelBufferRef pixelBuffer = NULL;
    int nalType = vp.buffer[4] & 0x1F;
    switch (nalType) {
      case 0x05:
        NSLog(@"Nal type is IDR frame");
        if([self initH264Decoder]) {
          pixelBuffer = [self decode:vp];
        }
        break;
      case 0x07:
        NSLog(@"Nal type is SPS");
        _spsSize = vp.size - 4;
        _sps = malloc(_spsSize);
        memcpy(_sps, vp.buffer + 4, _spsSize);
        break;
      case 0x08:
        NSLog(@"Nal type is PPS");
        _ppsSize = vp.size - 4;
        _pps = malloc(_ppsSize);
        memcpy(_pps, vp.buffer + 4, _ppsSize);
        break;
        
      default:
        NSLog(@"Nal type is B/P frame");
        pixelBuffer = [self decode:vp];
        break;
    }
    
    if(pixelBuffer) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        _glLayer.pixelBuffer = pixelBuffer;
      });
      
      CVPixelBufferRelease(pixelBuffer);
    }
    
    NSLog(@"Read Nalu size %ld", vp.size);
  }
  [parser close];
}

-(void)playButtonEvent:(id)sender
{
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    [self decodeFile:self.h264Path];
  });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  self.playView = [[UIView alloc] initWithFrame:CGRectMake(0, TitleView_HEIGHT, 128, 72)];
  [self.view addSubview:self.playView];
  _glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(0, 0, 128, 72)];
  [self.playView.layer addSublayer:_glLayer];
  UIButton* recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [recordButton setTitle:@"播放" forState:UIControlStateNormal];
  recordButton.frame = CGRectMake(0, 0, 100, 44);
  recordButton.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 80);
  [recordButton addTarget:self action:@selector(playButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:recordButton];
  
  self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PLS_SCREEN_WIDTH, TitleView_HEIGHT)];
  self.titleView.backgroundColor = [UIColor blueColor];
  [self.view addSubview:self.titleView];
  //关闭按钮
  UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  backButton.frame = CGRectMake(10, 25, 35, 35);
  [backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_a"] forState:UIControlStateNormal];
  [backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_b"] forState:UIControlStateHighlighted];
  [backButton addTarget:self action:@selector(backButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addSubview:backButton];
}

-(void)backButtonEvent:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
