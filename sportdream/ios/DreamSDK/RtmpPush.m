//
//  RtmpPush.m
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "RtmpPush.h"

#define RTMP_HEAD_SIZE   (sizeof(PILI_RTMPPacket)+RTMP_MAX_HEADER_SIZE)

@interface RtmpPush()
@property (nonatomic,assign) uint32_t sendtimestamp;
@end

@implementation RtmpPush
{
  dispatch_queue_t _sendRtmpQueue;
  PILI_RTMP* m_pRtmp;
  int _audioSampleRate; //音频采样率
}

-(id)init
{
  self = [super init];
  if(self){
    m_pRtmp = NULL;
    self.sendtimestamp = 0;
    _sendRtmpQueue = dispatch_queue_create("sendrtmpqueue", DISPATCH_QUEUE_SERIAL);
    _audioSampleRate = 44100;
  }
  return self;
}

//开始rtmp推送
-(bool)startRtmp:(NSString*) pushUrl
{
  m_pRtmp = PILI_RTMP_Alloc();
  PILI_RTMP_Init(m_pRtmp);
  if(!PILI_RTMP_SetupURL(m_pRtmp, [pushUrl UTF8String],NULL)){
    PILI_RTMP_Free(m_pRtmp);
    return false;
  }
  PILI_RTMP_EnableWrite(m_pRtmp);
  if(!PILI_RTMP_Connect(m_pRtmp, NULL, NULL)){
    PILI_RTMP_Free(m_pRtmp);
    return false;
  }
  if(!PILI_RTMP_ConnectStream(m_pRtmp, 0, NULL)){
    PILI_RTMP_Close(m_pRtmp, NULL);
    PILI_RTMP_Free(m_pRtmp);
    return false;
  }
  NSLog(@"rtmp connect success");
  return true;
}

//结束rtmp推送
-(void)stopRtmp
{
  if(m_pRtmp){
    PILI_RTMP_Close(m_pRtmp, NULL);
    //PILI_RTMP_Free(m_pRtmp);
    //m_pRtmp = NULL;
  }
}

//推送H264 sps pps 信息
-(int)sendVideoSpsPps:(uint8_t*)pps ppsLen:(int)ppsLen sps:(uint8_t*)sps spsLen:(int)spsLen
{
  PILI_RTMPPacket* packet = NULL;
  uint8_t* body = NULL;
  int i;
  packet = (PILI_RTMPPacket*)malloc(RTMP_HEAD_SIZE+1024);
  memset(packet,0,RTMP_HEAD_SIZE+1024);
  packet->m_body = (char*)packet + RTMP_HEAD_SIZE;
  body = (unsigned char*)packet->m_body;
  i=0;
  body[i++] = 0x17;
  body[i++] = 0x00;
  
  body[i++] = 0x00;
  body[i++] = 0x00;
  body[i++] = 0x00;
  
  body[i++] = 0x01;
  body[i++] = sps[1];
  body[i++] = sps[2];
  body[i++] = sps[3];
  body[i++] = 0xff;
  
  body[i++]   = 0xe1;
  body[i++] = (spsLen >> 8) & 0xff;
  body[i++] = spsLen & 0xff;
  memcpy(&body[i],sps,spsLen);
  i +=  spsLen;
  
  /*pps*/
  body[i++]   = 0x01;
  body[i++] = (ppsLen >> 8) & 0xff;
  body[i++] = (ppsLen) & 0xff;
  memcpy(&body[i],pps,ppsLen);
  i +=  ppsLen;
  
  packet->m_packetType = RTMP_PACKET_TYPE_VIDEO;
  packet->m_nBodySize = i;
  packet->m_nChannel = 0x04;
  self.sendtimestamp++;
  packet->m_nTimeStamp = self.sendtimestamp;
  packet->m_hasAbsTimestamp = 0;
  packet->m_headerType = RTMP_PACKET_SIZE_MEDIUM;
  packet->m_nInfoField2 = m_pRtmp->m_stream_id;
  int nRet = PILI_RTMP_SendPacket(m_pRtmp, packet, true, NULL);
  free(packet);
  return nRet;
}

