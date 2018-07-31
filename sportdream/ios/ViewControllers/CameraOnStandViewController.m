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
#import "PacketID.h"
#import "libyuv.h"
#import <Orientation.h>

const int highlight_tcp_port = 4002;
const int highlight_udp_port = 5002;

@implementation H264FrameMetaData
-(id)init
{
  self = [super init];
  if(self){
    self.type = -1;  //帧类型：1代表pps,2 代表sps,3代表I帧，4代表P帧
    self.absoluteTime = -1;  //绝对时间
    self.relativeTime = -1;      //相对时间
    self.frameIndex = -1;        //第几帧
    self.IFrameIndex = -1;       //p帧对应的I帧位置
    self.position = -1;          //该帧在文件中的位置，字节为单位
    self.length = 0;            //该帧的长度，字节为单位
    self.duration = 0;       //该帧持续时间，毫秒为单位，每一段的第一个I帧持续时间是0
  }
  return self;
}

+(int)size
{
  /*return sizeof(self.type)+sizeof(self.absoluteTime)+sizeof(self.relativeTime)
  +sizeof(self.frameIndex)+sizeof(self.IFrameIndex)+sizeof(self.position)
  +sizeof(self.length)+sizeof(self.duration);*/
  
  return sizeof(int8_t)+sizeof(int64_t)+sizeof(int32_t)
  +sizeof(int32_t)+sizeof(int32_t)+sizeof(int64_t)
  +sizeof(int32_t)+sizeof(int16_t);
}
@end

@interface CameraOnStandViewController ()
@property (nonatomic,strong) CameraSlowMotionRecord* record;
@property (nonatomic,strong) h264encode* encode;
@property (nonatomic,strong) h264encode* smallEncode;
@property (nonatomic,strong) NSMutableArray<H264FrameMetaData*>* metaBigData;
@property (nonatomic,strong) NSMutableArray<H264FrameMetaData*>* metaSmallData;
@property (nonatomic,strong) LocalWifiNetwork* localClient;
@property (nonatomic,strong) LocalWifiNetwork* highlightClient;
//@property (nonatomic,strong) h264CacheQueue* cacheQueue;

@property (nonatomic,strong) UIView* containerpreview;
@property (nonatomic,strong) UILabel* info;
@property (nonatomic,strong) UILabel* timeInfo;
@property (nonatomic,strong) UIButton* highlightButton;
@property (nonatomic,strong) UIButton* directorButton;
@property (nonatomic,strong) NSString* filename;
@end

@implementation CameraOnStandViewController
{
  NSString* _h264BigFileName;
  NSString* _h264SmallFileName;
  NSString* _metaBigFileName;
  NSString* _metaSmallFileName;
  
  FILE *_h264BigFile;
  FILE *_h264SmallFile;
  FILE *_metaBigFile;
  FILE *_metaSmallFile;
  
  NSFileHandle *mSmallVideoFileHandle;
  
  //导播服务器状态
  BOOL canSendBigH264;
  BOOL canSendSmallH264;
  BOOL isDirectServerConnected;
  //集锦服务器状态
  BOOL canSendHighlightH264;
  BOOL isHighlightServerConnected;
  //sps pps
  NSData* mHighlightSPS;
  NSData* mHighlightPPS;
  NSData* mDirectServerBigSPS;
  NSData* mDirectServerBigPPS;
  NSData* mDirectServerSmallSPS;
  NSData* mDirectServerSmallPPS;
  
  int mCaptureFrameCount;                    //采集的总帧数
  int64_t beginCaptureTimestamp;       //获得第一帧时的时间戳
  int mBigFrameCount;               //编码的大流帧数
  int mSmallFrameCount;             //编码的小流帧数
  int lastBigIFrameIndex;               //上一个大流I帧的索引
  int lastSmallIFrameIndex;             //上一个小流I帧的索引
  int64_t currentBigFileLength;             //当前大流视频文件大小，以字节为单位
  int64_t currentSmallFileLength;           //当前小流视频文件大小，以字节为单位
  int64_t mInitBigRelativeTime;      //以第一个大流I帧的绝对编码时间为初始值
  int64_t mInitSmallRelativeTime;     //以第一个小流I帧的绝对编码时间为初始值
  int     mlastBigFrameRelativeTime;   //上一帧的相对时间
  int     mlastSmallFrameRelativeTime;  //上一帧的相对时间
}

-(void)highlightButtonEvent:(id)sender
{
  if(isHighlightServerConnected){
    return;
  }
  NSDictionary* dict = @{
                         @"id": @"getHighlightServerIP",
                         };
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
  [self.localClient clientSendPacket:JSON_MESSAGE data:jsonData];
}

-(void)directerButtonEvent:(id)sender
{
  if(isDirectServerConnected){
    return;
  }
  [self.localClient searchDirectorServer];
}

