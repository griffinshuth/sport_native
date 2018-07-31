//
//  FootballRobots.m
//  FootballAgentDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#import "FootballRobots.h"
#import "RobotMain.hpp"

const int MAXPLAYERS = 10;
@implementation FootballRobots
{
    int mUserId;
    int mRoomId;
    NSString* mEps01FilePath;
    NSString* mEps001FilePath;
    NSString* mKicker_valueFilePath;
    NSString* mPlayer_confFilePath;
    NSString* mSensitivity_netFilePath;
    NSString* mSensitivity_trainFilePath;
    NSString* mServer_confFilePath;
    NSString* mTrain_confFilePath;
    NSString* mAttack433FilePath;
    NSString* mDefend433FilePath;
    NSString* mAttack442FilePath;
    NSString* mDefend442FilePath;
    NSString* logFilePath;
    NSString* ip;
    NSString* teamname;
    
    RobotMain* team1;
    
}

-(id)initWithUserId:(int)userId roomid:(int)roomId
{
    self = [super init];
    if(self){
        mUserId = userId;
        mRoomId = roomId;
        mEps01FilePath = [[NSBundle mainBundle]pathForResource:@"eps01" ofType:@"conf"];
        mEps001FilePath = [[NSBundle mainBundle]pathForResource:@"eps001" ofType:@"conf"];
        mKicker_valueFilePath = [[NSBundle mainBundle]pathForResource:@"kicker_value" ofType:@"conf"];
        mPlayer_confFilePath = [[NSBundle mainBundle]pathForResource:@"player" ofType:@"conf"];
        mSensitivity_netFilePath = [[NSBundle mainBundle]pathForResource:@"sensitivity" ofType:@"net"];
        mSensitivity_trainFilePath = [[NSBundle mainBundle]pathForResource:@"sensitivity" ofType:@"train"];
        mServer_confFilePath = [[NSBundle mainBundle]pathForResource:@"server" ofType:@"conf"];
        mTrain_confFilePath = [[NSBundle mainBundle]pathForResource:@"train" ofType:@"conf"];
        mAttack433FilePath = [[NSBundle mainBundle]pathForResource:@"433_Attack" ofType:@"conf"];
        mDefend433FilePath = [[NSBundle mainBundle]pathForResource:@"433_Defend" ofType:@"conf"];
        mAttack442FilePath = [[NSBundle mainBundle]pathForResource:@"442_Attack" ofType:@"conf"];
        mDefend442FilePath = [[NSBundle mainBundle]pathForResource:@"442_Defend" ofType:@"conf"];
        
        NSString* documentDictionary = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* logfilename = @"robotlog";
        logFilePath = [NSString stringWithFormat:@"%@/%@",documentDictionary,logfilename];
         BOOL bo = [[NSFileManager defaultManager] createDirectoryAtPath:logFilePath withIntermediateDirectories:YES attributes:nil error:nil];
        ip = @"192.168.0.108";
        teamname = @"laker";
        
        team1 = new RobotMain();
    
    }
    return self;
}

-(void)dealloc
{
    delete team1;
}

-(void)startMatch
{
    team1->init((char*)[mEps01FilePath UTF8String],
                (char*)[mEps001FilePath UTF8String],
                (char*)[mKicker_valueFilePath UTF8String],
                (char*)[mPlayer_confFilePath UTF8String],
                (char*)[mSensitivity_netFilePath UTF8String],
                (char*)[mSensitivity_trainFilePath UTF8String],
                (char*)[mServer_confFilePath UTF8String],
                (char*)[mTrain_confFilePath UTF8String],
                (char*)[mAttack433FilePath UTF8String],
                (char*)[mDefend433FilePath UTF8String],
                (char*)[mAttack442FilePath UTF8String],
                (char*)[mDefend442FilePath UTF8String],
                (char*)[logFilePath UTF8String],
                (char*)[ip UTF8String],
                (char*)[teamname UTF8String]
                );
    team1->run();
}
@end
