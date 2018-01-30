//
//  RtmpPush.h
//  sportdream
//
//  Created by lili on 2017/12/29.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rtmp.h"
#import "rtmp_sys.h"
#import "amf.h"

@interface RtmpPush : NSObject
-(bool)startRtmp:(NSString*) pushUrl;
-(void)stopRtmp;
-(int)sendVideoSpsPps:(uint8_t*)pps ppsLen:(int)ppsLen sps:(uint8_t*)sps spsLen:(int)spsLen;
-(void)sendAACHeader;
-(void)sendAACPacket:(void*)data size:(int)size;
-(int)sendH264Packet:(void*)data size:(int)size isKeyFrame:(bool)isKeyFrame;
@end
