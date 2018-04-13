//
//  pool_av_user.h
//  sportdream
//
//  Created by lili on 2018/3/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "live_packet_pool.hpp"
#import <AVFoundation/AVFoundation.h>

@interface pool_av_user : NSObject
+(void)sendAudioDataToPool:(void*)buffer length:(int)length;
+(void)sendSpsPpsToPool:(NSData*)sps pps:(NSData*)pps timestramp:(Float64)miliseconds;
+(void)sendVideoDataToPool:(NSData*)data isKeyFrame:(BOOL)isKeyFrame timestramp:(Float64)miliseconds pts:(int64_t) pts dts:(int64_t) dts;
@end
