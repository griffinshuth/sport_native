//
//  h264CacheQueue.m
//  sportdream
//
//  Created by lili on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "h264CacheQueue.h"
#import "PacketID.h"


@implementation h264Frame

@end

@implementation SpsPpsMetaData

@end

@interface h264CacheQueue()
@property (nonatomic,strong) SpsPpsMetaData* bigMetaData;
@property (nonatomic,strong) NSMutableArray* bigH264Queue;
@property (nonatomic,strong) NSMutableArray* bigKeyFrameList;
@property (nonatomic,strong) h264Frame* lastBigKeyFrame;
@property (nonatomic,strong) h264Frame* lastSendBigFrame;

@property (nonatomic,strong) SpsPpsMetaData* smallMetaData;
@property (nonatomic,strong) NSMutableArray* smallH264Queue;
@property (nonatomic,strong) NSMutableArray* smallKeyFrameList;
@property (nonatomic,strong) h264Frame* lastSmallKeyFrame;
@property (nonatomic,strong) h264Frame* lastSendSmallFrame;

@property (nonatomic,strong) LocalWifiNetwork* localClient;
@end

@implementation h264CacheQueue
{
  int maxCapacity;
  BOOL sendBigH264;
  BOOL sendSmallH264;
  BOOL beginRecord;
}

-(id)init
{
  self = [super init];
  if(self){
    maxCapacity = 25*60*1;
    sendBigH264 = false;
    sendSmallH264 = false;
    beginRecord = false;
    
    self.lastSendBigFrame = nil;
    self.lastSendSmallFrame = nil;
    
    self.bigMetaData = [[SpsPpsMetaData alloc] init];
    self.bigH264Queue = [[NSMutableArray alloc] initWithCapacity:maxCapacity];
    self.bigKeyFrameList = [[NSMutableArray alloc] init];
    
    self.smallMetaData = [[SpsPpsMetaData alloc] init];
    self.smallH264Queue = [[NSMutableArray alloc] initWithCapacity:maxCapacity];
    self.smallKeyFrameList = [[NSMutableArray alloc] init];
    
    self.localClient = [[LocalWifiNetwork alloc] initWithType:false];
    self.localClient.delegate = self;
    [self.localClient searchDirectorServer];
  }
  return self;
}

//LocalWifiNetworkDelegate
-(void)serverDiscovered:(LocalWifiNetwork*)network ip:(NSString*)ip
{
  
}
-(void)clientSocketConnected:(LocalWifiNetwork*)network
{
  
}
- (void)clientSocketDisconnect:(LocalWifiNetwork*)network sock:(GCDAsyncSocket *)sock
{
  
}
-(void)clientReceiveData:(LocalWifiNetwork*)network packetID:(uint16_t)packetID data:(NSData*)data
{
  if(packetID == START_SEND_BIGDATA){
    if(beginRecord){
      if(!sendBigH264){
        //发送视频元数据
        [self send:SEND_BIG_H264DATA data:self.bigMetaData.pps];
        [self send:SEND_BIG_H264DATA data:self.bigMetaData.sps];
        sendBigH264 = true;
      }
    }
  }if(packetID == STOP_SEND_BIGDATA){
    if(sendBigH264){
      sendBigH264 = false;
      self.lastSendBigFrame = nil;
    }
  }
}

-(void)send:(uint16_t)packetID data:(NSData*)data
{
  [self.localClient clientSendPacket:packetID data:data];
}

-(void)setBigSPSPPS:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen
{
  self.bigMetaData.sps = [[NSData alloc] initWithBytes:sps length:spsLen];
  self.bigMetaData.pps = [[NSData alloc] initWithBytes:pps length:ppsLen];
}

-(void)enterBigH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame
{
  h264Frame* frame = [[h264Frame alloc] init];
  frame.isKeyFrame = isKeyFrame;
  frame.timestamp = [[NSDate date] timeIntervalSince1970];
  frame.frameData = [[NSData alloc] initWithBytes:data length:length];
  
  //判断队列是否已满，满的话需要移除最久的帧，然后才能插入新的帧
  if([self.bigH264Queue count] >= maxCapacity){
    //删除最久的帧
    h264Frame* oldestframe = [self.bigH264Queue objectAtIndex:0];
    if(oldestframe.isKeyFrame){
      [self.bigKeyFrameList removeObjectAtIndex:0];
    }
    [self.bigH264Queue removeObjectAtIndex:0];
    //添加新的帧
    [self.bigH264Queue addObject:frame];
  }else{
    [self.bigH264Queue addObject:frame];
  }
  //如果是关键帧，则记录下来，并存入关键帧队列
  if(isKeyFrame){
    self.lastBigKeyFrame = frame;
    [self.bigKeyFrameList addObject:frame];
  }
  //收到第一帧后，设置开始录制的标记
  if(!beginRecord){
    beginRecord = true;
  }
  
  //是否需要发送到网络
  if(sendBigH264){
    if(!self.lastSendBigFrame){
      //上一帧不存在，代表第一次发送，发送最近的一个关键帧，并记录下来
      [self send:SEND_BIG_H264DATA data:self.lastBigKeyFrame.frameData];
      self.lastSendBigFrame = self.lastBigKeyFrame;
    }else{
      //获得当前要发送的帧
      NSUInteger index = [self.bigH264Queue indexOfObject:self.lastSendBigFrame];
      h264Frame* current = [self.bigH264Queue objectAtIndex:index+1];
      [self send:SEND_BIG_H264DATA data:current.frameData];
      self.lastSendBigFrame = current;
    }
  }
}

-(void)setSmallSPSPPS
{
  
}

-(void)enterSmallH264
{
  
}
@end