-(void)handlePinch:(UIPinchGestureRecognizer*)recognizer
{
  float scale = recognizer.scale;
  [self.record zoom:scale];
  recognizer.scale = 1;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [Orientation setOrientation:UIInterfaceOrientationMaskLandscapeLeft];
  self.filename = [NSString stringWithFormat:@"Camera_%d_%@_%@",self.mRoomID,self.mDeviceID,self.mCameraName];
  
  NSString* documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  _h264BigFileName = [NSString stringWithFormat:@"%@_big.h264",self.filename];
  _h264SmallFileName = [NSString stringWithFormat:@"%@_small.h264",self.filename];
  _metaBigFileName = [NSString stringWithFormat:@"%@_big.meta",self.filename];
  _metaSmallFileName = [NSString stringWithFormat:@"%@_small.meta",self.filename];
  _h264BigFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_h264BigFileName] UTF8String], "ab+");
  _h264SmallFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_h264SmallFileName] UTF8String], "ab+");
  _metaBigFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_metaBigFileName] UTF8String], "ab+");
  _metaSmallFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_metaSmallFileName] UTF8String], "ab+");
  
  mSmallVideoFileHandle = [NSFileHandle fileHandleForReadingAtPath:[NSString stringWithFormat:@"%@/%@",documentDictionary,_h264SmallFileName]];
    // Do any additional setup after loading the view.
  MyFrameLayout* rootLayout = [MyFrameLayout new];
  rootLayout.backgroundColor = [UIColor whiteColor];
  self.view = rootLayout;
  int screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
  int screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
  self.containerpreview = [[UIView alloc] init];
  //self.containerpreview.widthSize.equalTo(rootLayout.widthSize);
  //self.containerpreview.heightSize.equalTo(rootLayout.heightSize);
  self.containerpreview.myWidth = screenHeight;
  self.containerpreview.myHeight =screenWidth;
  [rootLayout addSubview:self.containerpreview];
  
  UIView *backView = View.wh(40,40).bgColor(@"blue,0.7").borderRadius(20).shadow(0.8).onClick(^{
    [Orientation setOrientation:UIInterfaceOrientationMaskPortrait];
    //[[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
    [self dismissViewControllerAnimated:YES completion:nil];
  });
  ImageView.img(@"btn_camera_cancel_a").embedIn(backView).centerMode;
  
  backView.myTop = 20;
  backView.myTrailing = 10;
  [rootLayout addSubview:backView];
  
  self.info = [UILabel new];
  self.info.text = @"采集的帧数：00000000000";
  [self.info sizeToFit];
  self.info.centerXPos.equalTo(@0);
  self.info.centerYPos.equalTo(@(1/6.0)).offset(self.info.frame.size.height / 2); //对于框架布局来说中心点偏移也可以设置为相对偏移。
  [rootLayout addSubview:self.info];
  
  self.timeInfo = [UILabel new];
  self.timeInfo.text = @"持续时间：000000000000000";
  [self.timeInfo sizeToFit];
  self.timeInfo.myTop = 80;
  [rootLayout addSubview:self.timeInfo];
  
  self.highlightButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3);
  self.highlightButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  self.highlightButton.str(@"集锦服务器没有连接");
  self.highlightButton.myHeight = 30;
  self.highlightButton.myWidth = 200;
  self.highlightButton.myTop = 30;
  self.highlightButton.myLeading = 10;
  [self.highlightButton addTarget:self action:@selector(highlightButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [rootLayout addSubview:self.highlightButton];
  
  self.directorButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3);
  self.directorButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  self.directorButton.str(@"导播服务器没有连接");
  self.directorButton.myHeight = 30;
  self.directorButton.myWidth = 200;
  self.directorButton.myTop = 30;
  self.directorButton.myLeading = 220;
  [self.directorButton addTarget:self action:@selector(directerButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
  [rootLayout addSubview:self.directorButton];
  
  UIPinchGestureRecognizer* pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
  [self.view addGestureRecognizer:pinchGestureRecognizer];
  mCaptureFrameCount = 0;
  beginCaptureTimestamp = 0;
  mBigFrameCount = 0;               //编码的大流帧数
  mSmallFrameCount = 0;             //编码的小流帧数
  currentBigFileLength = 0;             //当前大流视频文件大小
  currentSmallFileLength = 0;           //当前小流视频文件大小
  
  //初始化编码器
  self.encode = [[h264encode alloc] initEncodeWith:1280 height:720 framerate:25 bitrate:1600*1000];
  self.encode.delegate = self;
  self.smallEncode = [[h264encode alloc] initSmallEncodeWith:320 height:180 framerate:25 bitrate:160 * 1000];
  self.smallEncode.delegate = self;
  //初始化缓存队列
  //self.cacheQueue = [[h264CacheQueue alloc] init];
  
  //导播服务器
  self.localClient = [[LocalWifiNetwork alloc] initWithType:false];
  self.localClient.delegate = self;
  [self.localClient searchDirectorServer];
  canSendBigH264 = false;
  canSendSmallH264 = false;
  isDirectServerConnected = false;
  
  //集锦服务器
  self.highlightClient = [[LocalWifiNetwork alloc] initClientWithUdpPort:highlight_udp_port TcpPort:highlight_tcp_port];
  self.highlightClient.delegate = self;
  isHighlightServerConnected = false;
  canSendHighlightH264 = false;
  if(self.highlightIP != nil){
    [self.highlightClient connectServerByIP:self.highlightIP];
  }
  
  self.metaBigData = [[NSMutableArray alloc] init];
  self.metaSmallData = [[NSMutableArray alloc] init];
  
  //从文件系统读取大流元数据
  fseek(_metaBigFile,0L,SEEK_END); /* 定位到文件末尾 */
  long biglen=ftell(_metaBigFile); /* 得到文件大小 */
  //读取大流视频文件大小
  fseek(_h264BigFile,0L,SEEK_END); /* 定位到文件末尾 */
  long bigvideolen=ftell(_h264BigFile); /* 得到文件大小 */
  if(biglen>0){
    fseek(_metaBigFile,0L,SEEK_SET); /* 定位到文件开头 */
    uint8_t* bigBuffer = (uint8_t*)malloc(biglen);
    fread(bigBuffer, biglen, 1, _metaBigFile);
    int size = [H264FrameMetaData size];
    //判断数据格式是否正确，必须是size的倍数
    if(biglen%size != 0){
      NSLog(@"BigMetaData size not correct,please check!!!");
    }
    uint8_t* bigTemp_ptr = bigBuffer;
    long metaDataCount = biglen/size;
    mBigFrameCount = (int)metaDataCount; //获得当前帧数
    long bigMetaDataFileLength = 0;
    while (metaDataCount>0) {
      H264FrameMetaData* t = [self getH264FrameMetaDataFromBytes:bigTemp_ptr];
      bigMetaDataFileLength += t.length;
      [self.metaBigData addObject:t];
      bigTemp_ptr += size;
      metaDataCount--;
    }
    if(bigvideolen != bigMetaDataFileLength){
      //rename(old, new)
      NSLog(@"big video and meta file length not equal,please check!!!");
    }
    currentBigFileLength = bigvideolen;   //获得当前视频文件大小
    free(bigBuffer);
  }
  
  //从文件系统读取小流数据
  fseek(_metaSmallFile, 0L, SEEK_END);
  long metaSmallLen = ftell(_metaSmallFile);
  fseek(_h264SmallFile, 0L, SEEK_END);
  long smallvideolen = ftell(_h264SmallFile);
  if(metaSmallLen>0){
    fseek(_metaSmallFile, 0L, SEEK_SET);
    uint8_t* smallBuffer = (uint8_t*)malloc(metaSmallLen);
    fread(smallBuffer, metaSmallLen, 1, _metaSmallFile);
    int size = [H264FrameMetaData size];
    if(metaSmallLen%size != 0){
      NSLog(@"SmallMetaData size not correct,please check!!!");
    }
    uint8_t* smallTemp_ptr = smallBuffer;
    long metaDataCount = metaSmallLen/size;
    mSmallFrameCount = (int)metaDataCount;
    long smallVideoLengthFromMetaData = 0;
    while (metaDataCount>0) {
      H264FrameMetaData* t = [self getH264FrameMetaDataFromBytes:smallTemp_ptr];
      smallVideoLengthFromMetaData += t.length;
      [self.metaSmallData addObject:t];
      smallTemp_ptr += size;
      metaDataCount--;
    }
    if(smallvideolen != smallVideoLengthFromMetaData){
      NSLog(@"small video and meta file length not equal,please check!!!");
    }
    currentSmallFileLength = smallvideolen;
    free(smallBuffer);
  }
  
}

-(void)viewWillAppear:(BOOL)animated
{
  mInitBigRelativeTime = -1;      //以第一个大流I帧的绝对编码时间为初始值
  mInitSmallRelativeTime = -1;     //以第一个小流I帧的绝对编码时间为初始值
  mlastBigFrameRelativeTime = -1;   //上一帧的相对时间
  mlastSmallFrameRelativeTime = -1;  //上一帧的相对时间
  [self.encode startH264EncodeSession];
  [self.smallEncode startH264EncodeSession];
}

-(void)viewDidAppear:(BOOL)animated
{
  //初始化录制模块
  if(self.isSlowMotion){
    self.record = [[CameraSlowMotionRecord alloc] initWithPreview:self.containerpreview isSlowMotion:true];
  }else{
    self.record = [[CameraSlowMotionRecord alloc] initWithPreview:self.containerpreview isSlowMotion:false];
  }
  self.record.delegate = self;
  [self.record startCapture];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [self.record stopCapture];
  [self.encode stopH264EncodeSession];
  [self.smallEncode stopH264EncodeSession];
}


-(void)dealloc
{
  fclose(_h264BigFile);
  fclose(_h264SmallFile);
  fclose(_metaBigFile);
  fclose(_metaSmallFile);
  [mSmallVideoFileHandle closeFile];
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


-(H264FrameMetaData*)getH264FrameMetaDataFromBytes:(uint8_t*)bytes
{
  H264FrameMetaData* data = [[H264FrameMetaData alloc] init];
  uint8_t* temp = bytes;
  //帧类型
  int8_t* type_ptr = (int8_t*)temp;
  data.type = *type_ptr;
  temp += 1;
  //绝对时间
  int64_t* absoluteTime_ptr = (int64_t*)temp;
  data.absoluteTime = *absoluteTime_ptr;
  temp += 8;
  //相对时间
  int32_t* relativeTime_ptr = (int32_t*)temp;
  data.relativeTime = *relativeTime_ptr;
  temp += 4;
  //第几帧
  int32_t* frameIndex_ptr = (int32_t*)temp;
  data.frameIndex = *frameIndex_ptr;
  temp += 4;
  //p帧对应的I帧位置
  int32_t* IFrameIndex_ptr = (int32_t*)temp;
  data.IFrameIndex = *IFrameIndex_ptr;
  temp += 4;
  //该帧在文件中的位置，字节为单位
  int64_t* position_ptr = (int64_t*)temp;
  data.position = *position_ptr;
  temp += 8;
  //该帧的长度，字节为单位
  int32_t* length_ptr = (int32_t*)temp;
  data.length = *length_ptr;
  temp += 4;
  //该帧持续时间，毫秒为单位，每一段的第一个I帧持续时间是0
  int16_t* duration_ptr = (int16_t*)temp;
  data.duration = *duration_ptr;
  
  return data;
}

-(void)saveH264FrameMetaDataToBytes:(uint8_t*)bytes metaData:(H264FrameMetaData*)metaData
{
  uint8_t* temp = bytes;
  int8_t type = metaData.type;
  memcpy(temp, &type, 1);
  temp += 1;
  int64_t absoluteTime = metaData.absoluteTime;
  memcpy(temp, &absoluteTime, 8);
  temp += 8;
  int32_t relativeTime = metaData.relativeTime;
  memcpy(temp, &relativeTime, 4);
  temp += 4;
  int32_t frameIndex = metaData.frameIndex;
  memcpy(temp, &frameIndex, 4);
  temp += 4;
  int32_t IFrameIndex = metaData.IFrameIndex;
  memcpy(temp, &IFrameIndex, 4);
  temp += 4;
  int64_t position = metaData.position;
  memcpy(temp, &position, 8);
  temp += 8;
  int32_t length = metaData.length;
  memcpy(temp, &length, 4);
  temp += 4;
  int16_t duration = metaData.duration;
  memcpy(temp, &duration, 2);
}

-(NSString *)getMMSSFromSS:(NSInteger)seconds{
  //format of hour
  NSString *str_hour = [NSString stringWithFormat:@"%02ld",seconds/3600];
  //format of minute
  NSString *str_minute = [NSString stringWithFormat:@"%02ld",(seconds%3600)/60];
  //format of second
  NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
  //format of time
  NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
  
  return format_time;
}

//CameraSlowMotionRecordDelegate
-(void)captureOutput:(CMSampleBufferRef)sampleBuffer
{
  mCaptureFrameCount++;
  if(beginCaptureTimestamp == 0){
    beginCaptureTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
  }
  int64_t currentTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
  //计算持续时间
  int64_t totalscecond = (currentTimestamp-beginCaptureTimestamp)/1000;
  
  double frameInterval = (currentTimestamp-beginCaptureTimestamp)/mCaptureFrameCount;
  int fps = 0;
  if(frameInterval>0){
    fps = 1000/frameInterval;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    self.info.text = [NSString stringWithFormat:@"帧数：%d,帧率：%d",mCaptureFrameCount,fps];
    self.timeInfo.text = [self getMMSSFromSS:totalscecond];
  });
  [self.encode encodeCMSampleBuffer:sampleBuffer];
  
  //提取出NV12数据，然后缩放，编码后，发给服务器
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    uint8_t* yuvData = (uint8_t*)malloc(bufferWidth*bufferHeight+bufferWidth*bufferHeight/2);
    uint8_t* I420_y = yuvData;
    uint8_t* I420_u = yuvData+bufferHeight*bufferWidth;
    uint8_t* I420_v = yuvData+bufferHeight*bufferWidth+bufferWidth*bufferHeight/4;
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    uint8_t *y_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    uint8_t *uv_frame = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    //NV12ToI420
    NV12ToI420(y_frame,bufferWidth,uv_frame,bufferWidth,I420_y,bufferWidth,I420_u,bufferWidth/2,I420_v,bufferWidth/2,bufferWidth,bufferHeight);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    //I420Scale
    int scale_width = 320;
    int scale_height = 180;
    uint8_t* scale_yuvData = (uint8_t*)malloc(scale_width*scale_height+scale_width*scale_height/2);
    uint8_t* scale_y = scale_yuvData;
    uint8_t* scale_u = scale_yuvData+scale_width*scale_height;
    uint8_t* scale_v = scale_yuvData+scale_width*scale_height+scale_width*scale_height/4;
    I420Scale(I420_y, bufferWidth, I420_u, bufferWidth/2, I420_v, bufferWidth/2, bufferWidth, bufferHeight, scale_y, scale_width, scale_u, scale_width/2, scale_v, scale_width/2, scale_width, scale_height, kFilterBilinear);
    //I420ToNV12
    uint8_t* nv12Data = (uint8_t*)malloc(scale_width*scale_height+scale_width*scale_height/2);
    I420ToNV12(scale_y, scale_width, scale_u, scale_width/2, scale_v, scale_width/2, nv12Data, scale_width, nv12Data+scale_width*scale_height, scale_width, scale_width, scale_height);
    NSData* scale_finalData = [[NSData alloc] initWithBytes:nv12Data length:scale_width*scale_height+scale_width*scale_height/2];
    [self.smallEncode encodeH264Frame:scale_finalData];
    free(yuvData);
    free(scale_yuvData);
    free(nv12Data);
  
}

//LocalWifiNetworkDelegate
-(void)serverDiscovered:(LocalWifiNetwork*)network ip:(NSString*)ip
{
  dispatch_async(dispatch_get_main_queue(), ^{
    //self.status.text = [NSString stringWithFormat:@"发现导播服务器"];
    self.directorButton.str(@"发现导播服务器");
  });
}
-(void)clientSocketConnected:(LocalWifiNetwork*)network
{
  if(network == self.localClient){
    isDirectServerConnected = true;
    dispatch_async(dispatch_get_main_queue(), ^{
      //self.status.text = [NSString stringWithFormat:@"服务器连接成功"];
      self.directorButton.str(@"导播服务器连接成功");
    });
    //发送导播服务器登录信息
    NSDictionary* dict = @{
                           @"id": @"localCameraLogin",
                           @"deviceID":self.mDeviceID,
                           @"type":[NSNumber numberWithInt:self.mCameraType],
                           @"name":self.mCameraName,
                           @"subtype":[NSNumber numberWithInt:-1],
                           @"isSlowMotion":[NSNumber numberWithBool:self.isSlowMotion]
                           };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    [self.localClient clientSendPacket:JSON_MESSAGE data:jsonData];
  }else if(network == self.highlightClient){
    //集锦服务器
    isHighlightServerConnected = true;
    NSDictionary* dict = @{
                           @"id": @"login",
                           @"deviceID":self.mDeviceID,
                           @"type":[NSNumber numberWithInt:self.mCameraType],
                           @"name":self.mCameraName,
                           @"isSlowMotion":[NSNumber numberWithBool:self.isSlowMotion]
                           };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    [self.highlightClient clientSendPacket:JSON_MESSAGE data:jsonData];
    dispatch_async(dispatch_get_main_queue(), ^{
      //self.status.text = [NSString stringWithFormat:@"服务器连接成功"];
      self.highlightButton.str(@"集锦服务器连接成功");
    });
  }
  
}
- (void)clientSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  if(network == self.localClient){
    isDirectServerConnected = false;
    dispatch_async(dispatch_get_main_queue(), ^{
      //self.status.text = [NSString stringWithFormat:@"服务器断开连接"];
      self.highlightButton.str(@"导播服务器断开连接");
    });
  }else if(network == self.highlightClient){
    isHighlightServerConnected = false;
    self.highlightButton.str(@"集锦服务器断开连接");
  }
}
-(void)clientReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data
{
  if(network == self.localClient){
    if(packetID == START_SEND_BIGDATA){
      if(!canSendBigH264){
        //重置大流编码器
        /*[self.encode stopH264EncodeSession];
        [self.encode startH264EncodeSession];
        //重置小流编码器
        [self.smallEncode stopH264EncodeSession];
        [self.smallEncode startH264EncodeSession];*/
        //[self Toast:@"start big"];
        
        [self.localClient clientSendPacket:SEND_BIG_H264DATA data:mDirectServerBigPPS];
        [self.localClient clientSendPacket:SEND_BIG_H264DATA data:mDirectServerBigSPS];
      
        canSendBigH264 = true;
      }
    }else if(packetID == STOP_SEND_BIGDATA){
      if(canSendBigH264){
        canSendBigH264 = false;
      }
    }else if(packetID == START_SEND_SMALLDATA){
      if(!canSendSmallH264){
        //重置大流编码器
        /*[self.encode stopH264EncodeSession];
        [self.encode startH264EncodeSession];
        //重置小流编码器
        [self.smallEncode stopH264EncodeSession];
        [self.smallEncode startH264EncodeSession];*/
        [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:mDirectServerSmallPPS];
        [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:mDirectServerSmallSPS];
        canSendSmallH264 = true;
      }
    }else if(packetID == STOP_SEND_SMALLDATA){
      if(canSendSmallH264){
        canSendSmallH264 = false;
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
      if([json_id isEqualToString:@"getHighlightServerIP"]){
        BOOL isconnect = [dic[@"isConnect"] boolValue];
        NSString* ip = dic[@"ip"];
        if(isconnect){
          //[self Toast:ip];
          [self.highlightClient connectServerByIP:ip];
        }else{
          [self Toast:@"集锦服务器没有启动,请稍后重试"];
        }
      }else if([json_id isEqualToString:@"getFirstSmallIFramebyAbsoluteTimestamp"]){
        int64_t timestamp = [dic[@"timestamp"] longLongValue];
        H264FrameMetaData* metaData = [self getSmallIFrameByTimestamp:timestamp];
        if(metaData){
          NSDictionary* dic = @{
                                @"id":@"getFirstSmallIFramebyAbsoluteTimestamp",
                                @"type":[NSNumber numberWithInt:metaData.type],
                                @"absoluteTime":[NSNumber numberWithLongLong:metaData.absoluteTime],
                                @"relativeTime":[NSNumber numberWithInt:metaData.relativeTime],
                                @"frameIndex":[NSNumber numberWithInt:metaData.frameIndex],
                                @"IFrameIndex":[NSNumber numberWithInt:metaData.IFrameIndex],
                                @"position":[NSNumber numberWithLongLong:metaData.position],
                                @"length":[NSNumber numberWithInt:metaData.length],
                                @"duration":[NSNumber numberWithInt:metaData.duration]
                                };
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
          //发送视频帧元数据
          [self.localClient clientSendPacket:JSON_MESSAGE data:jsonData];
          //发送h264的pps和sps
          [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:mDirectServerSmallPPS];
          [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:mDirectServerSmallSPS];
           //发送视频帧
          NSData* frameData = [self getFrameDataFromSmallFile:metaData.position+4 length:metaData.length-4];
          [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:frameData];
        }
      }else if([json_id isEqualToString:@"getNextSmallFrameByFrameIndex"]){
        int frameIndex = [dic[@"frameIndex"] intValue];
        H264FrameMetaData* metaData = [self getNextSmallFrameByIndex:frameIndex];
        if(metaData){
          NSDictionary* dic = @{
                                @"id":@"getNextSmallFrameByFrameIndex",
                                @"type":[NSNumber numberWithInt:metaData.type],
                                @"absoluteTime":[NSNumber numberWithLongLong:metaData.absoluteTime],
                                @"relativeTime":[NSNumber numberWithInt:metaData.relativeTime],
                                @"frameIndex":[NSNumber numberWithInt:metaData.frameIndex],
                                @"IFrameIndex":[NSNumber numberWithInt:metaData.IFrameIndex],
                                @"position":[NSNumber numberWithLongLong:metaData.position],
                                @"length":[NSNumber numberWithInt:metaData.length],
                                @"duration":[NSNumber numberWithInt:metaData.duration]
                                };
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
          //发送视频帧元数据
          [self.localClient clientSendPacket:JSON_MESSAGE data:jsonData];
          //发送视频帧
          NSData* frameData = [self getFrameDataFromSmallFile:metaData.position+4 length:metaData.length-4];
          [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:frameData];
        }
      }else if([json_id isEqualToString:@"getFirstBigIFramebyAbsoluteTimestamp"]){
        int64_t timestamp = [dic[@"timestamp"] longLongValue];
        H264FrameMetaData* metaData = [self getBigIFrameByTimestamp:timestamp];
        if(metaData){
          NSDictionary* dic = @{
                                @"id":@"getFirstBigIFramebyAbsoluteTimestamp",
                                @"type":[NSNumber numberWithInt:metaData.type],
                                @"absoluteTime":[NSNumber numberWithLongLong:metaData.absoluteTime],
                                @"relativeTime":[NSNumber numberWithInt:metaData.relativeTime],
                                @"frameIndex":[NSNumber numberWithInt:metaData.frameIndex],
                                @"IFrameIndex":[NSNumber numberWithInt:metaData.IFrameIndex],
                                @"position":[NSNumber numberWithLongLong:metaData.position],
                                @"length":[NSNumber numberWithInt:metaData.length],
                                @"duration":[NSNumber numberWithInt:metaData.duration]
                                };
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
          //发送视频帧元数据
          [self.localClient clientSendPacket:JSON_MESSAGE data:jsonData];
          //发送h264的pps和sps
          [self.localClient clientSendPacket:SEND_BIG_H264DATA data:mDirectServerBigPPS];
          [self.localClient clientSendPacket:SEND_BIG_H264DATA data:mDirectServerBigSPS];
          //发送视频帧
          NSData* frameData = [self getFrameDataFromBigFile:metaData.position+4 length:metaData.length-4];
          [self.localClient clientSendPacket:SEND_BIG_H264DATA data:frameData];
        }
      }else if([json_id isEqualToString:@"getNextBigFrameByFrameIndex"]){
        int frameIndex = [dic[@"frameIndex"] intValue];
        H264FrameMetaData* metaData = [self getNextBigFrameByIndex:frameIndex];
        if(metaData){
          NSDictionary* dic = @{
                                @"id":@"getNextBigFrameByFrameIndex",
                                @"type":[NSNumber numberWithInt:metaData.type],
                                @"absoluteTime":[NSNumber numberWithLongLong:metaData.absoluteTime],
                                @"relativeTime":[NSNumber numberWithInt:metaData.relativeTime],
                                @"frameIndex":[NSNumber numberWithInt:metaData.frameIndex],
                                @"IFrameIndex":[NSNumber numberWithInt:metaData.IFrameIndex],
                                @"position":[NSNumber numberWithLongLong:metaData.position],
                                @"length":[NSNumber numberWithInt:metaData.length],
                                @"duration":[NSNumber numberWithInt:metaData.duration]
                                };
          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
          //发送视频帧元数据
          [self.localClient clientSendPacket:JSON_MESSAGE data:jsonData];
          //发送视频帧
          NSData* frameData = [self getFrameDataFromBigFile:metaData.position+4 length:metaData.length-4];
          [self.localClient clientSendPacket:SEND_BIG_H264DATA data:frameData];
        }
      }
    }
  }else if(network == self.highlightClient){
    if(packetID == JSON_MESSAGE){
      NSError *err;
      NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                          options:NSJSONReadingMutableContainers
                                                            error:&err];
      if(err){
        NSLog(@"json解析失败：%@",err);
        return;
      }
      NSString* json_id = dic[@"id"];
      if([json_id isEqualToString:@"highlight_startplay"]){
        BOOL state = [dic[@"state"] boolValue];
        if(state){
          //发送sps,pps
          [self.highlightClient clientSendPacket:SEND_SMALL_H264SDATA data:mHighlightSPS];
          [self.highlightClient clientSendPacket:SEND_SMALL_H264SDATA data:mHighlightPPS];
        }
        canSendHighlightH264 = state;
      }else if([json_id isEqualToString:@"getNewestSmallIFrame"]){
        canSendHighlightH264 = false; //停止自动发送实时画面
        H264FrameMetaData* metaData = [self getNewestSmallIFrame];
        if(metaData != nil){
          //发送sps,pps
          [self.highlightClient clientSendPacket:SEND_SMALL_H264SDATA data:mHighlightSPS];
          [self.highlightClient clientSendPacket:SEND_SMALL_H264SDATA data:mHighlightPPS];
          [self sendFrameDataToHighlightServer:metaData jsonID:@"getNewestSmallIFrame"];
        }
      }else if([json_id isEqualToString:@"getNextSmallFrame"]){
        int frameindex = [[dic valueForKey:@"frameindex"] intValue];
        H264FrameMetaData* metaData = [self getNextSmallFrameByIndex:frameindex];
        if(metaData != nil){
          [self sendFrameDataToHighlightServer:metaData jsonID:@"getNextSmallFrame"];
        }
      }else if([json_id isEqualToString:@"seekBackIFrame"]){
        int frameIndex = [[dic valueForKey:@"frameindex"] intValue];
        int interval = [[dic valueForKey:@"interval"] intValue];
        H264FrameMetaData* metaData = [self getBackSmallframeByIndex:frameIndex andDistance:interval];
        if(metaData != nil){
          [self sendFrameDataToHighlightServer:metaData jsonID:@"seekBackIFrame"];
        }
      }else if([json_id isEqualToString:@"seekFrontIFrame"]){
        int frameindex = [[dic valueForKey:@"frameindex"] intValue];
        int interval = [[dic valueForKey:@"interval"] intValue];
        H264FrameMetaData* metaData = [self getFrontSmallIframeByIndex:frameindex andDistance:interval];
        if(metaData != nil){
          [self sendFrameDataToHighlightServer:metaData jsonID:@"seekFrontIFrame"];
        }
      }
    }
  }
}

//向集锦服务器发送某一帧的元数据和视频数据
-(void)sendFrameDataToHighlightServer:(H264FrameMetaData*)metaData jsonID:(NSString*)jsonID
{
  NSDictionary* dic = @{
                        @"id":jsonID,
                        @"type":[NSNumber numberWithInt:metaData.type],
                        @"absoluteTime":[NSNumber numberWithLongLong:metaData.absoluteTime],
                        @"relativeTime":[NSNumber numberWithInt:metaData.relativeTime],
                        @"frameIndex":[NSNumber numberWithInt:metaData.frameIndex],
                        @"IFrameIndex":[NSNumber numberWithInt:metaData.IFrameIndex],
                        @"position":[NSNumber numberWithLongLong:metaData.position],
                        @"length":[NSNumber numberWithInt:metaData.length],
                        @"duration":[NSNumber numberWithInt:metaData.duration]
                        };
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
  //发送视频帧元数据
  [self.highlightClient clientSendPacket:JSON_MESSAGE data:jsonData];
  NSData* frameData = [self getFrameDataFromSmallFile:metaData.position+4 length:metaData.length-4];
  //发送视频帧
  [self.highlightClient clientSendPacket:SEND_SMALL_H264SDATA data:frameData];
}

//获得距离指定视频帧最近的前一个关键帧
-(H264FrameMetaData*) getFrontSmallIframeByIndex:(int)frameIndex
{
  int index = frameIndex-1;
  while (index>=0) {
    H264FrameMetaData* metaData = [self.metaSmallData objectAtIndex:index];
    if(metaData.type == H264FRAMETYPE_IFRAME){
      return metaData;
    }
    index--;
  }
  return nil;
}

//获得距离指定视频帧前n个关键帧的视频帧，如果到达文件头部，则可以小于n
-(H264FrameMetaData*)getFrontSmallIframeByIndex:(int)frameIndex andDistance:(int)distance
{
  H264FrameMetaData* result = nil;
  int n = distance;
  int index = frameIndex - 1;
  while (index>=0) {
    H264FrameMetaData* metaData = [self.metaSmallData objectAtIndex:index];
    if(metaData.type == H264FRAMETYPE_IFRAME){
      result = metaData;
      n--;
      if(n<=0){
        break;
      }
    }
    index--;
  }
  return result;
}

//获得距离指定视频帧最近的后一个关键帧
-(H264FrameMetaData*) getBackSmallframeByIndex:(int)frameIndex
{
  int index = frameIndex+1;
  long length = [self.metaSmallData count];
  while(index<length){
    H264FrameMetaData* metaData = [self.metaSmallData objectAtIndex:index];
    if(metaData.type == H264FRAMETYPE_IFRAME){
      return metaData;
    }
    index++;
  }
  return nil;
}

//获得距离指定视频帧后n个关键帧的视频帧，如果到达文件尾部，则可以小于n
-(H264FrameMetaData*)getBackSmallframeByIndex:(int)frameIndex andDistance:(int)distance
{
  H264FrameMetaData* result = nil;
  int n = distance;
  int index = frameIndex+1;
  long length = [self.metaSmallData count];
  while (index < length) {
    H264FrameMetaData* metaData = [self.metaSmallData objectAtIndex:index];
    if(metaData.type == H264FRAMETYPE_IFRAME){
      result = metaData;
      n--;
      if(n<=0){
        break;
      }
    }
    index++;
  }
  return result;
}

//获得距离调用该API时最近的一个关键帧
-(H264FrameMetaData*) getNewestSmallIFrame
{
  long index = [self.metaSmallData count]-1;
  while (index>=0) {
    H264FrameMetaData* metaData = [self.metaSmallData objectAtIndex:index];
    if(metaData.type == H264FRAMETYPE_IFRAME){
      return metaData;
    }
    index--;
  }
  return nil;
}

//获得指定视频帧的下一个视频帧
-(H264FrameMetaData*) getNextSmallFrameByIndex:(int)frameIndex
{
  int index = frameIndex+1;
  if(index<[self.metaSmallData count]){
    H264FrameMetaData* metaData = [self.metaSmallData objectAtIndex:index];
    return metaData;
  }
  return nil;
}

//获得指定视频帧的下一个视频帧
-(H264FrameMetaData*) getNextBigFrameByIndex:(int)frameIndex
{
  int index = frameIndex+1;
  if(index<[self.metaBigData count]){
    H264FrameMetaData* metaData = [self.metaBigData objectAtIndex:index];
    return metaData;
  }
  return nil;
}

//距离绝对时间戳最近的一帧关键视频帧
-(H264FrameMetaData*)getSmallIFrameByTimestamp:(int64_t)timestamp
{
  H264FrameMetaData* result = nil;
  long index = [self.metaSmallData count]-1;
  while (index>=0) {
    H264FrameMetaData* metaData = [self.metaSmallData objectAtIndex:index];
    if(metaData.type == H264FRAMETYPE_IFRAME){
      result = metaData;
      if(metaData.absoluteTime <= timestamp){
        break;
      }
    }
    index--;
  }
  return result;
}

//距离绝对时间戳最近的一帧关键视频帧
-(H264FrameMetaData*)getBigIFrameByTimestamp:(int64_t)timestamp
{
  H264FrameMetaData* result = nil;
  long index = [self.metaBigData count]-1;
  while (index>=0) {
    H264FrameMetaData* metaData = [self.metaBigData objectAtIndex:index];
    if(metaData.type == H264FRAMETYPE_IFRAME){
      result = metaData;
      if(metaData.absoluteTime <= timestamp){
        break;
      }
    }
    index--;
  }
  return result;
}

//从文件系统获得一帧小流视频数据
-(NSData*) getFrameDataFromSmallFile:(long)position length:(int)length
{
  /*void* buffer = malloc(length);
  fseek(_h264SmallFile, position, 0);
  fread(buffer, 1, length, _h264SmallFile);
  NSData* data = [[NSData alloc] initWithBytesNoCopy:buffer length:length];
  return data;*/
  
  [mSmallVideoFileHandle seekToFileOffset:position];
  NSData *data = [mSmallVideoFileHandle readDataOfLength:length];
  return data;
}

//从文件系统获得一帧大流视频数据
-(NSData*) getFrameDataFromBigFile:(long)position length:(int)length
{
  void* buffer = malloc(length);
   fseek(_h264BigFile, position, 0);
   fread(buffer, 1, length, _h264BigFile);
   NSData* data = [[NSData alloc] initWithBytesNoCopy:buffer length:length];
   return data;
}


//集锦服务器相关接口
-(void)setSPSPPSToHighlightServer:(NSData*)pps sps:(NSData*)sps
{
  mHighlightPPS = pps;
  mHighlightSPS = sps;
}

-(void)enterH264DataToHighlightServer:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
  if(isHighlightServerConnected && canSendHighlightH264){
    [self.highlightClient clientSendPacket:SEND_SMALL_H264SDATA data:data];
  }
}


