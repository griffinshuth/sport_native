//
//  DirectorServerViewController.m
//  sportdream
//
//  Created by lili on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "DirectorServerViewController.h"
#import "MyLayout.h"
#import "CFTool.h"
#import "NerdyUI.h"
#import "../DreamSDK/PacketID.h"
#import "RemoteCameraSession.h"
#import "StreamingClient.h"
#import "AudioMixer.h"
#import "libyuv.h"
#import "FFmpegPushClient.h"
#import "MatchDataStruct.h"
#import "MatchDataUI.h"
#import "FootballCourtViewController.h"
#import "BasketCourtViewController.h"
#import <Orientation.h>
#import <CoreImage/CoreImage.h>
#import "MBProgressHUD.h"

typedef enum {
  PUSH_TYPE_EMPTY = 0,
  PUSH_TYPE_LOCAL_CAMERA = 1,
  PUSH_TYPE_REMOTE_CAMERA = 2,
  PUSH_TYPE_FILE_CAMERA = 3,
  PUSH_TYPE_HIGHLIGHT = 4,
  PUSH_TYPE_FLASHBACK = 5
} PushType;

//基础本地机位数据结构
@interface LocalNetClientInfo:NSObject
  @property (nonatomic,strong) GCDAsyncSocket* socket;
  @property (nonatomic,strong) NSString* deviceID;
  @property (nonatomic,strong) NSString* name;
  @property (nonatomic,assign) int type;
  @property (nonatomic,assign) int subtype;
  @property (nonatomic,assign) BOOL isSlowMotion;
  @property (nonatomic,assign) BOOL isPreviewing;   //是否真正预览
  @property (nonatomic,strong) AACDecode* audioDecoder;
  @property (nonatomic,strong) h264decode* smallH264Decoder;
@end

@implementation LocalNetClientInfo

@end

//集锦和精彩回放片段数据结构
@interface HighlightSectionStruct:NSObject
@property (nonatomic,strong) NSString* deviceID;
@property (nonatomic,assign) BOOL isSlowMotion;
@property (nonatomic,assign) int64_t beginAbsoluteTimestamp;  //片段开始绝对时间
@property (nonatomic,assign) int     framesLength;            //该片段有多少帧
@end

@implementation HighlightSectionStruct
- (instancetype)initWithDeviceID:(NSString*)deviceID isSlowMotion:(BOOL)isSlowMotion beginAbsoluteTimestamp:(int64_t)beginAbsoluteTimestamp framesLength:(int)framesLength
{
  self = [super init];
  if(self){
    self.deviceID = deviceID;
    self.isSlowMotion = isSlowMotion;
    self.beginAbsoluteTimestamp = beginAbsoluteTimestamp;
    self.framesLength = framesLength;
  }
  return self;
}
@end

@interface HighlightStruct:NSObject
@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSMutableArray<HighlightSectionStruct*>* sections;
@end

@implementation HighlightStruct
-(id)init
{
  self = [super init];
  if(self){
    self.name = @"";
    self.sections = [[NSMutableArray alloc] init];
  }
  return self;
}
@end

//导播系统分为两个部分，远程画面和本地画面，远程画面可以从SDK中直接得到解码后的数据，直接发送原始数据到推流模块进行编码发送即可
//本地画面需要先用解码模块进行解码，得到原始数据进行后处理，然后发送到推流模块进行编码发送。

@interface DirectorServerViewController ()
//本地服务器
@property (nonatomic,strong) LocalWifiNetwork* localserver;
//音视频处理模块
@property (nonatomic,strong) h264decode* bigStreamDecode;    //大流解码器
@property (nonatomic,strong) h264decode* smallStreamDecode;  //小流解码器
@property (nonatomic,strong) h264encode* videoEncode;        //视频编码器,已经废弃，后面会删除
@property (nonatomic,strong) AudioMixer* audioMixer;         //混音器
@property (nonatomic,strong) VideoPlayer* filePlayer;        //文件播放
//rtmp直播对象
@property (nonatomic,strong) StreamingClient* rtmpClient;          //自己写的,只支持rtmp推送，已经废弃
@property (strong,nonatomic) FFmpegPushClient* FFmpegRtmpclient;   //基于FFmpeg的mp4文件保存和rtmp直播,画面和声音必须同时推送，否则推送失败
//功能单元，分别是机位，现场解说，视频集锦和精彩回放，文件，演播室，主播,数据统计客户端，集锦客户端
//演播室和主播
@property (nonatomic,strong) AgoraKitRemoteCamera* camera;
@property (nonatomic,strong) NSMutableArray<RemoteCameraSession*>* remoteCameraSessions;

@property (nonatomic,strong) NSMutableArray* files;  //本地可以播放的文件
@property (nonatomic,strong) NSMutableArray* localCameras; //前方机位
@property (nonatomic,strong) NSMutableArray* livecommentors; //现场解说
@property (nonatomic,strong) LocalNetClientInfo* matchDataClient;  //数据统计客户端
@property (nonatomic,strong) MatchDataStruct* matchData;
@property (nonatomic,strong) LocalNetClientInfo* highlightClient;  //集锦客户端
@property (nonatomic,strong) NSMutableArray<HighlightStruct*>* HighlightArray; //集锦列表
@property (nonatomic,strong) NSMutableArray<HighlightStruct*>* flashbackHistory; //精彩回放历史
//导播服务器状态，用于切换声音和画面
@property (nonatomic,assign) int commentMode;     //解说的模式，分两种：（1）后方解说，该模式下现场声音和后方演播室的声音进行混音后推送（2）现场解说：后方的声音和现场声音独立推送，两个声音流是互斥的
@property (nonatomic,assign) PushType currentPushType;
@property (nonatomic,assign) BOOL isLocalLiving;   //现场机位画面
//现场机位切换时需要的临时变量
@property (nonatomic,assign) BOOL isChangingLocalCamera;  //当切换机位时，下一个机位可能处于P帧，需要等I帧产生后，在通知上一个机位停止发送视频帧，
@property (nonatomic,strong) GCDAsyncSocket* lastLocalCameraSocket;
@property (nonatomic,strong) GCDAsyncSocket* nextLocalCameraSocket;
@property (nonatomic,strong) NSData* nextBigSPS;
@property (nonatomic,strong) NSData* nextBigPPS;

@property (nonatomic,assign) BOOL isRomoteLiving;  //演播室或主播画面
@property (nonatomic,assign) BOOL isFileLiving;    //本地文件画面
@property (nonatomic,assign) BOOL isHighlighting;  //精彩回放和集锦画面
//rtmp推送所需的变量
@property (nonatomic,strong) LocalNetClientInfo *cameraOnStandOfLiving; //正在直播中的机位
@property (nonatomic,strong) RemoteCameraSession* currentLivingRemoteCamera;  //当前正在直播的远程摄像头
@property (nonatomic,strong) NSDictionary* currentPlayingFile;  //当前正在播放的文件
@property (nonatomic,strong) HighlightStruct* currentPlayingHighlight; //当前播放的集锦
@property (nonatomic,assign) BOOL isPlayingHighlight;      //是否正在播放集锦
@property (nonatomic,assign) BOOL isHighlightPlayingSmall; //是否播放的是小流
@property (nonatomic,assign) int currentPlayingHighlightSectionIndex;
@property (nonatomic,assign) int currentPlayingHighlightFrameIndex;
@property (nonatomic,assign) int currentPlayingHighlightProgress;
@property (nonatomic,strong) HighlightStruct* currentFlashback;  //当前的精彩回放，可能为空，播放完后，放到精彩回放历史中，然后置空
@property (nonatomic,assign) BOOL isPlayingFlashBack;
@property (nonatomic,assign) BOOL isFlashBackPlayingSmall; //是否播放的是小流
@property (nonatomic,assign) int currentPlayingFlashBackSectionIndex;
@property (nonatomic,assign) int currentPlayingFlashBackFrameIndex;
@property (nonatomic,assign) int currentPlayingFlashBackProgress;
//回放或集锦需要的定时器
@property (nonatomic,strong) NSTimer* timeoutTimer;
//预览所需的变量
@property (nonatomic,strong) LocalNetClientInfo *cameraOnPreview;  //正在预览的机位
//界面
@property (nonatomic,strong) UIView* liveView;
@property (nonatomic,strong) MyLinearLayout* rootLayout;
@end

@implementation DirectorServerViewController
{
  MyFlowLayout *remoteCameraLayout;   //后方镜头列表容器
  MyFlowLayout *localCameraLayout;    //前方镜头列表容器
  MyFlowLayout *liveCommentorLayout;  //现场解说列表容器
  MyFlowLayout *highlightLayout;      //集锦列表容器
  MyFrameLayout *frameLayout;         //功能tabs容器
  
  //前方镜头界面
  MyLinearLayout *option1View;
  MyLinearLayout* option1LineLayout;
  //后方镜头界面
  MyLinearLayout *option2View;
  MyLinearLayout* option2LineLayout;
  //本地文件界面
  MyLinearLayout *option3View;
  MyLinearLayout* option3LineLayout;
  //集锦和精彩回放界面
  MyLinearLayout *option4View;
  MyLinearLayout* option4LineLayout;
  UILabel* highlightClientStatusUI;
  //现场解说界面
  MyLinearLayout *option5View;
  MyLinearLayout* option5LineLayout;
  //技术统计界面
  MyLinearLayout *option6View;
  MyLinearLayout* option6LineLayout;
  UILabel* matchDataStatusUI;
  //视频叠加层UI生成
  MyLinearLayout* option7View;
  MyLinearLayout*option7LineLayout;
  
  CVPixelBufferRef pixelBuf;
  //CMTime timestamp;   //推送给agora远端摄像头的当前时间戳，必须是递增的
  int64_t agoraBeginTimestamp;
  int screen_width;
  int screen_height;
  Byte* argb_buffer;
}

-(void) Toast:(NSString*)str
{
  dispatch_async(dispatch_get_main_queue(), ^(){
    //初始化进度框，置于当前的View当中
    MBProgressHUD* HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    //如果设置此属性则当前的view置于后台
    HUD.dimBackground = NO;
    
    //设置对话框文字
    HUD.labelText = str;
    
    //显示对话框
    [HUD showAnimated:YES whileExecutingBlock:^{
      //对话框显示时需要执行的操作
      sleep(1);
    } completionBlock:^{
      //操作执行完后取消对话框
      [HUD removeFromSuperview];
    }];
  });
}

//utils
-(GCDAsyncSocket*)getSocketbyDeviceID:(NSString*)deviceID
{
  for(int i=0;i<[self.localCameras count];i++){
    LocalNetClientInfo* s = self.localCameras[i];
    if([s.deviceID isEqualToString:deviceID]){
      return s.socket;
    }
  }
  return nil;
}
//utils

