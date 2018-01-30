//
//  LocalNetworkViewController.m
//  sportdream
//
//  Created by lili on 2017/10/7.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "LocalNetworkViewController.h"
#import "NerdyUI.h"
#import "MyLayout.h"
#import "MBProgressHUD.h"

@interface LocalNetworkViewController ()
@property (nonatomic,strong) CameraRecord* record;
@property (nonatomic,strong) mp4Push* fileplay;
@property (nonatomic,strong) h264encode* encode;
@property (nonatomic,strong) LocalWifiNetwork*  network;
@end

@implementation LocalNetworkViewController
{
  BOOL startEncode;
  FILE *_h264File;
  MBProgressHUD * HUD;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
  startEncode = false;
  NSString* documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  _h264File = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,@"testmodule.h264"] UTF8String], "ab+");
  //UI
  MyFrameLayout *rootLayout = [MyFrameLayout new];
  rootLayout.backgroundColor = [UIColor whiteColor];
  //rootLayout.insetsPaddingFromSafeArea = ~UIRectEdgeBottom;
  self.view = rootLayout;
  
  UIView* preview = [[UIView alloc] init];
  preview.widthSize.equalTo(rootLayout.widthSize);
  preview.heightSize.equalTo(rootLayout.heightSize);
  [rootLayout addSubview:preview];
  
  int width = 1280;
  int height = 720;
  self.record = [[CameraRecord alloc] initWithPreview:preview width:width height:height];
  self.record.delegate = self;
  self.encode = [[h264encode alloc] initEncodeWith:width height:height framerate:25 bitrate:1600*1000];
  self.encode.delegate = self;
  [self.encode startH264EncodeSession];
  [self.record startCapture];
  
  //标题栏
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
  UILabel     *_iapLabel = Label.fnt(9).color(@"darkGray").lines(2).str(@"导播系统");
  HorStack(
           _actionButton,
           @10,
           _iapLabel,
           ).embedIn(view1, 10, 10, 10, 15);
  //工具栏
  UIView *toolbar = View.wh(screen_width, 50).bgColor(@"red").opacity(0.7).border(3, @"3d3d3d");
  toolbar.myTop = 90;
  toolbar.myLeading = 0;
  rootLayout.addChild(toolbar);
  
  UIButton* clientButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    self.network = [[LocalWifiNetwork alloc] initWithType:false];
    self.network.delegate = self;
    [self.network searchDirectorServer];
  });
  clientButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  clientButton.str(@"客户端");
  
  UIButton* serverButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    self.network = [[LocalWifiNetwork alloc] initWithType:true];
    self.network.delegate = self;
  });
  serverButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  serverButton.str(@"服务器");
  
  HorStack(
           clientButton,
           @30,
           serverButton,
           ).embedIn(toolbar, 10, 10, 10, 15);
  
  UIButton* testpacket = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    NSString *welcomeMsg = @"hello";
    NSData *info =[welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    [self.network clientSendPacket:1 data:info];
  });
  testpacket.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  testpacket.str(@"发送");
  UIView *view3 = View.wh(screen_width, 50).bgColor(@"red").opacity(0.7).border(3, @"3d3d3d");
  view3.myTop = 150;
  view3.myLeading = 0;
  rootLayout.addChild(view3);
  testpacket.embedIn(view3, 10,10,10,15);
  
  //self.fileplay = [[mp4Push alloc] initWithPreview:self.view fileName:@"luckydag" fileExtension:@"mov"];
  //[self.fileplay startPush];
}

-(void)dealloc
{
  [self.record stopCapture];
  fclose(_h264File);
  [self.encode stopH264EncodeSession];
}

-(void)captureOutput:(NSData*)sampleBuffer frameTime:(CMTime)frameTime
{
  if(startEncode){
    [self.encode encodeH264Frame:sampleBuffer];
  }
}

-(void)dataEncodeToH264:(const void*)data length:(size_t)length;
{
  [self writeH264Data:data length:length];
}

//h264数据存入文件
-(void)writeH264Data:(const void*)data length:(size_t)length
{
  const Byte bytes[] = "\x00\x00\x00\x01";
  //本地存储
  if(_h264File){
    fwrite(bytes, 1, 4, _h264File);
    fwrite(data, 1, length, _h264File);
  }else{
    NSLog(@"_h264File null error, check if it open successed");
  }
}

-(void)serverDiscovered:(NSString*)ip
{
  //[self Toast:ip];
}

-(void)broadcastReceived:(NSString*)ip
{
  //[self Toast:ip];
}

-(void)acceptNewSocket:(GCDAsyncSocket *)newSocket
{
  NSString* ip = [newSocket connectedHost];
  NSString* info = [[NSString alloc]initWithFormat:@"新连接：%@",ip];
  [self Toast:info];
}
-(void)clientSocketConnected
{
  [self Toast:@"导播服务器连接成功"];
}
- (void)serverSocketDisconnect:(GCDAsyncSocket *)sock
{
  NSString* info = [[NSString alloc]initWithFormat:@"连接断开"];
  [self Toast:info];
}
- (void)clientSocketDisconnect:(GCDAsyncSocket *)sock
{
  [self Toast:@"导播服务器断开连接"];
}

-(void)clientReceiveData:(uint16_t)packetID data:(NSData*)data
{
  NSString *aStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [self Toast:aStr];
}
-(void)serverReceiveData:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock
{
  NSString *aStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  [self Toast:aStr];
  if(packetID == 1){
    NSString *welcomeMsg = @"welcome";
    NSData *info =[welcomeMsg dataUsingEncoding:NSUTF8StringEncoding];
    [self.network serverSendPacket:2 data:info sock:sock];
  }
}

-(void) Toast:(NSString*)str
{
  dispatch_async(dispatch_get_main_queue(), ^(){
    //初始化进度框，置于当前的View当中
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
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
      HUD = nil;
    }];
  });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