//h264encodeDelegate
-(void)dataEncodeToH264:(const void*)data length:(size_t)length
{
 
}

-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds;
{
  //[self.cacheQueue setBigSPSPPS:pps ppsLen:ppsLen sps:sps spsLen:spsLen];
  
  //每一帧的分隔符
  const Byte frameSpliter[] = "\x00\x00\x00\x01";
  int64_t currentTimeMills = [[NSDate date] timeIntervalSince1970] * 1000;
  int size = [H264FrameMetaData size];
  uint8_t* metabuffer = (uint8_t*)malloc(size);
  //记录sps元数据
  H264FrameMetaData* bigSpsMetaData = [[H264FrameMetaData alloc] init];
  bigSpsMetaData.type = 2;
  bigSpsMetaData.absoluteTime = currentTimeMills;
  bigSpsMetaData.relativeTime = -1;
  bigSpsMetaData.frameIndex = mBigFrameCount;
  mBigFrameCount++;
  bigSpsMetaData.IFrameIndex = -1;
  bigSpsMetaData.position = currentBigFileLength;
  bigSpsMetaData.length = (int)(4+spsLen);
  bigSpsMetaData.duration = 0;
  currentBigFileLength += (4+spsLen);
  
  [self.metaBigData addObject:bigSpsMetaData];
  [self saveH264FrameMetaDataToBytes:metabuffer metaData:bigSpsMetaData];
  //保存sps元数据到本地磁盘
  fwrite(metabuffer, 1, size, _metaBigFile);
  //保存原始数据
  fwrite(frameSpliter, 1, 4, _h264BigFile);
  fwrite(sps, 1, spsLen, _h264BigFile);
  
  //记录pps元数据
  H264FrameMetaData* bigPpsMetaData = [[H264FrameMetaData alloc] init];
  bigPpsMetaData.type = 1;
  bigPpsMetaData.absoluteTime = currentTimeMills;
  bigPpsMetaData.relativeTime = -1;
  bigPpsMetaData.frameIndex = mBigFrameCount;
  mBigFrameCount++;
  bigPpsMetaData.IFrameIndex = -1;
  bigPpsMetaData.position = currentBigFileLength;
  bigPpsMetaData.length = (int)(4+ppsLen);
  bigPpsMetaData.duration = 0;
  currentBigFileLength += (4+ppsLen);
  
  [self.metaBigData addObject:bigPpsMetaData];
  [self saveH264FrameMetaDataToBytes:metabuffer metaData:bigPpsMetaData];
  //保存pps元数据到本地磁盘
  fwrite(metabuffer, 1, size, _metaBigFile);
  //保存原始数据
  fwrite(frameSpliter, 1, 4, _h264BigFile);
  fwrite(pps, 1, ppsLen, _h264BigFile);
  
  free(metabuffer);
  
  mDirectServerBigPPS = [[NSData alloc] initWithBytes:pps length:ppsLen];
  mDirectServerBigSPS = [[NSData alloc] initWithBytes:sps length:spsLen];
  
  if(isDirectServerConnected && canSendBigH264){
    //[self.localClient clientSendPacket:SEND_BIG_H264DATA data:mDirectServerPPS];
    //[self.localClient clientSendPacket:SEND_BIG_H264DATA data:mDirectServerSPS];
  }
}
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  //[self.cacheQueue enterBigH264:data length:length isKeyFrame:isKeyFrame];
  const Byte frameSpliter[] = "\x00\x00\x00\x01";
  int64_t currentTimeMills = [[NSDate date] timeIntervalSince1970] * 1000;
  int size = [H264FrameMetaData size];
  uint8_t* metabuffer = (uint8_t*)malloc(size);
  if(mInitBigRelativeTime == -1){
    //保存第一帧到来的绝对时间
    mInitBigRelativeTime = currentTimeMills;
  }
  
  int32_t relativeTime = (int32_t)(currentTimeMills - mInitBigRelativeTime);
  H264FrameMetaData* bigMetaData = [[H264FrameMetaData alloc] init];
  if(isKeyFrame){
    bigMetaData.type = 3;
    bigMetaData.absoluteTime = currentTimeMills;
    bigMetaData.relativeTime = relativeTime;
    bigMetaData.frameIndex = mBigFrameCount;
    lastBigIFrameIndex = mBigFrameCount;
    mBigFrameCount++;
    bigMetaData.IFrameIndex = -1;
    bigMetaData.position = currentBigFileLength;
    bigMetaData.length = (int)(4+length);
    if(mlastBigFrameRelativeTime == -1){
      bigMetaData.duration = 0;
    }else{
      bigMetaData.duration = relativeTime - mlastBigFrameRelativeTime;
    }
    currentBigFileLength += (4+length);
  }else{
    bigMetaData.type = 4;
    bigMetaData.absoluteTime = currentTimeMills;
    bigMetaData.relativeTime = relativeTime;
    bigMetaData.frameIndex = mBigFrameCount;
    mBigFrameCount++;
    bigMetaData.IFrameIndex = lastBigIFrameIndex;
    bigMetaData.position = currentBigFileLength;
    bigMetaData.length = (int)(4+length);
    if(mlastBigFrameRelativeTime == -1){
      bigMetaData.duration = 0;
    }else{
      bigMetaData.duration = relativeTime - mlastBigFrameRelativeTime;
    }
    currentBigFileLength += (4+length);
  }
  //保存本帧相对时间，供下一帧计算持续时间
  mlastBigFrameRelativeTime = (int)relativeTime;
  
  [self.metaBigData addObject:bigMetaData];
  [self saveH264FrameMetaDataToBytes:metabuffer metaData:bigMetaData];
  //保存视频帧元数据到本地磁盘
  fwrite(metabuffer, 1, size, _metaBigFile);
  //保存原始数据
  fwrite(frameSpliter, 1, 4, _h264BigFile);
  fwrite(data, 1, length, _h264BigFile);
  
  free(metabuffer);
  
  if(isDirectServerConnected && canSendBigH264){
    NSData* frameData = [[NSData alloc] initWithBytes:data length:length];
    [self.localClient clientSendPacket:SEND_BIG_H264DATA data:frameData];
  }
}