- (void)viewDidLoad {
    [super viewDidLoad];
  
  self.rtmpPushUrl = @"rtmp://pili-publish.2310live.com/grasslive/groupmatch_roomid";
  self.rtmpPlayUrl = @"rtmp://pili-live-rtmp.2310live.com/grasslive/groupmatch_roomid";
  self.hlsPlayUrl = @"http://pili-live-hls.2310live.com/grasslive/groupmatch_roomid.m3u8";
  
  screen_width = 1280;
  screen_height = 720;
  
  argb_buffer = (Byte*)malloc(screen_width*screen_height*4);
  memset(argb_buffer, 0, screen_width*screen_height*4);
  //混音
  self.audioMixer = [[AudioMixer alloc] init];
  self.audioMixer.delegate = self;
  //UI
  self.rootLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  self.rootLayout.backgroundColor = [UIColor whiteColor];
  //rootLayout.padding = UIEdgeInsetsMake(10, 10, 10, 10);
  self.rootLayout.myHorzMargin = 0;
  self.view = self.rootLayout;
  
  UIView *titlebar = View.bgColor(@"red").opacity(0.7);
  titlebar.myTop = 0;
  titlebar.myLeading = 0;
  titlebar.myTrailing = 0;
  titlebar.myHeight = 64;
  [self.rootLayout addSubview:titlebar];
  UIButton* backButton = Button.fnt(@18).color(@"#0065F7").onClick(^(UIButton* btn){
    [self.camera leaveChannel];
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  backButton.highColor(@"white").highBgImg(@"#0065F7");
  backButton.str(@"导播系统");
  backButton.embedIn(titlebar);
  
  UILabel *livelabel = [self createLabel:NSLocalizedString(@"实时画面", @"") backgroundColor:[CFTool color:1]];
  livelabel.myLeading = 0;
  livelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  livelabel.myHeight = 20;
  [self.rootLayout addSubview:livelabel];
  self.liveView = View.bgColor(@"white");
  self.liveView.myLeading = 0;
  self.liveView.myTrailing = 0;
  self.liveView.myHeight = 72*3;
  [self.rootLayout addSubview:self.liveView];
  
  NSArray *array = [NSArray arrayWithObjects:@"机位",@"演播室",@"文件",@"集锦",@"解说",@"统计",@"叠加层", nil];
  //初始化UISegmentedControl
  UISegmentedControl *segment = [[UISegmentedControl alloc]initWithItems:array];
  segment.myHeight = 30;
  segment.myLeading = 0;
  segment.myTrailing = 0;
  segment.myTop = 2;
  segment.myBottom = 2;
  segment.myLeft = 0;
  segment.myRight = 0;
  //添加到视图
  int screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
  int optionHeight = screenHeight-64-20-200-30-2-2;
  [self.rootLayout addSubview:segment];
  [segment addTarget:self action:@selector(segmentchanged:) forControlEvents:UIControlEventValueChanged];
  frameLayout = [MyFrameLayout new];
  frameLayout.backgroundColor = [UIColor whiteColor];
  frameLayout.myHorzMargin = 0;
  frameLayout.myHeight = optionHeight;
  [self.rootLayout addSubview:frameLayout];
  //选项1
  option1View = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  option1LineLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  [self createSegmentView:option1View optionLineLayout:option1LineLayout optionIndex:1 optionHeight:optionHeight];
  UILabel *localCameralabel = [self createLabel:NSLocalizedString(@"机位列表", @"") backgroundColor:[CFTool color:1]];
  localCameralabel.myLeading = 0;
  localCameralabel.myTrailing = 0; //上面两行代码将左右边距设置为0。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  localCameralabel.myHeight = 35;
  [option1LineLayout addSubview:localCameralabel];
  localCameraLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  localCameraLayout.wrapContentHeight = YES;
  localCameraLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  localCameraLayout.subviewHSpace = 5;
  localCameraLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  localCameraLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  localCameraLayout.myLeading = 0;
  localCameraLayout.myTrailing = 0;
  [option1LineLayout addSubview:localCameraLayout];
  //选项2
  option2View = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  option2LineLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  [self createSegmentView:option2View optionLineLayout:option2LineLayout optionIndex:2 optionHeight:optionHeight];
  UILabel *remotelabel = [self createLabel:NSLocalizedString(@"演播室和主播", @"") backgroundColor:[CFTool color:6]];
  remotelabel.myLeading = 0;
  remotelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  remotelabel.myHeight = 35;
  [option2LineLayout addSubview:remotelabel];
  
  remoteCameraLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  remoteCameraLayout.wrapContentHeight = YES;
  remoteCameraLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  remoteCameraLayout.subviewHSpace = 5;
  remoteCameraLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  remoteCameraLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  remoteCameraLayout.myLeading = 0;
  remoteCameraLayout.myTrailing = 0;
  [option2LineLayout addSubview:remoteCameraLayout];
  //选项3
  option3View = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  option3LineLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  [self createSegmentView:option3View optionLineLayout:option3LineLayout optionIndex:3 optionHeight:optionHeight];
  UILabel *filelabel = [self createLabel:NSLocalizedString(@"本地可播放文件", @"") backgroundColor:[CFTool color:1]];
  filelabel.myLeading = 5;
  filelabel.myTrailing = 0; //上面两行代码将左右边距设置为0。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  filelabel.myHeight = 35;
  [option3LineLayout addSubview:filelabel];
  MyFlowLayout *filesLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  filesLayout.wrapContentHeight = YES;
  filesLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  filesLayout.subviewHSpace = 5;
  filesLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  filesLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  filesLayout.myLeading = 0;
  filesLayout.myTrailing = 0;
  [option3LineLayout addSubview:filesLayout];
  
  self.files = [[NSMutableArray alloc] init];
  [self.files addObject:@{@"name":@"IMG_0032",@"extention":@"m4v"}];
  [self.files addObject:@{@"name":@"1223_1-2",@"extention":@"mov"}];
  [self.files addObject:@{@"name":@"ijustwannadance",@"extention":@"mov"}];

  for (NSInteger i = 0; i < self.files.count; i++)
  {
    [filesLayout addSubview:[self createFileViewWithindex:i]];
  }
  //选项4
  option4View = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  option4LineLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  [self createSegmentView:option4View optionLineLayout:option4LineLayout optionIndex:4 optionHeight:optionHeight];
  highlightClientStatusUI = [self createLabel:NSLocalizedString(@"集锦客户端未连接", @"") backgroundColor:[CFTool color:7]];
  highlightClientStatusUI.myLeading = 0;
  highlightClientStatusUI.myTrailing = 0;
  highlightClientStatusUI.myHeight = 35;
  [option4LineLayout addSubview:highlightClientStatusUI];
  UILabel *flashBacklabel = [self createLabel:NSLocalizedString(@"精彩回放", @"") backgroundColor:[CFTool color:1]];
  flashBacklabel.myLeading = 0;
  flashBacklabel.myTrailing = 0; //上面两行代码将左右边距设置为0。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  flashBacklabel.myHeight = 20;
  [option4LineLayout addSubview:flashBacklabel];
  UIView *flashBackView = View.border(1, @"3d3d3d");
  flashBackView.myLeading = 0;
  flashBackView.myTrailing = 0;
  flashBackView.myHeight = 100;
  [option4LineLayout addSubview:flashBackView];
  MyFlowLayout *flashBackButtonContainer;
  flashBackButtonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:3];
  flashBackButtonContainer.wrapContentHeight = YES;
  flashBackButtonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  flashBackButtonContainer.subviewHSpace = 5;
  flashBackButtonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  flashBackButtonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  flashBackButtonContainer.myLeading = 0;
  flashBackButtonContainer.myTrailing = 0;
  flashBackButtonContainer.myTop = 5;
  UIButton* flashBackButtonLiveButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    //先根据绝对时间戳向机位请求sps,pps和该片段第一帧的数据，等收到第一帧的数据后，启动一个定时器，继续请求剩下的视频帧，定时器的时间根据是否是慢镜头而不同。到达最后一帧后，重复之前的逻辑。
    if(self.currentPushType == PUSH_TYPE_FLASHBACK && self.isPlayingFlashBack){
      [self Toast:@"正在推送中"];
      return;
    }
    [self startPushWithType:PUSH_TYPE_FLASHBACK index:0];
  });
  flashBackButtonLiveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  flashBackButtonLiveButton.str(@"推送");
  flashBackButtonLiveButton.myHeight = 40;
  [flashBackButtonContainer addSubview:flashBackButtonLiveButton];
  
  UIButton* flashBackButtonpreviewButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick((^(UIButton* btn){
    //先根据绝对时间戳向机位请求sps,pps和该片段第一帧的数据，等收到第一帧的数据后，启动一个定时器，继续请求剩下的视频帧，定时器的时间根据是否是慢镜头而不同。到达最后一帧后，重复之前的逻辑。
    if(self.currentFlashback){
      if([self.currentFlashback.sections count] == 0){
        [self Toast:@"精彩回放片段数量是0"];
        return;
      }
      HighlightSectionStruct* firstSection = self.currentFlashback.sections[0];
      NSString* deviceID = self.currentFlashback.sections[0].deviceID;
      GCDAsyncSocket* socket = [self getSocketbyDeviceID:deviceID];
      if(socket == nil){
        [self Toast:@"片段对应的机位连接已经断开"];
        return;
      }
      [self.smallStreamDecode setPreview:flashBackView];
      self.isPlayingFlashBack = true;
      self.isFlashBackPlayingSmall = true;
      self.currentPlayingFlashBackSectionIndex = 0;
      NSDictionary* dict = @{
                             @"id": @"getFirstSmallIFramebyAbsoluteTimestamp",
                             @"timestamp":[NSNumber numberWithLongLong:firstSection.beginAbsoluteTimestamp]
                             };
      NSError *error;
      NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
      [self send:socket packetID:JSON_MESSAGE data:jsonData];
    }else{
      [self Toast:@"没有精彩回放数据"];
    }
  }));
  flashBackButtonpreviewButton.str(@"预览");
  flashBackButtonpreviewButton.myHeight = 40;
  [flashBackButtonContainer addSubview:flashBackButtonpreviewButton];
  [option4LineLayout addSubview:flashBackButtonContainer];
  UILabel *highlightlabel = [self createLabel:NSLocalizedString(@"集锦列表", @"") backgroundColor:[CFTool color:1]];
  highlightlabel.myLeading = 0;
  highlightlabel.myTrailing = 0; //上面两行代码将左右边距设置为0。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  highlightlabel.myHeight = 20;
  [option4LineLayout addSubview:highlightlabel];
  highlightLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  highlightLayout.wrapContentHeight = YES;
  highlightLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  highlightLayout.subviewHSpace = 5;
  highlightLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  highlightLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  highlightLayout.myLeading = 0;
  highlightLayout.myTrailing = 0;
  [option4LineLayout addSubview:highlightLayout];
  
  //选项5
  option5View = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  option5LineLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  [self createSegmentView:option5View optionLineLayout:option5LineLayout optionIndex:5 optionHeight:optionHeight];
  UILabel *liveCommentorLabel = [self createLabel:NSLocalizedString(@"现场解说员列表", @"") backgroundColor:[CFTool color:1]];
  liveCommentorLabel.myLeading = 0;
  liveCommentorLabel.myTrailing = 0; //上面两行代码将左右边距设置为0。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  liveCommentorLabel.myHeight = 35;
  [option5LineLayout addSubview:liveCommentorLabel];
  liveCommentorLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  liveCommentorLayout.wrapContentHeight = YES;
  liveCommentorLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  liveCommentorLayout.subviewHSpace = 5;
  liveCommentorLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  liveCommentorLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  liveCommentorLayout.myLeading = 0;
  liveCommentorLayout.myTrailing = 0;
  [option5LineLayout addSubview:liveCommentorLayout];
  //选项6
  option6View = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  option6LineLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  [self createSegmentView:option6View optionLineLayout:option6LineLayout optionIndex:6 optionHeight:optionHeight];
  matchDataStatusUI = [self createLabel:NSLocalizedString(@"数据统计客户端未连接", @"") backgroundColor:[CFTool color:6]];
  matchDataStatusUI.myLeading = 0;
  matchDataStatusUI.myTrailing = 0;
  matchDataStatusUI.myHeight = 35;
  [option6LineLayout addSubview:matchDataStatusUI];
  //生成比赛直播地址二维码
  CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
  // 滤镜恢复默认设置
  [filter setDefaults];
  NSString *string = [[NSString alloc] initWithFormat:@"playrtmpurl&%@",self.rtmpPlayUrl];
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  // 使用KVC的方式给filter赋值
  [filter setValue:data forKeyPath:@"inputMessage"];
  // 3. 生成rtmp播放地址二维码
  CIImage *qrimage = [filter outputImage];
  UIImageView* qrcode = [[UIImageView alloc] init];
  qrcode.contentMode = UIViewContentModeScaleAspectFit;
  qrcode.myWidth = 128;
  qrcode.myHeight = 128;
  qrcode.image = [UIImage imageWithCIImage:qrimage];
  [option6LineLayout addSubview:qrcode];
  //选项7
  option7View = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  option7LineLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  [self createSegmentView:option7View optionLineLayout:option7LineLayout optionIndex:7 optionHeight:optionHeight];
  UILabel* overlayLabel = [self createLabel:NSLocalizedString(@"增加视频叠加层", @"") backgroundColor:[CFTool color:6]];
  overlayLabel.myLeading = 0;
  overlayLabel.myTrailing = 0;
  overlayLabel.myHeight = 35;
  [option7LineLayout addSubview:overlayLabel];
  [self createOverlayUIButtons];
  
  [frameLayout bringSubviewToFront:option1View];
  [segment setSelectedSegmentIndex:0];

  //初始化解码器
  self.bigStreamDecode = [[h264decode alloc] initWithGPUImageView:self.liveView]; //用于解码机位们发过来的H264视频帧，并进行后期处理和界面叠加后显示。
  self.bigStreamDecode.delegate = self;
  self.smallStreamDecode = [[h264decode alloc] initWithView:nil]; //机位预览视频帧的解码和显示
  
  self.videoEncode = [[h264encode alloc] initEncodeWith:1280 height:720 framerate:30 bitrate:1600 * 1024];
  self.videoEncode.delegate = self;
  [self.videoEncode startH264EncodeSession];
  //初始化Agora引擎，用于联系后方演播室和主播
  self.camera = [[AgoraKitRemoteCamera alloc] initWithChannelName:self.AgoraChannelName useExternalVideoSource:true localView:nil useExternalAudioSource:true externalSampleRate:44100 externalChannelsPerFrame:1];
  self.camera.delegate = self;
  [self.camera joinChannel];
  //初始化导播服务器
  self.localserver = [[LocalWifiNetwork alloc] initWithType:true];
  self.localserver.delegate = self;
  //初始化连接到导播服务器的客户端
  self.remoteCameraSessions = [[NSMutableArray alloc] init]; //演播室和主播
  self.localCameras = [[NSMutableArray alloc] init];         //现场机位
  self.livecommentors = [[NSMutableArray alloc] init];       //现场解说
  self.matchDataClient = [[LocalNetClientInfo alloc] init];     //数据统计客户端
  self.matchData = [[MatchDataStruct alloc] init];           //比赛当前数据
  self.highlightClient = [[LocalNetClientInfo alloc] init];  //精彩回放和集锦客户端
  self.HighlightArray = [[NSMutableArray alloc] init];            //集锦列表
  self.flashbackHistory = [[NSMutableArray alloc] init];         //精彩回放历史
  
  self.isPlayingHighlight = false;
  self.isHighlightPlayingSmall = true;
  self.currentPlayingHighlightSectionIndex = -1;
  self.currentPlayingHighlightFrameIndex = -1;
  self.currentPlayingHighlightProgress = 0;

  self.isPlayingFlashBack = false;
  self.isFlashBackPlayingSmall = true;
  self.currentPlayingFlashBackSectionIndex = -1;
  self.currentPlayingFlashBackFrameIndex = -1;
  self.currentPlayingFlashBackProgress = 0;
  
  self.currentPushType = PUSH_TYPE_EMPTY;

  int width = 1280;
  int height = 720;
  CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuf);
  //timestamp = kCMTimeZero;
  agoraBeginTimestamp = -1;
  //用于播放本地文件
  self.filePlayer = [[VideoPlayer alloc] init];
  self.filePlayer.delegate = self;

  self.FFmpegRtmpclient = [[FFmpegPushClient alloc] initWithUrl:self.rtmpPushUrl isRtmp:true];
}

