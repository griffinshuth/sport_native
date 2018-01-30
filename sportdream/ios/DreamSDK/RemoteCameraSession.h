//
//  RemoteCameraSession.h
//  sportdream
//
//  Created by lili on 2018/1/17.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraVideoChat/AgoraVideoChat.h>

@interface RemoteCameraSession:NSObject
@property (assign,nonatomic) NSUInteger uid;
@property (strong,nonatomic) AgoraRtcVideoCanvas* canvas;
@property (strong,nonatomic) UIView* hostingView;
@property (strong,nonatomic) NSString* name;

-(id)initWithView:(UIView*)view uid:(NSUInteger)uid;
@end
