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
#import "PCMPlayer.h"
#import "KTVAUGraphRecorder.h"
#import "AudioMixer.h"
#import "libyuv.h"
#import "FFmpegPushClient.h"


enum {
  LOCAL_CAMERA = 1,
  REMOTE_CAMERA = 2,
  FILE_CAMERA = 3,
};

//基础数据结构
@interface CameraOnStand:NSObject
@property (nonatomic,strong) GCDAsyncSocket* socket;
@property (nonatomic,strong) NSString* name;
@end

@implementation CameraOnStand

@end

//导播系统分为两个部分，远程画面和本地画面，远程画面可以从SDK中直接得到解码后的数据，直接发送原始数据到推流模块进行编码发送即可
//本地画面需要先用解码模块进行解码，得到原始数据进行后处理，然后发送到推流模块进行编码发送。

@interface DirectorServerViewController ()
@property (nonatomic,strong) LocalWifiNetwork* localserver;
@property (nonatomic,strong) h264decode* bigStreamDecode;
@property (nonatomic,strong) h264decode* smallStreamDecode;
@property (nonatomic,strong) h264encode* videoEncode;
@property (nonatomic,strong) NSMutableArray* localCameras;
//视频房间
@property (nonatomic,strong) AgoraKitRemoteCamera* camera;
@property (nonatomic,strong) NSMutableArray<RemoteCameraSession*>* remoteCameraSessions;
@property (nonatomic,strong) NSString* channelName;
//
@property (nonatomic,strong) NSMutableArray* files;
@property (nonatomic,strong) UIView* liveView;
@property (nonatomic,strong) MyLinearLayout* rootLayout;
@property (nonatomic,assign) BOOL isLocalLiving;
@property (nonatomic,assign) BOOL isRomoteLiving;
@property (nonatomic,assign) BOOL isFileLiving;

@property (nonatomic,strong) CameraOnStand *cameraOnStandOfLiving; //正在直播中的机位
@property (nonatomic,strong) CameraOnStand *cameraOnPreview;  //正在预览的机位

//rtmp直播对象
@property (nonatomic,strong) StreamingClient* rtmpClient;
@property (strong,nonatomic) FFmpegPushClient* FFmpegRtmpclient;

@property (nonatomic,strong) PCMPlayer* pcmPLayer;
@property (nonatomic,strong) KTVAUGraphRecorder* KTVRecorder;
@property (nonatomic,strong) AACDecode* audioDecoder1;
@property (nonatomic,strong) AACDecode* audioDecoder2;
@property (nonatomic,strong) AACDecode* audioDecoder3;
@property (nonatomic,strong) AudioMixer* audioMixer;
@property (nonatomic,strong) VideoPlayer* filePlayer;
@end

