//
//  SocketClient.m
//  sportdream
//
//  Created by lili on 2017/12/17.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "SocketClient.h"

@implementation PacketInfo

@end

@implementation SocketClient
-(id)init
{
  self = [super init];
  if(self){
    self.socket = nil;
    self.maxSize = 1024*1024;
    self.currentSize = 0;
    self.buffer = malloc(self.maxSize);
    self.info = [[NSMutableDictionary alloc] init];
  }
  return self;
}

-(void)dealloc
{
  free(self.buffer);
}

-(BOOL)addData:(NSData*)data
{
  NSUInteger length = [data length];
  //判断当前可用空间是否够用
  size_t availSize = self.maxSize - self.currentSize;
  if(availSize<length){
    return FALSE;
  }
  void* t = self.buffer+self.currentSize;
  [data getBytes:t length:length];
  self.currentSize += length;
  return TRUE;
}
//前4个字节代表包长度，后面两个字节代表包ID，后面的字节代表包数据
-(PacketInfo*)nextPacket:(PacketInfo*)last
{
  if(last){
    //把上个包的数据清空，通过移位的方式
    long t = self.currentSize - (last.len+6);
    memcpy(self.buffer, self.buffer+last.len+6, t);
    self.currentSize = t;
  }
  if(self.currentSize <6){
    return nil;
  }
  uint32_t* Len_pointer = (uint32_t*)self.buffer;
  uint32_t len = CFSwapInt32BigToHost(*Len_pointer);
  //判断缓存中是否有一个完整的包
  if((self.currentSize-6)<len){
    NSLog(@"packet is partial");
    return nil;
  }
  uint16_t* ID_pointer = (uint16_t*)(self.buffer+4);
  uint16_t ID = CFSwapInt16BigToHost(*ID_pointer);
  PacketInfo* info = [PacketInfo alloc];
  info.len = len;
  info.packetID = ID;
  info.data = self.buffer+6;
  return info;
}

+(NSData*)createPacket:(uint32_t)len ID:(uint16_t)ID bytes:(const Byte*)bytes
{
  Byte* t = malloc(len+6);
  uint32_t big_len = CFSwapInt32HostToBig(len);
  uint16_t big_ID = CFSwapInt16HostToBig(ID);
  memcpy(t, (void*)&big_len, 4);
  memcpy(t+4, (void*)&big_ID, 2);
  memcpy(t+6, bytes, len);
  
  NSData* data = [[NSData alloc] initWithBytes:t length:len+6];
  free(t);
  return data;
}
@end






































