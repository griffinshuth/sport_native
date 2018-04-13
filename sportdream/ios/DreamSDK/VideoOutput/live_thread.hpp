//
//  live_thread.hpp
//  sportdream
//
//  Created by lili on 2018/3/27.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#ifndef live_thread_hpp
#define live_thread_hpp

#include <stdio.h>
#include <pthread.h>
#include "platform_4_live_common.h"

class LiveThread{
public:
  LiveThread();
  ~LiveThread();
  
  void start();
  void startAsync();
  int wait();
  
  void waitOnNotify();
  void notify();
  virtual void stop();
  
protected:
  bool mRunning;
  virtual void handleRun(void* ptr);
  
protected:
  pthread_t mThread;
  pthread_mutex_t mLock;
  pthread_cond_t mCondition;
  static void* startThread(void* ptr);
};

#endif /* live_thread_hpp */
