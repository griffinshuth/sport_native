//
//  VideoChatSession.h
//  sportdream
//
//  Created by lili on 2018/1/1.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraVideoChat/AgoraVideoChat.h>

@interface VideoChatSession : NSObject
@property (assign,nonatomic) NSUInteger uid;
@property (strong,nonatomic) UIView* hostingView;
@property (strong,nonatomic) AgoraRtcVideoCanvas* canvas;

-(id)initWithUid:(NSUInteger)uid;
+(id)localSession;
+(id)localSessionFromExternal:(UIView*)preview;
@end
