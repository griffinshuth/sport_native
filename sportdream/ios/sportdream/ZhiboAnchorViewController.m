//
//  ZhiboAnchorViewController.m
//  sportdream
//
//  Created by lili on 2017/9/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "ZhiboAnchorViewController.h"
#import <PLMediaStreamingKit/PLMediaStreamingKit.h>
#import <PLPlayerKit/PLPlayerKit.h>
#import "AppDelegate.h"

@interface ZhiboAnchorViewController ()
@property (nonatomic, strong) PLMediaStreamingSession *session;
@property (strong, nonatomic) PLPlayer* player;
@end

@implementation ZhiboAnchorViewController
-(void)initUI
{
  //关闭按钮
  UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  backButton.frame = CGRectMake(10, 25, 35, 35);
  [backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_a"] forState:UIControlStateNormal];
  [backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_b"] forState:UIControlStateHighlighted];
  [backButton addTarget:self action:@selector(backButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  
  // Do any additional setup after loading the view.
  PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
  videoCaptureConfiguration.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
  videoCaptureConfiguration.sessionPreset = AVCaptureSessionPreset1280x720;
  PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
  PLVideoStreamingConfiguration *videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
  videoStreamingConfiguration.videoSize = CGSizeMake(1280, 720);
  PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
  
  self.session = [[PLMediaStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
  [self.view addSubview:self.session.previewView];
  [self.view addSubview:backButton];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:@"横屏" forState:UIControlStateNormal];
  button.frame = CGRectMake(0, 0, 100, 44);
  button.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 80);
  [button addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];
  NSURL *pushURL = [NSURL URLWithString:self.url];
  [self.session startStreamingWithPushURL:pushURL feedback:^(PLStreamStartStateFeedback feedback) {
    if (feedback == PLStreamStartStateSuccess) {
      NSLog(@"Streaming started.");
    }
    else {
      NSLog(@"Oops.");
    }
  }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //允许横屏
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.allowRotation = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
      SEL selector = NSSelectorFromString(@"setOrientation:");
      NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
      [invocation setSelector:selector];
      [invocation setTarget:[UIDevice currentDevice]];
      int val =UIInterfaceOrientationLandscapeLeft;
      [invocation setArgument:&val atIndex:2];
      [invocation invoke];
    }
}

- (void)actionButtonPressed:(id)sender {
  
}

//一开始的方向  很重要

/*-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
  
  return UIInterfaceOrientationLandscapeLeft;
  
}*/

-(void)backButtonEvent:(id)sender
{
  [self.session stopStreaming];
  if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[UIDevice currentDevice]];
    int val =UIInterfaceOrientationPortrait;
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
  }
  //禁止横屏
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.allowRotation = NO;
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  if(orientation == UIInterfaceOrientationLandscapeLeft){
    [self initUI];
  }
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