@implementation DirectorServerViewController
{
  MyFlowLayout *remoteCameraLayout;
  MyFlowLayout *localCameraLayout;
  CVPixelBufferRef pixelBuf;
  CMTime timestamp;
  FILE *_AACFile;
  
  int screen_width;
  int screen_height;
  Byte* argb_buffer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
  screen_width = 1280;
  screen_height = 720;
  
  argb_buffer = (Byte*)malloc(screen_width*screen_height*4);
  memset(argb_buffer, 0, screen_width*screen_height*4);
  NSString* documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  _AACFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,@"testmixer.aac"] UTF8String], "ab+");
  //播放文件
  //self.pcmPLayer = [[PCMPlayer alloc] initWithFileName:@"1223_1-2" fileExtension:@"mov" channel:2];
  //现场解说
  //self.pcmPLayer = [[PCMPlayer alloc] initWithFileName:nil fileExtension:nil channel:1];
  //[self.pcmPLayer play];
  //混音
  self.audioMixer = [[AudioMixer alloc] init];
  //PCM解码器
  self.audioDecoder1 = [[AACDecode alloc] init];
  self.audioDecoder1.delegate = self;
  self.audioDecoder2 = [[AACDecode alloc] init];
  self.audioDecoder2.delegate = self;
  self.audioDecoder3 = [[AACDecode alloc] init];
  self.audioDecoder3.delegate = self;
  
  //K歌模块
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = paths[0];
  NSString *recordFolderPath = [documentsDirectory stringByAppendingPathComponent:@"record"];
  NSFileManager *fm = [NSFileManager defaultManager];
  
  if (![fm fileExistsAtPath:recordFolderPath isDirectory:NULL])
  {
    //if folder notfound, create one
    [fm createDirectoryAtPath:recordFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
  }
  //self.KTVRecorder = [[KTVAUGraphRecorder alloc] initWithRecordFilePath:[recordFolderPath stringByAppendingPathComponent:@"temp.wav"]];
  //[self.KTVRecorder startRecord];
    // Do any additional setup after loading the view.
  //network
  self.localserver = [[LocalWifiNetwork alloc] initWithType:true];
  self.localserver.delegate = self;
  
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
  
  UILabel *livelabel = [self createLabel:NSLocalizedString(@"直播画面", @"") backgroundColor:[CFTool color:1]];
  livelabel.myLeading = 0;
  livelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  livelabel.myHeight = 35;
  [self.rootLayout addSubview:livelabel];
  self.liveView = View.border(1, @"3d3d3d");
  self.liveView.myTop = 5;
  self.liveView.myBottom = 5;
  self.liveView.myLeading = 0;
  self.liveView.myTrailing = 0;
  self.liveView.myHeight = 200;
  [self.rootLayout addSubview:self.liveView];
  //远程画面开始
  UILabel *remotelabel = [self createLabel:NSLocalizedString(@"远程画面", @"") backgroundColor:[CFTool color:6]];
  remotelabel.myLeading = 0;
  remotelabel.myTrailing = 0; //上面两行代码将左右边距设置为10。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  remotelabel.myHeight = 35;
  [self.rootLayout addSubview:remotelabel];
  
  remoteCameraLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  remoteCameraLayout.wrapContentHeight = YES;
  remoteCameraLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  remoteCameraLayout.subviewHSpace = 5;
  remoteCameraLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  remoteCameraLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  remoteCameraLayout.myLeading = 0;
  remoteCameraLayout.myTrailing = 0;
  [self.rootLayout addSubview:remoteCameraLayout];

  //远程画面结束
  //本地镜头列表
  UILabel *localCameralabel = [self createLabel:NSLocalizedString(@"本地镜头列表", @"") backgroundColor:[CFTool color:1]];
  localCameralabel.myLeading = 5;
  localCameralabel.myTrailing = 0; //上面两行代码将左右边距设置为0。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  localCameralabel.myHeight = 35;
  [self.rootLayout addSubview:localCameralabel];
  localCameraLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  localCameraLayout.wrapContentHeight = YES;
  localCameraLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  localCameraLayout.subviewHSpace = 5;
  localCameraLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  localCameraLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  localCameraLayout.myLeading = 0;
  localCameraLayout.myTrailing = 0;
  [self.rootLayout addSubview:localCameraLayout];
  
  //本地镜头列表结束
  //本地文件
  UILabel *filelabel = [self createLabel:NSLocalizedString(@"本地可播放文件", @"") backgroundColor:[CFTool color:1]];
  filelabel.myLeading = 5;
  filelabel.myTrailing = 0; //上面两行代码将左右边距设置为0。对于垂直线性布局来说如果子视图同时设置了左右边距则宽度会自动算出，因此不需要设置myWidth的值了。
  filelabel.myHeight = 35;
  [self.rootLayout addSubview:filelabel];
  MyFlowLayout *filesLayout = [MyFlowLayout flowLayoutWithOrientation:MyOrientation_Vert arrangedCount:2];
  filesLayout.wrapContentHeight = YES;
  filesLayout.gravity = MyGravity_Horz_Fill; //平均分配里面所有子视图的宽度
  filesLayout.subviewHSpace = 5;
  filesLayout.subviewVSpace = 5;  //设置里面子视图的水平和垂直间距。
  filesLayout.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  filesLayout.myLeading = 0;
  filesLayout.myTrailing = 0;
  [self.rootLayout addSubview:filesLayout];
  
  NSArray *filesactions = @[@"才艺表演",
                                  @"投篮教学",@"战术分析",@"集锦",@"五佳球",@"啦啦队",@"搞笑视频"
                                  ];
  for (NSInteger i = 0; i < filesactions.count; i++)
  {
    [filesLayout addSubview:[self createFileView:filesactions[i] index:i]];
  }
  
  //初始化解码器
  self.bigStreamDecode = [[h264decode alloc] initWithGPUImageView:self.liveView];
  self.bigStreamDecode.delegate = self;
  self.smallStreamDecode = [[h264decode alloc] initWithView:nil];
  
  self.videoEncode = [[h264encode alloc] initEncodeWith:1280 height:720 framerate:30 bitrate:1600 * 1024];
  self.videoEncode.delegate = self;
  [self.videoEncode startH264EncodeSession];
  //初始化Agora引擎
  self.channelName = @"mangguo";
  self.camera = [[AgoraKitRemoteCamera alloc] initWithChannelName:self.channelName useExternalVideoSource:true localView:nil];
  self.camera.delegate = self;
  [self.camera joinChannel];
  //初始化数据容器
  self.remoteCameraSessions = [[NSMutableArray alloc] init];
  self.localCameras = [[NSMutableArray alloc] init];
  self.files = [[NSMutableArray alloc] init];

  int width = 1280;
  int height = 720;
  CVPixelBufferCreate(NULL, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, NULL, &pixelBuf);
  timestamp = kCMTimeZero;
  
  self.filePlayer = [[VideoPlayer alloc] init];
  self.filePlayer.delegate = self;
  
  self.FFmpegRtmpclient = [[FFmpegPushClient alloc] init];
}