-(void)dealloc
{
  free(argb_buffer);
  if(![self.filePlayer isStop]){
    [self.filePlayer stop];
  }
  [self.videoEncode stopH264EncodeSession];
  if([self.FFmpegRtmpclient isPushing]){
    [self.FFmpegRtmpclient stopStreaming];
  }
  
  if(self.timeoutTimer){
    [self.timeoutTimer invalidate];
  }
}

-(void)viewWillAppear:(BOOL)animated
{
  //[Orientation setOrientation:UIInterfaceOrientationMaskPortrait];
}

-(void)viewDidAppear:(BOOL)animated
{
  
}

-(void)viewWillDisappear:(BOOL)animated
{
 
}

-(void)startPushWithType:(PushType)nextType index:(int)index
{
  //开启ffmpeg推送
  if(![self.FFmpegRtmpclient isPushing]){
    [self.FFmpegRtmpclient startStreaming];
  }
  //开始改变推送方式
  //处理切换到前方机位的逻辑
  if(nextType == PUSH_TYPE_LOCAL_CAMERA){
    LocalNetClientInfo* currentCamera = self.localCameras[index];
    if(self.currentPushType == PUSH_TYPE_LOCAL_CAMERA){
      if(currentCamera == self.cameraOnStandOfLiving){
        //当前机位正在直播，不进行任何操作
        return;
      }else{
        if(self.cameraOnStandOfLiving){
          //[self stopBigVideo:self.cameraOnStandOfLiving.socket];
          self.lastLocalCameraSocket = self.cameraOnStandOfLiving.socket;
        }
      }
    }else if(self.currentPushType == PUSH_TYPE_FILE_CAMERA){
      
    }else if(self.currentPushType == PUSH_TYPE_REMOTE_CAMERA){
      
    }else if(self.currentPushType == PUSH_TYPE_HIGHLIGHT){
      
    }else if(self.currentPushType == PUSH_TYPE_FLASHBACK){
      
    }
    //切换到选择的机位
    self.currentPushType = PUSH_TYPE_LOCAL_CAMERA;
    self.cameraOnStandOfLiving = currentCamera;
    self.isChangingLocalCamera = true;
    self.nextLocalCameraSocket = currentCamera.socket;
    [self startBigVideo:self.cameraOnStandOfLiving.socket];
  }
  //处理播放本地文件的逻辑
  if(nextType == PUSH_TYPE_FILE_CAMERA){
    NSDictionary* nextFile = self.files[index];
    NSString* nextFilename = nextFile[@"name"];
    NSString* nextExtension = nextFile[@"extention"];
    if(self.currentPushType == PUSH_TYPE_FILE_CAMERA){
      if(self.currentPlayingFile == nextFile){
        //当前文件正在播放
        return;
      }
      if(![self.filePlayer isStop]){
        //[self.filePlayer stop];
        //[self Toast:@"请先停止推送或预览的视频文件"];
        return;
      }
    }else if(self.currentPushType == PUSH_TYPE_FILE_CAMERA){
      
    }else if(self.currentPushType == PUSH_TYPE_REMOTE_CAMERA){
      
    }else if(self.currentPushType == PUSH_TYPE_HIGHLIGHT){
      
    }else if(self.currentPushType == PUSH_TYPE_FLASHBACK){
      
    }else if(self.currentPushType == PUSH_TYPE_LOCAL_CAMERA){
      
    }
    self.currentPushType = PUSH_TYPE_FILE_CAMERA;
    self.currentPlayingFile = nextFile;
    [self.filePlayer startPush:nextFilename fileExtension:nextExtension];
  }
  //处理远程镜头的逻辑，包括后方演播室和主播等
  if(nextType == PUSH_TYPE_REMOTE_CAMERA){
    RemoteCameraSession* nextAgoraCamera = self.remoteCameraSessions[index];
    if(self.currentPushType == PUSH_TYPE_REMOTE_CAMERA){
      if(self.currentLivingRemoteCamera == nextAgoraCamera){
        return;
      }
      [self.camera setRemoteBigSmallStream:self.currentLivingRemoteCamera.uid isBig:false];
    }else if(self.currentPushType == PUSH_TYPE_LOCAL_CAMERA){
      
    }else if(self.currentPushType == PUSH_TYPE_FILE_CAMERA){
      
    }else if(self.currentPushType == PUSH_TYPE_HIGHLIGHT){
      
    }else if(self.currentPushType == PUSH_TYPE_FLASHBACK){
      
    }
    self.currentPushType = PUSH_TYPE_REMOTE_CAMERA;
    self.currentLivingRemoteCamera = nextAgoraCamera;
    [self.camera setRemoteBigSmallStream:nextAgoraCamera.uid isBig:true];
  }
  //处理精彩回放
  if(nextType == PUSH_TYPE_FLASHBACK){
    //先根据绝对时间戳向机位请求sps,pps和该片段第一帧的数据，等收到第一帧的数据后，启动一个定时器，继续请求剩下的视频帧，定时器的时间根据是否是慢镜头而不同。到达最后一帧后，重复之前的逻辑。
    if(self.currentFlashback){
      if([self.currentFlashback.sections count] == 0){
        [self Toast:@"精彩回放片段数量是0"];
        return;
      }
      HighlightSectionStruct* firstSection = self.currentFlashback.sections[0];
      NSString* deviceID = self.currentFlashback.sections[0].deviceID;
      GCDAsyncSocket* socket = [self getSocketbyDeviceID:deviceID];
      if(socket == nil){
        [self Toast:@"片段对应的机位连接已经断开"];
        return;
      }
      self.isPlayingFlashBack = true;
      self.isFlashBackPlayingSmall = false;
      self.currentPlayingFlashBackSectionIndex = 0;
      NSDictionary* dict = @{
                             @"id": @"getFirstBigIFramebyAbsoluteTimestamp",
                             @"timestamp":[NSNumber numberWithLongLong:firstSection.beginAbsoluteTimestamp]
                             };
      NSError *error;
      NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
      [self send:socket packetID:JSON_MESSAGE data:jsonData];
      self.currentPushType = PUSH_TYPE_FLASHBACK;
    }else{
      [self Toast:@"没有精彩回放数据"];
    }
  }
  //处理集锦
  if(nextType == PUSH_TYPE_HIGHLIGHT){
    HighlightStruct* currentSection = self.HighlightArray[index];
    if(currentSection){
      self.currentPlayingHighlight = currentSection;
      if([self.currentPlayingHighlight.sections count] == 0){
        [self Toast:@"精彩回放片段数量是0"];
        return;
      }
      HighlightSectionStruct* firstSection = self.currentPlayingHighlight.sections[0];
      NSString* deviceID = self.currentPlayingHighlight.sections[0].deviceID;
      GCDAsyncSocket* socket = [self getSocketbyDeviceID:deviceID];
      if(socket == nil){
        [self Toast:@"片段对应的机位连接已经断开"];
        return;
      }
      self.isPlayingHighlight = true;
      self.isHighlightPlayingSmall = false;
      self.currentPlayingHighlightSectionIndex = 0;
      NSDictionary* dict = @{
                             @"id": @"getFirstBigIFramebyAbsoluteTimestamp",
                             @"timestamp":[NSNumber numberWithLongLong:firstSection.beginAbsoluteTimestamp]
                             };
      NSError *error;
      NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
      [self send:socket packetID:JSON_MESSAGE data:jsonData];
    }
  }
  
}

