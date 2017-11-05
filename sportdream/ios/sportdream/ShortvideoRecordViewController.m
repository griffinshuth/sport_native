//
//  ShortvideoRecordViewController.m
//  sportdream
//
//  Created by lili on 2017/9/28.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "ShortvideoRecordViewController.h"
#import "PLShortVideoKit/PLShortVideoKit.h"

#define PLS_SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)
#define PLS_SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define TitleView_HEIGHT 64

@interface ShortvideoRecordViewController () <PLShortVideoRecorderDelegate>
@property (strong, nonatomic) PLShortVideoRecorder *shortVideoRecorder;
@property (strong, nonatomic) UIView* titleView;

@property (strong, nonatomic) UIView* toolBoxView;
@property (strong, nonatomic) UIButton* recordButton;
@property (strong, nonatomic) UIButton* deleteButton;
@property (strong, nonatomic) UIButton* endButton;

@end

@implementation ShortvideoRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  //设置标题栏
  [self setupRecordView];
  [self setupTitleView];
}

- (void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.shortVideoRecorder startCaptureSession];
}

-(void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self.shortVideoRecorder stopCaptureSession];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTitleView
{
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
  
  UIButton* flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
  flashButton.frame = CGRectMake(PLS_SCREEN_WIDTH-155, 25, 35, 35);
  [flashButton setBackgroundImage:[UIImage imageNamed:@"flash_close"] forState:UIControlStateNormal];
  [flashButton setBackgroundImage:[UIImage imageNamed:@"flash_open"] forState:UIControlStateSelected];
  [flashButton addTarget:self action:@selector(flashButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addSubview:flashButton];
  
  UIButton *beautyFaceButton = [UIButton buttonWithType:UIButtonTypeCustom];
  beautyFaceButton.frame = CGRectMake(PLS_SCREEN_WIDTH - 100, 20, 30, 30);
  [beautyFaceButton setTitle:@"美颜" forState:UIControlStateNormal];
  [beautyFaceButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  beautyFaceButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [beautyFaceButton addTarget:self action:@selector(beautyFaceButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addSubview:beautyFaceButton];
  
  UIButton* toggleCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
  toggleCameraButton.frame = CGRectMake(PLS_SCREEN_WIDTH-45, 20, 35, 35);
  [toggleCameraButton setBackgroundImage:[UIImage imageNamed:@"toggle_camera"] forState:UIControlStateNormal];
  [toggleCameraButton addTarget:self action:@selector(toggleCameraButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addSubview:toggleCameraButton];
  
  self.toolBoxView = [[UIView alloc] initWithFrame:CGRectMake(0, 400, PLS_SCREEN_WIDTH, 100)];
  self.toolBoxView.backgroundColor = [UIColor greenColor];
  [self.view addSubview:self.toolBoxView];
  CGFloat buttonWidth = 80.0f;
  self.recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.recordButton.frame = CGRectMake(0, 0, buttonWidth, buttonWidth);
  self.recordButton.center = CGPointMake(PLS_SCREEN_WIDTH/2, 50);
  [self.recordButton setImage:[UIImage imageNamed:@"btn_record_a"] forState:UIControlStateNormal];
  [self.recordButton addTarget:self action:@selector(recordButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [self.toolBoxView addSubview:self.recordButton];
  
}

- (void) setupRecordView
{
  // Do any additional setup after loading the view.
  NSLog(@"PLShortVideoRecorder versionInfo: %@", [PLShortVideoRecorder versionInfo]);
  PLSVideoConfiguration* videoConfiguration = [PLSVideoConfiguration defaultConfiguration];
  videoConfiguration.position = AVCaptureDevicePositionFront;
  videoConfiguration.videoFrameRate = 25;
  videoConfiguration.averageVideoBitRate = 1024*1000;
  videoConfiguration.videoSize = CGSizeMake(480, 854);
  videoConfiguration.videoOrientation = AVCaptureVideoOrientationPortrait;
  
  PLSAudioConfiguration* audioConfiguration = [PLSAudioConfiguration defaultConfiguration];
  self.shortVideoRecorder = [[PLShortVideoRecorder alloc] initWithVideoConfiguration:videoConfiguration audioConfiguration:audioConfiguration];
  self.shortVideoRecorder.previewView.frame = CGRectMake(0, 0, PLS_SCREEN_WIDTH, PLS_SCREEN_HEIGHT);
  [self.view addSubview:self.shortVideoRecorder.previewView];
  self.shortVideoRecorder.delegate = self;
  self.shortVideoRecorder.maxDuration = 30.0f;
}

-(void)backButtonEvent:(id)sender
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)flashButtonEvent:(id)sender
{
  if(self.shortVideoRecorder.torchOn){
    self.shortVideoRecorder.torchOn = NO;
  }else{
    self.shortVideoRecorder.torchOn = YES;
  }
}

-(void)beautyFaceButtonEvent:(id)sender
{
  UIButton *button = (UIButton *)sender;
  
  [self.shortVideoRecorder setBeautifyModeOn:!button.selected];
  
  button.selected = !button.selected;
}

-(void)toggleCameraButtonEvent:(id)sender
{
  [self.shortVideoRecorder toggleCamera];
}

-(void)recordButtonEvent:(id)sender
{
  if(self.shortVideoRecorder.isRecording){
    [self.shortVideoRecorder stopRecording];
  }else{
    [self.shortVideoRecorder startRecording];
  }
}

#pragma mark - 视频数据回调
/// @abstract 获取到摄像头原数据时的回调, 便于开发者做滤镜等处理，需要注意的是这个回调在 camera 数据的输出线程，请不要做过于耗时的操作，否则可能会导致帧率下降
- (CVPixelBufferRef)shortVideoRecorder:(PLShortVideoRecorder *)recorder cameraSourceDidGetPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
  return pixelBuffer;
}

// 开始录制一段视频时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
{
  
}

// 正在录制的过程中
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration
{
  
}

// 删除了某一段视频
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didDeleteFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration
{
  
}

// 完成一段视频的录制时
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fileDuration:(CGFloat)fileDuration totalDuration:(CGFloat)totalDuration
{
  
}

// 在达到指定的视频录制时间 maxDuration 后，如果再调用 [PLShortVideoRecorder startRecording]，直接执行该回调
- (void)shortVideoRecorder:(PLShortVideoRecorder *)recorder didFinishRecordingMaxDuration:(CGFloat)maxDuration
{
  
}




/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) dealloc {
  NSLog(@"dealloc: %@", [[self class] description]);
  self.shortVideoRecorder.delegate = nil;
  self.shortVideoRecorder = nil;
}

@end