-(void)sendAACHeader
{
  //AAC头部固定4个字节
  /*
   音频同步包大小固定为 4 个字节。前两个字节被称为 [AACDecoderSpecificInfo]，
   用于描述这个音频包应当如何被解析。后两个字节称为 [AudioSpecificConfig]，更加详细的指定了音频格式。
   [AACDecoderSpecificInfo] 第 1 个字节高 4 位 |1010| 代表音频数据编码类型为 AAC，
   接下来 2 位 |11| 表示采样率为 44kHz，接下来 1 位 |1| 表示采样点位数16bit，最低 1 位 |1| 表示双声道。
   其第二个字节表示数据包类型，0 则为 AAC 音频同步包，1 则为普通 AAC 数据包。
   */
  PILI_RTMPPacket* packet = NULL;
  uint8_t* body = NULL;
  int i;
  packet = (PILI_RTMPPacket*)malloc(RTMP_HEAD_SIZE+4);
  memset(packet,0,RTMP_HEAD_SIZE+4);
  packet->m_body = (char*)packet + RTMP_HEAD_SIZE;
  body = (unsigned char*)packet->m_body;
  i=0;
  body[i++] = 0xAE;
  body[i++] = 0x00;
  
  uint16_t audio_specific_config = 0;
  audio_specific_config |= ((2<<11)&0xF800); //2:AAC-LC(Low Complexity)
  audio_specific_config |= ((4<<7)&0x0780); //4:44kHz
  audio_specific_config |= ((1<<3)&0x78); // 2:立体声,1:单通道
  audio_specific_config |= 0&0x07; //padding:000
  body[i++] = (audio_specific_config>>8)&0xFF;
  body[i++] = audio_specific_config&0xFF;
  
  packet->m_packetType = RTMP_PACKET_TYPE_AUDIO;
  packet->m_nBodySize = i;
  packet->m_nChannel = 0x04;
  self.sendtimestamp++;
  packet->m_nTimeStamp = self.sendtimestamp;
  packet->m_hasAbsTimestamp = 0;
  packet->m_headerType = RTMP_PACKET_SIZE_MEDIUM;
  packet->m_nInfoField2 = m_pRtmp->m_stream_id;
  int nRet = PILI_RTMP_SendPacket(m_pRtmp, packet, true, NULL);
  free(packet);
}

//推送AAC数据
-(void)sendAACPacket:(void*)data size:(int)size
{
  uint8_t* body = (uint8_t*)malloc(size+2);
  memset(body, 0, size+2);
  int i=0;
  body[i++] = 0xAE;
  body[i++] = 0x01;
  memcpy(&body[i], data, size);
  int bRet = [self sendRtmpPacket:RTMP_PACKET_TYPE_AUDIO data:body size:i+size];
  free(body);
}

//推送H264帧数据
-(int)sendH264Packet:(void*)data size:(int)size isKeyFrame:(bool)isKeyFrame
{
  uint8_t* body = (uint8_t*)malloc(size+9);
  memset(body, 0, size+9);
  
  int i=0;
  if(isKeyFrame){
    body[i++] = 0x17;// 1:Iframe  7:AVC
    body[i++] = 0x01;// AVC NALU
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = 0x00;
    
    
    // NALU size
    body[i++] = size>>24 &0xff;
    body[i++] = size>>16 &0xff;
    body[i++] = size>>8 &0xff;
    body[i++] = size&0xff;
    // NALU data
    memcpy(&body[i],data,size);
  }else{
    body[i++] = 0x27;// 2:Pframe  7:AVC
    body[i++] = 0x01;// AVC NALU
    body[i++] = 0x00;
    body[i++] = 0x00;
    body[i++] = 0x00;
    
    
    // NALU size
    body[i++] = size>>24 &0xff;
    body[i++] = size>>16 &0xff;
    body[i++] = size>>8 &0xff;
    body[i++] = size&0xff;
    // NALU data
    memcpy(&body[i],data,size);
  }
  
  int bRet = [self sendRtmpPacket:RTMP_PACKET_TYPE_VIDEO data:body size:i+size];
  free(body);
  return bRet;
}

//推送rtmp包
-(int)sendRtmpPacket:(int)packetType data:(uint8_t*)data size:(int)size
{
  
  PILI_RTMPPacket* packet;
  packet = (PILI_RTMPPacket*)malloc(RTMP_HEAD_SIZE+size);
  memset(packet, 0, RTMP_HEAD_SIZE);
  packet->m_body = (char*)packet + RTMP_HEAD_SIZE;
  packet->m_nBodySize = size;
  memcpy(packet->m_body, data, size);
  packet->m_hasAbsTimestamp = 0;
  packet->m_packetType = packetType; /*此处为类型有两种一种是音频,一种是视频*/
  packet->m_nInfoField2 = m_pRtmp->m_stream_id;
  packet->m_nChannel = 0x04;
  packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
  if (RTMP_PACKET_TYPE_AUDIO ==packetType && size !=4)
  {
    packet->m_headerType = RTMP_PACKET_SIZE_MEDIUM;
  }
  if(packetType == RTMP_PACKET_TYPE_AUDIO){
    self.sendtimestamp += 1024 * 1000 / _audioSampleRate;
  }else{
    self.sendtimestamp += 1;
  }
  
  packet->m_nTimeStamp = self.sendtimestamp;
  if(PILI_RTMP_IsConnected(m_pRtmp)){
    dispatch_async(_sendRtmpQueue, ^{
      if(!m_pRtmp){
        return;
      }
      int nRet = 0;
      nRet = PILI_RTMP_SendPacket(m_pRtmp, packet, true, NULL);
      free(packet);
    });
  }
  //NSLog(@"send packet");
  return 1;
}


@end
