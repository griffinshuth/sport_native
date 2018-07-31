//
//  FootBallServer.m
//  RcssServerDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#import "FootBallServer.h"
#import "ServerMain.hpp"

@implementation FootBallServer
{
    ServerMain* server;
    //定时器
    NSTimer* timer;
}
-(id)initWithRoomId:(int)roomId
{
    self = [super init];
    if(self){
        server = new ServerMain(roomId);
        timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    return self;
}

-(void)dealloc
{
    if(server != NULL){
        delete server;
    }
    [timer invalidate];
}

//更新球员和足球的位置等信息
-(void)updateUI
{
    showinfo_double show = server->getCurrentInfo();
    //NSLog(@"ball:%d,%d",show.pos[0].x,show.pos[0].y);
    CourtInfo* info = [[CourtInfo alloc] init];
    info.time = show.time;
    info.mode = show.pmode;
    info.ball = [[PosInfo alloc] init];
    info.ball.x = show.pos[0].x;
    info.ball.y = show.pos[0].y;
    info.players = [[NSMutableArray alloc] init];
    for(int i=0;i<MAX_PLAYER*2;i++){
        PosInfo* p = [[PosInfo alloc] init];
        p.enable = show.pos[i+1].enable;
        p.x = show.pos[i+1].x;
        p.y = show.pos[i+1].y;
        p.angle = show.pos[i+1].angle;
        p.side = show.pos[i+1].side;
        p.unum = show.pos[i+1].unum;
        [info.players addObject:p];
    }
    info.teams = [[NSMutableArray alloc] init];
    for(int i=0;i<2;i++){
        TeamInfo* t = [[TeamInfo alloc] init];
        t.name = [[NSString alloc] initWithFormat:@"%s",show.team[i].name];
        t.score = show.team[i].score;
        [info.teams addObject:t];
    }
    [self.delegate StadiumUpdate:info];
}

-(void)startServer
{
    server->init();
    server->run();
}

-(void)kickOff
{
    server->KickOff();
}
@end
