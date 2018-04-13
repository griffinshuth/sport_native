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
//@property (nonatomic,strong) h264CacheQueue* cacheQueue;
@property (nonatomic,strong) UIView* containerpreview;
@property (nonatomic,strong) UILabel* info;
@property (nonatomic,strong) UILabel* status;
@property (nonatomic,strong) LocalWifiNetwork* localClient;

@property (nonatomic,strong) NSString* filename;

@property (nonatomic,strong) NSMutableArray<H264FrameMetaData*>* metaBigData;
@property (nonatomic,strong) NSMutableArray<H264FrameMetaData*>* metaSmallData;
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
  
  BOOL canSendBigH264;
  BOOL canSendSmallH264;
  BOOL isServerConnect;
  
  int mCaptureFrameCount;                    //采集的总帧数
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
  int64_t mBeginServerAbsoluteTime;  //服务器绝对时间
  int64_t mBeginLocalAbsoluteTime;   //收到服务器时间同步包时的本机绝对时间
}
- (void)viewDidLoad {
    [super viewDidLoad];
  self.filename = @"Camera_roomid_deviceid_positionname";
  self.mDeviceID = @"234543";
  self.mRoomID = 223343;
  self.mPositionName = @"court_left_top";
  self.mCameraName = @"carl";
  self.mCameraType = CameraType_NORMAL;
  self.filename = [NSString stringWithFormat:@"Camera_%d_%@_%@",self.mRoomID,self.mDeviceID,self.mPositionName];
  
  NSString* documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  _h264BigFileName = [NSString stringWithFormat:@"%@_big.h264",self.filename];
  _h264SmallFileName = [NSString stringWithFormat:@"%@_small.h264",self.filename];
  _metaBigFileName = [NSString stringWithFormat:@"%@_big.meta",self.filename];
  _metaSmallFileName = [NSString stringWithFormat:@"%@_small.meta",self.filename];
  _h264BigFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_h264BigFileName] UTF8String], "ab+");
  _h264SmallFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_h264SmallFileName] UTF8String], "ab+");
  _metaBigFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_metaBigFileName] UTF8String], "ab+");
  _metaSmallFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,_metaSmallFileName] UTF8String], "ab+");
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
  self.info.text = @"采集的帧数：00000";
  [self.info sizeToFit];
  self.info.centerXPos.equalTo(@0);
  self.info.centerYPos.equalTo(@(1/6.0)).offset(self.info.frame.size.height / 2); //对于框架布局来说中心点偏移也可以设置为相对偏移。
  [rootLayout addSubview:self.info];
  
  self.status = [UILabel new];
  self.status.text = @"连接中。。。";
  //[self.status sizeToFit];
  self.status.myHeight = 50;
  self.status.myWidth = 200;
  self.status.centerXPos.equalTo(@0);
  self.status.centerYPos.equalTo(@(200)).offset(self.status.frame.size.height*2); //对于框架布局来说中心点偏移也可以设置为相对偏移。
  [rootLayout addSubview:self.status];
  
  mCaptureFrameCount = 0;
  mBigFrameCount = 0;               //编码的大流帧数
  mSmallFrameCount = 0;             //编码的小流帧数
  currentBigFileLength = 0;             //当前大流视频文件大小
  currentSmallFileLength = 0;           //当前小流视频文件大小
  
  //初始化编码器
  self.encode = [[h264encode alloc] initEncodeWith:1280 height:720 framerate:25 bitrate:1600*1000];
  self.encode.delegate = self;
  self.smallEncode = [[h264encode alloc] initSmallEncodeWith:320 height:180 framerate:25 bitrate:300 * 1024];
  self.smallEncode.delegate = self;
  //初始化缓存队列
  //self.cacheQueue = [[h264CacheQueue alloc] init];
  
  self.localClient = [[LocalWifiNetwork alloc] initWithType:false];
  self.localClient.delegate = self;
  [self.localClient searchDirectorServer];
  
  canSendBigH264 = false;
  canSendSmallH264 = false;
  isServerConnect = false;
  
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
      NSLog(@"video and meta file length not equal,please check!!!");
    }
    currentBigFileLength = bigvideolen;   //获得当前视频文件大小
    free(bigBuffer);
  }
  
  /*H264FrameMetaData* tempData = [[H264FrameMetaData alloc] init];
  tempData.type = 3;
  tempData.absoluteTime = 1523287276932;
  tempData.relativeTime = 4433;
  tempData.frameIndex = 3445;
  tempData.IFrameIndex = 322;
  tempData.position = 33234;
  tempData.length = 33452;
  tempData.duration = 30;
  
  int size = [H264FrameMetaData size];
  uint8_t* tempbuffer = (uint8_t*)malloc(size);
  [self saveH264FrameMetaDataToBytes:tempbuffer metaData:tempData];
  H264FrameMetaData* copyData = [self getH264FrameMetaDataFromBytes:tempbuffer];*/
  
}

