//
//  MatchDataStruct.h
//  sportdream
//
//  Created by lili on 2018/5/22.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeamMemberStruct:NSObject
@property (nonatomic,strong) NSString* faceid;
@property (nonatomic,assign) int uid;
@property (nonatomic,strong) NSString* nickname;
@property (nonatomic,strong) NSString* image;
@end

@interface SingleDataStruct:NSObject
@property (nonatomic,assign) int number;
@property (nonatomic,assign) int section;
@property (nonatomic,assign) float time;
@property (nonatomic,assign) float time24;
@end

@interface FreethrowStruct:NSObject
@property (nonatomic,assign) int type;
@property (nonatomic,assign) int shoot;
@property (nonatomic,assign) int score;
@property (nonatomic,assign) int section;
@property (nonatomic,assign) float time;
@property (nonatomic,assign) float time24;
@end

@interface ShootStruct:NSObject
@property (nonatomic,assign) float x;
@property (nonatomic,assign) float y;
@property (nonatomic,assign) int point;
@property (nonatomic,assign) BOOL isScore;
@property (nonatomic,assign) int section;
@property (nonatomic,assign) float time;
@property (nonatomic,assign) float time24;
@end

@interface OnCourtTimeStruct:NSObject
@property (nonatomic,assign) int state;
@property (nonatomic,assign) int oncourt_section;
@property (nonatomic,assign) float oncourt_time;
@property (nonatomic,assign) float oncourt_time24;
@property (nonatomic,assign) int offcourt_section;
@property (nonatomic,assign) float offcourt_time;
@property (nonatomic,assign) float offcourt_time24;
@end

@interface DataStatisticsStruct:NSObject
@property (nonatomic,strong) NSMutableArray<SingleDataStruct*>* points;
@property (nonatomic,strong) NSMutableArray<SingleDataStruct*>* rebounds;
@property (nonatomic,strong) NSMutableArray<SingleDataStruct*>* assists;
@property (nonatomic,strong) NSMutableArray<SingleDataStruct*>* blocks;
@property (nonatomic,strong) NSMutableArray<SingleDataStruct*>* steals;
@property (nonatomic,strong) NSMutableArray<SingleDataStruct*>* faults;
@property (nonatomic,strong) NSMutableArray<SingleDataStruct*>* fouls;
@property (nonatomic,strong) NSMutableArray<FreethrowStruct*>* freethrow;
@property (nonatomic,strong) NSMutableArray<ShootStruct*>* shoots;
@property (nonatomic,strong) NSMutableArray<OnCourtTimeStruct*>* oncourttimes;
@end

@interface MatchTimelineStruct:NSObject
@property (nonatomic,assign) int64_t absoluteTime;
@property (nonatomic,assign) int actionType;
@property (nonatomic,assign) int team_uid;
@property (nonatomic,assign) int player_uid;
@property (nonatomic,assign) int otherplayer_uid;
@property (nonatomic,assign) int actionResult;
@property (nonatomic,assign) int section;
@property (nonatomic,assign) float sectiontime;
@property (nonatomic,assign) float time24;
@end


@interface MatchDataStruct : NSObject
@property (nonatomic,assign) int game_uid;
@property (nonatomic,assign) int team1_uid;
@property (nonatomic,assign) int team2_uid;
@property (nonatomic,strong) NSString* team1name;
@property (nonatomic,strong) NSString* team2name;
@property (nonatomic,strong) NSString* team1logo;
@property (nonatomic,strong) NSString* team2logo;
@property (nonatomic,strong) NSMutableArray<TeamMemberStruct*>* team1MembersOnCourt;
@property (nonatomic,strong) NSMutableArray<TeamMemberStruct*>* team2MembersOnCourt;
@property (nonatomic,strong) NSMutableArray<TeamMemberStruct*>* team1MembersOffCourt;
@property (nonatomic,strong) NSMutableArray<TeamMemberStruct*>* team2MembersOffCourt;
@property (nonatomic,assign) float currentattacktime;
@property (nonatomic,assign) int currentsection;
@property (nonatomic,assign) float currentsectiontime;
@property (nonatomic,assign) int team1currentscore;
@property (nonatomic,assign) int team2currentscore;
@property (nonatomic,assign) int team1timeout;
@property (nonatomic,assign) int team2timeout;
@property (nonatomic,strong) NSMutableDictionary<NSString*,DataStatisticsStruct*>* team1dataStatistics;
@property (nonatomic,strong) NSMutableDictionary<NSString*,DataStatisticsStruct*>* team2dataStatistics;
@property (nonatomic,strong) NSMutableArray<MatchTimelineStruct*>* timeline;

-(void)loadMatchData:(NSDictionary*)jsonData;
@end
