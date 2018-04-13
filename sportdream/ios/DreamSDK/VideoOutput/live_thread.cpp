//
//  live_thread.cpp
//  sportdream
//
//  Created by lili on 2018/3/27.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#include "live_thread.hpp"

LiveThread::LiveThread(){
  pthread_mutex_init(&mLock, NULL);
  pthread_cond_init(&mCondition, NULL);
}

LiveThread::~LiveThread(){
  
}

void LiveThread::start(){
  handleRun(NULL);
}

void LiveThread::startAsync(){
  pthread_create(&mThread, NULL, startThread, this);
}

int LiveThread::wait(){
  if(!mRunning){
    return 0;
  }
  
  void* status;
  int ret = pthread_join(mThread,&status);
  return ret;
}

void LiveThread::stop(){
  
}

void* LiveThread::startThread(void* ptr){
  LiveThread* thread = (LiveThread *) ptr;
  thread->mRunning = true;
  thread->handleRun(ptr);
  thread->mRunning = false;
  return NULL;
}

void LiveThread::waitOnNotify(){
  pthread_mutex_lock(&mLock);
  pthread_cond_wait(&mCondition, &mLock);
  pthread_mutex_unlock(&mLock);
}

void LiveThread::notify(){
  pthread_mutex_lock(&mLock);
  pthread_cond_signal(&mCondition);
  pthread_mutex_unlock(&mLock);
}

void LiveThread::handleRun(void* ptr) {
}
