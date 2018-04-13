//
//  EaseMessageViewManager.h
//  sportdream
//
//  Created by lili on 2017/9/15.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <React/RCTViewManager.h>
#import <AgoraVideoChat/AgoraVideoChat.h>
#import "../AgoraPush/AGVideoProcessing.h"
#import "h264encode.h"

@interface AgorachatViewManager : RCTViewManager <AgoraRtcEngineDelegate,h264encodeDelegate>
@property (strong, nonatomic) AgoraRtcEngineKit *agoraKit;
- (void)addLocalYBuffer:(void *)yBuffer
                uBuffer:(void *)uBuffer
                vBuffer:(void *)vBuffer
                yStride:(int)yStride
                uStride:(int)uStride
                vStride:(int)vStride
                  width:(int)width
                 height:(int)height
               rotation:(int)rotation;
- (void)addRemoteOfUId:(unsigned int)uid
               yBuffer:(void *)yBuffer
               uBuffer:(void *)uBuffer
               vBuffer:(void *)vBuffer
               yStride:(int)yStride
               uStride:(int)uStride
               vStride:(int)vStride
                 width:(int)width
                height:(int)height
              rotation:(int)rotation;

@end
