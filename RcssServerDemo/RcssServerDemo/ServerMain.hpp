//
//  ServerMain.hpp
//  RcssServerDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#ifndef ServerMain_hpp
#define ServerMain_hpp

#include <stdio.h>
#include "src/stadium.h"
#include "stdtimer.h"
class ServerMain
{
public:
    ServerMain(int roomid);
    virtual ~ServerMain();
    void init();
    void run();
    static void * startThread(void* p);
    void StartRoutine();
    //获得当前场上球员和球的信息，上层会定时调用，用来更新界面
    showinfo_double getCurrentInfo();
public:
    void KickOff();
private:
    int mRoomId;
    Stadium stadium;
    Timer* timer;
    pthread_t mThread;
};
#endif /* ServerMain_hpp */
