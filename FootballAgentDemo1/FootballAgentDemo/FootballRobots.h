//
//  FootballRobots.h
//  FootballAgentDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FootballRobots : NSObject
-(id)initWithUserId:(int)userId roomid:(int)roomId;
-(void)startMatch;
@end
