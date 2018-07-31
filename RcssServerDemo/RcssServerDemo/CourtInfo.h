//
//  CourtInfo.h
//  RcssServerDemo
//
//  Created by lili on 2018/6/29.
//  Copyright © 2018年 lili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PosInfo:NSObject
@property (nonatomic,assign) short enable;
@property (nonatomic,assign) short side;
@property (nonatomic,assign) short unum;
@property (nonatomic,assign) short angle;
@property (nonatomic,assign) double x;
@property (nonatomic,assign) double y;
@end

@interface TeamInfo:NSObject
@property (nonatomic,strong) NSString* name;
@property (nonatomic,assign) short score;
@end

@interface CourtInfo : NSObject
@property (nonatomic,assign) int time;
@property (nonatomic,assign) int mode;
@property (nonatomic,strong) NSMutableArray<TeamInfo*>* teams;
@property (nonatomic,strong) NSMutableArray<PosInfo*>* players;
@property (nonatomic,strong) PosInfo* ball;
@end
