//
//  live_audio_packet_pool.hpp
//  sportdream
//
//  Created by lili on 2018/3/28.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef live_audio_packet_pool_hpp
#define live_audio_packet_pool_hpp

#include <stdio.h>
#include "live_audio_packet_queue.hpp"

class LiveAudioPacketPool{
protected:
  LiveAudioPacketPool();
  static LiveAudioPacketPool* instance;
  LiveAudioPacketQueue* audioPacketQueue;
  
public:
  static LiveAudioPacketPool* GetInstance();
  virtual ~LiveAudioPacketPool();
  
  /** 人声的packet queue的所有操作 **/
  virtual void initAudioPacketQueue();
  virtual void abortAudioPacketQueue();
  virtual void destoryAudioPacketQueue();
  virtual int getAudioPacket(LiveAudioPacket **audioPacket, bool block);
  virtual void pushAudioPacketToQueue(LiveAudioPacket* audioPacket);
  virtual int getAudioPacketQueueSize();
};

#endif /* live_audio_packet_pool_hpp */
