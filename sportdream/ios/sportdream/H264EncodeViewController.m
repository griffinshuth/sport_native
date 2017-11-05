//
//  H264EncodeViewController.m
//  sportdream
//
//  Created by lili on 2017/10/1.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "H264EncodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "PlayerH264ViewController.h"
#import "GPUImage.h"
#import "rtmp.h"
#import "rtmp_sys.h"
#import "amf.h"

#define PLS_SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)
#define PLS_SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define TitleView_HEIGHT 64
#define RTMP_HEAD_SIZE   (sizeof(PILI_RTMPPacket)+RTMP_MAX_HEADER_SIZE)

@interface H264EncodeViewController () <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
  //H264编码相关
  VTCompressionSessionRef _encodeSession;
  dispatch_queue_t _encodeQueue;
  dispatch_queue_t _sendRtmpQueue;
  long _frameCount;
  FILE *_h264File;
  FILE *_AACFile;
  int _spsppsFound;
  //end
  bool _isStartRecord;
  int _processCount;
  //慢动作相关
  bool _isSlowMotion;
  CMTime _defaultVideoMaxFrameDuration;
  //end
  //aac编码相关
  AudioConverterRef _audioConverter;
  uint32_t _audioMaxOutputFrameSize;
  uint32_t _channelCount;
  uint32_t _sampleRate;
  uint32_t _sampleSize;
  uint32_t _bitrate;
  //rtmp推送相关
  PILI_RTMP* m_pRtmp;
  int nH264TimeStamp; //h264帧时间戳
  int nH264FrameDuration; //每帧的持续时间，和编码的帧率有关
  int nH264FrameRate; //H264编码帧率
  bool _isReadyPushRtmp; //是否准备推流
  bool _isAudioHeaderSend; //AAC音频同步包是否已经发送
}
@property (nonatomic,strong) NSString *documentDictionary;
@property (nonatomic,strong) NSString *h264FileName;
@property (nonatomic,strong) NSString *aacFileName;
@property (nonatomic,strong) AVCaptureSession* videoCaptureSession;
@property (strong, nonatomic) UIView* titleView;
@property (strong, nonatomic) UIView* toolView;
@property (strong,nonatomic) UIButton* recordButton;
@property (strong,nonatomic) UIButton* slowMotionButton;
@property (strong,nonatomic) UILabel* processLabel;

//前后摄像头
@property (nonatomic,strong) AVCaptureDeviceInput* frontCamera;
@property (nonatomic,strong) AVCaptureDeviceInput* backCamera;
//当前使用的视频设备
@property (nonatomic,strong) AVCaptureDeviceInput* videoInputDevice;
//音频设备
@property (nonatomic,strong) AVCaptureDeviceInput* audioInputDevice;
//输出数据接收
@property (nonatomic,strong) AVCaptureVideoDataOutput* videoDataOutput;
@property (nonatomic,strong) AVCaptureAudioDataOutput* audioDataOutput;
//默认后置摄像头默认格式
@property (nonatomic,strong) AVCaptureDeviceFormat* defaultBackCameraFormat;

//aac硬编码相关
@property (nonatomic,strong) NSData* curFramePcmData;

@property (atomic) uint32_t sendtimestamp;


@end

@implementation H264EncodeViewController

//切换前后摄像头
-(void)setVideoInputDevice:(AVCaptureDeviceInput *)videoInputDevice
{
  if([videoInputDevice isEqual:_videoInputDevice]){
    return;
  }
  [self.videoCaptureSession beginConfiguration];
  if(_videoInputDevice){
    [self.videoCaptureSession removeInput:_videoInputDevice];
  }
  if(videoInputDevice){
    [self.videoCaptureSession addInput:videoInputDevice];
  }
  [self setVideoOutConfig];
  [self.videoCaptureSession commitConfiguration];
  _videoInputDevice = videoInputDevice;
}


//初始化音视频输入设备
-(void) createCaptureDevice
{
  NSArray* videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
  self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];

  AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
  self.videoInputDevice = self.backCamera;
}

