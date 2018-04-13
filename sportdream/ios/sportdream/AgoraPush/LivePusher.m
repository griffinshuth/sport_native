//
//  LivePusher.m
//  sportdream
//
//  Created by lili on 2017/12/11.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "LivePusher.h"
#import "libyuv.h"
#import "AGVideoBuffer.h"
#import "AGAudioBuffer.h"
#import "StreamingClient.h"
#import "FFmpegPushClient.h"

@interface LivePusher ()
//@property (strong,nonatomic) StreamingClient* client;
@property (strong,nonatomic) FFmpegPushClient* client;
@property (assign,nonatomic) BOOL isPushing;

@property (strong,nonatomic) AGVideoBuffer* localVideoBuffer;
@property (strong,nonatomic) NSMutableArray* remoteVideoBuffers;
@property (strong,nonatomic) dispatch_source_t videoPublishTimer;

@property (strong,nonatomic) NSMutableArray* mixedAudioBuffers;
@property (assign,nonatomic) void* mixedAudioBuffer;
@property (assign,nonatomic) int mixedAudioBufferLength;
@property (strong,nonatomic) dispatch_source_t audioPublishTimer;

//录制类型，1:比赛，2:基本功挑战赛
@property (assign,nonatomic) int matchtype;
@property (assign,nonatomic) unsigned int uid; //比赛当前显示的画面，0代表现场比赛画面，其他数字代表解说员和才艺表演等
@property (assign,nonatomic) int maxscreen; //基本功挑战赛单次最大人数
@property (assign,nonatomic) int screen_width; //四分屏的屏幕宽度
@property (assign,nonatomic) int screen_height; //四分屏的屏幕高度
@end


@implementation LivePusher
{
  uint8* argb_buffer;
}
-(id)init
{
  self = [super init];
  if(self)
  {
    self.matchtype = 2; //默认是比赛类型
    self.uid = 0;       //默认显示现场比赛画面
    self.maxscreen = 4; //每个子屏幕是640*360
    self.screen_width = 1280;
    self.screen_height = 720;
    argb_buffer = (uint8*)malloc(self.screen_width*self.screen_height*4);
    memset(argb_buffer, 0, self.screen_width*self.screen_height*4);
  }
  return self;
}

-(void)dealloc
{
  free(argb_buffer);
}

+ (LivePusher *)sharedPusher
{
  static LivePusher *sharedPusher = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedPusher = [[LivePusher alloc] init];
  });
  return sharedPusher;
}

+ (dispatch_queue_t)sharedQueue
{
  static dispatch_queue_t queue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = dispatch_queue_create("io.agora.PushRTMPQueue", NULL);
  });
  
  return queue;
}

- (FFmpegPushClient *)client
{
  if (!_client) {
    _client = [[FFmpegPushClient alloc] init];
  }
  return _client;
}

- (NSMutableArray *)remoteVideoBuffers
{
  if (!_remoteVideoBuffers) {
    _remoteVideoBuffers = [[NSMutableArray alloc] init];
  }
  return _remoteVideoBuffers;
}

- (NSMutableArray *)mixedAudioBuffers
{
  if (!_mixedAudioBuffers) {
    _mixedAudioBuffers = [[NSMutableArray alloc] init];
  }
  return _mixedAudioBuffers;
}

+ (void)start
{
  [[self sharedPusher] start];
}

+ (void)stop
{
  [[self sharedPusher] stop];
}

- (void)start
{
  if (self.isPushing) {
    return;
  }
  
  [self.client startStreaming];
  self.isPushing = YES;
  
  dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [LivePusher sharedQueue]);
  dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, YUVDataSendTimeInterval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
  __weak typeof(self) weakSelf = self;
  dispatch_source_set_event_handler(timer, ^{
    [weakSelf mergeVideoToPush];
  });
  dispatch_resume(timer);
  self.videoPublishTimer = timer;
  
  dispatch_source_t timer2 = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, [LivePusher sharedQueue]);
  dispatch_source_set_timer(timer2, DISPATCH_TIME_NOW, PCMDataSendTimeInterval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
  dispatch_source_set_event_handler(timer2, ^{
    //[weakSelf mergeAudioToPush];
  });
  dispatch_resume(timer2);
  self.audioPublishTimer = timer2;
}

- (void)stop
{
  if (!self.isPushing) {
    return;
  }
  
  self.videoPublishTimer = nil;
  self.audioPublishTimer = nil;
  
  [self.client stopStreaming];
  self.isPushing = NO;
  
  self.localVideoBuffer = nil;
  [self.remoteVideoBuffers removeAllObjects];
  self.remoteVideoBuffers = nil;
}