-(void)createOverlayUIButtons
{
  MyFlowLayout *buttonContainer;
  buttonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  buttonContainer.wrapContentHeight = YES;
  buttonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  buttonContainer.subviewHSpace = 5;
  buttonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  buttonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  buttonContainer.myLeading = 0;
  buttonContainer.myTrailing = 0;
  buttonContainer.myTop = 5;
  
  __weak typeof(self) ws = self;
  UIButton* liveButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [ws.bigStreamDecode showPlaybackBeginImage];
  });
  liveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  liveButton.str(@"开始回放动画");
  liveButton.myHeight = 40;
  
  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [ws.bigStreamDecode createMainOverlayImage];
  });
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"记分牌");
  smallH264Button.myHeight = 40;
  
  UIButton* stopButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  stopButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  stopButton.str(@"结束统计");
  stopButton.myHeight = 40;
  
  [buttonContainer addSubview:liveButton];
  [buttonContainer addSubview:smallH264Button];
  [buttonContainer addSubview:stopButton];
  [option7LineLayout addSubview:buttonContainer];
}

-(MyFlowLayout*)createShootDistributionButton:(NSDictionary*)member teamindex:(int)teamindex gameData:(NSDictionary*)gameData
{
  MyFlowLayout *buttonContainer;
  buttonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  buttonContainer.wrapContentHeight = YES;
  buttonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  buttonContainer.subviewHSpace = 5;
  buttonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  buttonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  buttonContainer.myLeading = 0;
  buttonContainer.myTrailing = 0;
  buttonContainer.myTop = 5;
  UIButton* button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    BasketCourtViewController* courtViewController = [[BasketCourtViewController alloc] init];
    courtViewController.gameData = gameData;
    courtViewController.currentMember = member;
    courtViewController.teamindex = teamindex;
    [self presentViewController:courtViewController animated:YES completion:nil];
  });
  button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  button.str(@"投篮分布图");
  button.myHeight = 40;
  [buttonContainer addSubview:button];
  return buttonContainer;
}

-(void)alert:(NSString*)message
{
  UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"alert"
   message:message
   preferredStyle:UIAlertControllerStyleAlert];
   
   UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
   handler:^(UIAlertAction * action) {
   //响应事件
   NSLog(@"action = %@", action);
   }];
   UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
   handler:^(UIAlertAction * action) {
   //响应事件
   NSLog(@"action = %@", action);
   }];
   
   [alert addAction:defaultAction];
   [alert addAction:cancelAction];
   [self presentViewController:alert animated:YES completion:nil];
}

-(UIView*)createTeamMembersView:(NSDictionary*)gameData teamIndex:(int)teamIndex layout:(MyLinearLayout*)layout
{
  int screen_width = CGRectGetWidth([[UIScreen mainScreen] bounds]);
  if(teamIndex == 0){
    NSArray* team1Members = gameData[@"team1Members"];
    for(int i=0;i<[team1Members count];i++){
      NSDictionary* member = [team1Members objectAtIndex:i];
      UILabel* nickname = [UILabel new];
      nickname.text = member[@"nickname"];
      [nickname sizeToFit];
      //每一列球员信息的UI
      MyRelativeLayout* container = [MyRelativeLayout new];
      container.myHeight = 100;
      container.myLeading = 0;
      container.myTrailing = 0;
      container.myBottom = 5;
      MyLinearLayout* head = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
      head.myHeight = 100;
      head.myWidth = 80;
      head.backgroundColor = [UIColor yellowColor];
      head.padding = UIEdgeInsetsMake(10, 10, 10, 10);
      UIImageView* imageView = [MatchDataUI createImageOfUrl:member[@"image"] width:64 height:64];
      imageView.myCenterX = 0;
      [head addSubview:imageView];
      nickname.myCenterX = 0;
      [head addSubview:nickname];
      [container addSubview:head];
      MyLinearLayout* body = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
      body.backgroundColor = [UIColor redColor];
      body.myHeight = 100;
      body.topPos.equalTo(@0);
      body.leadingPos.equalTo(head.trailingPos);
      body.myWidth = screen_width-80;
      body.padding = UIEdgeInsetsMake(10, 10, 10, 10);
      //技术统计
      if([member[@"id"] isKindOfClass:[NSString class]]){
        int point = [MatchDataUI TechnicalStatisticsOfIDWithType:@"point" uid:member[@"id"] gameData:gameData teamindex:0];
        UILabel* pointLabel = [UILabel new];
        pointLabel.text = [[NSString alloc] initWithFormat:@"得分：%d",point];
        [pointLabel sizeToFit];
        [body addSubview:pointLabel];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"rebound" uid:member[@"id"] gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"assists" uid:member[@"id"] gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"block" uid:member[@"id"] gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"steals" uid:member[@"id"] gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"fault" uid:member[@"id"] gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"foul" uid:member[@"id"] gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"freethrow" uid:member[@"id"] gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"shoot" uid:member[@"id"] gameData:gameData teamindex:0];
        [body addSubview:[self createShootDistributionButton:member teamindex:0 gameData:gameData]];
      }else{
        NSString* uidStr = [[NSString alloc] initWithFormat:@"%d",[member[@"id"] intValue]];
        int point = [MatchDataUI TechnicalStatisticsOfIDWithType:@"point" uid:uidStr gameData:gameData teamindex:0];
        UILabel* pointLabel = [UILabel new];
        pointLabel.text = [[NSString alloc] initWithFormat:@"得分：%d",point];
        [pointLabel sizeToFit];
        [body addSubview:pointLabel];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"rebound" uid:uidStr gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"assists" uid:uidStr gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"block" uid:uidStr gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"steals" uid:uidStr gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"fault" uid:uidStr gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"foul" uid:uidStr gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"freethrow" uid:uidStr gameData:gameData teamindex:0];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"shoot" uid:uidStr gameData:gameData teamindex:0];
        [body addSubview:[self createShootDistributionButton:member teamindex:0 gameData:gameData]];
      }
      [container addSubview:body];
      [layout addSubview:container];
    }
  }else if(teamIndex == 1){
    NSArray* team2Members = gameData[@"team2Members"];
    for(int i=0;i<[team2Members count];i++){
      NSDictionary* member = [team2Members objectAtIndex:i];
      UILabel* nickname = [UILabel new];
      nickname.text = member[@"nickname"];
      [nickname sizeToFit];
      //每一列球员信息的UI
      MyRelativeLayout* container = [MyRelativeLayout new];
      container.myHeight = 100;
      container.myLeading = 0;
      container.myTrailing = 0;
      container.myBottom = 5;
      MyLinearLayout* head = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
      head.myHeight = 100;
      head.myWidth = 80;
      head.backgroundColor = [UIColor yellowColor];
      head.padding = UIEdgeInsetsMake(10, 10, 10, 10);
      UIImageView* imageView = [MatchDataUI createImageOfUrl:member[@"image"] width:64 height:64];
      imageView.myCenterX = 0;
      [head addSubview:imageView];
      nickname.myCenterX = 0;
      [head addSubview:nickname];
      [container addSubview:head];
      MyLinearLayout* body = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
      body.backgroundColor = [UIColor redColor];
      body.myHeight = 100;
      body.topPos.equalTo(@0);
      body.leadingPos.equalTo(head.trailingPos);
      body.myWidth = screen_width-80;
      body.padding = UIEdgeInsetsMake(10, 10, 10, 10);
      //技术统计
      if([member[@"id"] isKindOfClass:[NSString class]]){
        int point = [MatchDataUI TechnicalStatisticsOfIDWithType:@"point" uid:member[@"id"] gameData:gameData teamindex:1];
        UILabel* pointLabel = [UILabel new];
        pointLabel.text = [[NSString alloc] initWithFormat:@"得分：%d",point];
        [pointLabel sizeToFit];
        [body addSubview:pointLabel];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"rebound" uid:member[@"id"] gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"assists" uid:member[@"id"] gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"block" uid:member[@"id"] gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"steals" uid:member[@"id"] gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"fault" uid:member[@"id"] gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"foul" uid:member[@"id"] gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"freethrow" uid:member[@"id"] gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"shoot" uid:member[@"id"] gameData:gameData teamindex:1];
        [body addSubview:[self createShootDistributionButton:member teamindex:1 gameData:gameData]];
      }else{
        NSString* uidStr = [[NSString alloc] initWithFormat:@"%d",[member[@"id"] intValue]];
        int point = [MatchDataUI TechnicalStatisticsOfIDWithType:@"point" uid:uidStr gameData:gameData teamindex:1];
        UILabel* pointLabel = [UILabel new];
        pointLabel.text = [[NSString alloc] initWithFormat:@"得分：%d",point];
        [pointLabel sizeToFit];
        [body addSubview:pointLabel];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"rebound" uid:uidStr gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"assists" uid:uidStr gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"block" uid:uidStr gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"steals" uid:uidStr gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"fault" uid:uidStr gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"foul" uid:uidStr gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"freethrow" uid:uidStr gameData:gameData teamindex:1];
        [MatchDataUI TechnicalStatisticsOfIDWithType:@"shoot" uid:uidStr gameData:gameData teamindex:1];
        [body addSubview:[self createShootDistributionButton:member teamindex:1 gameData:gameData]];
      }
      [container addSubview:body];
      [layout addSubview:container];
    }
  }
  return layout;
}