//初始化音视频输出设备
-(void)createOutput
{
  dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
  [self.videoDataOutput setSampleBufferDelegate:self queue:captureQueue];
  [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
  [self.videoDataOutput setVideoSettings:@{
                                           (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                           }];
  self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
  [self.audioDataOutput setSampleBufferDelegate:self queue:captureQueue];
  
}

//获得最大帧率
- (void)configureCameraForHighestFrameRate:(AVCaptureDevice *)device
{
  AVCaptureDeviceFormat *bestFormat = nil;
  AVFrameRateRange *bestFrameRateRange = nil;
  for ( AVCaptureDeviceFormat *format in [device formats] ) {
    for ( AVFrameRateRange *range in format.videoSupportedFrameRateRanges ) {
      if ( range.maxFrameRate > bestFrameRateRange.maxFrameRate ) {
        bestFormat = format;
        bestFrameRateRange = range;
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

//配置音视频捕获会话
-(void)createCaptureSession
{
  self.videoCaptureSession = [[AVCaptureSession alloc] init];
  [self.videoCaptureSession beginConfiguration];
  if([self.videoCaptureSession canAddInput:self.videoInputDevice])
  {
    [self.videoCaptureSession addInput:self.videoInputDevice];
  }
  if([self.videoCaptureSession canAddInput:self.audioInputDevice])
  {
    [self.videoCaptureSession addInput:self.audioInputDevice];
  }
  if([self.videoCaptureSession canAddOutput:self.videoDataOutput])
  {
    [self.videoCaptureSession addOutput:self.videoDataOutput];
  }
  if([self.videoCaptureSession canAddOutput:self.audioDataOutput])
  {
    [self.videoCaptureSession addOutput:self.audioDataOutput];
  }
  /*if (![self.videoCaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
    @throw [NSException exceptionWithName:@"Not supported captureSessionPreset" reason:[NSString stringWithFormat:@"captureSessionPreset is [%@]", AVCaptureSessionPreset1280x720] userInfo:nil];
  }else{
    [self.videoCaptureSession setSessionPreset:AVCaptureSessionPreset1280x720];
  }*/
  self.videoCaptureSession.sessionPreset = AVCaptureSessionPresetInputPriority;
  [self setVideoOutConfig];
  [self.videoCaptureSession commitConfiguration];
}

//销毁会话
-(void) destroyCaptureSession{
  if (self.videoCaptureSession) {
    [self.videoCaptureSession removeInput:self.audioInputDevice];
    [self.videoCaptureSession removeInput:self.videoInputDevice];
    [self.videoCaptureSession removeOutput:self.self.videoDataOutput];
    [self.videoCaptureSession removeOutput:self.self.audioDataOutput];
  }
  self.videoCaptureSession = nil;
}

//设置视频配置信息，横竖屏设置
-(void) setVideoOutConfig{
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

- (void)viewDidLoad {
    [super viewDidLoad];
  _isStartRecord = false;
  //获得时间戳
  double timestamp = [[NSDate date] timeIntervalSince1970];
  self.h264FileName =[NSString stringWithFormat:@"%f%@",timestamp,@"vt_encode.h264"];
  self.aacFileName = [NSString stringWithFormat:@"%f%@",timestamp,@"vt_encode.aac"];
  
  _isSlowMotion = false;
  _channelCount = 1; //音频通道数量 1为单声道，2为立体声。除非使用外部硬件进行录制，否则通常使用单声道录制。
  _sampleRate = 44100; //音频采样率
  _sampleSize = 16; //音频采样位数
  _bitrate = 100000; //音频码率
  m_pRtmp = NULL;
  nH264TimeStamp = 0; //h264帧时间戳
  nH264FrameRate = 25; //H264编码帧率
  nH264FrameDuration = 1000/nH264FrameRate; //每帧的持续时间，和编码的帧率有关
  _isReadyPushRtmp = true; //是否允许进行rtmp推送
  _isAudioHeaderSend = false;
  self.sendtimestamp = 0;
  /////////////////////////////////
  NSArray* videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
  AVCaptureDevice* backCamera = videoDevices.firstObject;
  self.defaultBackCameraFormat = backCamera.activeFormat;
  _defaultVideoMaxFrameDuration = backCamera.activeVideoMaxFrameDuration;
  //[self initVideoCapture];
  [self createCaptureDevice];
  [self createOutput];
  [self createCaptureSession];
  //设置摄像头预览界面
  CGRect frame = self.view.frame;
  AVCaptureVideoPreviewLayer* previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoCaptureSession];
  [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  [previewLayer setFrame:frame];
  [self.view.layer addSublayer:previewLayer];
  
  //标题栏
  self.titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PLS_SCREEN_WIDTH, TitleView_HEIGHT)];
  self.titleView.backgroundColor = [UIColor blueColor];
  [self.view addSubview:self.titleView];
  
  //工具栏
  self.toolView = [[UIView alloc] initWithFrame:CGRectMake(0, 500, PLS_SCREEN_WIDTH, TitleView_HEIGHT)];
  self.toolView.backgroundColor = [UIColor blueColor];
   [self.view addSubview:self.toolView];
  
  //关闭按钮
  UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  backButton.frame = CGRectMake(10, 25, 35, 35);
  [backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_a"] forState:UIControlStateNormal];
  [backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_b"] forState:UIControlStateHighlighted];
  [backButton addTarget:self action:@selector(backButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addSubview:backButton];
  
  //进度
  _processCount = 0;
  self.processLabel = [[UILabel alloc] init];
  self.processLabel.frame = CGRectMake(60, 25, 80, 35);
  self.processLabel.text = [NSString stringWithFormat:@"帧数：%d",_processCount];
  [self.titleView addSubview:self.processLabel];
  
  UIButton* playback = [UIButton buttonWithType:UIButtonTypeSystem];
  [playback setTitle:@"回放" forState:UIControlStateNormal];
  playback.frame = CGRectMake(160, 25, 35, 35);
  [playback addTarget:self action:@selector(playbackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addSubview:playback];
  
  UIButton* switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [switchButton setTitle:@"切换" forState:UIControlStateNormal];
  switchButton.frame = CGRectMake(210, 25, 35, 35);
  [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addSubview:switchButton];
  
  self.slowMotionButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.slowMotionButton setTitle:@"慢动作" forState:UIControlStateNormal];
  self.slowMotionButton.frame = CGRectMake(10, 25, 60, 35);
  [self.slowMotionButton addTarget:self action:@selector(slowMotionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self.toolView addSubview:self.slowMotionButton];
  
  
  self.recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.recordButton setTitle:@"开始" forState:UIControlStateNormal];
  self.recordButton.frame = CGRectMake(0, 0, 100, 44);
  self.recordButton.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 80);
  [self.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.recordButton];
    // Do any additional setup after loading the view.
  _encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  _sendRtmpQueue = dispatch_queue_create("sendrtmpqueue", DISPATCH_QUEUE_SERIAL);
  self.documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  
}

-(void)viewWillAppear:(BOOL)animated
{
  [self.videoCaptureSession startRunning];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [self.videoCaptureSession stopRunning];
  if(_isStartRecord){
    [self.recordButton setTitle:@"开始" forState:UIControlStateNormal];
    _isStartRecord = false;
    [self stopH264EncodeSession];
  }
}

//设置慢动作模式
-(void)slowMotionButtonPressed:(id)sender
{
  //判断是否是后置摄像头
  if([self.videoInputDevice isEqual:self.backCamera]){
    if(!_isSlowMotion){
      [self.videoCaptureSession stopRunning];
      NSArray* videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
      AVCaptureDevice* backCamera = videoDevices.firstObject;
      //AVCaptureDevice *backCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
      [self configureCameraForHighestFrameRate:backCamera];
      NSLog(@"videoDevice.activeFormat:%@", backCamera.activeFormat);
      [self.slowMotionButton setTitle:@"默认动作" forState:UIControlStateNormal];
      _isSlowMotion = true;
      [self.videoCaptureSession startRunning];
      float maxRate = [[backCamera.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
      NSString* title = @"最大帧率";
      NSString* message = [NSString stringWithFormat:@"%f",maxRate];
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
      [alert show];
    }else{
      [self.videoCaptureSession stopRunning];
      NSArray* videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
      AVCaptureDevice* backCamera = videoDevices.firstObject;
      [backCamera lockForConfiguration:nil];
      backCamera.activeFormat = self.defaultBackCameraFormat;
      backCamera.activeVideoMaxFrameDuration = _defaultVideoMaxFrameDuration;
      [backCamera unlockForConfiguration];
      NSLog(@"videoDevice.activeFormat:%@", backCamera.activeFormat);
      [self.slowMotionButton setTitle:@"慢动作" forState:UIControlStateNormal];
      _isSlowMotion = false;
      [self.videoCaptureSession startRunning];
      float maxRate = [[backCamera.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
      NSString* title = @"最大帧率";
      NSString* message = [NSString stringWithFormat:@"%f",maxRate];
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
      [alert show];
    }
  }else{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"错误"
                                                    message:@"只有后置摄像头支持慢动作"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
  }
}

//切换摄像头
-(void)switchCamera:(id)sender
{
  if([self.videoInputDevice isEqual:self.frontCamera]){
    self.videoInputDevice = self.backCamera;
  }else{
    self.videoInputDevice = self.frontCamera;
  }
}

//回放
-(void)playbackButtonPressed:(id)sender
{
  if(_processCount > 10){
    PlayerH264ViewController* playH264ViewController = [[PlayerH264ViewController alloc] init];
    playH264ViewController.h264Path = [NSString stringWithFormat:@"%@/%@",self.documentDictionary,self.h264FileName];
    [self presentViewController:playH264ViewController animated:true completion:nil];
  }
}

//退出界面
-(void)backButtonEvent:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

//开始和停止录制
-(void)recordButtonPressed:(id)sender
{
  if(!_isStartRecord){
    [self.recordButton setTitle:@"结束" forState:UIControlStateNormal];
    //视频编码
    [self startH264EncodeSession:1280 height:(int)720 framerate:nH264FrameRate bitrate:1600*1000];
    //音频编码
    [self startAACEncodeSession];
    if(_isReadyPushRtmp){
      //开始推流
      [self startRtmp:@"rtmp://pili-publish.2310live.com/grasslive/test1"];
    }
    _isStartRecord = true;
  }else{
    if(_isStartRecord){
      [self.recordButton setTitle:@"开始" forState:UIControlStateNormal];
      _isStartRecord = false;
      [self stopH264EncodeSession];
      [self stopAACEncodeSession];
      if(_isReadyPushRtmp){
        [self stopRtmp];
      }
    }
  }
}

//音视频采样数据回调接口
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection
{
  if(_isStartRecord){
    if([self.videoDataOutput isEqual:captureOutput]){
      [self encodeH264Frame:sampleBuffer];
    }else if([self.audioDataOutput isEqual:captureOutput]){
      [self encodePCMData:sampleBuffer];
    }
  }
}

//开始rtmp推送
-(bool)startRtmp:(NSString*) pushUrl
{
  m_pRtmp = PILI_RTMP_Alloc();
  PILI_RTMP_Init(m_pRtmp);
  if(!PILI_RTMP_SetupURL(m_pRtmp, [pushUrl UTF8String],NULL)){
    PILI_RTMP_Free(m_pRtmp);
    return false;
  }
  PILI_RTMP_EnableWrite(m_pRtmp);
  if(!PILI_RTMP_Connect(m_pRtmp, NULL, NULL)){
    PILI_RTMP_Free(m_pRtmp);
    return false;
  }
  if(!PILI_RTMP_ConnectStream(m_pRtmp, 0, NULL)){
    PILI_RTMP_Close(m_pRtmp, NULL);
    PILI_RTMP_Free(m_pRtmp);
    return false;
  }
  NSLog(@"rtmp connect success");
  return true;
}

//结束rtmp推送
-(void)stopRtmp
{
  if(m_pRtmp){
    PILI_RTMP_Close(m_pRtmp, NULL);
    PILI_RTMP_Free(m_pRtmp);
    m_pRtmp = NULL;
  }
}

//开始h264格式编码
-(int)startH264EncodeSession:(int)width height:(int)height framerate:(int)fps bitrate:(int)bt
{
  OSStatus status;
  _frameCount = 0;
  VTCompressionOutputCallback cb = encodeOutputCallback;
  status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, cb, (__bridge void *)(self), &_encodeSession);
  if(status != noErr){
    NSLog(@"VTCompressionSessionCreate failed. ret=%d", (int)status);
    return -1;
  }
  // 设置实时编码输出，降低编码延迟
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
  NSLog(@"set realtime  return: %d", (int)status);
  // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
  NSLog(@"set profile   return: %d", (int)status);
   // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bt));
  status += VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bt*2/8), @1]);
  NSLog(@"set bitrate   return: %d", (int)status);
  // 设置关键帧间隔，即gop size
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(fps*2));
  // 设置帧率，只用于初始化session，不是实际FPS
  status = VTSessionSetProperty(_encodeSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
  NSLog(@"set framerate return: %d", (int)status);
  
  // 开始编码
  status = VTCompressionSessionPrepareToEncodeFrames(_encodeSession);
  _h264File = fopen([[NSString stringWithFormat:@"%@/%@",self.documentDictionary,self.h264FileName] UTF8String], "ab+");
  NSLog(@"start encode  return: %d", (int)status);
  
  return 0;
}

//停止h264编码
-(void)stopH264EncodeSession
{
  VTCompressionSessionCompleteFrames(_encodeSession, kCMTimeInvalid);
  VTCompressionSessionInvalidate(_encodeSession);
  CFRelease(_encodeSession);
  _encodeSession = NULL;
  fclose(_h264File);
}

-(void)startAACEncodeSession
{
  AudioStreamBasicDescription inputAudioDes = {
    .mFormatID = kAudioFormatLinearPCM,
    .mSampleRate = _sampleRate,
    .mBitsPerChannel = _sampleSize,
    .mFramesPerPacket = 1,
    .mBytesPerFrame = 2,
    .mBytesPerPacket = 2,
    .mChannelsPerFrame = _channelCount,
    .mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsNonInterleaved,
    .mReserved = 0
  };
  AudioStreamBasicDescription outputAudioDes = {
    .mChannelsPerFrame = _channelCount,
    .mFormatID = kAudioFormatMPEG4AAC,
    0
  };
  uint32_t outDesSize = sizeof(outputAudioDes);
  AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &outDesSize, &outputAudioDes);
  OSStatus status = AudioConverterNew(&inputAudioDes, &outputAudioDes, &_audioConverter);
  if (status != noErr) {
    NSLog(@"硬编码AAC创建失败");
  }
  
  //设置码率
  uint32_t aBitrate = _bitrate;
  uint32_t aBitrateSize = sizeof(aBitrate);
  status = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, aBitrateSize, &aBitrate);
  
  //查询最大输出
  uint32_t aMaxOutput = 0;
  uint32_t aMaxOutputSize = sizeof(aMaxOutput);
  AudioConverterGetProperty(_audioConverter, kAudioConverterPropertyMaximumOutputPacketSize, &aMaxOutputSize, &aMaxOutput);
  _audioMaxOutputFrameSize = aMaxOutput;
  if (aMaxOutput == 0) {
    NSLog(@"AAC 获取最大frame size失败");
  }
  _AACFile = fopen([[NSString stringWithFormat:@"%@/%@",self.documentDictionary,self.aacFileName] UTF8String], "ab+");
}

-(void)stopAACEncodeSession
{
  AudioConverterDispose(_audioConverter);
  _audioConverter = NULL;
  self.curFramePcmData = nil;
  _audioMaxOutputFrameSize = 0;
  fclose(_AACFile);
}

//音频aac格式编码
-(void)encodePCMData:(CMSampleBufferRef)sampleBuffer
{
  dispatch_sync(_encodeQueue,^{
    //获得pcm数据大小
    NSInteger audioDataSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    //分配空间
    int8_t* audio_data = malloc(audioDataSize);
    memset(audio_data, 0, audioDataSize);
    //获得CMBlockBufferRef
    //这个结构里面就保存了 PCM数据
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //直接将数据copy至我们自己分配的内存中
    CMBlockBufferCopyDataBytes(dataBuffer, 0, audioDataSize, audio_data);
    //生成NSData对象
    NSData* pcmData = [NSData dataWithBytesNoCopy:audio_data length:audioDataSize];
    
    self.curFramePcmData = pcmData;
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = _channelCount;
    outAudioBufferList.mBuffers[0].mDataByteSize = _audioMaxOutputFrameSize;
    outAudioBufferList.mBuffers[0].mData = malloc(_audioMaxOutputFrameSize);
    uint32_t outputDataPacketSize = 1;
    
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInputDataProc, (__bridge void * _Nullable)(self), &outputDataPacketSize, &outAudioBufferList, NULL);
    if(status == noErr){
      NSData *rawAAC = [NSData dataWithBytesNoCopy: outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
      if(_isReadyPushRtmp){
        //开始rtmp推送
        if(!_isAudioHeaderSend){
          //发送音频同步包
          nH264TimeStamp++;
          NSLog(@"audioheadertimestamp:%d",nH264TimeStamp);
          [self sendAACHeader:nH264TimeStamp];
          _isAudioHeaderSend = true;
        }
        nH264TimeStamp += 1024 * 1000 / _sampleRate;
        NSLog(@"audiotimestamp:%d",nH264TimeStamp);
        [self sendAACPacket:(void*)rawAAC.bytes size:(int)rawAAC.length nTimeStamp:nH264TimeStamp];
      }
      //产生adts头信息
      uint32_t packetlen = (uint32_t)(rawAAC.length+7);
      uint8_t* header = [self addADTStoPacket:packetlen];
      [self writeAACData:(int8_t*)rawAAC.bytes length:rawAAC.length adtsHeader:header];
      free(header);
    }else{
      NSLog(@"aac 编码错误");
    }
  });
}

-(uint8_t*)addADTStoPacket:(uint32_t)packetlen
{
  uint8_t* header = malloc(7);
  uint8_t profile = kMPEG4Object_AAC_LC;
  uint8_t sampleRate = 4;
  uint8_t chanCfg = _channelCount;
  header[0] = 0xFF;
  header[1] = 0xF9;
  header[2] = (uint8_t)(((profile-1)<<6) + (sampleRate<<2) +(chanCfg>>2));
  header[3] = (uint8_t)(((chanCfg&3)<<6) + (packetlen>>11));
  header[4] = (uint8_t)((packetlen&0x7FF) >> 3);
  header[5] = (uint8_t)(((packetlen&7)<<5) + 0x1F);
  header[6] = (uint8_t)0xFC;
  
  return header;
}

//h264编码
-(void)encodeH264Frame:(CMSampleBufferRef)sampleBuffer
{
  dispatch_sync(_encodeQueue, ^{
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CMTime pts = CMTimeMake(_frameCount, 1000);
    CMTime duration = kCMTimeInvalid;
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSession, imageBuffer, pts, duration, NULL, NULL, &flags);
    if(statusCode != noErr){
      NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
      [self stopH264EncodeSession];
      [self.recordButton setTitle:@"开始" forState:UIControlStateNormal];
      _isStartRecord = false;
      return;
    }else{
      dispatch_async(dispatch_get_main_queue(), ^{
        _processCount++;
        self.processLabel.text = [NSString stringWithFormat:@"帧数：%d",_processCount];
      });
    }
  });
}

//提供AAC编码需要的PCM数据回调
static OSStatus aacEncodeInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData){
  H264EncodeViewController *vc = (__bridge H264EncodeViewController *)inUserData;
  if (vc.curFramePcmData) {
    ioData->mBuffers[0].mData = (void *)vc.curFramePcmData.bytes;
    ioData->mBuffers[0].mDataByteSize = (uint32_t)vc.curFramePcmData.length;
    ioData->mNumberBuffers = 1;
    ioData->mBuffers[0].mNumberChannels = vc->_channelCount;
    
    return noErr;
  }
  
  return -1;
}

// h264编码回调，每当系统编码完一帧之后，会异步掉用该方法，此为c语言方法
void encodeOutputCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                          CMSampleBufferRef sampleBuffer )
{
  if (status != noErr) {
    NSLog(@"didCompressH264 error: with status %d, infoFlags %d", (int)status, (int)infoFlags);
    return;
  }
  if (!CMSampleBufferDataIsReady(sampleBuffer))
  {
    NSLog(@"didCompressH264 data is not ready ");
    return;
  }
  H264EncodeViewController* vc = (__bridge H264EncodeViewController*)userData;
  
  dispatch_sync(vc->_encodeQueue, ^{
    CFArrayRef cfArr = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFDictionaryRef cfDict = (CFDictionaryRef)CFArrayGetValueAtIndex(cfArr, 0);
    bool keyframe = !CFDictionaryContainsKey(cfDict, kCMSampleAttachmentKey_NotSync);
    if(keyframe && !vc->_spsppsFound){
      size_t spsSize,spsCount;
      size_t ppsSize,ppsCount;
      const uint8_t *spsData,*ppsData;
      CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
      OSStatus err0 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &spsSize, &spsCount, 0);
      OSStatus err1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &ppsSize, &ppsCount, 0);
      if(err0 == noErr && err1 == noErr){
        vc->_spsppsFound = 1;
        [vc writeH264Data:(void*)spsData length:spsSize addStartCode:YES];
        [vc writeH264Data:(void*)ppsData length:ppsSize addStartCode:YES];
        //rtmp推流
        if(vc->_isReadyPushRtmp){
          vc->nH264TimeStamp++;
          NSLog(@"spspstimestamp:%d",vc->nH264TimeStamp);
          [vc sendVideoSpsPps:(uint8_t*)ppsData ppsLen:(int)ppsSize sps:(uint8_t*)spsData spsLen:(int)spsSize nTimeStamp:vc->nH264TimeStamp];
        }
        //NSLog(@"got sps/pps data. Length: sps=%zu, pps=%zu", spsSize, ppsSize);
      }
    }
    
    size_t lengthAtOffset,totalLength;
    char* data;
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus error = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &data);
    if(error == noErr){
      size_t offset = 0;
      const int lengthInfoSize = 4;// 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
      while(offset<totalLength){
        uint32_t naluLength = 0;
        memcpy(&naluLength, data+offset, lengthInfoSize);
        naluLength = CFSwapInt32BigToHost(naluLength);
        //开始推流
        if(vc->_isReadyPushRtmp){
          vc->nH264TimeStamp += vc->nH264FrameDuration;
          NSLog(@"videotimestamp:%d",vc->nH264TimeStamp);
          [vc sendH264Packet:data+offset+lengthInfoSize size:naluLength isKeyFrame:keyframe nTimeStamp:vc->nH264TimeStamp];
          
        }
        //结束推流
        //NSLog(@"got nalu data, length=%d, totalLength=%zu", naluLength, totalLength);
        [vc writeH264Data:data+offset+lengthInfoSize length:naluLength addStartCode:YES];
        offset += lengthInfoSize+naluLength;
      }
    }
  });
}

