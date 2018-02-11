//
//  QiniuPlayerViewController.m
//  sportdream
//
//  Created by lili on 2017/12/13.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "QiniuPlayerViewController.h"
#import "AppDelegate.h"

@interface QiniuPlayerViewController ()
@property (nonatomic,strong) UIButton* backButton;
@property (nonatomic,strong) UIButton* backSmallButton;
@property (nonatomic,strong) UIButton* fullScreenButton;
@end

@implementation QiniuPlayerViewController
-(void)initLandscapeUI
{
  [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  CGFloat screen_width = CGRectGetWidth([UIScreen mainScreen].bounds);
  CGFloat screen_height = CGRectGetHeight([UIScreen mainScreen].bounds);
  self.player.playerView.frame = CGRectMake(0, 0, screen_width, screen_height);
  [self.view addSubview:self.player.playerView];
  [self.view addSubview:self.backSmallButton];
}
-(void)initPortraitUI
{
  [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  CGFloat screen_width = CGRectGetWidth([UIScreen mainScreen].bounds);
  self.player.playerView.frame = CGRectMake(0, 0, screen_width, 200);
  [self.view addSubview:self.player.playerView];
  [self.view addSubview:self.backButton];
  [self.view addSubview:self.fullScreenButton];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.allowBothRotation = YES;
  //监控横竖屏切换
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
  
  self.backButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.backButton.frame = CGRectMake(10, 25, 35, 35);
  [self.backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_a"] forState:UIControlStateNormal];
  [self.backButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_b"] forState:UIControlStateHighlighted];
  [self.backButton addTarget:self action:@selector(backButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  
  PLPlayerOption *option = [PLPlayerOption defaultOption];
  [option setOptionValue:@15 forKey:PLPlayerOptionKeyTimeoutIntervalForMediaPackets];
  //播放url
  NSURL *url = [NSURL URLWithString:self.url];
  self.player = [PLPlayer playerWithURL:url option:option];
  self.player.delegate = self;
  
  self.fullScreenButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.fullScreenButton setTitle:@"横屏" forState:UIControlStateNormal];
  self.fullScreenButton.frame = CGRectMake(0, 0, 100, 44);
  self.fullScreenButton.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds) - 80);
  [self.fullScreenButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  
  self.backSmallButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.backSmallButton.frame = CGRectMake(10, 25, 35, 35);
  [self.backSmallButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_a"] forState:UIControlStateNormal];
  [self.backSmallButton setBackgroundImage:[UIImage imageNamed:@"btn_camera_cancel_b"] forState:UIControlStateHighlighted];
  [self.backSmallButton addTarget:self action:@selector(backSmallButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  
  [self initPortraitUI];
  [self.player play];
}
-(void)backButtonEvent:(id)sender
{
  AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
  appDelegate.allowBothRotation = NO;
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)actionButtonPressed:(id)sender {
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

-(void)backSmallButtonEvent:(id)sender{
  if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[UIDevice currentDevice]];
    int val =UIInterfaceOrientationPortrait;
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
  }
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  if(orientation == UIInterfaceOrientationLandscapeLeft){
    [self initLandscapeUI];
  }else if(orientation == UIInterfaceOrientationPortrait){
    [self initPortraitUI];
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
