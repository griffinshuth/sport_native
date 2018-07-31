//
//  CheerLeaderViewController.m
//  sportdream
//
//  Created by lili on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CheerLeaderViewController.h"
#import "MyLayout.h"
#import "CFTool.h"
#import "NerdyUI.h"
#import "RemoteCameraSession.h"
#import <Orientation.h>

@interface CheerLeaderViewController ()
@property (nonatomic,strong) AgoraKitRemoteCamera* camera;
@property (nonatomic,strong) NSMutableArray<RemoteCameraSession*>* sessions;
@property (nonatomic,strong) MyLinearLayout* rootLayout;
@property (nonatomic,strong) MyFlowLayout *actionLayout;
@property (nonatomic,strong) KTVAUGraphRecorder* KTVRecorder;//伴奏KTV
@property (nonatomic,assign) BOOL isJoinChannelSuccess;
@property (nonatomic,assign) NSTimeInterval audioTimestamp;
@property (nonatomic,assign) NSTimeInterval audioBeginAbsoluteTimestamp;
@end

@implementation CheerLeaderViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  self.isJoinChannelSuccess = false;
  [Orientation setOrientation:UIInterfaceOrientationMaskLandscape];
  //K歌模块
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = paths[0];
  NSString *recordFolderPath = [documentsDirectory stringByAppendingPathComponent:@"record"];
  NSFileManager *fm = [NSFileManager defaultManager];
  
  if (![fm fileExistsAtPath:recordFolderPath isDirectory:NULL])
  {
    [fm createDirectoryAtPath:recordFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
  }
  self.KTVRecorder = [[KTVAUGraphRecorder alloc] initWithRecordFilePath:[recordFolderPath stringByAppendingPathComponent:@"temp.wav"]];
  self.KTVRecorder.delegate = self;
  [self.KTVRecorder startRecord];
  //UI
  UIScrollView *scrollView = [UIScrollView new];
  scrollView.backgroundColor = [UIColor whiteColor];
  self.view = scrollView;
  
  self.rootLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  self.rootLayout.backgroundColor = [UIColor whiteColor];
  //rootLayout.padding = UIEdgeInsetsMake(10, 10, 10, 10);
  self.rootLayout.myHorzMargin = 0;
  self.rootLayout.heightSize.lBound(scrollView.heightSize,10,1);
  [scrollView addSubview:self.rootLayout];
  
  UIView *titlebar = View.bgColor(@"red").opacity(0.7).border(1, @"3d3d3d");
  titlebar.myTop = 0;
  titlebar.myLeading = 0;
  titlebar.myTrailing = 0;
  titlebar.myHeight = 44;
  [self.rootLayout addSubview:titlebar];
  UIButton* backButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [self.camera leaveChannel];
    [Orientation setOrientation:UIInterfaceOrientationMaskPortrait];
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  backButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  backButton.str(@"演播室");
  backButton.embedIn(titlebar, UIEdgeInsetsMake(10, 10, 10, 10));
  
  MyLinearLayout* cameralistUI = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Horz];
  cameralistUI.myTop = 5;
  cameralistUI.myBottom = 5;
  cameralistUI.myLeading = 0;
  cameralistUI.myTrailing = 0;
  cameralistUI.myHeight = 72*3;
  [self.rootLayout addSubview:cameralistUI];
  //本地画面
  UIView* liveView = View.border(1, @"3d3d3d");
  liveView.myTop = 0;
  liveView.myBottom = 0;
  liveView.myWidth = 128*3;
  [cameralistUI addSubview:liveView];
  //远程画面
  self.actionLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:1];
  self.actionLayout.wrapContentHeight = YES;
  self.actionLayout.gravity = MyGravity_Horz_Fill; //垂直分配里面所有子视图的高度
  self.actionLayout.subviewHSpace = 5;
  self.actionLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  self.actionLayout.padding = UIEdgeInsetsMake(0, 0, 0, 0);
  self.actionLayout.myWidth = 128;
  [cameralistUI addSubview:self.actionLayout];
  
  self.camera = [[AgoraKitRemoteCamera alloc] initWithChannelName:self.channelName useExternalVideoSource:false localView:liveView useExternalAudioSource:true externalSampleRate:44100 externalChannelsPerFrame:2];
  self.camera.delegate = self;
  [self.camera joinChannel];
  self.sessions = [[NSMutableArray alloc] init];
}

