//
//  ConfFilePath.hpp
//  FootballAgentDemo
//
//  Created by lili on 2018/6/27.
//  Copyright © 2018年 lili. All rights reserved.
//

#ifndef ConfFilePath_hpp
#define ConfFilePath_hpp

#include <stdio.h>
class ConfFilePath
{
private:
    ConfFilePath();
    ConfFilePath(const ConfFilePath&);
    ConfFilePath& operator=(const ConfFilePath&);
public:
    virtual ~ConfFilePath();
    static ConfFilePath& instance();
    void init(
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
              );
    
    const char* getFilePathOfeps01(){
        return eps01;
    }
    const char* getFilePathOfeps001(){
        return eps001;
    }
    const char* getFilePathOfkicker_value(){
        return kicker_value;
    }
    const char* getFilePathOfplayer_conf(){
        return player_conf;
    }
    const char* getFilePathOfsensitivity_net(){
        return sensitivity_net;
    }
    const char* getFilePathOfsensitivity_train(){
        return sensitivity_train;
    }
    const char* getFilePathOfserver_conf(){
        return server_conf;
    }
    const char* getFilePathOftrain_conf(){
        return train_conf;
    }
    const char* getFilePathOfAttack433(){
        return Attack433;
    }
    const char* getFilePathOfDefend433(){
        return Defend433;
    }
    const char* getFilePathOfAttack442(){
        return Attack442;
    }
    const char* getFilePathOfDefend442(){
        return Defend442;
    }
    const char* getFilePathOfLog(){
        return logfilepath;
    }
private:
    char* eps01;
    char* eps001;
    char* kicker_value;
    char* player_conf;
    char* sensitivity_net;
    char* sensitivity_train;
    char* server_conf;
    char* train_conf;
    char* Attack433;
    char* Defend433;
    char* Attack442;
    char* Defend442;
    char* logfilepath;
};
#endif /* ConfFilePath_hpp */
