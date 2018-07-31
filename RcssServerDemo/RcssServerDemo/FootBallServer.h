//
//  FootBallServer.h
//  RcssServerDemo
//
//  Created by lili on 2018/6/25.
//  Copyright © 2018年 lili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CourtInfo.h"

@protocol StadiumUpdateDelegate <NSObject>
-(void)StadiumUpdate:(CourtInfo*)info;
@end

@interface FootBallServer : NSObject
@property (nonatomic, weak) id <StadiumUpdateDelegate> delegate;
-(id)initWithRoomId:(int)roomId;
-(void)startServer;
-(void)kickOff;
@end
