//
//  MatchDataStruct.m
//  sportdream
//
//  Created by lili on 2018/5/22.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "MatchDataStruct.h"

@implementation MatchDataStruct
-(id)init
{
  self = [super init];
  if(self){
    self.game_uid = -1;
    self.team1_uid = -1;
    self.team2_uid = -1;
    self.team1name = @"";
    self.team2name = @"";
    self.team1logo = @"";
    self.team2logo = @"";
    self.team1MembersOnCourt = [[NSMutableArray alloc] init];
    self.team2MembersOnCourt = [[NSMutableArray alloc] init];
    self.team1MembersOffCourt = [[NSMutableArray alloc] init];
    self.team2MembersOffCourt = [[NSMutableArray alloc] init];
    self.currentattacktime = 24;
    self.currentsection = 1;
    self.currentsectiontime = 0;
    self.team1currentscore = 0;
    self.team2currentscore = 0;
    self.team1timeout = 0;
    self.team2timeout = 0;
    self.team1dataStatistics = [[NSMutableDictionary alloc] init];
    self.team2dataStatistics = [[NSMutableDictionary alloc] init];
    self.timeline = [[NSMutableArray alloc] init];
  }
  return self;
}

//解析从数据统计节点发送过来的比赛json数据，并初始化
-(void)loadMatchData:(NSDictionary*)jsonData
{
  self.game_uid = [jsonData[@"game_uid"] intValue];
  self.team1_uid = [jsonData[@"team1info"][@"teamid"] intValue];
  self.team1name = jsonData[@"team1info"][@"name"];
  self.team1logo =  jsonData[@"team1info"][@"logo"];
  self.team2_uid = [jsonData[@"team2info"][@"teamid"] intValue];
  self.team2name = jsonData[@"team2info"][@"name"];
  self.team2logo =  jsonData[@"team2info"][@"logo"];
  self.currentattacktime = [jsonData[@"currentattacktime"] floatValue];
  self.currentsection = [jsonData[@"currentsection"] intValue];
  self.currentsectiontime = [jsonData[@"currentsectiontime"] floatValue];
  self.team1currentscore = [jsonData[@"team1currentscore"] intValue];
  self.team2currentscore = [jsonData[@"team2currentscore"] intValue];
  self.team1timeout = [jsonData[@"team1timeout"] intValue];
  self.team2timeout = [jsonData[@"team2timeout"] intValue];
  //队伍1场上球员
  for(int i=0;i<[jsonData[@"team1Members"] count];i++){
    NSDictionary* json_player = jsonData[@"team1Members"][i];
    TeamMemberStruct* player = [[TeamMemberStruct alloc] init];
    if([json_player[@"id"] isKindOfClass:[NSString class]]){
      player.faceid = json_player[@"id"];
      player.uid = -1;
    }else{
      player.uid = [json_player[@"id"] intValue];
      player.faceid = nil;
    }
    player.nickname = json_player[@"nickname"];
    player.image = json_player[@"image"];
    [self.team1MembersOnCourt addObject:player];
  }
  //队伍2场上球员
  for(int i=0;i<[jsonData[@"team2Members"] count];i++){
    NSDictionary* json_player = jsonData[@"team2Members"][i];
    TeamMemberStruct* player = [[TeamMemberStruct alloc] init];
    if([json_player[@"id"] isKindOfClass:[NSString class]]){
      player.faceid = json_player[@"id"];
      player.uid = -1;
    }else{
      player.uid = [json_player[@"id"] intValue];
      player.faceid = nil;
    }
    player.nickname = json_player[@"nickname"];
    player.image = json_player[@"image"];
    [self.team2MembersOnCourt addObject:player];
  }
  //队伍1场下球员
  for(int i=0;i<[jsonData[@"members1OffCourt"] count];i++){
    NSDictionary* json_player = jsonData[@"members1OffCourt"][i];
    TeamMemberStruct* player = [[TeamMemberStruct alloc] init];
    if([json_player[@"id"] isKindOfClass:[NSString class]]){
      player.faceid = json_player[@"id"];
      player.uid = -1;
    }else{
      player.uid = [json_player[@"id"] intValue];
      player.faceid = nil;
    }
    player.nickname = json_player[@"nickname"];
    player.image = json_player[@"image"];
    [self.team1MembersOffCourt addObject:player];
  }
  //队伍2场下球员
  for(int i=0;i<[jsonData[@"members2OffCourt"] count];i++){
    NSDictionary* json_player = jsonData[@"members2OffCourt"][i];
    TeamMemberStruct* player = [[TeamMemberStruct alloc] init];
    if([json_player[@"id"] isKindOfClass:[NSString class]]){
      player.faceid = json_player[@"id"];
      player.uid = -1;
    }else{
      player.uid = [json_player[@"id"] intValue];
      player.faceid = nil;
    }
    player.nickname = json_player[@"nickname"];
    player.image = json_player[@"image"];
    [self.team2MembersOffCourt addObject:player];
  }
  //队伍1技术统计
  for(NSString* UidOrFaceid in jsonData[@"team1dataStatistics"]){
    DataStatisticsStruct* statistics = [[DataStatisticsStruct alloc] init];
    //得分
    NSArray* pointsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"point"];
    if(pointsArray){
      statistics.points = [[NSMutableArray alloc] init];
      for(int i=0;i<[pointsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [pointsArray[i][@"number"] intValue];
        cell.section = [pointsArray[i][@"section"] intValue];
        cell.time24 = [pointsArray[i][@"time24"] floatValue];
        cell.time = [pointsArray[i][@"time"] floatValue];
        [statistics.points addObject:cell];
      }
    }
    //篮板
    NSArray* reboundsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"rebound"];
    if(reboundsArray){
      statistics.rebounds = [[NSMutableArray alloc] init];
      for(int i=0;i<[reboundsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [reboundsArray[i][@"number"] intValue];
        cell.section = [reboundsArray[i][@"section"] intValue];
        cell.time24 = [reboundsArray[i][@"time24"] floatValue];
        cell.time = [reboundsArray[i][@"time"] floatValue];
        [statistics.rebounds addObject:cell];
      }
    }
    //助攻
    NSArray* assistsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"assists"];
    if(assistsArray){
      statistics.assists = [[NSMutableArray alloc] init];
      for(int i=0;i<[assistsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [assistsArray[i][@"number"] intValue];
        cell.section = [assistsArray[i][@"section"] intValue];
        cell.time24 = [assistsArray[i][@"time24"] floatValue];
        cell.time = [assistsArray[i][@"time"] floatValue];
        [statistics.assists addObject:cell];
      }
    }
    //盖帽
    NSArray* blocksArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"block"];
    if(blocksArray){
      statistics.blocks = [[NSMutableArray alloc] init];
      for(int i=0;i<[blocksArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [blocksArray[i][@"number"] intValue];
        cell.section = [blocksArray[i][@"section"] intValue];
        cell.time24 = [blocksArray[i][@"time24"] floatValue];
        cell.time = [blocksArray[i][@"time"] floatValue];
        [statistics.blocks addObject:cell];
      }
    }
    //抢断
    NSArray* stealsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"steals"];
    if(stealsArray){
      statistics.steals = [[NSMutableArray alloc] init];
      for(int i=0;i<[stealsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [stealsArray[i][@"number"] intValue];
        cell.section = [stealsArray[i][@"section"] intValue];
        cell.time24 = [stealsArray[i][@"time24"] floatValue];
        cell.time = [stealsArray[i][@"time"] floatValue];
        [statistics.steals addObject:cell];
      }
    }
    //失误
    NSArray* faultsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"fault"];
    if(faultsArray){
      statistics.faults = [[NSMutableArray alloc] init];
      for(int i=0;i<[faultsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [faultsArray[i][@"number"] intValue];
        cell.section = [faultsArray[i][@"section"] intValue];
        cell.time24 = [faultsArray[i][@"time24"] floatValue];
        cell.time = [faultsArray[i][@"time"] floatValue];
        [statistics.faults addObject:cell];
      }
    }
    //犯规
    NSArray* foulsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"foul"];
    if(foulsArray){
      statistics.fouls = [[NSMutableArray alloc] init];
      for(int i=0;i<[foulsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [foulsArray[i][@"number"] intValue];
        cell.section = [foulsArray[i][@"section"] intValue];
        cell.time24 = [foulsArray[i][@"time24"] floatValue];
        cell.time = [foulsArray[i][@"time"] floatValue];
        [statistics.fouls addObject:cell];
      }
    }
    //罚球
    NSArray* freethrowsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"freethrow"];
    if(freethrowsArray){
      statistics.freethrow = [[NSMutableArray alloc] init];
      for(int i=0;i<[freethrowsArray count];i++){
        FreethrowStruct* cell = [[FreethrowStruct alloc] init];
        cell.type = [freethrowsArray[i][@"type"] intValue];
        cell.shoot = [freethrowsArray[i][@"shoot"] intValue];
        cell.score = [freethrowsArray[i][@"score"] intValue];
        cell.section = [freethrowsArray[i][@"section"] intValue];
        cell.time = [freethrowsArray[i][@"time"] floatValue];
        cell.time24 = [freethrowsArray[i][@"time24"] floatValue];
        [statistics.freethrow addObject:cell];
      }
    }
    //投篮
    NSArray* shootsArray = jsonData[@"team1dataStatistics"][UidOrFaceid][@"shoot"];
    if(shootsArray){
      statistics.shoots = [[NSMutableArray alloc] init];
      for(int i=0;i<[shootsArray count];i++){
        ShootStruct* cell = [[ShootStruct alloc] init];
        cell.x = [shootsArray[i][@"x"] floatValue];
        cell.y = [shootsArray[i][@"y"] floatValue];
        cell.point = [shootsArray[i][@"point"] intValue];
        cell.isScore = [shootsArray[i][@"score"] boolValue];
        cell.section = [shootsArray[i][@"section"] intValue];
        cell.time = [shootsArray[i][@"time"] floatValue];
        cell.time24 = [shootsArray[i][@"time24"] floatValue];
        [statistics.shoots addObject:cell];
      }
    }
    
    [self.team1dataStatistics setValue:statistics forKey:UidOrFaceid];
  }
  
  //队伍2技术统计
  for(NSString* UidOrFaceid in jsonData[@"team2dataStatistics"]){
    DataStatisticsStruct* statistics = [[DataStatisticsStruct alloc] init];
    //得分
    NSArray* pointsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"point"];
    if(pointsArray){
      statistics.points = [[NSMutableArray alloc] init];
      for(int i=0;i<[pointsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [pointsArray[i][@"number"] intValue];
        cell.section = [pointsArray[i][@"section"] intValue];
        cell.time24 = [pointsArray[i][@"time24"] floatValue];
        cell.time = [pointsArray[i][@"time"] floatValue];
        [statistics.points addObject:cell];
      }
    }
    //篮板
    NSArray* reboundsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"rebound"];
    if(reboundsArray){
      statistics.rebounds = [[NSMutableArray alloc] init];
      for(int i=0;i<[reboundsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [reboundsArray[i][@"number"] intValue];
        cell.section = [reboundsArray[i][@"section"] intValue];
        cell.time24 = [reboundsArray[i][@"time24"] floatValue];
        cell.time = [reboundsArray[i][@"time"] floatValue];
        [statistics.rebounds addObject:cell];
      }
    }
    //助攻
    NSArray* assistsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"assists"];
    if(assistsArray){
      statistics.assists = [[NSMutableArray alloc] init];
      for(int i=0;i<[assistsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [assistsArray[i][@"number"] intValue];
        cell.section = [assistsArray[i][@"section"] intValue];
        cell.time24 = [assistsArray[i][@"time24"] floatValue];
        cell.time = [assistsArray[i][@"time"] floatValue];
        [statistics.assists addObject:cell];
      }
    }
    //盖帽
    NSArray* blocksArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"block"];
    if(blocksArray){
      statistics.blocks = [[NSMutableArray alloc] init];
      for(int i=0;i<[blocksArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [blocksArray[i][@"number"] intValue];
        cell.section = [blocksArray[i][@"section"] intValue];
        cell.time24 = [blocksArray[i][@"time24"] floatValue];
        cell.time = [blocksArray[i][@"time"] floatValue];
        [statistics.blocks addObject:cell];
      }
    }
    //抢断
    NSArray* stealsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"steals"];
    if(stealsArray){
      statistics.steals = [[NSMutableArray alloc] init];
      for(int i=0;i<[stealsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [stealsArray[i][@"number"] intValue];
        cell.section = [stealsArray[i][@"section"] intValue];
        cell.time24 = [stealsArray[i][@"time24"] floatValue];
        cell.time = [stealsArray[i][@"time"] floatValue];
        [statistics.steals addObject:cell];
      }
    }
    //失误
    NSArray* faultsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"fault"];
    if(faultsArray){
      statistics.faults = [[NSMutableArray alloc] init];
      for(int i=0;i<[faultsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [faultsArray[i][@"number"] intValue];
        cell.section = [faultsArray[i][@"section"] intValue];
        cell.time24 = [faultsArray[i][@"time24"] floatValue];
        cell.time = [faultsArray[i][@"time"] floatValue];
        [statistics.faults addObject:cell];
      }
    }
    //犯规
    NSArray* foulsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"foul"];
    if(foulsArray){
      statistics.fouls = [[NSMutableArray alloc] init];
      for(int i=0;i<[foulsArray count];i++){
        SingleDataStruct* cell = [[SingleDataStruct alloc] init];
        cell.number = [foulsArray[i][@"number"] intValue];
        cell.section = [foulsArray[i][@"section"] intValue];
        cell.time24 = [foulsArray[i][@"time24"] floatValue];
        cell.time = [foulsArray[i][@"time"] floatValue];
        [statistics.fouls addObject:cell];
      }
    }
    //罚球
    NSArray* freethrowsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"freethrow"];
    if(freethrowsArray){
      statistics.freethrow = [[NSMutableArray alloc] init];
      for(int i=0;i<[freethrowsArray count];i++){
        FreethrowStruct* cell = [[FreethrowStruct alloc] init];
        cell.type = [freethrowsArray[i][@"type"] intValue];
        cell.shoot = [freethrowsArray[i][@"shoot"] intValue];
        cell.score = [freethrowsArray[i][@"score"] intValue];
        cell.section = [freethrowsArray[i][@"section"] intValue];
        cell.time = [freethrowsArray[i][@"time"] floatValue];
        cell.time24 = [freethrowsArray[i][@"time24"] floatValue];
        [statistics.freethrow addObject:cell];
      }
    }
    //投篮
    NSArray* shootsArray = jsonData[@"team2dataStatistics"][UidOrFaceid][@"shoot"];
    if(shootsArray){
      statistics.shoots = [[NSMutableArray alloc] init];
      for(int i=0;i<[shootsArray count];i++){
        ShootStruct* cell = [[ShootStruct alloc] init];
        cell.x = [shootsArray[i][@"x"] floatValue];
        cell.y = [shootsArray[i][@"y"] floatValue];
        cell.point = [shootsArray[i][@"point"] intValue];
        cell.isScore = [shootsArray[i][@"score"] boolValue];
        cell.section = [shootsArray[i][@"section"] intValue];
        cell.time = [shootsArray[i][@"time"] floatValue];
        cell.time24 = [shootsArray[i][@"time24"] floatValue];
        [statistics.shoots addObject:cell];
      }
    }
    
    [self.team2dataStatistics setValue:statistics forKey:UidOrFaceid];
  }
  
  //比赛时间线
  NSArray* timelineArray = jsonData[@"timeline"];
  if(timelineArray){
    
  }
}
@end

@implementation TeamMemberStruct

@end

@implementation DataStatisticsStruct
-(id)init
{
  self = [super init];
  if(self){
    self.points = [[NSMutableArray alloc] init];
    self.rebounds = [[NSMutableArray alloc] init];
    self.assists = [[NSMutableArray alloc] init];
    self.blocks = [[NSMutableArray alloc] init];
    self.steals = [[NSMutableArray alloc] init];
    self.faults = [[NSMutableArray alloc] init];
    self.fouls = [[NSMutableArray alloc] init];
    self.freethrow = [[NSMutableArray alloc] init];
    self.shoots = [[NSMutableArray alloc] init];
    self.oncourttimes = [[NSMutableArray alloc] init];
  }
  return self;
}
@end

@implementation SingleDataStruct

@end

@implementation FreethrowStruct

@end

@implementation ShootStruct

@end

@implementation OnCourtTimeStruct

@end

@implementation MatchTimelineStruct

@end
