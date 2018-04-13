//
//  live_audio_packet_queue.hpp
//  sportdream
//
//  Created by lili on 2018/3/26.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef live_audio_packet_queue_hpp
#define live_audio_packet_queue_hpp

#include <stdio.h>
#include <pthread.h>
#include "platform_4_live_common.h"

typedef struct LiveAudioPacket{
  short* buffer;
  byte* data;
  int size;
  float position;
  long frameNum;
  
  LiveAudioPacket(){
    buffer = NULL;
    data = NULL;
    size = 0;
    position = -1;
  }
  
  ~LiveAudioPacket(){
    if(NULL != buffer){
      delete[] buffer;
      buffer = NULL;
    }
    
    if(NULL != data){
      delete[] data;
      data = NULL;
    }
  }
} LiveAudioPacket;

typedef struct LiveAudioPacketList{
  LiveAudioPacket* pkt;
  struct LiveAudioPacketList* next;
  LiveAudioPacketList(){
    pkt = NULL;
    next = NULL;
  }
} LiveAudioPacketList;

inline void buildPacketFromBuffer(LiveAudioPacket* audioPacket,short* samples,int sampleSize){
  short* packetBuffer = new short[sampleSize];
  if(NULL != packetBuffer){
    memcpy(packetBuffer, samples, sampleSize*2);
    audioPacket->buffer = packetBuffer;
    audioPacket->size = sampleSize;
  }else{
    audioPacket->size = -1;
  }
}

class LiveAudioPacketQueue{
public:
  LiveAudioPacketQueue();
  LiveAudioPacketQueue(const char*  queueNameParam);
  ~LiveAudioPacketQueue();
  
  void init();
  void flush();
  int put(LiveAudioPacket* audioPacket);
  int get(LiveAudioPacket **audioPacket, bool block);
  int size();
  void abort();
  
private:
  LiveAudioPacketList* mFirst;
  LiveAudioPacketList* mLast;
  int mNbPackets;
  bool mAbortRequest;
  pthread_mutex_t mLock;
  pthread_cond_t mCondition;
  const char* queueName;
};

#endif /* live_audio_packet_queue_hpp */













































