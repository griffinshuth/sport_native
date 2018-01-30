//
//  LiveCommentatorsViewController.m
//  sportdream
//
//  Created by lili on 2018/1/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "LiveCommentatorsViewController.h"
#import "MyLayout.h"
#import "NerdyUI.h"
#import "PacketID.h"

@interface LiveCommentatorsViewController ()
@property (nonatomic,strong) UIView* containerpreview;
@property (nonatomic,strong) AudioRecord* audioRecord;
@property (nonatomic,strong) AACEncode* encode;
@property (nonatomic,strong) LocalWifiNetwork* network;
@end

@implementation LiveCommentatorsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  MyFrameLayout* rootLayout = [MyFrameLayout new];
  rootLayout.backgroundColor = [UIColor whiteColor];
  self.view = rootLayout;
  self.containerpreview = [[UIView alloc] init];
  self.containerpreview.widthSize.equalTo(rootLayout.widthSize);
  self.containerpreview.heightSize.equalTo(rootLayout.heightSize);
  [rootLayout addSubview:self.containerpreview];
  
  UIView *backView = View.wh(40,40).bgColor(@"blue,0.7").borderRadius(20).shadow(0.8).onClick(^{
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  ImageView.img(@"btn_camera_cancel_a").embedIn(backView).centerMode;
  
  backView.myTop = 20;
  backView.myTrailing = 10;
  [rootLayout addSubview:backView];
  
  //初始化功能模块和委托
  self.audioRecord = [[AudioRecord alloc] init];
  self.audioRecord.delegate = self;
  self.encode = [[AACEncode alloc] init];
  self.encode.delegate = self;
  self.network = [[LocalWifiNetwork alloc] initWithType:false];
  self.network.delegate = self;
  [self.network searchDirectorServer];
  
  [self.encode startAACEncodeSession];
  [self.audioRecord startCapture];
}

-(void)captureAudioOutput:(CMSampleBufferRef)sampleBuffer
{
  [self.encode encodeCMSampleBufferPCMData:sampleBuffer];
}

-(void)dataEncodeToAAC:(NSData*)data
{
  [self send:COMMENT_AUDIO data:data];
}

-(void)serverDiscovered:(NSString*)ip
{
  
}
-(void)clientSocketConnected
{
  
}
- (void)clientSocketDisconnect:(GCDAsyncSocket *)sock
{
  
}
-(void)clientReceiveData:(uint16_t)packetID data:(NSData*)data
{
  
}

-(void)send:(uint16_t)packetID data:(NSData*)data
{
  [self.network clientSendPacket:packetID data:data];
}

-(void)dealloc
{
  [self.audioRecord stopCapture];
  [self.encode stopAACEncodeSession];
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
