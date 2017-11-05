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

#define PLS_SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)
#define PLS_SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#define TitleView_HEIGHT 64

@interface ZhiboAnchorViewController ()
@property (nonatomic, strong) PLMediaStreamingSession *session;
@property (strong, nonatomic) UIView* titleView;
@property (strong, nonatomic) PLPlayer* player;
@end

@implementation ZhiboAnchorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  
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
    // Do any additional setup after loading the view.
  PLVideoCaptureConfiguration *videoCaptureConfiguration = [PLVideoCaptureConfiguration defaultConfiguration];
  PLAudioCaptureConfiguration *audioCaptureConfiguration = [PLAudioCaptureConfiguration defaultConfiguration];
  PLVideoStreamingConfiguration *videoStreamingConfiguration = [PLVideoStreamingConfiguration defaultConfiguration];
  PLAudioStreamingConfiguration *audioStreamingConfiguration = [PLAudioStreamingConfiguration defaultConfiguration];
  
  self.session = [[PLMediaStreamingSession alloc] initWithVideoCaptureConfiguration:videoCaptureConfiguration audioCaptureConfiguration:audioCaptureConfiguration videoStreamingConfiguration:videoStreamingConfiguration audioStreamingConfiguration:audioStreamingConfiguration stream:nil];
  [self.view addSubview:self.session.previewView];
  [self.view addSubview:self.titleView];
  
  UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:@"start" forState:UIControlStateNormal];
  button.frame = CGRectMake(0, 0, 100, 44);
  button.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 80);
  [button addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];
}

- (void)actionButtonPressed:(id)sender {
  NSURL *pushURL = [NSURL URLWithString:@"rtmp://pili-publish.2310live.com/grasslive/audiotest"];
  [self.session startStreamingWithPushURL:pushURL feedback:^(PLStreamStartStateFeedback feedback) {
    if (feedback == PLStreamStartStateSuccess) {
      NSLog(@"Streaming started.");
    }
    else {
      NSLog(@"Oops.");
    }
  }];
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
