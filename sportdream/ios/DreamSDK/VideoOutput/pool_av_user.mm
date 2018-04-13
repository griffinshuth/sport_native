//
//  pool_av_user.m
//  sportdream
//
//  Created by lili on 2018/3/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "pool_av_user.h"

@implementation pool_av_user
+(void)sendAudioDataToPool:(void*)buffer length:(int)length
{
  int sampleCount = length / 2;
  short *packetBuffer = new short[sampleCount];
  memcpy(packetBuffer, buffer, length);
  LiveAudioPacket *audioPacket = new LiveAudioPacket();
  audioPacket->buffer = packetBuffer;
  audioPacket->size = length/2;
  LivePacketPool::GetInstance()->pushAudioPacketToQueue(audioPacket);
}
+(void)sendSpsPpsToPool:(NSData*)sps pps:(NSData*)pps timestramp:(Float64)miliseconds
{
  const char bytesHeader[] = "\x00\x00\x00\x01";
  size_t headerLength = 4; //string literals have implicit trailing '\0'
  
  LiveVideoPacket* spsPpsVideoPacket = new LiveVideoPacket();
  size_t length = 2*headerLength+sps.length+pps.length;
  spsPpsVideoPacket->buffer = new unsigned char[length];
  spsPpsVideoPacket->size = int(length);
  memcpy(spsPpsVideoPacket->buffer, bytesHeader, headerLength);
  memcpy(spsPpsVideoPacket->buffer + headerLength, (unsigned char*)[sps bytes], sps.length);
  memcpy(spsPpsVideoPacket->buffer + headerLength + sps.length, bytesHeader, headerLength);
  memcpy(spsPpsVideoPacket->buffer + headerLength*2 + sps.length, (unsigned char*)[pps bytes], pps.length);
  spsPpsVideoPacket->timeMills = 0;
  LivePacketPool::GetInstance()->pushRecordingVideoPacketToQueue(spsPpsVideoPacket);
}
+(void)sendVideoDataToPool:(NSData*)data isKeyFrame:(BOOL)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  const char bytesHeader[] = "\x00\x00\x00\x01";
  size_t headerLength = 4; //string literals have implicit trailing '\0'
  
  LiveVideoPacket* videoPacket = new LiveVideoPacket();
  
  videoPacket->buffer = new unsigned char[headerLength+data.length];
  videoPacket->size = int(headerLength+data.length);
  memcpy(videoPacket->buffer,bytesHeader, headerLength);
  memcpy(videoPacket->buffer + headerLength, (unsigned char*)[data bytes], data.length);
  videoPacket->timeMills = miliseconds;
  //    videoPacket->pts = pts;
  //    videoPacket->dts = dts;
  LivePacketPool::GetInstance()->pushRecordingVideoPacketToQueue(videoPacket);
}

@end
