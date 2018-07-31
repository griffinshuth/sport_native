//
//  LivePusher.h
//  sportdream
//
//  Created by lili on 2017/12/11.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LivePusher : NSObject
+ (void)start:(NSString*)urlOrFileName isRtmp:(BOOL)isRtmp;
+ (void)stop;
+ (void)addLocalYBuffer:(void *)yBuffer
                uBuffer:(void *)uBuffer
                vBuffer:(void *)vBuffer
                yStride:(int)yStride
                uStride:(int)uStride
                vStride:(int)vStride
                  width:(int)width
                 height:(int)height
               rotation:(int)rotation;
+ (void)addRemoteOfUId:(unsigned int)uid
               yBuffer:(void *)yBuffer
               uBuffer:(void *)uBuffer
               vBuffer:(void *)vBuffer
               yStride:(int)yStride
               uStride:(int)uStride
               vStride:(int)vStride
                 width:(int)width
                height:(int)height
              rotation:(int)rotation;

+ (void)addAudioBuffer:(void *)buffer length:(int)length;
@end