#pragma mark add video data
+ (void)addLocalYBuffer:(void *)yBuffer uBuffer:(void *)uBuffer vBuffer:(void *)vBuffer
                yStride:(int)yStride uStride:(int)uStride vStride:(int)vStride
                  width:(int)width height:(int)height
               rotation:(int)rotation
{
  [[self sharedPusher] addLocalYBuffer:yBuffer uBuffer:uBuffer vBuffer:vBuffer yStride:yStride uStride:uStride vStride:vStride width:width height:height rotation:rotation];
}

+ (void)addRemoteOfUId:(unsigned int)uid
               yBuffer:(void *)yBuffer uBuffer:(void *)uBuffer vBuffer:(void *)vBuffer
               yStride:(int)yStride uStride:(int)uStride vStride:(int)vStride
                 width:(int)width height:(int)height
              rotation:(int)rotation
{
  [[self sharedPusher] addRemoteOfUId:uid yBuffer:yBuffer uBuffer:uBuffer vBuffer:vBuffer yStride:yStride uStride:uStride vStride:vStride width:width height:height rotation:rotation];
}

- (void)addLocalYBuffer:(void *)yBuffer uBuffer:(void *)uBuffer vBuffer:(void *)vBuffer
                yStride:(int)yStride uStride:(int)uStride vStride:(int)vStride
                  width:(int)width height:(int)height
               rotation:(int)rotation
{
  if(!self.isPushing)
  {
    return;
  }
  AGVideoBuffer* buffer = [[AGVideoBuffer alloc] initWithUId:0 yBuffer:yBuffer uBuffer:uBuffer vBuffer:vBuffer yStride:yStride uStride:uStride vStride:vStride width:width height:height rotation:rotation];
  dispatch_async([LivePusher sharedQueue], ^{
    if(self.localVideoBuffer != nil)
    {
      [self.localVideoBuffer updateWithYBuffer:buffer.yBuffer uBuffer:buffer.uBuffer vBuffer:buffer.vBuffer yStride:buffer.yStride uStride:buffer.uStride vStride:buffer.vStride width:buffer.width height:buffer.height rotation:buffer.rotation];
    }else{
      self.localVideoBuffer = buffer;
    }
  });
}

- (void)addRemoteOfUId:(unsigned int)uid
               yBuffer:(void *)yBuffer uBuffer:(void *)uBuffer vBuffer:(void *)vBuffer
               yStride:(int)yStride uStride:(int)uStride vStride:(int)vStride
                 width:(int)width height:(int)height
              rotation:(int)rotation
{
  if(!self.isPushing)
  {
    return;
  }
  AGVideoBuffer *newRemoteBuffer = [[AGVideoBuffer alloc] initWithUId:uid yBuffer:yBuffer uBuffer:uBuffer vBuffer:vBuffer yStride:yStride uStride:uStride vStride:vStride width:width height:height rotation:rotation];
  
  dispatch_async([LivePusher sharedQueue], ^{
    for (NSUInteger index = 0; index < self.remoteVideoBuffers.count; ++index) {
      AGVideoBuffer *buffer = self.remoteVideoBuffers[index];
      if (buffer.uid != newRemoteBuffer.uid) {
        continue;
      }
      
      if (buffer.width == newRemoteBuffer.width && buffer.height == newRemoteBuffer.height) {
        [buffer updateWithYBuffer:newRemoteBuffer.yBuffer uBuffer:newRemoteBuffer.uBuffer vBuffer:newRemoteBuffer.vBuffer yStride:newRemoteBuffer.yStride uStride:newRemoteBuffer.uStride vStride:newRemoteBuffer.vStride width:newRemoteBuffer.width height:newRemoteBuffer.height rotation:newRemoteBuffer.rotation];
      } else {
        [self.remoteVideoBuffers replaceObjectAtIndex:index withObject:newRemoteBuffer];
      }
      return;
    }
    
    [self.remoteVideoBuffers addObject:newRemoteBuffer];
  });
}

#pragma mark add audio
+ (void)addAudioBuffer:(void *)buffer length:(int)length
{
  [[self sharedPusher] addAudioBuffer:buffer length:length];
}

- (void)addAudioBuffer:(void *)buffer length:(int)length
{
  [self pushPCMData:buffer length:length];
}

