//
//  AGVideoProcessing.h
//  sportdream
//
//  Created by lili on 2017/12/11.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AgoraVideoChat/AgoraVideoChat.h>

@interface AGVideoProcessing : NSObject
+ (int)registerPreprocessing:(AgoraRtcEngineKit*) kit;
+ (int)deregisterPreprocessing:(AgoraRtcEngineKit*) kit;
@end