-(void)dealloc
{
  //[self.pcmPLayer stop];
  [self.audioDecoder1 stopAACEncodeSession];
  [self.audioDecoder2 stopAACEncodeSession];
  [self.audioDecoder3 stopAACEncodeSession];
  fclose(_AACFile);
  free(argb_buffer);
  if(![self.filePlayer isStop]){
    [self.filePlayer stop];
  }
  [self.videoEncode stopH264EncodeSession];
  //[self.KTVRecorder stopRecord];
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
  dispatch_sync(dispatch_get_main_queue(), ^{
    [localCameraLayout removeAllSubviews];
    for (NSInteger i = 0; i < self.localCameras.count; i++)
    {
      CameraOnStand* c = self.localCameras[i];
      [localCameraLayout addSubview:[self createLocalCameraView:c.name index:i]];
    }
    [self.rootLayout layoutIfNeeded];
  });
}

-(void)refreshRemoteCameras
{
  [remoteCameraLayout removeAllSubviews];
  for (NSInteger i = 0; i < self.remoteCameraSessions.count; i++)
  {
    RemoteCameraSession* c = self.remoteCameraSessions[i];
    [remoteCameraLayout addSubview:[self createRomoteCameraView:c.name index:i preview:c.hostingView]];
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

//VideoPlayerDelegate
- (void)didCompletePlayingMovie
{
  
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
- (void)didAudioOutput:(CMSampleBufferRef)audioData
{
  
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
-(void)dataFromPostProgress:(NSData*)yuvData frameTime:(CMTime)frameTime
{
  CMTime t = CMTimeMake(1, 25);
  timestamp = CMTimeAdd(timestamp, t);
  int width = 1280;
  int height = 720;
  /*CVPixelBufferLockBaseAddress(pixelBuf, 0);
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
  [self.FFmpegRtmpclient sendRGBAData:(Byte*)yuvData.bytes dataLength:yuvData.length];
  [self.camera pushExternalVideoData:yuvData timeStamp:timestamp];
}

//LocalWifiNetworkDelegate begin
-(void)broadcastReceived:(LocalWifiNetwork*)network ip:(NSString*)ip
{
 
}

-(void)acceptNewSocket:(LocalWifiNetwork*)network newSocket:(GCDAsyncSocket *)newSocket
{
  NSArray *localCameraNames = @[@"全局镜头",
                                  @"左侧镜头",@"右侧镜头",@"篮下镜头",@"篮板镜头",@"持球人镜头",@"球员特写"
                                  ];
  CameraOnStand* c = [[CameraOnStand alloc] init];
  c.socket = newSocket;
  c.name = @"";
  [self.localCameras addObject:c];
  NSUInteger len = [self.localCameras count];
  c.name = localCameraNames[len-1];
  [self refreshLocalCameras];
  [self.audioMixer commentorConnected:c.name];
}

- (void)serverSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  for(CameraOnStand* obj in self.localCameras){
    if(obj.socket == sock){
      //判断要断开的连接是否是正在直播的机位
      if(sock == self.cameraOnStandOfLiving.socket){
        self.cameraOnStandOfLiving = nil;
      }
      if(sock == self.cameraOnPreview.socket){
        self.cameraOnPreview = nil;
      }
      [self.audioMixer commentorDisconnected:obj.name];
      [self.localCameras removeObject:obj];
      [self refreshLocalCameras];
      NSLog(@"remove from connectedSockets:num:%zd",[self.localCameras count]);
      break;
    }
  }
}

-(void)serverReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data sock:(GCDAsyncSocket *)sock
{
  NSString* name = [self getNameOfLocalSocket:sock];
  if(packetID == SEND_BIG_H264DATA){
    if(sock == self.cameraOnStandOfLiving.socket){
      //收到不含头部的h264帧数据 ，传给解码器进行解码显示
      [self.bigStreamDecode decodeH264WithoutHeader:data];
    }
  }else if(packetID == SEND_SMALL_H264SDATA){
    if(sock == self.cameraOnPreview.socket){
      [self.smallStreamDecode decodeH264WithoutHeader:data];
    }
  }
  else if(packetID == COMMENT_AUDIO){
    
    uint32_t packetlen = (uint32_t)(data.length+7);
    uint8_t* header = [self addADTStoPacket:packetlen];
    //[self writeAACData:(int8_t*)data.bytes length:data.length adtsHeader:header];
    NSData* t = [[NSData alloc] initWithBytes:header length:7];
    NSMutableData* final_result = [[NSMutableData alloc] initWithData:t];
    [final_result appendData:data];
    free(header);
    if([name isEqualToString:@"左侧镜头"]){
      [self.audioDecoder2 decodeAudioFrame:final_result SocketName:name];
    }else if([name isEqualToString:@"右侧镜头"]){
      [self.audioDecoder3 decodeAudioFrame:final_result SocketName:name];
    }else{
      [self.audioDecoder1 decodeAudioFrame:final_result SocketName:name];
    }
  }
}

//LocalWifiNetworkDelegate end

-(NSString*)getNameOfLocalSocket:(GCDAsyncSocket*)sock
{
  for(CameraOnStand* obj in self.localCameras){
    if(obj.socket == sock){
      return obj.name;
    }
  }
  return @"";
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

//aac数据存入文件
-(void)writeAACData:(void*)data length:(size_t)length adtsHeader:(uint8_t*)header
{
  if(_AACFile){
    fwrite(header, 1,7, _AACFile);
    fwrite(data, 1,length, _AACFile);
  }else{
    NSLog(@"_AACFile null error, check if it open successed");
  }
}

//AACDecodeDelegate
-(void)AACDecodeToPCM:(NSData*)data  SocketName:(NSString*)SocketName;
{
  //[self.pcmPLayer intoAudioData:data];
  [self.audioMixer intoAudioData:data ip:SocketName];
  
  
}

//agora sdk delegate
- (void)didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
  NSArray *actions = @[@"主持人",
                       @"解说员",
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
  return;
  Byte* argb = (Byte*)malloc(width*height*4);
  libyuv::I420ToARGB((const uint8*)yBuffer,yStride,(const uint8*)uBuffer,uStride,(const uint8*)vBuffer,vStride,argb,yStride*4,width,height);
  NSData* BRGABuffer = [[NSData alloc] initWithBytesNoCopy:argb length:width*height*4];
  dispatch_sync(dispatch_get_main_queue(), ^{
    [self.bigStreamDecode postProcess:BRGABuffer width:width height:height];
  });
}

- (void)addAudioBuffer:(void *)buffer length:(int)length
{
  
}

//agora sdk delegate end

/*-(UIButton*)createActionButton:(NSString*)title tag:(NSInteger)tag action:(SEL)action
{
  UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [actionButton setTitle:title forState:UIControlStateNormal];
  actionButton.titleLabel.adjustsFontSizeToFitWidth = YES;
  actionButton.titleLabel.font = [CFTool font:14];
  actionButton.tag = tag;
  [actionButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  actionButton.layer.borderColor = [UIColor grayColor].CGColor;
  actionButton.layer.cornerRadius = 4;
  actionButton.layer.borderWidth = 0.5;
  [actionButton sizeToFit];
  return actionButton;
}*/

-(MyLinearLayout*)createFileView:(NSString*)name index:(NSInteger)index
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
    if(![self.filePlayer isStop]){
      [self.filePlayer stop];
    }
    if(index == 0)
      [self.filePlayer startPush:@"IMG_0032" fileExtension:@"m4v"];
    else
      [self.filePlayer startPush:@"1223_1-2" fileExtension:@"mov"];
    if(![self.FFmpegRtmpclient isPushing]){
      [self.FFmpegRtmpclient startStreaming];
    }
  });
  liveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  liveButton.str(@"推送");
  liveButton.tag = index;
  liveButton.myHeight = 40;
  
  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    if(![self.filePlayer isStop]){
      [self.filePlayer stop];
    }
    if(index == 0)
      [self.filePlayer startPreview:@"IMG_0032" fileExtension:@"m4v" view:preview];
    else
      [self.filePlayer startPreview:@"1223_1-2" fileExtension:@"mov" view:preview];
  });
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"预览");
  smallH264Button.myHeight = 40;
  
  UIButton* stopButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    if(![self.filePlayer isStop]){
      [self.filePlayer stop];
    }
    if([self.FFmpegRtmpclient isPushing]){
      [self.FFmpegRtmpclient stopStreaming];
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
    
    CameraOnStand* currentCamera = ws.localCameras[index];
      //判断是否已经有其他镜头在直播，如果有则先停止该镜头
    if(self.isFileLiving){
      
    }else if(self.isRomoteLiving){
      
    }else if(self.isLocalLiving){
      if(currentCamera == ws.cameraOnStandOfLiving){
        //当前机位正在直播，不进行任何操作
        return;
      }else{
        //停掉当前机位
        if(ws.cameraOnStandOfLiving){
          [ws stopBigVideo:ws.cameraOnStandOfLiving.socket];
        }
      }
    }
    //切换到选择的机位
    self.isLocalLiving = true;
    ws.cameraOnStandOfLiving = currentCamera;
    [ws startBigVideo:ws.cameraOnStandOfLiving.socket];
    
  });
  liveButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  liveButton.str(@"直播");
  liveButton.tag = index;
  liveButton.myHeight = 40;

  UIButton* smallH264Button = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3).onClick(^(UIButton* btn){
    CameraOnStand* currentPreview = ws.localCameras[index];
    if(currentPreview == ws.cameraOnPreview){
      return;
    }else{
      if(ws.cameraOnPreview){
        [ws stopSmallVideo:ws.cameraOnPreview.socket];
      }
    }
    //切换预览的机位
    ws.cameraOnPreview = currentPreview;
    [ws startSmallVideo:ws.cameraOnPreview.socket];
    [self.smallStreamDecode setPreview:preview];
  });
  smallH264Button.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  smallH264Button.str(@"预览");
  smallH264Button.myHeight = 40;
  
  UIButton* beforeButton = Button.fnt(@15).color(@"#0065F7").border(1, @"#0065F7").borderRadius(3);
  beforeButton.highColor(@"white").highBgImg(@"#0065F7").insets(5, 10);
  beforeButton.str(@"回放");
  beforeButton.myHeight = 40;
  [buttonContainer addSubview:liveButton];
  [buttonContainer addSubview:smallH264Button];
  [buttonContainer addSubview:beforeButton];
  [cameraView addSubview:buttonContainer];
  return cameraView;
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

