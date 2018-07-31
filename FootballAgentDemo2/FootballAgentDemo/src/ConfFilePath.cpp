//
//  ConfFilePath.cpp
//  FootballAgentDemo
//
//  Created by lili on 2018/6/27.
//  Copyright © 2018年 lili. All rights reserved.
//

#include "ConfFilePath.hpp"

ConfFilePath::ConfFilePath(){
    
}

ConfFilePath::~ConfFilePath(){
    
}

ConfFilePath& ConfFilePath::instance(){
    static ConfFilePath item;
    return item;
}

void ConfFilePath::init(
                        char* pEsp01,
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
                        char* pLogfilepath
                        ){
    this->eps01 = pEsp01;
    this->eps001 = pEsp001;
    this->kicker_value = pKicker_value;
    this->player_conf = pPlayer_conf;
    this->sensitivity_net = pSensitivity_net;
    this->sensitivity_train = pSensitivity_train;
    this->server_conf = pServer_conf;
    this->train_conf = pTrain_conf;
    this->Attack433 = pAttack433;
    this->Defend433 = pDefend433;
    this->Attack442 = pAttack442;
    this->Defend442 = pDefend442;
    this->logfilepath = pLogfilepath;
}