-(void)dealloc
{
  fclose(_h264BigFile);
  fclose(_h264SmallFile);
  fclose(_metaBigFile);
  fclose(_metaSmallFile);
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

//CameraSlowMotionRecordDelegate
-(void)captureOutput:(CMSampleBufferRef)sampleBuffer
{
  mCaptureFrameCount++;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.info.text = [NSString stringWithFormat:@"采集的帧数：%d",mCaptureFrameCount];
  });
  [self.encode encodeCMSampleBuffer:sampleBuffer];
  
  if(canSendSmallH264){
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
}

//LocalWifiNetworkDelegate
-(void)serverDiscovered:(LocalWifiNetwork*)network ip:(NSString*)ip
{
  dispatch_async(dispatch_get_main_queue(), ^{
    self.status.text = [NSString stringWithFormat:@"发现导播服务器"];
  });
}
-(void)clientSocketConnected:(LocalWifiNetwork*)network
{
  isServerConnect = true;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.status.text = [NSString stringWithFormat:@"服务器连接成功"];
  });
}
- (void)clientSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  isServerConnect = false;
  dispatch_async(dispatch_get_main_queue(), ^{
    self.status.text = [NSString stringWithFormat:@"服务器断开连接"];
  });
}
-(void)clientReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data
{
  if(packetID == START_SEND_BIGDATA){
    if(!canSendBigH264){
      [self.encode stopH264EncodeSession];
      [self.encode startH264EncodeSession];
      canSendBigH264 = true;
    }
  }else if(packetID == STOP_SEND_BIGDATA){
    if(canSendBigH264){
      canSendBigH264 = false;
    }
  }else if(packetID == START_SEND_SMALLDATA){
    if(!canSendSmallH264){
      [self.smallEncode stopH264EncodeSession];
      [self.smallEncode startH264EncodeSession];
      canSendSmallH264 = true;
    }
  }else if(packetID == STOP_SEND_SMALLDATA){
    if(canSendSmallH264){
      canSendSmallH264 = false;
    }
  }
}

-(void)send:(uint16_t)packetID data:(NSData*)data
{
  [self.localClient clientSendPacket:packetID data:data];
}


//h264encodeDelegate
-(void)dataEncodeToH264:(const void*)data length:(size_t)length
{
  [self writeH264Data:data length:length];
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
  
  if(isServerConnect && canSendBigH264){
    NSData* ppsData = [[NSData alloc] initWithBytes:pps length:ppsLen];
    NSData* spsData = [[NSData alloc] initWithBytes:sps length:spsLen];
    [self send:SEND_BIG_H264DATA data:ppsData];
    [self send:SEND_BIG_H264DATA data:spsData];
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
  
  if(isServerConnect && canSendBigH264){
    NSData* frameData = [[NSData alloc] initWithBytes:data length:length];
    [self send:SEND_BIG_H264DATA data:frameData];
  }
}

-(void)rtmpSmallSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds
{
  if(isServerConnect && canSendSmallH264){
    NSData* ppsData = [[NSData alloc] initWithBytes:pps length:ppsLen];
    NSData* spsData = [[NSData alloc] initWithBytes:sps length:spsLen];
    [self send:SEND_SMALL_H264SDATA data:ppsData];
    [self send:SEND_SMALL_H264SDATA data:spsData];
  }
}
-(void)rtmpSmallH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  if(isServerConnect && canSendSmallH264){
    NSData* frameData = [[NSData alloc] initWithBytes:data length:length];
    [self send:SEND_SMALL_H264SDATA data:frameData];
  }
}

//h264数据存入文件
-(void)writeH264Data:(const void*)data length:(size_t)length
{
  return;
  const Byte bytes[] = "\x00\x00\x00\x01";
  //本地存储
  if(_h264BigFile){
    fwrite(bytes, 1, 4, _h264BigFile);
    fwrite(data, 1, length, _h264BigFile);
  }else{
    NSLog(@"_h264File null error, check if it open successed");
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
  self.record = [[CameraSlowMotionRecord alloc] initWithPreview:self.containerpreview isSlowMotion:false];
  self.record.delegate = self;
  [self.record startCapture];
}

-(void)viewWillDisappear:(BOOL)animated
{
  [self.record stopCapture];
  [self.encode stopH264EncodeSession];
  [self.smallEncode stopH264EncodeSession];
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
