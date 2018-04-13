//
//  aac_thread.hpp
//  sportdream
//
//  Created by lili on 2018/3/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef aac_thread_hpp
#define aac_thread_hpp

#include <stdio.h>
#include <pthread.h>
#include "live_packet_pool.hpp"
#include "live_audio_packet_pool.hpp"
#include "audio_encoder.hpp"

class AudioEncoderAdapter{
public:
  AudioEncoderAdapter();
  virtual ~AudioEncoderAdapter();
  
  void init(LivePacketPool* pcmPacketPool, int audioSampleRate, int audioChannels,
            int audioBitRate, const char* audio_codec_name);
  virtual void destroy();
  
protected:
  /** 控制编码线程的状态量 **/
  bool                     isEncoding;
  /** 编码线程的变量与方法 **/
  AudioEncoder*                 audioEncoder;
  pthread_t                   audioEncoderThread;
  static void* startEncodeThread(void* ptr);
  void startEncode();
  
  /** 负责从pcmPacketPool中取数据, 调用编码器编码之后放入aacPacketPool中 **/
  LivePacketPool*                 pcmPacketPool;
  LiveAudioPacketPool*             aacPacketPool;
  /** 由于音频的buffer大小和每一帧的大小不一样，所以我们利用缓存数据的方式来 分次得到正确的音频数据 **/
  int                       packetBufferSize;
  short*                     packetBuffer;
  int                       packetBufferCursor;
  int                       audioSampleRate;
  int                       audioChannels;
  int                       audioBitRate;
  char*                    audioCodecName;
  double                     packetBufferPresentationTimeMills;
  
  /** 安卓和iOS平台的输入声道是不一样的, 所以设置channelRatio这个参数 **/
  float                     channelRatio;
  
  int cpyToSamples(int16_t * samples, int samplesInShortCursor, int cpyPacketBufferSize, double* presentationTimeMills);
  
  int getAudioPacket();
  
  virtual int processAudio(){
    return packetBufferSize;
  };
  
  virtual void discardAudioPacket();
public:
  int getAudioFrame(int16_t * samples, int frame_size, int nb_channels, double* presentationTimeMills);
  
};

#endif /* aac_thread_hpp */