-(void)createMatchDataView:(NSDictionary*)gameData
{
  [option6LineLayout addSubview:[MatchDataUI createCourtDataView:gameData]];
  NSDictionary* team1info = gameData[@"team1info"];
  NSString* team1name = team1info[@"name"];
  NSString* team1title = [[NSString alloc] initWithFormat:@"%@球员列表",team1name];
  UILabel* team1MembersLabel = [self createLabel:NSLocalizedString(team1title, @"") backgroundColor:[CFTool color:6]];
  team1MembersLabel.myLeading = 0;
  team1MembersLabel.myTrailing = 0;
  team1MembersLabel.myHeight = 35;
  [option6LineLayout addSubview:team1MembersLabel];
  [self createTeamMembersView:gameData teamIndex:0 layout:option6LineLayout];
  
  NSDictionary* team2info = gameData[@"team2info"];
  NSString* team2name = team2info[@"name"];
  NSString* team2title = [[NSString alloc] initWithFormat:@"%@球员列表",team2name];
  UILabel* team2MembersLabel = [self createLabel:NSLocalizedString(team2title, @"") backgroundColor:[CFTool color:6]];
  team2MembersLabel.myLeading = 0;
  team2MembersLabel.myTrailing = 0;
  team2MembersLabel.myHeight = 35;
  [option6LineLayout addSubview:team2MembersLabel];
  [self createTeamMembersView:gameData teamIndex:1 layout:option6LineLayout];
}

-(void)createSegmentView:(MyLinearLayout*)optionView optionLineLayout:(MyLinearLayout*)optionLineLayout optionIndex:(int)optionIndex optionHeight:(int)optionHeight
{
  optionView.myLeading = 0;
  optionView.myTrailing = 0;
  optionView.myHeight = optionHeight;
  [frameLayout addSubview:optionView];
  UIScrollView * optionScrollView = [UIScrollView new];
  optionScrollView.backgroundColor = [UIColor whiteColor];
  optionScrollView.alwaysBounceVertical = YES;
  optionScrollView.myLeading = 0;
  optionScrollView.myTrailing = 0;
  optionScrollView.myHeight = optionHeight;
  [optionView addSubview:optionScrollView];
  optionLineLayout.frame = CGRectMake(0, 0, 800, optionHeight);
  optionLineLayout.myLeading = 0;
  optionLineLayout.myTrailing = 0;
  [optionScrollView addSubview:optionLineLayout];
}

-(void)segmentchanged:(UISegmentedControl *)sender{
  if (sender.selectedSegmentIndex == 0) {
    NSLog(@"1");
    [frameLayout bringSubviewToFront:option1View];
  }else if (sender.selectedSegmentIndex == 1){
    NSLog(@"2");
    [frameLayout bringSubviewToFront:option2View];
  }else if (sender.selectedSegmentIndex == 2){
    NSLog(@"3");
    [frameLayout bringSubviewToFront:option3View];
  }else if (sender.selectedSegmentIndex == 3){
    NSLog(@"4");
    [frameLayout bringSubviewToFront:option4View];
  }else if(sender.selectedSegmentIndex == 4){
    NSLog(@"5");
    [frameLayout bringSubviewToFront:option5View];
  }else if(sender.selectedSegmentIndex == 5){
    NSLog(@"6");
    [frameLayout bringSubviewToFront:option6View];
  }else if(sender.selectedSegmentIndex == 6){
    [frameLayout bringSubviewToFront:option7View];
  }
}

-(void)send:(GCDAsyncSocket*)sock packetID:(uint16_t)packetID data:(NSData*)data
{
  [self.localserver serverSendPacket:packetID data:data sock:sock];
}

-(void)startBigVideo:(GCDAsyncSocket*)sock
{
  NSString *json = @"{extra:0}";
  NSData *data =[json dataUsingEncoding:NSUTF8StringEncoding];
  [self send:sock packetID:START_SEND_BIGDATA data:data];
}

-(void)stopBigVideo:(GCDAsyncSocket*)sock
{
  NSString *json = @"{extra:0}";
  NSData *data =[json dataUsingEncoding:NSUTF8StringEncoding];
  [self send:sock packetID:STOP_SEND_BIGDATA data:data];
}

-(void)startSmallVideo:(GCDAsyncSocket*)sock
{
  NSString *json = @"{extra:0}";
  NSData *data =[json dataUsingEncoding:NSUTF8StringEncoding];
  [self send:sock packetID:START_SEND_SMALLDATA data:data];
}

-(void)stopSmallVideo:(GCDAsyncSocket*)sock
{
  NSString *json = @"{extra:0}";
  NSData *data =[json dataUsingEncoding:NSUTF8StringEncoding];
  [self send:sock packetID:STOP_SEND_SMALLDATA data:data];
}

-(void)refreshLocalCameras
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [localCameraLayout removeAllSubviews];
    for (NSInteger i = 0; i < self.localCameras.count; i++)
    {
      LocalNetClientInfo* c = self.localCameras[i];
      [localCameraLayout addSubview:[self createLocalCameraView:c.deviceID index:i]];
    }
    [self.rootLayout layoutIfNeeded];
  });
}

-(void)refreshLiveCommentors
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [liveCommentorLayout removeAllSubviews];
    for (NSInteger i = 0; i < self.livecommentors.count; i++)
    {
      LocalNetClientInfo* c = self.livecommentors[i];
      [liveCommentorLayout addSubview:[self createLiveCommentorView:c.deviceID index:i]];
    }
    [self.rootLayout layoutIfNeeded];
  });
}

-(void)refreshRemoteCameras
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [remoteCameraLayout removeAllSubviews];
    for (NSInteger i = 0; i < self.remoteCameraSessions.count; i++)
    {
      RemoteCameraSession* c = self.remoteCameraSessions[i];
      [remoteCameraLayout addSubview:[self createRomoteCameraView:c.name index:i preview:c.hostingView]];
      [self.camera setupRemoteVideo:c.canvas];
    }
    [self.rootLayout layoutIfNeeded];
  });
}

-(void)refreshHighlightList
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [highlightLayout removeAllSubviews];
    for (NSInteger i = 0; i < self.HighlightArray.count; i++)
    {
      [highlightLayout addSubview:[self createHighlightViewWithindex:i]];
    }
    [self.rootLayout layoutIfNeeded];
  });
}


-(MyLinearLayout*)createRomoteCameraView:(NSString*)name index:(NSInteger)index preview:(UIView*)preview
{
  MyLinearLayout* cameraView = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  UILabel *namelabel = [self createLabel:name backgroundColor:[CFTool color:5]];
  namelabel.myLeading = 0;
  namelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  namelabel.myHeight = 35;
  [cameraView addSubview:namelabel];
  //UIView *preview = View.border(1, @"3d3d3d");
  preview.myTop = 5;
  preview.myLeading = 0;
  preview.myTrailing = 0;
  preview.myHeight = 200;
  [cameraView addSubview:preview];
  MyFlowLayout *buttonContainer;
  buttonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  buttonContainer.wrapContentHeight = YES;
  buttonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  buttonContainer.subviewHSpace = 5;
  buttonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  buttonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  buttonContainer.myLeading = 0;
  buttonContainer.myTrailing = 0;
  buttonContainer.myTop = 5;
  
  __weak typeof(self) ws = self;
  UIButton* liveButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [self startPushWithType:PUSH_TYPE_REMOTE_CAMERA index:(int)index];
  });
  liveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  liveButton.str(@"推送");
  liveButton.tag = index;
  liveButton.myHeight = 40;
  
  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
   
  });
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"预览");
  smallH264Button.myHeight = 40;
  
  UIButton* stopButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  stopButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  stopButton.str(@"停止");
  stopButton.myHeight = 40;
  
  [buttonContainer addSubview:liveButton];
  [buttonContainer addSubview:smallH264Button];
  [buttonContainer addSubview:stopButton];
  
  [cameraView addSubview:buttonContainer];
  return cameraView;
}

//VideoPlayerDelegate begin
- (void)didPlayAutoCompleted
{
  //[self Toast:@"视频播放完毕"];
}
- (void)didPlayManualStop
{
  //[self Toast:@"视频成功停止播放"];
}
- (void)didVideoOutput:(CMSampleBufferRef)videoData
{
  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(videoData);
  CVPixelBufferLockBaseAddress(pixelBuffer, 0);
  int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
  int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
  Byte* pixel = (Byte*)CVPixelBufferGetBaseAddress(pixelBuffer);
  
  int length = screen_width*screen_height*4;
  for(int i=0;i<bufferHeight;i++){
    Byte* dst = argb_buffer+i*screen_width*4;
    Byte* src = pixel+i*bufferWidth*4;
    memcpy(dst, src, bufferWidth*4);
  }
  NSData* BRGABuffer = [[NSData alloc] initWithBytesNoCopy:argb_buffer length:length freeWhenDone:FALSE];
  CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self.bigStreamDecode postProcess:BRGABuffer width:screen_width height:screen_height];
  });
}

-(void)filePCMDataAfterProcess:(AudioBuffer) buffer
{
  if(self.currentPushType == PUSH_TYPE_FILE_CAMERA){
    [self.FFmpegRtmpclient sendPCMData:(unsigned char*)(buffer.mData) dataLength:buffer.mDataByteSize];
  }
}  //VideoPlayerDelegate end

//audioMixerDelegate
-(void)PCMDataAfterMixer:(AudioBuffer) mixBuffer
{
  if([self.FFmpegRtmpclient isPushing]){
    if(self.currentPushType == PUSH_TYPE_FILE_CAMERA){
      return;
    }
    [self.FFmpegRtmpclient sendPCMData:(unsigned char*)(mixBuffer.mData) dataLength:mixBuffer.mDataByteSize];
  }
}

//h264encodeDelegate
-(void)dataEncodeToH264:(const void*)data length:(size_t)length
{
  
}
-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds
{
  
}
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  
}


//PostProgressDelegate
-(void)dataFromPostProgress:(NSData*)BGRAData frameTime:(CMTime)frameTime
{
  //CMTime t = CMTimeMake(1, 25);
  //timestamp = CMTimeAdd(timestamp, t);
  if(agoraBeginTimestamp == -1){
    agoraBeginTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
  }
  int64_t now = [[NSDate date] timeIntervalSince1970] * 1000;
  int64_t interval = now - agoraBeginTimestamp;
  CMTime timestamp = CMTimeMake(interval, 1000);
  
  /*int width = 1280;
  int height = 720;
  CVPixelBufferLockBaseAddress(pixelBuf, 0);
  //将yuv数据填充到CVPixelBufferRef中
  size_t y_size = width * height;
  size_t uv_size = y_size / 4;
  uint8_t *yuv_frame = (uint8_t *)yuvData.bytes;
  
  //处理y frame
  uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 0);
  memcpy(y_frame, yuv_frame, y_size);
  
  uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 1);
  memcpy(uv_frame, yuv_frame + y_size, uv_size * 2);
  CVPixelBufferUnlockBaseAddress(pixelBuf, 0);*/
  //[self.videoEncode encodeBytes:(Byte*)yuvData.bytes];
  
  [self.FFmpegRtmpclient sendRGBAData:(Byte*)BGRAData.bytes dataLength:(int)BGRAData.length];
  [self.camera pushExternalVideoData:BGRAData timeStamp:timestamp];
}

