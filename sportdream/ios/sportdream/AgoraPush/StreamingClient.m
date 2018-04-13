//
//  StreamingClient.m
//  sportdream
//
//  Created by lili on 2018/1/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "StreamingClient.h"
#import "RtmpPush.h"


NSTimeInterval const YUVDataSendTimeInterval = 0.05;
NSTimeInterval const PCMDataSendTimeInterval = 0.01;
int const PCMDataSendLength = 2048;

@interface StreamingClient()
  @property (nonatomic,strong) h264encode* encode;
@property (nonatomic,strong) AACEncode* audioEncode;
  @property (nonatomic,strong) RtmpPush* rtmpPush;
@end

@implementation StreamingClient
{
  FILE *_h264File;
  FILE *_AACFile;
  BOOL _isAudioHeaderSend;
}
-(id)init
{
  if(self = [super init])
  {
    _isAudioHeaderSend = false;
  }
  return self;
}

-(void)dealloc
{
 
}

//delegate
-(void)rtmpSpsPps:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen timestramp:(Float64)miliseconds;
{
  [self.rtmpPush sendVideoSpsPps:(void*)pps ppsLen:(int)ppsLen sps:(void*)sps spsLen:(int)spsLen];
}
-(void)rtmpH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts
{
  [self.rtmpPush sendH264Packet:(void*)data size:(int)length isKeyFrame:isKeyFrame];
}
-(void)dataEncodeToH264:(const void*)data length:(size_t)length;
{
  [self writeH264Data:data length:length];
}

-(void)dataEncodeToAAC:(NSData *)data
{
  if(!_isAudioHeaderSend){
    _isAudioHeaderSend = true;
    [self.rtmpPush sendAACHeader];
  }
  [self.rtmpPush sendAACPacket:(void*)data.bytes size:(int)data.length];
  
  //
  uint32_t packetlen = (uint32_t)(data.length+7);
  uint8_t* header = [self addADTStoPacket:packetlen];
  [self writeAACData:(int8_t*)data.bytes length:data.length adtsHeader:header];
  free(header);
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

-(uint8_t*)addADTStoPacket:(uint32_t)packetlen
{
  uint8_t* header = malloc(7);
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


-(void)startStreaming
{
  int width = 1280;
  int height = 720;
  NSString* documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  _h264File = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,@"agorapushvideo.h264"] UTF8String], "ab+");
  _AACFile = fopen([[NSString stringWithFormat:@"%@/%@",documentDictionary,@"agorapushaudio.aac"] UTF8String], "ab+");
  self.encode = [[h264encode alloc] initEncodeWith:width height:height framerate:25 bitrate:1600*1000];
  self.encode.delegate = self;
  [self.encode startH264EncodeSession];
  self.audioEncode = [[AACEncode alloc] init];
  self.audioEncode.delegate = self;
  _isAudioHeaderSend = false;
  [self.audioEncode startAACEncodeSession];
  self.rtmpPush = [[RtmpPush alloc] init];
  [self.rtmpPush startRtmp:@"rtmp://pili-publish.2310live.com/grasslive/test2"];
}

-(void)stopStreaming
{
  fclose(_h264File);
  fclose(_AACFile);
  [self.encode stopH264EncodeSession];
  [self.audioEncode stopAACEncodeSession];
  self.encode = nil;
  [self.rtmpPush stopRtmp];
  self.rtmpPush = nil;
  _isAudioHeaderSend = false;
}

- (void)sendYUVData:(unsigned char *)pYUVBuff dataLength:(unsigned int)length
{
  //send video data
  NSData *sampleBuffer = [NSData dataWithBytesNoCopy:pYUVBuff length:length];
  [self.encode encodeH264Frame:sampleBuffer];
}

- (void)sendPCMData:(unsigned char*)pPCMData dataLength:(unsigned int)length
{
  //send audio data
  NSData* buffer = [[NSData alloc] initWithBytes:pPCMData length:length];
  [self.audioEncode encodeNSDataPCMData:buffer];
}
@end