#pragma mark push
-(void)mergeVideoToPush
{
  if(!self.isPushing)
  {
    return;
  }
  if(!self.localVideoBuffer)
  {
    return;
  }
  if(self.matchtype == 1){
    //全屏
    if(self.uid == 0){
      //现场画面
      int localYBufferSize = self.localVideoBuffer.yStride * self.localVideoBuffer.height;
      int localUBufferSize = self.localVideoBuffer.uStride * self.localVideoBuffer.height / 2;
      int localVBufferSize = self.localVideoBuffer.vStride * self.localVideoBuffer.height / 2;
      unsigned char *localYBuffer = [AGVideoBuffer copy:self.localVideoBuffer.yBuffer size:localYBufferSize];
      unsigned char *localUBuffer = [AGVideoBuffer copy:self.localVideoBuffer.uBuffer size:localUBufferSize];
      unsigned char *localVBuffer = [AGVideoBuffer copy:self.localVideoBuffer.vBuffer size:localVBufferSize];
      
      int dataLength = localYBufferSize + localUBufferSize + localVBufferSize;
      unsigned char* NV12Data = malloc(dataLength);
      I420ToNV12(localYBuffer, self.localVideoBuffer.yStride, localUBuffer, self.localVideoBuffer.uStride, localVBuffer, self.localVideoBuffer.vStride, NV12Data, self.localVideoBuffer.yStride, NV12Data+localYBufferSize, self.localVideoBuffer.uStride+self.localVideoBuffer.vStride, self.localVideoBuffer.yStride, self.localVideoBuffer.height);
      
      [self pushVideoYUVData:NV12Data dataLength:dataLength];
      //free(NV12Data);
      
      free(localYBuffer);
      free(localUBuffer);
      free(localVBuffer);
    }else{
      //远程画面
      for(AGVideoBuffer* remote in self.remoteVideoBuffers)
      {
        if(remote.uid == self.uid){
          int remoteYBufferSize = remote.yStride * remote.height;
          int remoteUBufferSize = remote.uStride * remote.height / 2;
          int remoteVBufferSize = remote.vStride * remote.height / 2;
          unsigned char *remoteYBuffer = [AGVideoBuffer copy:remote.yBuffer size:remoteYBufferSize];
          unsigned char *remoteUBuffer = [AGVideoBuffer copy:remote.uBuffer size:remoteUBufferSize];
          unsigned char *remoteVBuffer = [AGVideoBuffer copy:remote.vBuffer size:remoteVBufferSize];
          
          //push
          int dataLength = remoteYBufferSize + remoteUBufferSize + remoteVBufferSize;
          unsigned char *NV12Data = malloc(dataLength);
          I420ToNV12(remoteYBuffer, remote.yStride, remoteUBuffer, remote.uStride, remoteVBuffer, remote.vStride, NV12Data, remote.yStride, NV12Data+remoteYBufferSize, remote.uStride+remote.vStride, remote.yStride, remote.height);
          
          [self pushVideoYUVData:NV12Data dataLength:dataLength];
          
          free(remoteYBuffer);
          free(remoteUBuffer);
          free(remoteVBuffer);
          
          //free(NV12Data);
        }
      }
    }
    
  }else if(self.matchtype == 2){
    //四分屏
    //首先把本地画面绘制到缓冲中
    uint8* local_argb = (uint8*)malloc(self.localVideoBuffer.width*self.localVideoBuffer.height*4);
    I420ToARGB((const uint8*)self.localVideoBuffer.yBuffer,self.localVideoBuffer.yStride,(const uint8*)self.localVideoBuffer.uBuffer,self.localVideoBuffer.uStride,(const uint8*)self.localVideoBuffer.vBuffer,self.localVideoBuffer.vStride,local_argb,self.localVideoBuffer.yStride*4,self.localVideoBuffer.width,self.localVideoBuffer.height);
    for(int i=0;i<self.localVideoBuffer.height;i++){
      uint8* dst = argb_buffer+i*_screen_width*4;
      uint8* src = local_argb+i*self.localVideoBuffer.width*4;
      memcpy(dst, src, self.localVideoBuffer.width*4);
    }
    
    //绘制远端画面
    int index = 0;
    for(AGVideoBuffer* remote in self.remoteVideoBuffers){
      index++;
      if(index>=4){
        break;
      }
      I420ToARGB((const uint8*)remote.yBuffer,remote.yStride,(const uint8*)remote.uBuffer,remote.uStride,(const uint8*)remote.vBuffer,remote.vStride,local_argb,remote.yStride*4,remote.width,remote.height);
      if(index == 1){
        for(int i=0;i<remote.height;i++){
          uint8* dst = argb_buffer+i*_screen_width*4+remote.width*4;
          uint8* src = local_argb+i*remote.width*4;
          memcpy(dst, src, remote.width*4);
        }
      }
    }
    
    [self pushVideoRGBAData:argb_buffer dataLength:_screen_width*_screen_height*4];
    free(local_argb);
  }
  
}

-(void)pushVideoYUVData:(unsigned char *)pYUVBuff dataLength:(unsigned int)dataLength
{
  if(!self.isPushing)
  {
    return;
  }
  [self.client sendYUVData:pYUVBuff dataLength:dataLength];
}

-(void)pushVideoRGBAData:(unsigned char *)rgbaData dataLength:(unsigned int)dataLength
{
  if(!self.isPushing)
  {
    return;
  }
  [self.client sendRGBAData:rgbaData dataLength:dataLength];
}

- (void)pushPCMData: (unsigned char*)data length:(int)length
{
  if (!self.isPushing) {
    return;
  }
  
  [self.client sendPCMData:data dataLength:length];
}

@end














