//推送H264 sps pps 信息
-(int)sendVideoSpsPps:(uint8_t*)pps ppsLen:(int)ppsLen sps:(uint8_t*)sps spsLen:(int)spsLen nTimeStamp:(uint32_t)nTimeStamp
{
  PILI_RTMPPacket* packet = NULL;
  uint8_t* body = NULL;
  int i;
  packet = (PILI_RTMPPacket*)malloc(RTMP_HEAD_SIZE+1024);
  memset(packet,0,RTMP_HEAD_SIZE+1024);
  packet->m_body = (char*)packet + RTMP_HEAD_SIZE;
  body = (unsigned char*)packet->m_body;
  i=0;
  body[i++] = 0x17;
  body[i++] = 0x00;
  
  body[i++] = 0x00;
  body[i++] = 0x00;
  body[i++] = 0x00;
  
  body[i++] = 0x01;
  body[i++] = sps[1];
  body[i++] = sps[2];
  body[i++] = sps[3];
  body[i++] = 0xff;
  
  body[i++]   = 0xe1;
  body[i++] = (spsLen >> 8) & 0xff;
  body[i++] = spsLen & 0xff;
  memcpy(&body[i],sps,spsLen);
  i +=  spsLen;
  
  /*pps*/
  body[i++]   = 0x01;
  body[i++] = (ppsLen >> 8) & 0xff;
  body[i++] = (ppsLen) & 0xff;
  memcpy(&body[i],pps,ppsLen);
  i +=  ppsLen;
  
  packet->m_packetType = RTMP_PACKET_TYPE_VIDEO;
  packet->m_nBodySize = i;
  packet->m_nChannel = 0x04;
  packet->m_nTimeStamp = nTimeStamp;
  packet->m_hasAbsTimestamp = 0;
  packet->m_headerType = RTMP_PACKET_SIZE_MEDIUM;
  packet->m_nInfoField2 = m_pRtmp->m_stream_id;
  int nRet = PILI_RTMP_SendPacket(m_pRtmp, packet, true, NULL);
  free(packet);
  return nRet;
}

