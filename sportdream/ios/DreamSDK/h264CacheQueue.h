//
//  h264CacheQueue.h
//  sportdream
//
//  Created by lili on 2018/1/10.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalWifiNetwork.h"

@interface h264Frame : NSObject
@property (nonatomic,assign) BOOL isKeyFrame;
@property (nonatomic,strong) NSData* frameData;
@property (nonatomic,assign) NSTimeInterval timestamp;
@end

@interface SpsPpsMetaData:NSObject
@property (nonatomic,strong) NSData* sps;
@property (nonatomic,strong) NSData* pps;
@end

@interface h264CacheQueue : NSObject<LocalWifiNetworkDelegate>
-(void)setBigSPSPPS:(const uint8_t*)pps ppsLen:(size_t)ppsLen sps:(const uint8_t*)sps spsLen:(size_t)spsLen;
-(void)enterBigH264:(const void*)data length:(size_t)length isKeyFrame:(bool)isKeyFrame;
-(void)setSmallSPSPPS;
-(void)enterSmallH264;
@end