//LocalWifiNetworkDelegate begin
-(void)broadcastReceived:(LocalWifiNetwork*)network ip:(NSString*)ip
{
 
}

-(void)acceptNewSocket:(LocalWifiNetwork*)network newSocket:(GCDAsyncSocket *)newSocket
{
  /*NSArray *localCameraNames = @[@"全局镜头",
                                  @"左侧镜头",@"右侧镜头",@"篮下镜头",@"篮板镜头",@"持球人镜头",@"球员特写"
                                  ];
  LocalNetClientInfo* c = [[LocalNetClientInfo alloc] init];
  c.socket = newSocket;
  c.deviceID = @"";
  [self.localCameras addObject:c];
  NSUInteger len = [self.localCameras count];
  c.deviceID = localCameraNames[len-1];
  [self refreshLocalCameras];
  [self.audioMixer commentorConnected:c.deviceID];*/
}

- (void)serverSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  //判断是否是本地机位
  for(LocalNetClientInfo* obj in self.localCameras){
    if(obj.socket == sock){
      //判断要断开的连接是否是正在直播的机位
      if(sock == self.cameraOnStandOfLiving.socket){
        self.cameraOnStandOfLiving = nil;
      }
      if(sock == self.cameraOnPreview.socket){
        self.cameraOnPreview = nil;
      }
      [self.localCameras removeObject:obj];
      [self refreshLocalCameras];
      //NSLog(@"remove from connectedSockets:num:%zd",[self.localCameras count]);
      return;
    }
  }
  //判断是否是现场解说
  for(LocalNetClientInfo* obj in self.livecommentors){
    if(obj.socket == sock){
      [self.audioMixer commentorDisconnected:obj.deviceID];
      [obj.audioDecoder stopAACEncodeSession];
      [self.livecommentors removeObject:obj];
      [self refreshLiveCommentors];
      return;
    }
  }
  //判断是否是比赛数据客户端
  if(self.matchDataClient.socket == sock){
    self.matchDataClient.socket = nil;
    self.matchDataClient.deviceID = @"";
    dispatch_async(dispatch_get_main_queue(), ^(){
      matchDataStatusUI.text = @"数据统计客户端断开连接";
    });
    return;
  }
  //判断是否是集锦客户端
  if(self.highlightClient.socket == sock){
    self.highlightClient.socket = nil;
    self.highlightClient.deviceID = @"";
    dispatch_async(dispatch_get_main_queue(), ^(){
      highlightClientStatusUI.text = @"集锦客户端断开连接";
    });
    return;
  }
  
}

-(NSString*)getFrameType:(NSData*)frameData
{
  const Byte* buffer = (Byte*)[frameData bytes];
  int nalType = buffer[0] & 0x1F;
  switch(nalType){
      case 0x05:
        return @"iframe";
      case 0x07:
        return @"sps";
      case 0x08:
        return @"pps";
      default:
        return @"bpframe";
  }
}