-(void)sendAACHeader:(uint32_t)nTimeStamp
{
  //AAC头部固定4个字节
  /*
   音频同步包大小固定为 4 个字节。前两个字节被称为 [AACDecoderSpecificInfo]，
   用于描述这个音频包应当如何被解析。后两个字节称为 [AudioSpecificConfig]，更加详细的指定了音频格式。
   [AACDecoderSpecificInfo] 第 1 个字节高 4 位 |1010| 代表音频数据编码类型为 AAC，
   接下来 2 位 |11| 表示采样率为 44kHz，接下来 1 位 |1| 表示采样点位数16bit，最低 1 位 |1| 表示双声道。
   其第二个字节表示数据包类型，0 则为 AAC 音频同步包，1 则为普通 AAC 数据包。
   */
  PILI_RTMPPacket* packet = NULL;
  uint8_t* body = NULL;
  int i;
  packet = (PILI_RTMPPacket*)malloc(RTMP_HEAD_SIZE+4);
  memset(packet,0,RTMP_HEAD_SIZE+4);
  packet->m_body = (char*)packet + RTMP_HEAD_SIZE;
  body = (unsigned char*)packet->m_body;
  i=0;
  body[i++] = 0xAE;
  body[i++] = 0x00;
  
  uint16_t audio_specific_config = 0;
  audio_specific_config |= ((2<<11)&0xF800); //2:AAC-LC(Low Complexity)
  audio_specific_config |= ((4<<7)&0x0780); //4:44kHz
  audio_specific_config |= ((1<<3)&0x78); // 2:立体声,1:单通道
  audio_specific_config |= 0&0x07; //padding:000
  body[i++] = (audio_specific_config>>8)&0xFF;
  body[i++] = audio_specific_config&0xFF;
  
  packet->m_packetType = RTMP_PACKET_TYPE_AUDIO;
  packet->m_nBodySize = i;
  packet->m_nChannel = 0x04;
  packet->m_nTimeStamp = nTimeStamp;
  packet->m_hasAbsTimestamp = 0;
  packet->m_headerType = RTMP_PACKET_SIZE_MEDIUM;
  packet->m_nInfoField2 = m_pRtmp->m_stream_id;
  int nRet = PILI_RTMP_SendPacket(m_pRtmp, packet, true, NULL);
  free(packet);
}