-(void)rtmpSmallSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds
{
  //每一帧的分隔符
  const Byte frameSpliter[] = "\x00\x00\x00\x01";
  int64_t currentTimeMills = [[NSDate date] timeIntervalSince1970] * 1000;
  int size = [H264FrameMetaData size];
  uint8_t* metabuffer = (uint8_t*)malloc(size);
  //记录sps元数据
  H264FrameMetaData* smallSpsMetaData = [[H264FrameMetaData alloc] init];
  smallSpsMetaData.type = 2;
  smallSpsMetaData.absoluteTime = currentTimeMills;
  smallSpsMetaData.relativeTime = -1;
  smallSpsMetaData.frameIndex = mSmallFrameCount;
  mSmallFrameCount++;
  smallSpsMetaData.IFrameIndex = -1;
  smallSpsMetaData.position = currentSmallFileLength;
  smallSpsMetaData.length = (int)(4+spsLen);
  smallSpsMetaData.duration = 0;
  currentSmallFileLength += (4+spsLen);
  [self.metaSmallData addObject:smallSpsMetaData];
  [self saveH264FrameMetaDataToBytes:metabuffer metaData:smallSpsMetaData];
  //保存sps元数据到本地磁盘
  fwrite(metabuffer, 1, size, _metaSmallFile);
  //保存原始数据
  fwrite(frameSpliter, 1, 4, _h264SmallFile);
  fwrite(sps, 1, spsLen, _h264SmallFile);
  
  //记录pps元数据
  H264FrameMetaData* smallPpsMetaData = [[H264FrameMetaData alloc] init];
  smallPpsMetaData.type = 1;
  smallPpsMetaData.absoluteTime = currentTimeMills;
  smallPpsMetaData.relativeTime = -1;
  smallPpsMetaData.frameIndex = mSmallFrameCount;
  mSmallFrameCount++;
  smallPpsMetaData.IFrameIndex = -1;
  smallPpsMetaData.position = currentSmallFileLength;
  smallPpsMetaData.length = (int)(4+ppsLen);
  smallPpsMetaData.duration = 0;
  currentSmallFileLength += (4+ppsLen);
  
  [self.metaSmallData addObject:smallPpsMetaData];
  [self saveH264FrameMetaDataToBytes:metabuffer metaData:smallPpsMetaData];
  //保存pps元数据到本地磁盘
  fwrite(metabuffer, 1, size, _metaSmallFile);
  //保存原始数据
  fwrite(frameSpliter, 1, 4, _h264SmallFile);
  fwrite(pps, 1, ppsLen, _h264SmallFile);
  
  free(metabuffer);
  
  mDirectServerSmallPPS = [[NSData alloc] initWithBytes:pps length:ppsLen];
  mDirectServerSmallSPS = [[NSData alloc] initWithBytes:sps length:spsLen];
  
  //导播服务器数据
  if(isDirectServerConnected && canSendSmallH264){
    /*NSData* ppsData = [[NSData alloc] initWithBytes:pps length:ppsLen];
    NSData* spsData = [[NSData alloc] initWithBytes:sps length:spsLen];
    [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:ppsData];
    [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:spsData];*/
  }
  
  //集锦服务器数据
  NSData* ppsData = [[NSData alloc] initWithBytes:pps length:ppsLen];
  NSData* spsData = [[NSData alloc] initWithBytes:sps length:spsLen];
  [self setSPSPPSToHighlightServer:ppsData sps:spsData];
}
-(void)rtmpSmallH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  const Byte frameSpliter[] = "\x00\x00\x00\x01";
  int64_t currentTimeMills = [[NSDate date] timeIntervalSince1970] * 1000;
  int size = [H264FrameMetaData size];
  uint8_t* metabuffer = (uint8_t*)malloc(size);
  if(mInitSmallRelativeTime == -1){
    //保存第一帧到来的绝对时间
    mInitSmallRelativeTime = currentTimeMills;
  }
  
  int32_t relativeTime = (int32_t)(currentTimeMills - mInitSmallRelativeTime);
  H264FrameMetaData* smallMetaData = [[H264FrameMetaData alloc] init];
  if(isKeyFrame){
    smallMetaData.type = 3;
    smallMetaData.absoluteTime = currentTimeMills;
    smallMetaData.relativeTime = relativeTime;
    smallMetaData.frameIndex = mSmallFrameCount;
    lastSmallIFrameIndex = mSmallFrameCount;
    mSmallFrameCount++;
    smallMetaData.IFrameIndex = -1;
    smallMetaData.position = currentSmallFileLength;
    smallMetaData.length = (int)(4+length);
    if(mlastSmallFrameRelativeTime == -1){
      smallMetaData.duration = 0;
    }else{
      smallMetaData.duration = relativeTime - mlastSmallFrameRelativeTime;
    }
    currentSmallFileLength += (4+length);
  }else{
    smallMetaData.type = 4;
    smallMetaData.absoluteTime = currentTimeMills;
    smallMetaData.relativeTime = relativeTime;
    smallMetaData.frameIndex = mSmallFrameCount;
    mSmallFrameCount++;
    smallMetaData.IFrameIndex = lastSmallIFrameIndex;
    smallMetaData.position = currentSmallFileLength;
    smallMetaData.length = (int)(4+length);
    if(mlastSmallFrameRelativeTime == -1){
      smallMetaData.duration = 0;
    }else{
      smallMetaData.duration = relativeTime - mlastSmallFrameRelativeTime;
    }
    currentSmallFileLength += (4+length);
  }
  //保存本帧相对时间，供下一帧计算持续时间
  mlastSmallFrameRelativeTime = (int)relativeTime;
  
  [self.metaSmallData addObject:smallMetaData];
  [self saveH264FrameMetaDataToBytes:metabuffer metaData:smallMetaData];
  //保存视频帧元数据到本地磁盘
  fwrite(metabuffer, 1, size, _metaSmallFile);
  //保存原始数据
  fwrite(frameSpliter, 1, 4, _h264SmallFile);
  fwrite(data, 1, length, _h264SmallFile);
  
  free(metabuffer);
  
  //导播服务器数据
  if(isDirectServerConnected && canSendSmallH264){
    //预览数据只发送I帧
    if(isKeyFrame){
      NSData* frameData = [[NSData alloc] initWithBytes:data length:length];
      [self.localClient clientSendPacket:SEND_SMALL_H264SDATA data:frameData];
    }
  }
  
  //集锦服务器数据
  NSData* frameData = [[NSData alloc] initWithBytes:data length:length];
  if(isKeyFrame){
    [self enterH264DataToHighlightServer:frameData isKeyFrame:isKeyFrame];
  }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
  
}

@end