-(void)serverReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock
{
  if(packetID == SEND_BIG_H264DATA){
      //收到不含头部的h264帧数据 ，传给解码器进行解码显示
    if(!self.isChangingLocalCamera){
      if(self.currentPushType == PUSH_TYPE_LOCAL_CAMERA){
        if(sock == self.cameraOnStandOfLiving.socket){
          [self.bigStreamDecode decodeH264WithoutHeader:data];
        }
      }else{
        [self.bigStreamDecode decodeH264WithoutHeader:data];
      }
    }else{
      if(sock == self.lastLocalCameraSocket){
        [self.bigStreamDecode decodeH264WithoutHeader:data];
      }else if(sock == self.nextLocalCameraSocket){
        NSString* nalType = [self getFrameType:data];
        if([nalType isEqualToString:@"pps"]){
          self.nextBigPPS = data;
        }else if([nalType isEqualToString:@"sps"]){
          self.nextBigSPS = data;
        }else if([nalType isEqualToString:@"iframe"]){
          if(self.lastLocalCameraSocket){
            [self stopBigVideo:self.lastLocalCameraSocket];
            self.lastLocalCameraSocket = nil;
          }
          [self.bigStreamDecode decodeH264WithoutHeader:self.nextBigSPS];
          [self.bigStreamDecode decodeH264WithoutHeader:self.nextBigPPS];
          [self.bigStreamDecode decodeH264WithoutHeader:data];
          self.nextLocalCameraSocket = nil;
          self.nextBigPPS = nil;
          self.nextBigSPS = nil;
          self.isChangingLocalCamera = false;
        }
      }
    }
  }else if(packetID == SEND_SMALL_H264SDATA){
    LocalNetClientInfo* client = [self getClientInfoOfLocalCameras:sock];
    if(client){
      [client.smallH264Decoder decodeH264WithoutHeader:data];
    }
  }
  else if(packetID == COMMENT_AUDIO){
    LocalNetClientInfo* commentor = [self getClientIDOfLiveCommentors:sock];
    if(commentor){
      uint32_t packetlen = (uint32_t)(data.length+7);
      uint8_t* header = [self addADTStoPacket:packetlen];
      NSData* t = [[NSData alloc] initWithBytes:header length:7];
      NSMutableData* final_result = [[NSMutableData alloc] initWithData:t];
      [final_result appendData:data];
      free(header);
      [commentor.audioDecoder decodeAudioFrame:final_result SocketName:commentor.deviceID];
    }
  }else if(packetID == JSON_MESSAGE){
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err){
      NSLog(@"json解析失败：%@",err);
      return;
    }
    NSString* json_id = dic[@"id"];
    if([json_id isEqualToString:@"localCameraLogin"]){
      LocalNetClientInfo* c = [[LocalNetClientInfo alloc] init];
      NSString* deviceID = dic[@"deviceID"];
      NSString* name = dic[@"name"];
      int type = [[dic valueForKey:@"type"] intValue];
      int subtype = [[dic valueForKey:@"subtype"] intValue];
      int isSlowMotion = [[dic valueForKey:@"isSlowMotion"] boolValue];
      c.socket = sock;
      c.deviceID = deviceID;
      c.name = name;
      c.type = type;
      c.subtype = subtype;
      c.isSlowMotion = isSlowMotion;
      c.smallH264Decoder = [[h264decode alloc] initWithView:nil];
      [self.localCameras addObject:c];
      [self refreshLocalCameras];
    }else if([json_id isEqualToString:@"liveCommentorLogin"]){
      LocalNetClientInfo* c = [[LocalNetClientInfo alloc] init];
      NSString* deviceID = dic[@"deviceID"];
      NSString* name = dic[@"name"];
      int type = [[dic valueForKey:@"type"] intValue];
      int subtype = [[dic valueForKey:@"subtype"] intValue];
      c.socket = sock;
      c.deviceID = deviceID;
      c.name = name;
      c.type = type;
      c.subtype = subtype;
      c.audioDecoder = [[AACDecode alloc] init];
      c.audioDecoder.delegate = self;
      [self.livecommentors addObject:c];
      [self refreshLiveCommentors];
      [self.audioMixer commentorConnected:c.deviceID];
    }else if([json_id isEqualToString:@"matchDataLogin"]){
      NSString* deviceID = dic[@"deviceID"];
      self.matchDataClient.socket = sock;
      self.matchDataClient.deviceID = deviceID;
      dispatch_async(dispatch_get_main_queue(), ^(){
        matchDataStatusUI.text = @"数据统计客户端连接成功";
      });
    }else if([json_id isEqualToString:@"highlightsLogin"]){
      NSString* deviceID = dic[@"deviceID"];
      self.highlightClient.socket = sock;
      self.highlightClient.deviceID = deviceID;
      dispatch_async(dispatch_get_main_queue(), ^(){
        highlightClientStatusUI.text = @"集锦客户端连接成功";
      });
    }else if([json_id isEqualToString:@"uploadDataToDirectServer"]){
      [self.matchData loadMatchData:dic[@"data"]];
      //显示统计数据
      dispatch_async(dispatch_get_main_queue(), ^(){
        [self createMatchDataView:dic[@"data"]];
      });
    }else if([json_id isEqualToString:@"flashBackList"]){
      //[self Toast:@"flashBackList"];
      NSArray* sections = dic[@"sections"];
      if(self.currentFlashback != nil){
        [self.flashbackHistory addObject:self.currentFlashback];
      }
      self.currentFlashback = [[HighlightStruct alloc] init];
      for(int i=0;i<[sections count];i++){
        NSDictionary* t = sections[i];
        HighlightSectionStruct* section = [[HighlightSectionStruct alloc] initWithDeviceID:t[@"deviceId"] isSlowMotion:[t[@"isSlowMotion"] boolValue] beginAbsoluteTimestamp:[t[@"beginAbsoluteTimestamp"] longLongValue] framesLength:[t[@"framesLength"] intValue]];
        [self.currentFlashback.sections addObject:section];
      }
    }else if([json_id isEqualToString:@"highlightList"]){
      //[self Toast:@"highlightList"];
      NSArray* sections = dic[@"sections"];
      NSString* highlightName = dic[@"name"];
      HighlightStruct* singleHighlight = [[HighlightStruct alloc] init];
      singleHighlight.name = highlightName;
      for(int i=0;i<[sections count];i++){
        NSDictionary* t = sections[i];
        HighlightSectionStruct* section = [[HighlightSectionStruct alloc] initWithDeviceID:t[@"deviceId"] isSlowMotion:[t[@"isSlowMotion"] boolValue] beginAbsoluteTimestamp:[t[@"beginAbsoluteTimestamp"] longLongValue] framesLength:[t[@"framesLength"] intValue]];
        [singleHighlight.sections addObject:section];
      }
      [self.HighlightArray addObject:singleHighlight];
      [self refreshHighlightList];
    }else if([json_id isEqualToString:@"getHighlightServerIP"]){
      if(self.highlightClient.socket){
        //集锦服务器处于连接状态
        NSData* address = [self.highlightClient.socket connectedAddress];
        NSString* ip = [GCDAsyncSocket hostFromAddress:address];
        NSDictionary* dict = @{
                               @"id": @"getHighlightServerIP",
                               @"isConnect":@true,
                               @"ip":ip
                               };
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        [self send:sock packetID:JSON_MESSAGE data:jsonData];
      }else{
        //集锦服务器处于失联状态
        NSDictionary* dict = @{
                               @"id": @"getHighlightServerIP",
                               @"isConnect":@false,
                               };
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        [self send:sock packetID:JSON_MESSAGE data:jsonData];
      }
    }else if([json_id isEqualToString:@"getFirstSmallIFramebyAbsoluteTimestamp"] || [json_id isEqualToString:@"getFirstBigIFramebyAbsoluteTimestamp"]){
      int duration = [dic[@"duration"] intValue];
      float second = duration/1000.0;
      if(self.isPlayingFlashBack){
        BOOL isSlowMotion = self.currentFlashback.sections[self.currentPlayingFlashBackSectionIndex].isSlowMotion;
        if(isSlowMotion){
          //如果是慢镜头的话，则按照固定时间请求视频帧
          second = 1.0/24;
        }
        self.currentPlayingFlashBackProgress = 1;
        self.currentPlayingFlashBackFrameIndex = [dic[@"frameIndex"] intValue];
      }else if(self.isPlayingHighlight){
        BOOL isSlowMotion = self.currentPlayingHighlight.sections[self.currentPlayingHighlightSectionIndex].isSlowMotion;
        if(isSlowMotion){
          second = 1.0/24;
        }
        self.currentPlayingHighlightProgress = 1;
        self.currentPlayingHighlightFrameIndex = [dic[@"frameIndex"] intValue];
      }
      self.timeoutTimer = [NSTimer timerWithTimeInterval:second target:self selector:@selector(timerCallBack) userInfo:nil repeats:NO];
      [[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSDefaultRunLoopMode];
    }else if([json_id isEqualToString:@"getNextSmallFrameByFrameIndex"] || [json_id isEqualToString:@"getNextBigFrameByFrameIndex"]){
      int duration = [dic[@"duration"] intValue];
      float second = duration/1000.0;
      if(self.isPlayingFlashBack){
        BOOL isSlowMotion = self.currentFlashback.sections[self.currentPlayingFlashBackSectionIndex].isSlowMotion;
        if(isSlowMotion){
          //如果是慢镜头的话，则按照固定时间请求视频帧
          second = 1.0/24;
        }
        self.currentPlayingFlashBackProgress++;
        self.currentPlayingFlashBackFrameIndex = [dic[@"frameIndex"] intValue];
      }else if(self.isPlayingHighlight){
        BOOL isSlowMotion = self.currentPlayingHighlight.sections[self.currentPlayingHighlightSectionIndex].isSlowMotion;
        if(isSlowMotion){
          second = 1.0/24;
        }
        self.currentPlayingHighlightProgress++;
        self.currentPlayingHighlightFrameIndex = [dic[@"frameIndex"] intValue];
      }
      self.timeoutTimer = [NSTimer timerWithTimeInterval:second target:self selector:@selector(timerCallBack) userInfo:nil repeats:NO];
      [[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSDefaultRunLoopMode];
    }
  }
}

-(void)timerCallBack
{
  [self.timeoutTimer invalidate];
  if(self.isPlayingFlashBack){
    NSString* deviceID = self.currentFlashback.sections[self.currentPlayingFlashBackSectionIndex].deviceID;
    long sectionCount = [self.currentFlashback.sections count];
    GCDAsyncSocket* socket = [self getSocketbyDeviceID:deviceID];
    if(!socket){
      //该片段对应的机位已经离线，则停止回放
      self.isPlayingFlashBack = false;
      [self Toast:@"机位离线，停止回放"];
      return;
    }
    //首先判断是否到达当前片段的结尾
    if(self.currentPlayingFlashBackProgress < self.currentFlashback.sections[self.currentPlayingFlashBackSectionIndex].framesLength){
      //请求下一帧
      if(self.isFlashBackPlayingSmall){
        NSDictionary* dict = @{
                               @"id": @"getNextSmallFrameByFrameIndex",
                               @"frameIndex":[NSNumber numberWithInt:self.currentPlayingFlashBackFrameIndex],
                               };
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        [self send:socket packetID:JSON_MESSAGE data:jsonData];
      }else{
        NSDictionary* dict = @{
                               @"id": @"getNextBigFrameByFrameIndex",
                               @"frameIndex":[NSNumber numberWithInt:self.currentPlayingFlashBackFrameIndex],
                               };
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        [self send:socket packetID:JSON_MESSAGE data:jsonData];
      }
    }else{
      //进入下一个片段
      self.currentPlayingFlashBackSectionIndex++;
      if(self.currentPlayingFlashBackSectionIndex >= sectionCount){
        //所有片段已经播放完毕，停止回放
        self.isPlayingFlashBack = false;
        [self Toast:@"播放完毕"];
      }else{
        NSString* nextDeviceID = self.currentFlashback.sections[self.currentPlayingFlashBackSectionIndex].deviceID;
        GCDAsyncSocket* nextSocket = [self getSocketbyDeviceID:nextDeviceID];
        if(!nextSocket){
          self.isPlayingFlashBack = false;
          [self Toast:@"机位离线，停止回放"];
          return;
        }
        self.currentPlayingFlashBackProgress = 0;
        self.currentPlayingFlashBackFrameIndex = -1;
        if(self.isFlashBackPlayingSmall){
          NSDictionary* dict = @{
                                 @"id": @"getFirstSmallIFramebyAbsoluteTimestamp",
                                 @"timestamp":[NSNumber numberWithLongLong:self.currentFlashback.sections[self.currentPlayingFlashBackSectionIndex].beginAbsoluteTimestamp]
                                 };
          NSError *error;
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
          [self send:nextSocket packetID:JSON_MESSAGE data:jsonData];
        }else{
          NSDictionary* dict = @{
                                 @"id": @"getFirstBigIFramebyAbsoluteTimestamp",
                                 @"timestamp":[NSNumber numberWithLongLong:self.currentFlashback.sections[self.currentPlayingFlashBackSectionIndex].beginAbsoluteTimestamp]
                                 };
          NSError *error;
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
          [self send:nextSocket packetID:JSON_MESSAGE data:jsonData];
        }
      }
    }
  }else if(self.isPlayingHighlight){
    NSString* deviceID = self.currentPlayingHighlight.sections[self.currentPlayingHighlightSectionIndex].deviceID;
    long sectionCount = [self.currentPlayingHighlight.sections count];
    GCDAsyncSocket* socket = [self getSocketbyDeviceID:deviceID];
    if(!socket){
      //该片段对应的机位已经离线，则停止回放
      self.isPlayingHighlight = false;
      [self Toast:@"机位离线，停止回放"];
      return;
    }
    //首先判断是否到达当前片段的结尾
    if(self.currentPlayingHighlightProgress < self.currentPlayingHighlight.sections[self.currentPlayingHighlightSectionIndex].framesLength){
      //请求下一帧
      if(self.isHighlightPlayingSmall){
        NSDictionary* dict = @{
                               @"id": @"getNextSmallFrameByFrameIndex",
                               @"frameIndex":[NSNumber numberWithInt:self.currentPlayingHighlightFrameIndex],
                               };
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        [self send:socket packetID:JSON_MESSAGE data:jsonData];
      }else{
        NSDictionary* dict = @{
                               @"id": @"getNextBigFrameByFrameIndex",
                               @"frameIndex":[NSNumber numberWithInt:self.currentPlayingHighlightFrameIndex],
                               };
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        [self send:socket packetID:JSON_MESSAGE data:jsonData];
      }
    }else{
      //进入下一个片段
      self.currentPlayingHighlightSectionIndex++;
      if(self.currentPlayingHighlightSectionIndex >= sectionCount){
        //所有片段已经播放完毕，停止回放
        self.isPlayingHighlight = false;
        [self Toast:@"播放完毕"];
      }else{
        NSString* nextDeviceID = self.currentPlayingHighlight.sections[self.currentPlayingHighlightSectionIndex].deviceID;
        GCDAsyncSocket* nextSocket = [self getSocketbyDeviceID:nextDeviceID];
        if(!nextSocket){
          self.isPlayingHighlight = false;
          [self Toast:@"机位离线，停止回放"];
          return;
        }
        self.currentPlayingHighlightProgress = 0;
        self.currentPlayingHighlightFrameIndex = -1;
        if(self.isHighlightPlayingSmall){
          NSDictionary* dict = @{
                                 @"id": @"getFirstSmallIFramebyAbsoluteTimestamp",
                                 @"timestamp":[NSNumber numberWithLongLong:self.currentPlayingHighlight.sections[self.currentPlayingHighlightSectionIndex].beginAbsoluteTimestamp]
                                 };
          NSError *error;
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
          [self send:nextSocket packetID:JSON_MESSAGE data:jsonData];
        }else{
          NSDictionary* dict = @{
                                 @"id": @"getFirstBigIFramebyAbsoluteTimestamp",
                                 @"timestamp":[NSNumber numberWithLongLong:self.currentPlayingHighlight.sections[self.currentPlayingHighlightSectionIndex].beginAbsoluteTimestamp]
                                 };
          NSError *error;
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
          [self send:nextSocket packetID:JSON_MESSAGE data:jsonData];
        }
      }
    }
  }
}

//LocalWifiNetworkDelegate end

-(LocalNetClientInfo*)getClientIDOfLiveCommentors:(GCDAsyncSocket*)sock
{
  for(LocalNetClientInfo* obj in self.livecommentors){
    if(obj.socket == sock){
      return obj;
    }
  }
  return nil;
}

-(LocalNetClientInfo*)getClientInfoOfLocalCameras:(GCDAsyncSocket*)sock
{
  for(LocalNetClientInfo* obj in self.localCameras){
    if(obj.socket == sock){
      return obj;
    }
  }
  return nil;
}

-(uint8_t*)addADTStoPacket:(uint32_t)packetlen
{
  uint8_t* header = (uint8_t*)malloc(7);
  uint8_t profile = kMPEG4Object_AAC_LC;
  uint8_t sampleRate = 4;
  uint8_t chanCfg = 1; //单声道
  header[0] = 0xFF;
  header[1] = 0xF9;
  header[2] = (uint8_t)(((profile-1)<<6) + (sampleRate<<2) +(chanCfg>>2));
  header[3] = (uint8_t)(((chanCfg&3)<<6) + (packetlen>>11));
  header[4] = (uint8_t)((packetlen&0x7FF) >> 3);
  header[5] = (uint8_t)(((packetlen&7)<<5) + 0x1F);
  header[6] = (uint8_t)0xFC;
  
  return header;
}

//AACDecodeDelegate
-(void)AACDecodeToPCM:(NSData*)data  SocketName:(NSString*)SocketName;
{
  [self.audioMixer intoAudioData:data ip:SocketName];
}

//agora sdk delegate
- (void)didjoinChannelSuccess
{
  
}
- (void)firstLocalVideoFrameWithSize:(CGSize)size elapsed:(NSInteger)elapsed
{
  
}
- (void)didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
  NSArray *actions = @[@"演播室",
                       @"主播",
                       ];
  UIView *preview = View.border(1, @"3d3d3d");
  RemoteCameraSession* t = [[RemoteCameraSession alloc] initWithView:preview uid:uid];
  [self.remoteCameraSessions addObject:t];
  t.name = actions[self.remoteCameraSessions.count-1];
  [self refreshRemoteCameras];
  
}
- (void)didOfflineOfUid:(NSUInteger)uid reason:(AgoraRtcUserOfflineReason)reason
{
  for(RemoteCameraSession* obj in self.remoteCameraSessions)
  {
    if(obj.uid == uid)
    {
      [self.remoteCameraSessions removeObject:obj];
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
  if(self.currentPushType == PUSH_TYPE_REMOTE_CAMERA){
    if(width == screen_width && height == screen_height){
      if(self.currentLivingRemoteCamera != nil){
        if(uid == self.currentLivingRemoteCamera.uid){
          Byte* argb = (Byte*)malloc(width*height*4);
          libyuv::I420ToARGB((const uint8*)yBuffer,yStride,(const uint8*)uBuffer,uStride,(const uint8*)vBuffer,vStride,argb,yStride*4,width,height);
          NSData* BRGABuffer = [[NSData alloc] initWithBytesNoCopy:argb length:width*height*4];
          dispatch_sync(dispatch_get_main_queue(), ^{
            [self.bigStreamDecode postProcess:BRGABuffer width:width height:height];
          });
        }
      }
    }
  }
}

- (void)onMixedAudioFrame:(void *)buffer length:(int)length
{
  
}
- (void)onPlaybackAudioFrameBeforeMixing:(void *)buffer length:(int)length uid:(int)uid
{
  
}
//agora sdk delegate end

-(MyLinearLayout*)createHighlightViewWithindex:(NSInteger)index
{
  MyLinearLayout* cameraView = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  UILabel *namelabel = [self createLabel:@"集锦名称" backgroundColor:[CFTool color:5]];
  namelabel.myLeading = 0;
  namelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  namelabel.myHeight = 35;
  [cameraView addSubview:namelabel];
  UIView *preview = View.border(1, @"3d3d3d");
  preview.myTop = 5;
  preview.myLeading = 0;
  preview.myTrailing = 0;
  preview.myHeight = 100;
  [cameraView addSubview:preview];
  MyFlowLayout *buttonContainer;
  buttonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  buttonContainer.wrapContentHeight = YES;
  buttonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  buttonContainer.subviewHSpace = 5;
  buttonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  buttonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  buttonContainer.myLeading = 0;
  buttonContainer.myTrailing = 0;
  buttonContainer.myTop = 5;
  
  __weak typeof(self) ws = self;
  UIButton* liveButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    if(ws.currentPushType == PUSH_TYPE_HIGHLIGHT && ws.isPlayingHighlight){
      [ws Toast:@"集锦正在播放"];
      return;
    }
    [self startPushWithType:PUSH_TYPE_HIGHLIGHT index:(int)index];
  });
  liveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  liveButton.str(@"推送");
  liveButton.tag = index;
  liveButton.myHeight = 40;
  
  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick((^(UIButton* btn){
    HighlightStruct* currentSection = ws.HighlightArray[index];
    if(currentSection){
      ws.currentPlayingHighlight = currentSection;
      if([ws.currentPlayingHighlight.sections count] == 0){
        [ws Toast:@"精彩回放片段数量是0"];
        return;
      }
      HighlightSectionStruct* firstSection = ws.currentPlayingHighlight.sections[0];
      NSString* deviceID = ws.currentPlayingHighlight.sections[0].deviceID;
      GCDAsyncSocket* socket = [ws getSocketbyDeviceID:deviceID];
      if(socket == nil){
        [ws Toast:@"片段对应的机位连接已经断开"];
        return;
      }
      [ws.smallStreamDecode setPreview:preview];
      ws.isPlayingHighlight = true;
      ws.isHighlightPlayingSmall = true;
      ws.currentPlayingHighlightSectionIndex = 0;
      NSDictionary* dict = @{
                             @"id": @"getFirstSmallIFramebyAbsoluteTimestamp",
                             @"timestamp":[NSNumber numberWithLongLong:firstSection.beginAbsoluteTimestamp]
                             };
      NSError *error;
      NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
      [ws send:socket packetID:JSON_MESSAGE data:jsonData];
    }
  }));
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"预览");
  smallH264Button.myHeight = 40;
  
  UIButton* uiButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  uiButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  uiButton.str(@"UI");
  uiButton.myHeight = 40;
  
  [buttonContainer addSubview:liveButton];
  [buttonContainer addSubview:smallH264Button];
  [buttonContainer addSubview:uiButton];
  
  [cameraView addSubview:buttonContainer];
  return cameraView;
}