//推送AAC数据
-(void)sendAACPacket:(void*)data size:(int)size nTimeStamp:(uint32_t)nTimeStamp
{
  uint8_t* body = (uint8_t*)malloc(size+2);
  memset(body, 0, size+2);
  int i=0;
  body[i++] = 0xAE;
  body[i++] = 0x01;
  memcpy(&body[i], data, size);
  int bRet = [self sendRtmpPacket:RTMP_PACKET_TYPE_AUDIO data:body size:i+size nTimeStamp:nTimeStamp];
  free(body);
}

//推送H264帧数据
-(int)sendH264Packet:(void*)data size:(int)size isKeyFrame:(bool)isKeyFrame nTimeStamp:(int)nTimeStamp
{
  uint8_t* body = (uint8_t*)malloc(size+9);
  memset(body, 0, size+9);
  
  int i=0;
  if(isKeyFrame){
    body[i++] = 0x17;// 1:Iframe  7:AVC
    body[i++] = 0x01;// AVC NALU
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = 0x00;
    
    
    // NALU size
    body[i++] = size>>24 &0xff;
    body[i++] = size>>16 &0xff;
    body[i++] = size>>8 &0xff;
    body[i++] = size&0xff;
    // NALU data
    memcpy(&body[i],data,size);
  }else{
    body[i++] = 0x27;// 2:Pframe  7:AVC
    body[i++] = 0x01;// AVC NALU
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = 0x00;
    
    
    // NALU size
    body[i++] = size>>24 &0xff;
    body[i++] = size>>16 &0xff;
    body[i++] = size>>8 &0xff;
    body[i++] = size&0xff;
    // NALU data
    memcpy(&body[i],data,size);
  }
  
  int bRet = [self sendRtmpPacket:RTMP_PACKET_TYPE_VIDEO data:body size:i+size nTimeStamp:nTimeStamp];
  free(body);
  return bRet;
}

