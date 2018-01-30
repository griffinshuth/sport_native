//
//  ARCameraViewController.m
//  sportdream
//
//  Created by lili on 2017/12/19.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "ARCameraViewController.h"
#import "MyLayout.h"
#import "VideoChatAndPush.h"
#import "NerdyUI.h"
#import "LivePusher.h"


@interface ARCameraViewController ()
@property (nonatomic,strong) VideoChatAndPush* videoChat;
@property (nonatomic,assign) BOOL isPushing;
@property (nonatomic,strong) CameraRecord* record;
@end

@implementation ARCameraViewController
{
  CVPixelBufferRef pixelBuf;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  int width = 1280;
  int height = 720;
  CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuf);
  self.isPushing = false;
  MyFrameLayout *rootLayout = [MyFrameLayout new];
  rootLayout.backgroundColor = [UIColor whiteColor];
  rootLayout.insetsPaddingFromSafeArea = ~UIRectEdgeBottom;
  self.view = rootLayout;
  
  UIView* containerpreview = [[UIView alloc] init];
  containerpreview.widthSize.equalTo(rootLayout.widthSize);
  containerpreview.heightSize.equalTo(rootLayout.heightSize);
  [rootLayout addSubview:containerpreview];
  
  UIView* externalPreview = [[UIView alloc] init];
  self.record = [[CameraRecord alloc] initWithPreview:externalPreview width:width height:height];
  self.record.delegate = self;
  self.videoChat = [[VideoChatAndPush alloc] initWithChannelName:@"mangguo" isBroadcaster:true view:containerpreview useExternalVideoSource:true externalPreview:externalPreview];
  [self.record startCapture];
  
  CGFloat screen_width = CGRectGetWidth([UIScreen mainScreen].bounds);
  UIView *view1 = View.wh(screen_width, 50).bgColor(@"red").opacity(0.7).border(3, @"3d3d3d");
  view1.myTop = 30;
  view1.myLeading = 0;
  rootLayout.addChild(view1);
  //view1.topPos.equalTo(self.topLayoutGuide).offset(10);
  UIButton* _actionButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  _actionButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  _actionButton.str(@"BACK");
  UILabel     *_iapLabel = Label.fnt(9).color(@"darkGray").lines(2).str(@"直播系统");
  UIButton* pushButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3);
  pushButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  pushButton.str(@"开始推送");
  HorStack(
           _actionButton,
           @10,
           _iapLabel,
           @10,
           pushButton
           ).embedIn(view1, 10, 10, 10, 15);
  pushButton.onClick(^(UIButton* btn){
    if(!self.isPushing){
      [LivePusher start];
      pushButton.str(@"结束推送");
      self.isPushing = true;
    }else{
      [LivePusher stop];
      pushButton.str(@"开始推送");
      self.isPushing = false;
    }
  });
}

//CameraRecordDelegate
-(void)captureOutput:(NSData*)yuvData frameTime:(CMTime)frameTime
{
  CMTime timestamp = kCMTimeZero;
  int width = 1280;
  int height = 720;
  CVPixelBufferLockBaseAddress(pixelBuf, 0);
  //将yuv数据填充到CVPixelBufferRef中
  size_t y_size = width * height;
  size_t uv_size = y_size / 4;
  uint8_t *yuv_frame = (uint8_t *)yuvData.bytes;
  
  //处理y frame
  uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 0);
  memcpy(y_frame, yuv_frame, y_size);
  
  uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 1);
  memcpy(uv_frame, yuv_frame + y_size, uv_size * 2);
  CVPixelBufferUnlockBaseAddress(pixelBuf, 0);
  [self.videoChat pushExternalVideoData:pixelBuf timeStamp:frameTime];
}

-(void)dealloc
{
  [self.record stopCapture];
  if(self.isPushing){
    [LivePusher stop];
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
