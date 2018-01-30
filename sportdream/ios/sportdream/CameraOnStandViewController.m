//
//  CameraOnStandViewController.m
//  sportdream
//
//  Created by lili on 2018/1/9.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "CameraOnStandViewController.h"
#import "MyLayout.h"
#import "NerdyUI.h"
#import "h264CacheQueue.h"

@interface CameraOnStandViewController ()
@property (nonatomic,strong) CameraSlowMotionRecord* record;
@property (nonatomic,strong) h264encode* encode;
@property (nonatomic,strong) h264CacheQueue* cacheQueue;
@property (nonatomic,strong) UIView* containerpreview;
@property (nonatomic,strong) UILabel* info;
@end

@implementation CameraOnStandViewController
{
  FILE *_h264File;
  int framecount;
}
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
  
  self.info = [UILabel new];
  self.info.text = @"帧数：00000";
  [self.info sizeToFit];
  self.info.centerXPos.equalTo(@0);
  self.info.centerYPos.equalTo(@(1/6.0)).offset(self.info.frame.size.height / 2); //对于框架布局来说中心点偏移也可以设置为相对偏移。
  [rootLayout addSubview:self.info];
  
  framecount = 0;
  
  //初始化编码器
  self.encode = [[h264encode alloc] initEncodeWith:1280 height:720 framerate:25 bitrate:1600*1000];
  self.encode.delegate = self;
  //初始化缓存队列
  self.cacheQueue = [[h264CacheQueue alloc] init];
}

//CameraSlowMotionRecordDelegate
-(void)captureOutput:(CMSampleBufferRef)sampleBuffer
{
  framecount++;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.info.text = [NSString stringWithFormat:@"帧数：%d",framecount];
  });
  [self.encode encodeCMSampleBuffer:sampleBuffer];
}

//h264encodeDelegate
-(void)dataEncodeToH264:(const void*)data length:(size_t)length
{
  [self writeH264Data:data length:length];
}

-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen
{
  [self.cacheQueue setBigSPSPPS:pps ppsLen:ppsLen sps:sps spsLen:spsLen];
}
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame
{
  [self.cacheQueue enterBigH264:data length:length isKeyFrame:isKeyFrame];
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

-(void)viewWillAppear:(BOOL)animated
{
  NSString* documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  _h264File = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,@"SlowMotion2.h264"] UTF8String], "ab+");
  [self.encode startH264EncodeSession];
}

-(void)viewDidAppear:(BOOL)animated
{
  //初始化录制模块
  self.record = [[CameraSlowMotionRecord alloc] initWithPreview:self.containerpreview isSlowMotion:false];
  self.record.delegate = self;
  [self.record startCapture];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [self.record stopCapture];
  [self.encode stopH264EncodeSession];
  fclose(_h264File);
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
