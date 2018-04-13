//
//  CommentatorsViewController.m
//  sportdream
//
//  Created by lili on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CommentatorsViewController.h"
#import "MyLayout.h"
#import "CFTool.h"
#import "NerdyUI.h"
#import "RemoteCameraSession.h"

@interface CommentatorsViewController ()
@property (nonatomic,strong) AgoraKitRemoteCamera* camera;
@property (nonatomic,strong) NSMutableArray<RemoteCameraSession*>* sessions;
@property (nonatomic,strong) MyLinearLayout* rootLayout;
@property (nonatomic,strong) MyFlowLayout *actionLayout;
@property (nonatomic,strong) NSString* channelName;
@end

@implementation CommentatorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  backButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  backButton.str(@"BACK");
  backButton.embedIn(titlebar, UIEdgeInsetsMake(10, 10, 10, 10));
  
  UILabel *livelabel = [self createLabel:NSLocalizedString(@"本地画面", @"") backgroundColor:[CFTool color:1]];
  livelabel.myLeading = 0;
  livelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  livelabel.myHeight = 35;
  [self.rootLayout addSubview:livelabel];
  UIView* liveView = View.border(1, @"3d3d3d");
  liveView.myTop = 5;
  liveView.myBottom = 5;
  liveView.myLeading = 0;
  liveView.myTrailing = 0;
  liveView.myHeight = 200;
  [self.rootLayout addSubview:liveView];
  
  //远程画面开始
  UILabel *remotelabel = [self createLabel:NSLocalizedString(@"远程画面", @"") backgroundColor:[CFTool color:6]];
  remotelabel.myLeading = 0;
  remotelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  remotelabel.myHeight = 35;
  [self.rootLayout addSubview:remotelabel];
  
  self.actionLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:1];
  self.actionLayout.wrapContentHeight = YES;
  self.actionLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  self.actionLayout.subviewHSpace = 5;
  self.actionLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  self.actionLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  self.actionLayout.myLeading = 0;
  self.actionLayout.myTrailing = 0;
  [self.rootLayout addSubview:self.actionLayout];
  
  self.channelName = @"mangguo";
  self.camera = [[AgoraKitRemoteCamera alloc] initWithChannelName:self.channelName useExternalVideoSource:false localView:liveView];
  self.camera.delegate = self;
  [self.camera joinChannel];
  self.sessions = [[NSMutableArray alloc] init];
}

-(void)dealloc
{
  
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
  return cameraView;
}

//delegate
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

- (void)addAudioBuffer:(void *)buffer length:(int)length
{
  
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
