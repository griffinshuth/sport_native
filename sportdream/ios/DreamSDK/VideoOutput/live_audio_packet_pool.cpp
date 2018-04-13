//
//  live_audio_packet_pool.cpp
//  sportdream
//
//  Created by lili on 2018/3/28.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#include "live_audio_packet_pool.hpp"

LiveAudioPacketPool::LiveAudioPacketPool(){
  audioPacketQueue = NULL;
}

LiveAudioPacketPool::~LiveAudioPacketPool() {
}

LiveAudioPacketPool* LiveAudioPacketPool::instance = new LiveAudioPacketPool();
LiveAudioPacketPool* LiveAudioPacketPool::GetInstance(){
  return instance;
}

void LiveAudioPacketPool::initAudioPacketQueue(){
  const char* name = "audioPacket AAC Data queue";
  audioPacketQueue = new LiveAudioPacketQueue(name);
}

void LiveAudioPacketPool::abortAudioPacketQueue(){
  if(NULL != audioPacketQueue){
    audioPacketQueue->abort();
  }
}

void LiveAudioPacketPool::destoryAudioPacketQueue(){
  if(NULL != audioPacketQueue){
    delete audioPacketQueue;
    audioPacketQueue = NULL;
  }
}

int LiveAudioPacketPool::getAudioPacket(LiveAudioPacket **audioPacket, bool block){
  int result = -1;
  if(NULL != audioPacketQueue){
    result = audioPacketQueue->get(audioPacket, block);
  }
  return result;
}

int LiveAudioPacketPool::getAudioPacketQueueSize(){
  return audioPacketQueue->size();
}

void LiveAudioPacketPool::pushAudioPacketToQueue(LiveAudioPacket* audioPacket){
  if(NULL != audioPacketQueue){
    audioPacketQueue->put(audioPacket);
  }
}
