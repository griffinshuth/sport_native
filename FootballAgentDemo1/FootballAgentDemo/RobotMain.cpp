//
//  RobotMain.cpp
//  FootballAgentDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#include "RobotMain.hpp"
#include "src/ConfFilePath.hpp"
#include "src/ServerParam.h"
#include "src/PlayerParam.h"
#include <pthread.h>
#include "src/PthreadKeys.h"

RobotMain::RobotMain(){
    
}
RobotMain::~RobotMain(){
   
}

void RobotMain::init(char* pEsp01,
                     char* pEsp001,
                     char* pKicker_value,
                     char* pPlayer_conf,
                     char* pSensitivity_net,
                     char* pSensitivity_train,
                     char* pServer_conf,
                     char* pTrain_conf,
                     char* pAttack433,
                     char* pDefend433,
                     char* pAttack442,
                     char* pDefend442,
                     char* pLogfilepath,
                     char* ip,char* teamname){
    ConfFilePath::instance().init(pEsp01,
                                  pEsp001,
                                  pKicker_value,
                                  pPlayer_conf,
                                  pSensitivity_net,
                                  pSensitivity_train,
                                  pServer_conf,
                                  pTrain_conf,
                                  pAttack433,
                                  pDefend433,
                                  pAttack442,
                                  pDefend442,
                                  pLogfilepath);
   
    mIp = ip;
    mTeamname = teamname;
}

void RobotMain::run(){
    pthread_create(&mThreadID, 0, &startThread, this);
}

void* RobotMain::startThread(void* p)
{
    static_cast<RobotMain*>(p)->StartRoutine();
    return NULL;
}

void RobotMain::StartRoutine()
{
    //启动守门员
    Client* goalie = NULL;
    goalie = new Player(mIp, mTeamname, true, false, false);
    goalie->Start();
    sleep(5);
    
    Client* players[10];
    for(int i=0;i<10;i++){
        players[i] = new Player(mIp,mTeamname,false,false,false);
        players[i]->Start();
        sleep(2);
    }
    Client* coach = new Coach(mIp,mTeamname,false,true,false);
    coach->Start();
    sleep(2);
    
    goalie->Join();
    for(int i=0;i<10;i++){
        players[i]->Join();
    }
    coach->Join();
    
}
