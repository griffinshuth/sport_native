//
//  VideoChatViewController.m
//  sportdream
//
//  Created by lili on 2017/12/8.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "VideoChatViewController.h"

@interface VideoChatViewController ()
@property (strong, nonatomic) AgoraRtcEngineKit *agoraKit;
@property (weak, nonatomic) IBOutlet UIView *remoteVideo;
@property (weak, nonatomic) IBOutlet UIView *localVideo;
@property (weak, nonatomic) IBOutlet UIView *controlButtons;
@property (weak, nonatomic) IBOutlet UIImageView *remoteVideoMutedIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *localVideoMutedBg;
@property (weak, nonatomic) IBOutlet UIImageView *videoMutedIndicator;
@end

@implementation VideoChatViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupButtons];            // Tutorial Step 8
  [self hideVideoMuted];          // Tutorial Step 10
  [self initializeAgoraEngine];   // Tutorial Step 1
  [self setupVideo];              // Tutorial Step 2
  [self setupLocalVideo];         // Tutorial Step 3
  [self joinChannel];             // Tutorial Step 4
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initializeAgoraEngine{
  self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:@"b46966ee5e7e493496a97ddf6f19b87f" delegate:self];
}

-(void)setupVideo{
  [self.agoraKit enableVideo];
  [self.agoraKit setVideoProfile:AgoraRtc_VideoProfile_360P swapWidthAndHeight:false];
}

-(void)setupLocalVideo{
  AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
  videoCanvas.uid = 0;
  videoCanvas.view = self.localVideo;
  videoCanvas.renderMode = AgoraRtc_Render_Adaptive;
  [self.agoraKit setupLocalVideo:videoCanvas];
}

-(void)joinChannel{
  [self.agoraKit joinChannelByKey:nil channelName:@"mangguo" info:nil uid:0 joinSuccess:^(NSString* channel,
                                                                                          NSUInteger uid,NSInteger elapsed){
    [self.agoraKit setEnableSpeakerphone:NO];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
  }];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size: (CGSize)size elapsed:(NSInteger)elapsed {
  if (self.remoteVideo.hidden)
    self.remoteVideo.hidden = false;
  AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
  videoCanvas.uid = uid;
  // Since we are making a simple 1:1 video chat app, for simplicity sake, we are not storing the UIDs. You could use a mechanism such as an array to store the UIDs in a channel.
  
  videoCanvas.view = self.remoteVideo;
  videoCanvas.renderMode = AgoraRtc_Render_Adaptive;
  [self.agoraKit setupRemoteVideo:videoCanvas];
  // Bind remote video stream to view
  
  if (self.remoteVideo.hidden)
    self.remoteVideo.hidden = false;
}

- (IBAction)hangUpButton:(UIButton *)sender {
  [self leaveChannel];
}

- (void)leaveChannel {
  [self.agoraKit leaveChannel:^(AgoraRtcStats *stat) {
    [self hideControlButtons];     // Tutorial Step 8
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.remoteVideo removeFromSuperview];
    [self.localVideo removeFromSuperview];
    self.agoraKit = nil;
  }];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason {
  self.remoteVideo.hidden = true;
}

// Tutorial Step 8
- (void)setupButtons {
  [self performSelector:@selector(hideControlButtons) withObject:nil afterDelay:3];
  UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(remoteVideoTapped:)];
  [self.view addGestureRecognizer:tapGestureRecognizer];
  self.view.userInteractionEnabled = true;
}

- (void)hideControlButtons {
  self.controlButtons.hidden = true;
}

- (void)remoteVideoTapped:(UITapGestureRecognizer *)recognizer {
  if (self.controlButtons.hidden) {
    self.controlButtons.hidden = false;
    [self performSelector:@selector(hideControlButtons) withObject:nil afterDelay:3];
  }
}

- (void)resetHideButtonsTimer {
  [VideoChatViewController cancelPreviousPerformRequestsWithTarget:self];
  [self performSelector:@selector(hideControlButtons) withObject:nil afterDelay:3];
}

// Tutorial Step 9
- (IBAction)didClickMuteButton:(UIButton *)sender {
  sender.selected = !sender.selected;
  [self.agoraKit muteLocalAudioStream:sender.selected];
  [self resetHideButtonsTimer];
}

// Tutorial Step 10
- (IBAction)didClickVideoMuteButton:(UIButton *)sender {
  sender.selected = !sender.selected;
  [self.agoraKit muteLocalVideoStream:sender.selected];
  self.localVideo.hidden = sender.selected;
  self.localVideoMutedBg.hidden = !sender.selected;
  self.videoMutedIndicator.hidden = !sender.selected;
  [self resetHideButtonsTimer];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid {
  self.remoteVideo.hidden = muted;
  self.remoteVideoMutedIndicator.hidden = !muted;
}

- (void) hideVideoMuted {
  self.remoteVideoMutedIndicator.hidden = true;
  self.localVideoMutedBg.hidden = true;
  self.videoMutedIndicator.hidden = true;
}

// Tutorial Step 11
- (IBAction)didClickSwitchCameraButton:(UIButton *)sender {
  sender.selected = !sender.selected;
  [self.agoraKit switchCamera];
  [self resetHideButtonsTimer];
}

- (IBAction)back:(UIButton *)sender {
  [self.agoraKit leaveChannel:^(AgoraRtcStats* stats){}];
  [AgoraRtcEngineKit destroy];
  [self dismissViewControllerAnimated:YES completion:nil];
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
