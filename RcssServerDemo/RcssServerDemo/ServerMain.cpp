//
//  ServerMain.cpp
//  RcssServerDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#include "ServerMain.hpp"
#include "serverparam.h"
#include <pthread.h>

ServerMain::ServerMain(int roomid){
    mRoomId = roomid;
}

ServerMain::~ServerMain(){
    delete timer;
}

void ServerMain::init(){
    std::locale::global( std::locale::classic() );
    ServerParam::init();
    stadium.init();
    timer = new StandardTimer(stadium);
}

void ServerMain::run(){
    pthread_create(&mThread, 0, &startThread, this);
}

void* ServerMain::startThread(void* p){
    static_cast<ServerMain*>(p)->StartRoutine();
    return NULL;
}

void ServerMain::StartRoutine(){
    timer->run();
    int i=0;
}

showinfo_double ServerMain::getCurrentInfo(){
    return stadium.getCurrentInfo();
}

void ServerMain::KickOff(){
    stadium.kickOff();
}
