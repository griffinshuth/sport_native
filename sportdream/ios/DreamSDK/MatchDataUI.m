//
//  MatchDataUI.m
//  sportdream
//
//  Created by lili on 2018/6/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "MatchDataUI.h"
#import "MyLayout.h"
#import "NerdyUI.h"

@implementation MatchDataUI
+(UIView*)createBase64Image:(NSString*)base64String width:(int)width height:(int)height
{
  NSData *data = [[NSData alloc] initWithBase64EncodedString:[base64String substringFromIndex:22] options:NSDataBase64DecodingIgnoreUnknownCharacters];
  UIImage *team1image = [UIImage imageWithData: data];
  UIImageView* team1imageview = [UIImageView new];
  team1imageview.myHeight = height;
  team1imageview.myWidth = width;
  team1imageview.image = team1image;
  return team1imageview;
}

+(UIImageView*)createImageOfUrl:(NSString*)imageUrl width:(int)width height:(int)height
{
  NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
  UIImage* image = [UIImage imageWithData:data];
  UIImageView* imageview = [UIImageView new];
  imageview.myHeight = height;
  imageview.myWidth = width;
  imageview.image = image;
  imageview.borderRadius(5);
  return imageview;
}

+(UIView*)createCourtDataView:(NSDictionary*)gameData
{
  MyRelativeLayout *CourtData = [MyRelativeLayout new];
  CourtData.myHeight = 100;
  CourtData.myLeading = 0;
  CourtData.myTrailing = 0;
  //显示第一队信息
  NSDictionary* team1info = gameData[@"team1info"];
  MyLinearLayout* team1board = [MyLinearLayout new];
  team1board.backgroundColor = [UIColor yellowColor];
  team1board.heightSize.equalTo(@100);
  team1board.topPos.equalTo(@0);
  team1board.leadingPos.equalTo(@0);
  team1board.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  //logo
  [team1board addSubview:[MatchDataUI createBase64Image:team1info[@"logo"] width:32 height:32]];
  //队名
  UILabel* team1name = [UILabel new];
  team1name.text = team1info[@"name"];
  [team1name sizeToFit];
  [team1board addSubview:team1name];
  //得分
  int team1Score = [gameData[@"team1currentscore"] intValue];
  UILabel* team1ScoreLabel = [UILabel new];
  team1ScoreLabel.text = [[NSString alloc] initWithFormat:@"得分：%d",team1Score];
  [team1ScoreLabel sizeToFit];
  [team1board addSubview:team1ScoreLabel];
  //暂停
  int team1timeout = [gameData[@"team1timeout"] intValue];
  UILabel* team1TimeoutLabel = [UILabel new];
  team1TimeoutLabel.text = [[NSString alloc] initWithFormat:@"暂停：%d",team1timeout];
  [team1TimeoutLabel sizeToFit];
  [team1board addSubview:team1TimeoutLabel];
  
  [CourtData addSubview:team1board];
  //比赛时间相关信息
  MyLinearLayout* matchTimeview = [MyLinearLayout new];
  matchTimeview.backgroundColor = [UIColor blueColor];
  matchTimeview.heightSize.equalTo(@100);
  matchTimeview.topPos.equalTo(team1board.topPos);
  matchTimeview.leadingPos.equalTo(team1board.trailingPos);
  matchTimeview.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  //24秒
  int second24 = [gameData[@"currentattacktime"] intValue];
  UILabel* second24Label = [UILabel new];
  second24Label.text = [[NSString alloc] initWithFormat:@"24秒：%d",second24];
  [second24Label sizeToFit];
  [matchTimeview addSubview:second24Label];
  //第几节
  int section = [gameData[@"currentsection"] intValue];
  UILabel* sectionLabel = [UILabel new];
  sectionLabel.text = [[NSString alloc] initWithFormat:@"节：%d",section];
  [sectionLabel sizeToFit];
  [matchTimeview addSubview:sectionLabel];
  //当前节的当前时间
  int sectiontime = [gameData[@"currentsectiontime"] intValue];
  UILabel* sectiontimeLabel = [UILabel new];
  sectiontimeLabel.text = [[NSString alloc] initWithFormat:@"时间：%d",sectiontime];
  [sectiontimeLabel sizeToFit];
  [matchTimeview addSubview:sectiontimeLabel];
  [CourtData addSubview:matchTimeview];
  //显示第二队信息
  NSDictionary* team2info = gameData[@"team2info"];
  MyLinearLayout* team2board = [MyLinearLayout new];
  team2board.backgroundColor = [UIColor yellowColor];
  team2board.heightSize.equalTo(@100);
  team2board.topPos.equalTo(team1board.topPos);
  team2board.leadingPos.equalTo(matchTimeview.trailingPos);
  team2board.padding = UIEdgeInsetsMake(5, 5, 5, 5);
  //logo
  [team2board addSubview:[MatchDataUI createBase64Image:team2info[@"logo"] width:32 height:32]];
  //队名
  UILabel* team2name = [UILabel new];
  team2name.text = team2info[@"name"];
  [team2name sizeToFit];
  [team2board addSubview:team2name];
  //得分
  int team2Score = [gameData[@"team2currentscore"] intValue];
  UILabel* team2ScoreLabel = [UILabel new];
  team2ScoreLabel.text = [[NSString alloc] initWithFormat:@"得分：%d",team2Score];
  [team2ScoreLabel sizeToFit];
  [team2board addSubview:team2ScoreLabel];
  //暂停
  int team2timeout = [gameData[@"team2timeout"] intValue];
  UILabel* team2TimeoutLabel = [UILabel new];
  team2TimeoutLabel.text = [[NSString alloc] initWithFormat:@"暂停：%d",team2timeout];
  [team2TimeoutLabel sizeToFit];
  [team2board addSubview:team2TimeoutLabel];
  [CourtData addSubview:team2board];
  
  team1board.widthSize.equalTo(@[matchTimeview.widthSize,team2board.widthSize]);
  return CourtData;
}

+(int)TechnicalStatisticsOfIDWithType:(NSString*)type uid:(NSString*)uid gameData:(NSDictionary*)gameData teamindex:(int)teamindex
{
  NSDictionary* statisticsData = nil;
  if(teamindex == 0){
    statisticsData = gameData[@"team1dataStatistics"];
  }else{
    statisticsData = gameData[@"team2dataStatistics"];
  }
  if(statisticsData[uid] == nil){
    return 0;
  }
  if([type isEqualToString:@"point"]){
    NSArray* array = statisticsData[uid][@"point"];
    if(array){
      int total = 0;
      for(int i=0;i<[array count];i++){
        total += [array[i][@"number"] intValue];
      }
      return total;
    }
  }
  return 0;
}

@end
