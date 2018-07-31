//
//  RobotMain.hpp
//  FootballAgentDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#ifndef RobotMain_hpp
#define RobotMain_hpp

#include <stdio.h>
#include "src/Coach.h"
#include "src/Player.h"
#include "src/Logger.h"
#include "src/Trainer.h"

class RobotMain{
public:
    RobotMain();
    virtual ~RobotMain();
    void init(char* pEsp01,
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
              char* pLogfilepath,char* ip,char* teamname);
    void run();
    static void* startThread(void* p);
    void StartRoutine();
private:
    pthread_t mThreadID;
    char* mIp;
    char* mTeamname;
};

#endif /* RobotMain_hpp */