//推送rtmp包
-(int)sendRtmpPacket:(int)packetType data:(uint8_t*)data size:(int)size nTimeStamp:(int)nTimeStamp
{
  dispatch_sync(_sendRtmpQueue, ^{
    PILI_RTMPPacket* packet;
    packet = (PILI_RTMPPacket*)malloc(RTMP_HEAD_SIZE+size);
    memset(packet, 0, RTMP_HEAD_SIZE);
    packet->m_body = (char*)packet + RTMP_HEAD_SIZE;
    packet->m_nBodySize = size;
    memcpy(packet->m_body, data, size);
    packet->m_hasAbsTimestamp = 0;
    packet->m_packetType = packetType; /*此处为类型有两种一种是音频,一种是视频*/
    packet->m_nInfoField2 = m_pRtmp->m_stream_id;
    packet->m_nChannel = 0x04;
    packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
    if (RTMP_PACKET_TYPE_AUDIO ==packetType && size !=4)
    {
      packet->m_headerType = RTMP_PACKET_SIZE_MEDIUM;
    }
    if(packetType == RTMP_PACKET_TYPE_AUDIO){
      self.sendtimestamp += 1024 * 1000 / _sampleRate;
    }else{
      self.sendtimestamp += 1;//nH264FrameDuration;
    }
    
    packet->m_nTimeStamp = self.sendtimestamp; //nTimeStamp;
    int nRet = 0;
    if(PILI_RTMP_IsConnected(m_pRtmp)){
      nRet = PILI_RTMP_SendPacket(m_pRtmp, packet, true, NULL);
    }
    free(packet);
  });
  
  //NSLog(@"send packet");
  return 1;
}

//h264数据存入文件
-(void)writeH264Data:(void*)data length:(size_t)length addStartCode:(BOOL)b
{
  const Byte bytes[] = "\x00\x00\x00\x01";
  if(_h264File){
    if(b)
      fwrite(bytes, 1, 4, _h264File);
    fwrite(data, 1, length, _h264File);
  }else{
    NSLog(@"_h264File null error, check if it open successed");
  }
}

//aac数据存入文件
-(void)writeAACData:(void*)data length:(size_t)length adtsHeader:(uint8_t*)header
{
  if(_AACFile){
    fwrite(header, 1,7, _AACFile);
    fwrite(data, 1,length, _AACFile);
  }else{
    NSLog(@"_AACFile null error, check if it open successed");
  }
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