-(void)dealloc
{
  [self.KTVRecorder stopRecord];
}

-(UILabel*)createLabel:(NSString*)title backgroundColor:(UIColor*)color
{
  UILabel *v = [UILabel new];
  v.text = title;
  v.font = [CFTool font:15];
  v.numberOfLines = 0;
  v.textAlignment = NSTextAlignmentCenter;
  v.adjustsFontSizeToFitWidth = YES;
  v.backgroundColor =  color;
  v.layer.shadowOffset = CGSizeMake(3, 3);
  v.layer.shadowColor = [CFTool color:4].CGColor;
  v.layer.shadowRadius = 2;
  v.layer.shadowOpacity = 0.3;
  
  return v;
}

-(void)refreshRemoteCameras
{
  [self.actionLayout removeAllSubviews];
  for (NSInteger i = 0; i < self.sessions.count; i++)
  {
    RemoteCameraSession* c = self.sessions[i];
    [self.actionLayout addSubview:[self createRomoteCameraView:c.name index:i preview:c.hostingView]];
    [self.camera setupRemoteVideo:c.canvas];
  }
  [self.rootLayout layoutIfNeeded];
}


-(MyLinearLayout*)createRomoteCameraView:(NSString*)name index:(NSInteger)index preview:(UIView*)preview
{
  MyLinearLayout* cameraView = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  preview.myHeight = 72*3/2;
  preview.myWidth = 128*3/2;
  [cameraView addSubview:preview];
  return cameraView;
}

//KTVRecorder delegate
- (void) recordDidReceiveBuffer:(AudioBuffer)buffer
{
  if(self.isJoinChannelSuccess){
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timestamp = self.audioTimestamp+(now-self.audioBeginAbsoluteTimestamp);
    [self.camera pushExternalAudioFrameRawData:buffer.mData samples:buffer.mDataByteSize/2/buffer.mNumberChannels timestamp:timestamp];
  }
}

//delegate
- (void)didjoinChannelSuccess
{
  
}

- (void)firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed
{
  self.isJoinChannelSuccess = true;
  self.audioTimestamp = elapsed;
  self.audioBeginAbsoluteTimestamp = [[NSDate date] timeIntervalSince1970];
}

- (void)didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
  NSArray *actions = @[@"主持人",
                       @"解说员",
                       ];
  UIView *preview = View.border(1, @"3d3d3d");
  RemoteCameraSession* t = [[RemoteCameraSession alloc] initWithView:preview uid:uid];
  [self.sessions addObject:t];
  t.name = actions[self.sessions.count-1];
  [self refreshRemoteCameras];
  
}
- (void)didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason
{
  for(RemoteCameraSession* obj in self.sessions)
  {
    if(obj.uid == uid)
    {
      [self.sessions removeObject:obj];
      [self refreshRemoteCameras];
      break;
    }
  }
}
- (void)receiveStreamMessageFromUid:(NSUInteger)uid streamId:(NSInteger)streamId data:(NSString *)data
{
  
}
- (void)addLocalYBuffer:(void *)yBuffer
                uBuffer:(void *)uBuffer
                vBuffer:(void *)vBuffer
                yStride:(int)yStride
                uStride:(int)uStride
                vStride:(int)vStride
                  width:(int)width
                 height:(int)height
               rotation:(int)rotation
{
  
}
- (void)addRemoteOfUId:(unsigned int)uid
               yBuffer:(void *)yBuffer
               uBuffer:(void *)uBuffer
               vBuffer:(void *)vBuffer
               yStride:(int)yStride
               uStride:(int)uStride
               vStride:(int)vStride
                 width:(int)width
                height:(int)height
              rotation:(int)rotation
{
  
}

- (void)onMixedAudioFrame:(void *)buffer length:(int)length
{
  
}
- (void)onPlaybackAudioFrameBeforeMixing:(void *)buffer length:(int)length uid:(int)uid
{
  
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