-(MyLinearLayout*)createFileViewWithindex:(NSInteger)index
{
  NSString* filename = self.files[index][@"name"];
  NSString* extension = self.files[index][@"extention"];
  MyLinearLayout* cameraView = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  UILabel *namelabel = [self createLabel:filename backgroundColor:[CFTool color:5]];
  namelabel.myLeading = 0;
  namelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  namelabel.myHeight = 35;
  [cameraView addSubview:namelabel];
  UIView *preview = View.border(1, @"3d3d3d");
  preview.myTop = 5;
  preview.myLeading = 0;
  preview.myTrailing = 0;
  preview.myHeight = 100;
  [cameraView addSubview:preview];
  MyFlowLayout *buttonContainer;
  buttonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  buttonContainer.wrapContentHeight = YES;
  buttonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  buttonContainer.subviewHSpace = 5;
  buttonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  buttonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  buttonContainer.myLeading = 0;
  buttonContainer.myTrailing = 0;
  buttonContainer.myTop = 5;
  
  __weak typeof(self) ws = self;
  UIButton* liveButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [self startPushWithType:PUSH_TYPE_FILE_CAMERA index:(int)index];
  });
  liveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  liveButton.str(@"推送");
  liveButton.tag = index;
  liveButton.myHeight = 40;
  
  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    if(self.currentPushType == PUSH_TYPE_FILE_CAMERA){
      return;
    }
    if(![self.filePlayer isStop]){
      //[self.filePlayer stop];
      //[self Toast:@"请停止正在播放的视频"];
      return;
    }
    [self.filePlayer startPreview:filename fileExtension:extension view:preview];
  });
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"预览");
  smallH264Button.myHeight = 40;
  
  UIButton* stopButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    if(![self.filePlayer isStop]){
      [self.filePlayer stop];
    }
  });
  stopButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  stopButton.str(@"停止");
  stopButton.myHeight = 40;
  
  [buttonContainer addSubview:liveButton];
  [buttonContainer addSubview:smallH264Button];
  [buttonContainer addSubview:stopButton];

  [cameraView addSubview:buttonContainer];
  return cameraView;
}

-(MyLinearLayout*)createLocalCameraView:(NSString*)name index:(NSInteger)index
{
  MyLinearLayout* cameraView = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  UILabel *namelabel = [self createLabel:name backgroundColor:[CFTool color:5]];
  namelabel.myLeading = 0;
  namelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  namelabel.myHeight = 35;
  [cameraView addSubview:namelabel];
  UIView *preview = View.border(1, @"3d3d3d");
  preview.myTop = 5;
  preview.myLeading = 0;
  preview.myTrailing = 0;
  preview.myHeight = 100;
  [cameraView addSubview:preview];
  MyFlowLayout *buttonContainer;
  buttonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  buttonContainer.wrapContentHeight = YES;
  buttonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  buttonContainer.subviewHSpace = 5;
  buttonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  buttonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  buttonContainer.myLeading = 0;
  buttonContainer.myTrailing = 0;
  buttonContainer.myTop = 5;
  
  __weak typeof(self) ws = self;
  UIButton* liveButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [self startPushWithType:PUSH_TYPE_LOCAL_CAMERA index:(int)index];
  });
  liveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  liveButton.str(@"直播");
  liveButton.tag = index;
  liveButton.myHeight = 40;

  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    LocalNetClientInfo* currentPreview = ws.localCameras[index];
    if(currentPreview.isPreviewing){
      return;
    }
    /*if(currentPreview == ws.cameraOnPreview){
      return;
    }else{
      if(ws.cameraOnPreview){
        [ws stopSmallVideo:ws.cameraOnPreview.socket];
      }
    }
    //切换预览的机位
    ws.cameraOnPreview = currentPreview;*/
    [ws startSmallVideo:currentPreview.socket];
    //[self.smallStreamDecode setPreview:preview];
    [currentPreview.smallH264Decoder setPreview:preview];
    currentPreview.isPreviewing = true;
  });
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"预览");
  smallH264Button.myHeight = 40;
  
  UIButton* beforeButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    LocalNetClientInfo* currentPreview = ws.localCameras[index];
    if(!currentPreview.isPreviewing){
      return;
    }
    [ws stopSmallVideo:currentPreview.socket];
    currentPreview.isPreviewing = false;
  });
  beforeButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  beforeButton.str(@"停止");
  beforeButton.myHeight = 40;
  [buttonContainer addSubview:liveButton];
  [buttonContainer addSubview:smallH264Button];
  [buttonContainer addSubview:beforeButton];
  [cameraView addSubview:buttonContainer];
  return cameraView;
}

-(MyLinearLayout*)createLiveCommentorView:(NSString*)name index:(NSInteger)index
{
  MyLinearLayout* commentorView = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  UILabel *namelabel = [self createLabel:name backgroundColor:[CFTool color:5]];
  namelabel.myLeading = 0;
  namelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  namelabel.myHeight = 35;
  [commentorView addSubview:namelabel];
  UIView *preview = View.border(1, @"3d3d3d");
  preview.myTop = 5;
  preview.myLeading = 0;
  preview.myTrailing = 0;
  preview.myHeight = 100;
  [commentorView addSubview:preview];
  MyFlowLayout *buttonContainer;
  buttonContainer = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  buttonContainer.wrapContentHeight = YES;
  buttonContainer.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  buttonContainer.subviewHSpace = 5;
  buttonContainer.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  buttonContainer.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  buttonContainer.myLeading = 0;
  buttonContainer.myTrailing = 0;
  buttonContainer.myTop = 5;
  
  __weak typeof(self) ws = self;
  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    
  });
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"静音");
  smallH264Button.myHeight = 40;
  
  UIButton* beforeButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3);
  beforeButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  beforeButton.str(@"音量调整");
  beforeButton.myHeight = 40;
  [buttonContainer addSubview:smallH264Button];
  [buttonContainer addSubview:beforeButton];
  [commentorView addSubview:buttonContainer];
  return commentorView;
}

-(UILabel*)createSectionLabel:(NSString*)title
{
  UILabel *sectionLabel = [UILabel new];
  sectionLabel.text = title;
  sectionLabel.font = [CFTool font:17];
  [sectionLabel sizeToFit];             //sizeToFit函数的意思是让视图的尺寸刚好包裹其内容。注意sizeToFit方法必要在设置字体、文字后调用才正确。
  return sectionLabel;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