/*-(MyLinearLayout*)createVertSubviewLayout
{
  MyLinearLayout* vertLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Vert];
  vertLayout.backgroundColor = [CFTool color:0];
  UILabel *v1 = [self createLabel:NSLocalizedString(@"left margin", @"") backgroundColor:[CFTool color:5]];
  v1.myTop = 10;
  v1.myLeading = 10;
  v1.myWidth = 200;
  v1.myHeight = 35;
  [vertLayout addSubview:v1];
  
  UILabel *v2 = [self createLabel:NSLocalizedString(@"horz center", @"") backgroundColor:[CFTool color:6]];
  v2.myTop = 10;
  v2.myCenterX = 0;
  v2.mySize = CGSizeMake(200, 35);
  [vertLayout addSubview:v2];
  
  UILabel *v3 = [self createLabel:NSLocalizedString(@"right margin", @"") backgroundColor:[CFTool color:7]];
  v3.myTop = 10;
  v3.myTrailing = 10;
  v3.frame = CGRectMake(0, 0, 200, 35);
  [vertLayout addSubview:v3];
  
  UILabel *v4 = [self createLabel:NSLocalizedString(@"left right", @"") backgroundColor:[CFTool color:8]];
  v4.myTop = 10;
  v4.myBottom = 10;
  v4.myLeading = 10;
  v4.myTrailing = 10;
  v4.myHeight = 35;
  [vertLayout addSubview:v4];
  
  return vertLayout;
}

-(MyLinearLayout*)createHorzSubviewLayout
{
  MyLinearLayout* horzLayout = [MyLinearLayout linearLayoutWithOrientation:MyOrientation_Horz];
  horzLayout.backgroundColor = [CFTool color:0];
  
  UILabel *v1 = [self createLabel:NSLocalizedString(@"top margin", @"") backgroundColor:[CFTool color:5]];
  v1.myTop =10;
  v1.myLeading = 10;
  v1.myWidth = 60;
  v1.myHeight = 60;
  [horzLayout addSubview:v1];
  
  UILabel *v2 = [self createLabel:NSLocalizedString(@"vert center", @"") backgroundColor:[CFTool color:6]];
  v2.myLeading = 10;
  v2.myCenterY = 0;
  v2.mySize = CGSizeMake(60, 60);
  [horzLayout addSubview:v2];
  
  UILabel *v3 = [self createLabel:NSLocalizedString(@"bottom margin", @"") backgroundColor:[CFTool color:7]];
  v3.myBottom = 10;
  v3.myLeading = 10;
  v3.myTrailing = 5;
  v3.frame = CGRectMake(0, 0, 60, 60);
  [horzLayout addSubview:v3];
  
  UILabel *v4 = [self createLabel:NSLocalizedString(@"top bottom", @"") backgroundColor:[CFTool color:8]];
  v4.myTop = 10;
  v4.myBottom = 10;
  v4.myLeading = 10;
  v4.myTrailing = 10;
  v4.myWidth = 60;
  [horzLayout addSubview:v4];
  return horzLayout;
}*/

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
